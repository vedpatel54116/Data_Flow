/**
 HIDManager.swift

 Handles USB HID communication with the EvoFox Ronin keyboard using IOKit.

 Discovery strategy (in order of priority):
 1. Match by known EvoFox/Amkette vendor IDs (0x258A, 0x0483, 0x0C45)
 2. Match by product name containing "EvoFox", "Ronin", "Amkette"
 3. Match by any gaming keyboard vendor (broad VID list)
 4. Enumerate ALL HID devices and show them in logs so user can identify

 Usage Page / Usage note:
 - The keyboard keys interface: UsagePage=0x01, Usage=0x06 (Generic Desktop / Keyboard)
 - The RGB control interface often uses: UsagePage=0xFF00+ (vendor-defined)
 - Some keyboards expose BOTH interfaces; we need to match the right one
 - We enumerate ALL HID devices and filter by properties, not by usage

 To identify your keyboard's VID/PID:
 1. Connect the keyboard
 2. Run the app and check logs (Console app or Xcode console)
 3. Look for lines like: "Found HID: name=..., vid=0xXXXX, pid=0xYYYY"
 4. Update the known vendor/product lists below
*/

import Foundation
import IOKit
import IOKit.hid
import Combine
import ApplicationServices

public enum HIDConnectionState: Equatable {
    case disconnected
    case scanning
    case connecting
    case connected(deviceName: String)
    case error(HIDError)

    public var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    public var displayText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .scanning: return "Scanning..."
        case .connecting: return "Connecting..."
        case .connected(let name): return "Connected: \(name)"
        case .error(let error): return "Error: \(error)"
        }
    }
}

public enum HIDError: Error, Equatable {
    case deviceNotFound
    case permissionDenied
    case connectionFailed
    case writeFailed
    case readFailed
    case invalidReportSize(actual: Int, expected: Int)
    case timeout
    case sendFailed(IOReturn)
    case unknown

    public var description: String {
        switch self {
        case .deviceNotFound: return "Keyboard not found. Ensure it's connected via USB."
        case .permissionDenied: return "Permission denied. Grant Input Monitoring permission in System Settings > Privacy & Security > Input Monitoring."
        case .connectionFailed: return "Failed to open connection to keyboard."
        case .writeFailed: return "Failed to send command to keyboard."
        case .readFailed: return "Failed to read response from keyboard."
        case .invalidReportSize(let actual, let expected): return "Invalid HID report size: got \(actual), expected \(expected)."
        case .timeout: return "Communication timeout."
        case .sendFailed(let ret): return "HID send failed with code: 0x\(String(format: "%08X", ret))."
        case .unknown: return "Unknown HID error."
        }
    }
}

/// Discovered device info for logging and diagnostics
public struct HIDDeviceInfo: Identifiable {
    public let id = UUID()
    public let name: String
    public let vendorID: Int
    public let productID: Int
    public let usagePage: Int
    public let usage: Int
    public let reportSize: Int
    public let transport: String
    public let manufacturer: String
}

@Observable
open class HIDManager: @unchecked Sendable {
    public var connectionState: HIDConnectionState {
        get { stateLock.withLock { _connectionState } }
        set { stateLock.withLock { _connectionState = newValue } }
    }
    public var isMockMode: Bool {
        get { stateLock.withLock { _isMockMode } }
        set { stateLock.withLock { _isMockMode = newValue } }
    }
    public var discoveredDevices: [HIDDeviceInfo] {
        get { stateLock.withLock { _discoveredDevices } }
        set { stateLock.withLock { _discoveredDevices = newValue } }
    }

    private var _connectionState: HIDConnectionState = .disconnected
    private var _isMockMode: Bool = false
    private var _discoveredDevices: [HIDDeviceInfo] = []

    private var hidManager: IOHIDManager?
    private var device: IOHIDDevice?
    private var reportSize: Int = 64
    private var inputBuffer: UnsafeMutablePointer<UInt8>?
    private let stateLock = NSLock()
    private let hidQueue = DispatchQueue(label: "com.evofox.ronin.hid", qos: .userInitiated)
    
    // MARK: - Instance Tracking for Callback Safety
    private static let activeInstanceLock = NSLock()
    private static weak var activeInstance: HIDManager?
    
    /// Returns the currently active HIDManager instance, if any
    public static func getActiveInstance() -> HIDManager? {
        activeInstanceLock.withLock { activeInstance }
    }

    // Known EvoFox / Amkette / common OEM vendor IDs
    private let knownVendorIDs: [Int] = [
        0x320F,  // Evision / Ajazz (EvoFox Ronin TKL)
        0x258A,  // Apex Gaming / various OEM
        0x0483,  // STMicroelectronics
        0x0C45,  // Sonix Technology
        0x04D9,  // Holtek
        0x060B,  // Ducky
        0x0461,  // Primax
        0x2516,  // Cooler Master
        0x1532,  // Razer
        0x25A7,  // Areson / generic OEM
        0x093A,  // Pixart Imaging
        0x1BCF,  // Sunrex Technology
        0x24AE,  // Rapoo
        0x28AB,  // Shenzhen X-Keys
    ]

    // Known EvoFox / Amkette product name keywords
    private let knownNameKeywords = [
        "evofox", "ronin", "amkette", "amk", "evision",
        "gaming keyboard", "mechanical keyboard",
        "usb keyboard", "hid keyboard",
    ]

    // Common gaming keyboard PIDs to try
    private let knownProductIDs: [Int] = [
        0x5055,  // EvoFox Ronin TKL Wired
        0x0049, 0x004A, 0x004B, 0x004C,
        0x0001, 0x0002, 0x0003, 0x0004,
        0x1001, 0x1002, 0x1003, 0x1004,
        0x0200, 0x0201, 0x0202, 0x0203,
        0x5011, 0x5012, 0x5013,
    ]

    public init(mockMode: Bool = false) {
        self.isMockMode = mockMode
        if mockMode {
            connectionState = .connected(deviceName: "EvoFox Ronin (Mock Mode)")
        }
        // Track this instance for callback safety
        HIDManager.activeInstanceLock.withLock {
            HIDManager.activeInstance = self
        }
        // NOTE: We do NOT call setupHIDManager() here anymore.
        // IOKit manager is created lazily on first connect() to ensure
        // it's fully ready and avoid lifecycle issues with @State.
    }

    deinit {
        hidQueue.sync { [self] in
            shutdownHIDManager()
        }
    }

    private func shutdownHIDManager() {
        if let device = device {
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
            self.device = nil
        }
        if let manager = hidManager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            hidManager = nil
        }
        if let buf = inputBuffer {
            buf.deallocate()
            inputBuffer = nil
        }
    }

    // MARK: - Connection

    public func connect() {
        Logger.debug("connect() called — isMockMode=\(isMockMode), thread=\(Thread.current)")

        if isMockMode {
            connectionState = .connected(deviceName: "EvoFox Ronin (Mock Mode)")
            return
        }

        connectionState = .scanning
        discoveredDevices = []

        hidQueue.async { [weak self] in
            guard let self = self else { return }
            // Close previous manager if any to prevent resource leak
            stateLock.withLock {
                if let oldManager = self.hidManager {
                    IOHIDManagerClose(oldManager, IOOptionBits(kIOHIDOptionsTypeNone))
                    self.hidManager = nil
                }
                self.device = nil
            }
            doConnect()
        }
    }

    private func doConnect() {
        Logger.info("Starting background device scan and connection")

        // Create a dedicated HID manager for this connection attempt
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(manager, nil)

        // Schedule on the background thread's run loop
        guard let runLoop = CFRunLoopGetCurrent() else {
            Logger.error("Failed to get current run loop")
            self.updateState { $0.connectionState = .error(.unknown) }
            return
        }
        IOHIDManagerScheduleWithRunLoop(manager, runLoop, CFRunLoopMode.defaultMode.rawValue)

        // Register disconnect callback - use static weak reference instead of Unmanaged
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, _, _, device in
            guard let active = HIDManager.activeInstance else { return }
            if device == active.device {
                active.device = nil
                Logger.info("HID device disconnected")
                active.updateState { $0.connectionState = .disconnected }
            }
        }, nil)

        let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        Logger.info("Manager open: 0x\(String(format: "%08X", openResult))")

        guard openResult == kIOReturnSuccess else {
            // Check if this is a permission error
            if openResult == kIOReturnNotPermitted {
                Logger.error("Input Monitoring permission denied — grant in System Settings > Privacy & Security > Input Monitoring")
                self.updateState { $0.connectionState = .error(.permissionDenied) }
            } else {
                Logger.error("Failed to open HID manager: 0x\(String(format: "%08X", openResult))")
                self.updateState { $0.connectionState = .error(.connectionFailed) }
            }
            return
        }

        // Copy and score devices
        guard let allDevices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
            Logger.error("No HID devices found")
            self.updateState { $0.connectionState = .error(.deviceNotFound) }
            return
        }

        var deviceInfos: [HIDDeviceInfo] = []
        var candidates: [(score: Int, device: IOHIDDevice)] = []

        for dev in allDevices {
            let info = extractDeviceInfo(device: dev)
            deviceInfos.append(info)
            let score = scoreDevice(info)
            if score > 0 {
                candidates.append((score: score, device: dev))
            }
        }

        candidates.sort { $0.score > $1.score }
        self.updateState { $0.discoveredDevices = deviceInfos.sorted { $0.name < $1.name } }

        Logger.info("=== HID Device Scan: \(deviceInfos.count) devices, \(candidates.count) candidates ===")
        for info in deviceInfos {
            let score = scoreDevice(info)
            let marker = score > 0 ? "[MATCH \(score)]" : ""
            Logger.info("  \(marker) \(info.name) VID=0x\(String(format: "%04X", info.vendorID)) PID=0x\(String(format: "%04X", info.productID))")
        }

        // Try to open each candidate
        var openedDevice: IOHIDDevice?
        var openedName = ""

        for candidate in candidates {
            let info = extractDeviceInfo(device: candidate.device)
            Logger.info("Opening: \(info.name) (score=\(candidate.score))")
            let result = IOHIDDeviceOpen(candidate.device, IOOptionBits(kIOHIDOptionsTypeNone))
            if result == kIOReturnSuccess {
                openedDevice = candidate.device
                openedName = info.name
                Logger.info("Successfully opened: \(info.name)")

                // Register input report callback - use static weak reference
                let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: self.reportSize)
                self.inputBuffer = buf
                let callback: IOHIDReportCallback = { ctx, _, _, _, _, report, reportLength in
                    guard let active = HIDManager.activeInstance else { return }
                    let length = Int(reportLength)
                    let data = Data(bytes: UnsafeRawPointer(report), count: length)
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .hidInputReportReceived,
                            object: active,
                            userInfo: ["report": data]
                        )
                    }
                }
                IOHIDDeviceRegisterInputReportCallback(
                    candidate.device,
                    buf,
                    self.reportSize,
                    callback,
                    nil
                )

                break
            } else {
                Logger.warning("Failed to open \(info.name): 0x\(String(format: "%08X", result))")
            }
        }

        guard let deviceToUse = openedDevice else {
            Logger.error("No compatible keyboard found")
            self.updateState { $0.connectionState = .error(.deviceNotFound) }
            return
        }

        // Store the manager and device for later use
        stateLock.withLock {
            self.hidManager = manager
            self.device = deviceToUse
        }

        // Update connection state on main thread
        self.updateState { $0.connectionState = .connected(deviceName: openedName) }
        Logger.info("Connected to: \(openedName)")
    }

    /// Thread-safe state update on main thread
    private func updateState(_ block: @escaping (HIDManager) -> Void) {
        if Thread.isMainThread {
            block(self)
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                block(self)
                // Wake up the main run loop in case SwiftUI is in a tracking mode
                CFRunLoopWakeUp(CFRunLoopGetMain())
            }
        }
    }

    public func disconnect() {
        hidQueue.async { [weak self] in
            guard let self = self else { return }
            stateLock.withLock {
                if let dev = self.device {
                    IOHIDDeviceClose(dev, IOOptionBits(kIOHIDOptionsTypeNone))
                    self.device = nil
                }
                if let mgr = self.hidManager {
                    IOHIDManagerClose(mgr, IOOptionBits(kIOHIDOptionsTypeNone))
                    self.hidManager = nil
                }
            }
            self.updateState { $0.connectionState = .disconnected }
            self.updateState { $0.discoveredDevices = [] }
        }
    }

    // MARK: - Device Scoring

    /// Scores how likely a device is to be the EvoFox Ronin.
    /// Higher score = better match. 0 = not a candidate.
    private func scoreDevice(_ info: HIDDeviceInfo) -> Int {
        var score = 0

        // Name match (highest priority)
        let lowerName = info.name.lowercased()
        for keyword in knownNameKeywords {
            if lowerName.contains(keyword) {
                score += 100
            }
        }

        // Known vendor ID
        if knownVendorIDs.contains(info.vendorID) {
            score += 50
        }

        // Known product ID
        if knownProductIDs.contains(info.productID) {
            score += 30
        }

        // Gaming keyboards often use vendor-specific usage pages for RGB control
        if info.usagePage >= 0xFF00 {
            score += 20
        }

        // Standard keyboard interface
        if info.usagePage == 0x01 && info.usage == 0x06 {
            score += 10
        }

        return score
    }

    // MARK: - Device Info Extraction

    private func extractDeviceInfo(device: IOHIDDevice) -> HIDDeviceInfo {
        let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "Unknown"
        let vendorID = (IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int) ?? 0
        let productID = (IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int) ?? 0
        let usagePage = (IOHIDDeviceGetProperty(device, kIOHIDDeviceUsagePageKey as CFString) as? Int) ?? 0
        let usage = (IOHIDDeviceGetProperty(device, kIOHIDDeviceUsageKey as CFString) as? Int) ?? 0
        let reportSize = (IOHIDDeviceGetProperty(device, kIOHIDMaxInputReportSizeKey as CFString) as? Int) ?? 64
        let transport = IOHIDDeviceGetProperty(device, kIOHIDTransportKey as CFString) as? String ?? "unknown"
        let manufacturer = IOHIDDeviceGetProperty(device, kIOHIDManufacturerKey as CFString) as? String ?? ""

        return HIDDeviceInfo(
            name: name.isEmpty ? "Unknown HID Device" : name,
            vendorID: vendorID,
            productID: productID,
            usagePage: usagePage,
            usage: usage,
            reportSize: reportSize,
            transport: transport,
            manufacturer: manufacturer
        )
    }

    private func openDevice(_ device: IOHIDDevice) -> Bool {
        let result = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        if result == kIOReturnSuccess {
            self.device = device
            return true
        }

        // Decode the specific IOKit error
        switch result {
        case kIOReturnNotPermitted:
            Logger.error("Permission denied (0xE00002C2). Grant Input Monitoring in System Settings > Privacy & Security > Input Monitoring.")
            DispatchQueue.main.async {
                self.connectionState = .error(.permissionDenied)
            }
        case kIOReturnExclusiveAccess:
            Logger.error("Device exclusively claimed by another process (0xE00002C5)")
            DispatchQueue.main.async {
                self.connectionState = .error(.connectionFailed)
            }
        case kIOReturnBadArgument:
            Logger.error("Bad argument opening HID device (0xE00002C0)")
            DispatchQueue.main.async {
                self.connectionState = .error(.connectionFailed)
            }
        case kIOReturnNotFound:
            Logger.error("HID device not found (0xE00002C2)")
            DispatchQueue.main.async {
                self.connectionState = .error(.deviceNotFound)
            }
        default:
            Logger.error("IOHIDDeviceOpen failed with unknown error: 0x\(String(format: "%08X", result))")
            DispatchQueue.main.async {
                self.connectionState = .error(.connectionFailed)
            }
        }
        return false
    }

    // MARK: - HID Report Sending

    open func sendReport(data: [UInt8]) -> Result<Void, HIDError> {
        if isMockMode {
            Logger.debug("Would send HID report: \(data.map { String(format: "%02X", $0) }.joined(separator: " "))")
            return .success(())
        }

        guard let device = device else {
            Logger.warning("sendReport called but no device connected")
            return .failure(.deviceNotFound)
        }

        var reportData = data
        if reportData.count > reportSize {
            return .failure(.invalidReportSize(actual: reportData.count, expected: reportSize))
        }
        while reportData.count < reportSize {
            reportData.append(0)
        }

        let dataSize = reportData.count
        let result = reportData.withUnsafeMutableBytes { bytes in
            IOHIDDeviceSetReport(
                device,
                kIOHIDReportTypeOutput,
                CFIndex(0),
                bytes.bindMemory(to: UInt8.self).baseAddress!,
                dataSize
            )
        }

        if result != kIOReturnSuccess {
            Logger.error("sendReport failed with error: 0x\(String(format: "%08X", result))")
            return .failure(.sendFailed(result))
        }

        return .success(())
    }

    open func sendFeatureReport(data: [UInt8], reportID: UInt8 = 0) -> Result<Void, HIDError> {
        if isMockMode {
            Logger.debug("Would send feature report: \(data.map { String(format: "%02X", $0) }.joined(separator: " "))")
            return .success(())
        }

        guard let device = device else {
            Logger.warning("sendFeatureReport called but no device connected")
            return .failure(.deviceNotFound)
        }

        var reportData = data
        if reportID > 0 {
            reportData.insert(reportID, at: 0)
        }
        if reportData.count > reportSize {
            return .failure(.invalidReportSize(actual: reportData.count, expected: reportSize))
        }
        while reportData.count < reportSize {
            reportData.append(0)
        }

        let dataSize = reportData.count
        let result = reportData.withUnsafeMutableBytes { bytes in
            IOHIDDeviceSetReport(
                device,
                kIOHIDReportTypeFeature,
                CFIndex(reportID),
                bytes.bindMemory(to: UInt8.self).baseAddress!,
                dataSize
            )
        }

        if result != kIOReturnSuccess {
            Logger.error("sendFeatureReport failed with error: 0x\(String(format: "%08X", result))")
            return .failure(.sendFailed(result))
        }

        return .success(())
    }

    // MARK: - Diagnostics

    /// Returns a human-readable report of all discovered devices for troubleshooting
    public func diagnosticsReport() -> String {
        var lines: [String] = []
        lines.append("=== EvoFox Ronin HID Diagnostics ===")
        lines.append("Connection State: \(connectionState)")
        lines.append("Mock Mode: \(isMockMode)")
        lines.append("")
        lines.append("Discovered HID Devices (\(discoveredDevices.count)):")
        for info in discoveredDevices {
            let score = scoreDevice(info)
            let marker = score > 0 ? "★ MATCH (score=\(score))" : " "
            lines.append("\(marker)")
            lines.append("  Name:         \(info.name)")
            lines.append("  Manufacturer: \(info.manufacturer)")
            lines.append("  Vendor ID:    0x\(String(format: "%04X", info.vendorID))")
            lines.append("  Product ID:   0x\(String(format: "%04X", info.productID))")
            lines.append("  Usage Page:   0x\(String(format: "%04X", info.usagePage))")
            lines.append("  Usage:        0x\(String(format: "%04X", info.usage))")
            lines.append("  Report Size:  \(info.reportSize)")
            lines.append("  Transport:    \(info.transport)")
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Mock Mode

    public func enableMockMode() {
        isMockMode = true
        disconnect()
        connectionState = .connected(deviceName: "EvoFox Ronin (Mock Mode)")
    }

    public func disableMockMode() {
        isMockMode = false
        connectionState = .disconnected
        connect()
    }
}

extension Notification.Name {
    static let hidInputReportReceived = Notification.Name("com.evofox.ronin.hidInputReport")
}
