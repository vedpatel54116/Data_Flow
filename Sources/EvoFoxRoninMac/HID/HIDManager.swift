import Foundation
import IOKit
import IOKit.hid
import Combine
import ApplicationServices

// MARK: - HID Global Actor

@globalActor
public actor HIDActor {
    public static let shared = HIDActor()
}

// MARK: - HID Event Stream (AsyncSequence)

public struct HIDEvent: Sendable {
    public let data: Data
    public let timestamp: Date
}

public struct HIDEventStream: AsyncSequence {
    public typealias Element = HIDEvent

    private let stream: AsyncStream<HIDEvent>
    private let continuation: AsyncStream<HIDEvent>.Continuation

    public init() {
        var cont: AsyncStream<HIDEvent>.Continuation!
        stream = AsyncStream { continuation in
            cont = continuation
        }
        continuation = cont
    }

    public func makeAsyncIterator() -> AsyncStream<HIDEvent>.Iterator {
        stream.makeAsyncIterator()
    }

    public func emit(_ event: HIDEvent) {
        continuation.yield(event)
    }

    public func finish() {
        continuation.finish()
    }
}

// MARK: - Connection State

public enum HIDConnectionState: Equatable, Sendable {
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

// MARK: - Error Type

public enum HIDError: Error, Equatable, Sendable {
    case deviceNotFound
    case permissionDenied
    case connectionFailed
    case writeFailed
    case readFailed
    case invalidReportSize(actual: Int, expected: Int)
    case timeout
    case sendFailed(IOReturn)
    case invalidResponse
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
        case .invalidResponse: return "Invalid response from keyboard."
        case .unknown: return "Unknown HID error."
        }
    }

    public var isRetryable: Bool {
        switch self {
        case .timeout, .connectionFailed, .sendFailed: return true
        default: return false
        }
    }
}

// MARK: - Device Info

public struct HIDDeviceInfo: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let vendorID: Int
    public let productID: Int
    public let usagePage: Int
    public let usage: Int
    public let reportSize: Int
    public let transport: String
    public let manufacturer: String

    /// Whether this device is likely an RGB-capable keyboard based on usage page
    public var hasRGBCapability: Bool {
        usagePage >= 0xFF00 || usagePage == 0x01
    }
}

// MARK: - HID Manager

@MainActor
@Observable
open class HIDManager {
    public var connectionState: HIDConnectionState = .disconnected
    public var isMockMode: Bool = false
    public var discoveredDevices: [HIDDeviceInfo] = []

    // IOKit handles are not Sendable, use nonisolated(unsafe) for C interop
    private nonisolated(unsafe) var hidManager: IOHIDManager?
    private nonisolated(unsafe) var device: IOHIDDevice?
    private nonisolated(unsafe) var reportSize: Int = 64
    private nonisolated(unsafe) var inputBuffer: UnsafeMutablePointer<UInt8>?
    private nonisolated(unsafe) var pendingManager: IOHIDManager?

    // Async sequence for HID input events
    public nonisolated(unsafe) let eventStream = HIDEventStream()

    // MARK: - Instance Tracking for Callback Safety
    private static let activeInstanceLock = NSLock()
    private static weak var activeInstance: HIDManager?

    public static func getActiveInstance() -> HIDManager? {
        activeInstanceLock.withLock { activeInstance }
    }

    // Known EvoFox / Amkette / common OEM vendor IDs
    private nonisolated(unsafe) let knownVendorIDs: [Int] = [
        0x320F, 0x258A, 0x0483, 0x0C45, 0x04D9,
        0x060B, 0x0461, 0x2516, 0x1532, 0x25A7,
        0x093A, 0x1BCF, 0x24AE, 0x28AB,
    ]

    private nonisolated(unsafe) let knownNameKeywords = [
        "evofox", "ronin", "amkette", "amk", "evision",
        "gaming keyboard", "mechanical keyboard",
        "usb keyboard", "hid keyboard",
    ]

    private nonisolated(unsafe) let knownProductIDs: [Int] = [
        0x5055, 0x0049, 0x004A, 0x004B, 0x004C,
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
        HIDManager.activeInstanceLock.withLock {
            HIDManager.activeInstance = self
        }
    }

    deinit {
        shutdownHIDManager()
    }

    private nonisolated func shutdownHIDManager() {
        if let device = device {
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
        }
        if let manager = hidManager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        }
        if let buf = inputBuffer {
            buf.deallocate()
        }
        eventStream.finish()
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

        // Close previous manager synchronously on MainActor
        if let oldManager = hidManager {
            IOHIDManagerClose(oldManager, IOOptionBits(kIOHIDOptionsTypeNone))
            hidManager = nil
        }
        device = nil

        Task.detached(priority: .userInitiated) { [weak self] in
            await self?.doConnect()
        }
    }

    private nonisolated func doConnect() async {
        Logger.info("Starting background device scan and connection")

        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(manager, nil)
        self.pendingManager = manager

        if let runLoop = CFRunLoopGetMain() {
            IOHIDManagerScheduleWithRunLoop(manager, runLoop, CFRunLoopMode.defaultMode.rawValue)
        }

        IOHIDManagerRegisterDeviceRemovalCallback(manager, { _, _, _, device in
            guard let active = HIDManager.getActiveInstance() else { return }
            if device == active.device {
                active.device = nil
                Logger.info("HID device disconnected")
                Task { @MainActor in
                    active.connectionState = .disconnected
                }
            }
        }, nil)

        let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        Logger.info("Manager open: 0x\(String(format: "%08X", openResult))")

        guard openResult == kIOReturnSuccess else {
            if openResult == kIOReturnNotPermitted {
                Logger.error("Input Monitoring permission denied")
                await MainActor.run {
                    self.connectionState = .error(.permissionDenied)
                }
            } else {
                Logger.error("Failed to open HID manager: 0x\(String(format: "%08X", openResult))")
                await MainActor.run {
                    self.connectionState = .error(.connectionFailed)
                }
            }
            return
        }

        guard let allDevices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
            Logger.error("No HID devices found")
            await MainActor.run {
                self.connectionState = .error(.deviceNotFound)
            }
            return
        }

        let (deviceInfos, candidates) = scanDevices(allDevices)

        await MainActor.run {
            self.discoveredDevices = deviceInfos.sorted { $0.name < $1.name }
        }

        Logger.info("=== HID Device Scan: \(deviceInfos.count) devices, \(candidates.count) candidates ===")
        for info in deviceInfos {
            let score = scoreDevice(info)
            let marker = score > 0 ? "[MATCH \(score)]" : ""
            Logger.info("  \(marker) \(info.name) VID=0x\(String(format: "%04X", info.vendorID)) PID=0x\(String(format: "%04X", info.productID))")
        }

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

                let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: reportSize)
                HIDManager.registerInputCallback(device: candidate.device, buf: buf, size: reportSize)

                break
            } else {
                Logger.warning("Failed to open \(info.name): 0x\(String(format: "%08X", result))")
            }
        }

        guard let deviceToUse = openedDevice else {
            Logger.error("No compatible keyboard found")
            await MainActor.run {
                self.connectionState = .error(.deviceNotFound)
            }
            return
        }

        await MainActor.run {
            self.hidManager = self.pendingManager
            self.device = deviceToUse
            self.connectionState = .connected(deviceName: openedName)
        }
        Logger.info("Connected to: \(openedName)")
    }

    private nonisolated static func registerInputCallback(device: IOHIDDevice, buf: UnsafeMutablePointer<UInt8>, size: Int) {
        let callback: IOHIDReportCallback = { _, _, _, _, _, report, reportLength in
            let length = Int(reportLength)
            let data = Data(bytes: UnsafeRawPointer(report), count: length)
            let event = HIDEvent(data: data, timestamp: Date())
            Task { @MainActor in
                if let active = HIDManager.getActiveInstance() {
                    active.eventStream.emit(event)
                }
                NotificationCenter.default.post(
                    name: .hidInputReportReceived,
                    object: nil,
                    userInfo: ["report": data]
                )
            }
        }
        IOHIDDeviceRegisterInputReportCallback(device, buf, size, callback, nil)
    }

    private nonisolated func scanDevices(_ allDevices: Set<IOHIDDevice>) -> ([HIDDeviceInfo], [(score: Int, device: IOHIDDevice)]) {
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
        return (deviceInfos, candidates)
    }

    @MainActor
    private func updateState(_ block: @MainActor @Sendable (HIDManager) -> Void) {
        block(self)
    }

    public func disconnect() {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            await MainActor.run {
                if let dev = self.device {
                    IOHIDDeviceClose(dev, IOOptionBits(kIOHIDOptionsTypeNone))
                    self.device = nil
                }
                if let mgr = self.hidManager {
                    IOHIDManagerClose(mgr, IOOptionBits(kIOHIDOptionsTypeNone))
                    self.hidManager = nil
                }
                self.connectionState = .disconnected
                self.discoveredDevices = []
            }
        }
    }

    // MARK: - Device Scoring

    private nonisolated func scoreDevice(_ info: HIDDeviceInfo) -> Int {
        var score = 0

        let lowerName = info.name.lowercased()
        for keyword in knownNameKeywords {
            if lowerName.contains(keyword) {
                score += 100
            }
        }

        if knownVendorIDs.contains(info.vendorID) {
            score += 50
        }

        if knownProductIDs.contains(info.productID) {
            score += 30
        }

        if info.usagePage >= 0xFF00 {
            score += 20
        }

        if info.usagePage == 0x01 && info.usage == 0x06 {
            score += 10
        }

        return score
    }

    // MARK: - Device Info Extraction

    private nonisolated func extractDeviceInfo(device: IOHIDDevice) -> HIDDeviceInfo {
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

        switch result {
        case kIOReturnNotPermitted:
            Logger.error("Permission denied (0xE00002C2). Grant Input Monitoring in System Settings > Privacy & Security > Input Monitoring.")
            connectionState = .error(.permissionDenied)
        case kIOReturnExclusiveAccess:
            Logger.error("Device exclusively claimed by another process (0xE00002C5)")
            connectionState = .error(.connectionFailed)
        case kIOReturnBadArgument:
            Logger.error("Bad argument opening HID device (0xE00002C0)")
            connectionState = .error(.connectionFailed)
        case kIOReturnNotFound:
            Logger.error("HID device not found (0xE00002C2)")
            connectionState = .error(.deviceNotFound)
        default:
            Logger.error("IOHIDDeviceOpen failed with unknown error: 0x\(String(format: "%08X", result))")
            connectionState = .error(.connectionFailed)
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
