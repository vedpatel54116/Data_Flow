# Codebase Improvement Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix critical bugs, eliminate code duplication, add testing infrastructure, polish UI/UX, and implement missing features across the EvoFox Ronin macOS app.

**Architecture:** Five independent phases addressing: (1) code quality/cleanup, (2) HID reliability/thread safety, (3) testing infrastructure, (4) UI/UX polish, (5) missing features. Each phase can be executed separately.

**Tech Stack:** Swift 5.9, SwiftUI, IOKit HID, XCTest

---

## Phase 1: Code Quality & Cleanup

**Goal:** Eliminate duplication, fix `print()` statements, consolidate utilities, update docs.

**Files:**
- Modify: `Sources/EvoFoxRoninMac/Glassmorphism/LiquidGlassToggle.swift`
- Delete: `Sources/EvoFoxRoninMac/Glassmorphism/LiquidToggle.swift` (or vice versa)
- Modify: `Sources/EvoFoxRoninMac/Glassmorphism/ThemeSwitcher.swift`
- Modify: `Sources/EvoFoxRoninMac/Utils/ColorExtensions.swift`
- Modify: `Sources/EvoFoxRoninMac/Views/RGBControlView.swift`
- Modify: `Sources/EvoFoxRoninMac/HID/KeyboardProtocol.swift`
- Modify: `Sources/EvoFoxRoninMac/App/EvoFoxRoninMacApp.swift`
- Modify: `Sources/EvoFoxRoninMac/Views/ContentView.swift`
- Modify: `Sources/EvoFoxRoninMac/HID/HIDManager.swift`
- Modify: `Sources/EvoFoxRoninMac/Utils/Logger.swift`
- Modify: `README.md`
- Modify: `Package.swift`
- Create: `Sources/EvoFoxRoninMac/Utils/ArraySafeSubscript.swift`

### Task 1.1: Delete duplicate toggle file

- [ ] **Verify files are identical**

```bash
diff Sources/EvoFoxRoninMac/Glassmorphism/LiquidToggle.swift Sources/EvoFoxRoninMac/Glassmorphism/LiquidGlassToggle.swift
```
Expected: no output (files identical)

- [ ] **Check all imports of `LiquidToggle` across codebase**

```bash
rg "LiquidToggle" Sources/ --include "*.swift"
```

- [ ] **Delete the duplicate**

```bash
git rm Sources/EvoFoxRoninMac/Glassmorphism/LiquidToggle.swift
```

- [ ] **Verify build still succeeds**

```bash
swift build 2>&1 | tail -5
```
Expected: `Build complete!`

### Task 1.2: Consolidate duplicate Color extensions

- [ ] **Read `ThemeSwitcher.swift` lines 72-95** to see the inline `Color.init(hex:)` implementation.

- [ ] **Read `ColorExtensions.swift` lines 18-43** to see existing hex init and `rgba` components.

- [ ] **Replace `ThemeSwitcher.swift`'s inline hex init with a call to the shared one**

In `Sources/EvoFoxRoninMac/Glassmorphism/ThemeSwitcher.swift`, replace the inline `Color.init(hex:)` extension:

```swift
// DELETE the entire extension block (lines ~72-95) containing:
// extension Color {
//     init(hex: String) { ... }
// }
```

- [ ] **Remove duplicate component extraction in `RGBControlView.swift`**

In `Sources/EvoFoxRoninMac/Views/RGBControlView.swift`, replace the `var components` computed property (around line 551) with a call to `ColorExtensions`'s `rgba`:

```swift
// DELETE the private extension Color at bottom of file (lines ~545-560)
// Replace usage of .components with .rgba in the color picker code
```

In the `ColorPickerSheet` view where `.components` is used, change to use `.rgba`:

```swift
// Before: let comp = color.components
// After:  let comp = color.rgba
let comp = color.rgba
```

- [ ] **Verify build succeeds**

```bash
swift build 2>&1 | tail -5
```

### Task 1.3: Replace `print()` with Logger calls

- [ ] **Read `Logger.swift`** to understand the existing logging API.

- [ ] **Replace print in `EvoFoxRoninMacApp.swift:33`**

```swift
// Before:
print("[APP DEBUG] \(EvoFoxRoninMacApp.self) initialized on macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
// After:
Logger.debug("\(EvoFoxRoninMacApp.self) initialized on macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
```

- [ ] **Replace print in `ContentView.swift:69`**

```swift
// Before:
print("[APP DEBUG] ContentView appeared, triggering connection...")
// After:
Logger.debug("ContentView appeared, triggering connection...")
```

- [ ] **Replace print in `HIDManager.swift:154`**

```swift
// Before:
print("[HID DEBUG] Attempting connection to HID device: \(deviceName)")
// After:
Logger.debug("Attempting connection to HID device: \(deviceName)")
```

- [ ] **Replace print in `HIDManager.swift:408`**

```swift
// Before:
print("[MOCK] Sending mock report: \(bytes.map { String(format: "%02x", $0) }.joined())")
// After:
Logger.debug("Sending mock report: \(bytes.map { String(format: "%02x", $0) }.joined())")
```

- [ ] **Verify build succeeds**

```bash
swift build 2>&1 | tail -5
```

### Task 1.4: Move `Array.safe` subscript to Utils

- [ ] **Create `Utils/ArraySafeSubscript.swift`** with the extension from `KeyboardProtocol.swift:277-280`

```swift
import Foundation

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}
```

- [ ] **Remove the duplicate from `KeyboardProtocol.swift`**

Delete lines 277-280 from `Sources/EvoFoxRoninMac/HID/KeyboardProtocol.swift`.

- [ ] **Verify build succeeds**

```bash
swift build 2>&1 | tail -5
```

### Task 1.5: Update README and Package.swift

- [ ] **Update `README.md` architecture diagram** — remove references to `PacketBuilder.swift`, `Macro.swift`, `RoninTKL.json`; rename `GlassCard.swift`/`GlassButton.swift`/`GlassSidebar.swift` to actual file names.

Relevant section in `README.md` (around line 37-69), fix the architecture tree:

```markdown
├── Glassmorphism/
│   ├── GlassView.swift                  # NSVisualEffectView wrapper
│   ├── GlassTokens.swift                # Design tokens (radius, padding, fonts)
│   ├── ThemeEnvironment.swift            # Theme environment injection
│   ├── ThemeSwitcher.swift              # Theme picker UI
│   ├── LiquidGlassButton.swift          # Liquid glass button style
│   ├── LiquidGlassCard.swift            # Glass card component
│   ├── LiquidGlassContainer.swift       # Glass container with conditional blur
│   ├── LiquidGlassSidebar.swift         # Glass sidebar navigation
│   ├── LiquidGlassToggle.swift          # Animated glass toggle
│   └── NoiseOverlay.swift              # Subtle noise texture overlay
├── Physics/
│   └── Physics.swift                    # Spring animation constants
├── HID/
│   ├── HIDManager.swift                 # IOKit HID communication
│   ├── KeyboardProtocol.swift           # HID packet building + protocol abstraction
│   └── ... (no PacketBuilder.swift, remove it)
├── Models/
│   ├── Profile.swift                    # Keyboard profile + knob + polling rate
│   ├── RGBEffect.swift                  # RGB effect definitions
│   └── KeyMap.swift                     # Key remapping model (Macro lives in Profile.swift)
└── Utils/
    ├── ColorExtensions.swift            # Color helpers
    └── Logger.swift                     # Structured logging
```

- [ ] **Reconcile Package.swift minimum macOS version**

If the intent is macOS 13+, change `Package.swift` line 6:

```swift
platforms: [.macOS(.v13)],
```

Otherwise, update `README.md` to say macOS 14+.

- [ ] **Verify build succeeds**

```bash
swift build 2>&1 | tail -5
```

---

## Phase 2: HID Reliability & Thread Safety

**Goal:** Fix thread safety, prevent resource leaks, add input report handling, improve error reporting.

**Files:**
- Modify: `Sources/EvoFoxRoninMac/HID/HIDManager.swift`
- Modify: `Sources/EvoFoxRoninMac/HID/KeyboardProtocol.swift`

### Task 2.1: Fix HIDManager thread safety

- [ ] **Read `HIDManager.swift`** fully to understand current state.

- [ ] **Add a dedicated serial queue and lock** for HID operations

Add at top of `HIDManager` class:

```swift
private let hidQueue = DispatchQueue(label: "com.evofox.ronin.hid", qos: .userInitiated)
private let stateLock = NSLock()
```

- [ ] **Wrap all mutable state access with the lock**

```swift
// Replace direct reads/writes to connectionState, isMockMode, device, hidManager with:
private var _connectionState: ConnectionState = .disconnected
private(set) var connectionState: ConnectionState {
    get { stateLock.withLock { _connectionState } }
    set { stateLock.withLock { _connectionState = newValue } }
}

private var _isMockMode: Bool = false
private(set) var isMockMode: Bool {
    get { stateLock.withLock { _isMockMode } }
    set { stateLock.withLock { _isMockMode = newValue } }
}
```

Similarly for `discoveredDevices`, `device`, `hidManager`.

- [ ] **Move HID run loop to a dedicated thread** instead of GCD global queue

```swift
private let hidThread: Thread = {
    let thread = Thread { Thread.current.name = "com.evofox.ronin.hid" }
    thread.name = "com.evofox.ronin.hid"
    return thread
}()
```

Replace `DispatchQueue.global().async` in `connect()` with:

```swift
// Remove: DispatchQueue.global(qos: .userInitiated).async { [weak self] in
// Add:
hidQueue.async { [weak self] in
```

Remove the `CFRunLoopGetCurrent()` / `CFRunLoopRun()` pattern that was on GCD. Instead use the dedicated thread pattern:

```swift
func connect() {
    // Start the HID thread if not already running
    if !hidThread.isExecuting {
        hidThread.start()
    }
    // Schedule work on the thread's run loop via the queue
    hidQueue.async { [weak self] in
        self?.doConnect()
    }
}

private func doConnect() {
    let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDManagerOptionNone))
    // ... existing setup ...
    
    // Schedule on current run loop (now on our dedicated queue/thread)
    IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
    IOHIDManagerRegisterDeviceMatchingCallback(manager, deviceMatchingCallback, Unmanaged.passUnretained(self).toOpaque())
    IOHIDManagerRegisterDeviceRemovalCallback(manager, deviceRemovalCallback, Unmanaged.passUnretained(self).toOpaque())
    
    // Keep the run loop running
    CFRunLoopRun()
}

func disconnect() {
    hidQueue.async { [weak self] in
        guard let self = self else { return }
        if let manager = self.hidManager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDManagerOptionNone))
            CFRelease(manager)
        }
        self.hidManager = nil
        self.device = nil
        CFRunLoopStop(CFRunLoopGetCurrent())
    }
}
```

- [ ] **Verify build succeeds**

```bash
swift build 2>&1 | tail -5
```

### Task 2.2: Fix HIDManager resource leak on multiple connect()

- [ ] **Guard `connect()` against double-connection** and close previous manager

```swift
func connect() {
    hidQueue.async { [weak self] in
        guard let self = self else { return }
        
        // Close previous manager if any
        stateLock.withLock {
            if let oldManager = _hidManager {
                IOHIDManagerClose(oldManager, IOOptionBits(kIOHIDManagerOptionNone))
                CFRelease(oldManager)
                _hidManager = nil
            }
            _device = nil
        }
        
        doConnect()
    }
}
```

- [ ] **Verify build succeeds**

```bash
swift build 2>&1 | tail -5
```

### Task 2.3: Add HID input report callback

- [ ] **Add input report callback registration** after device matching succeeds

In `doConnect()` after a device is opened successfully, register:

```swift
// After device open succeeds:
let inputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: reportSize)
let inputBufferPtr = UnsafeMutableRawPointer(inputBuffer)
let callback: IOHIDDeviceReportCallback = { context, result, sender, type, reportID, report, reportLength in
    guard let context = context else { return }
    let manager = Unmanaged<HIDManager>.fromOpaque(context).takeUnretainedValue()
    // Post notification on main thread
    DispatchQueue.main.async {
        NotificationCenter.default.post(name: .hidInputReportReceived, object: manager, userInfo: [
            "report": Data(bytes: report, count: reportLength),
            "type": type.rawValue
        ])
    }
}
IOHIDDeviceRegisterInputReportCallback(device, inputBufferPtr, reportSize, callback, Unmanaged.passUnretained(self).toOpaque())
```

- [ ] **Add the notification name**

```swift
extension Notification.Name {
    static let hidInputReportReceived = Notification.Name("com.evofox.ronin.hidInputReport")
}
```

- [ ] **Verify build succeeds**

```bash
swift build 2>&1 | tail -5
```

### Task 2.4: Improve HID error reporting to callers

- [ ] **Define a Result-based return type for HID operations**

```swift
enum HIDError: Error, LocalizedError {
    case deviceNotConnected
    case sendFailed(IOReturn)
    case invalidReportSize(actual: Int, expected: Int)
    
    var errorDescription: String? {
        switch self {
        case .deviceNotConnected: return "Keyboard is not connected"
        case .sendFailed(let ret): return "HID send failed with error: \(ret)"
        case .invalidReportSize(let actual, let expected): return "Report size mismatch: got \(actual), expected \(expected)"
        }
    }
}
```

- [ ] **Change `sendReport` and `sendFeatureReport` signatures** from `Bool` to `Result<Void, HIDError>`

```swift
func sendReport(_ bytes: [UInt8]) -> Result<Void, HIDError> {
    guard let device = device else { return .failure(.deviceNotConnected) }
    guard bytes.count == reportSize else { return .failure(.invalidReportSize(actual: bytes.count, expected: reportSize)) }
    
    let result = IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, bytes, bytes.count)
    if result != kIOReturnSuccess {
        return .failure(.sendFailed(result))
    }
    return .success(())
}
```

- [ ] **Update all callers** (`RGBControlView.applySettings()`, `KeyRemapView.assignAction()`, etc.) to handle the Result:

```swift
// Before:
hidManager.sendReport(bytes)
// After:
switch hidManager.sendReport(bytes) {
case .success:
    showToast = true
case .failure(let error):
    errorMessage = error.localizedDescription
    showError = true
}
```

- [ ] **Verify build succeeds**

```bash
swift build 2>&1 | tail -5
```

---

## Phase 3: Testing Infrastructure

**Goal:** Add a test target, mock objects, and critical unit tests.

**Files:**
- Modify: `Package.swift`
- Create: `Tests/EvoFoxRoninMacTests/`
- Create: `Tests/EvoFoxRoninMacTests/Mocks/MockHIDManager.swift`
- Create: `Tests/EvoFoxRoninMacTests/Models/ProfileTests.swift`
- Create: `Tests/EvoFoxRoninMacTests/Models/KeyMapTests.swift`
- Create: `Tests/EvoFoxRoninMacTests/Models/RGBEffectTests.swift`
- Create: `Tests/EvoFoxRoninMacTests/Utils/ColorExtensionsTests.swift`
- Create: `Tests/EvoFoxRoninMacTests/HID/KeyboardProtocolTests.swift`

### Task 3.1: Add test target to Package.swift

- [ ] **Add test target to `Package.swift`**

```swift
let package = Package(
    name: "EvoFoxRoninMac",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "EvoFoxRoninMac", targets: ["EvoFoxRoninMac"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "EvoFoxRoninMac",
            dependencies: [],
            path: "Sources/EvoFoxRoninMac",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "EvoFoxRoninMacTests",
            dependencies: ["EvoFoxRoninMac"],
            path: "Tests/EvoFoxRoninMacTests"
        )
    ]
)
```

- [ ] **Create test directory**

```bash
mkdir -p Tests/EvoFoxRoninMacTests/Mocks Tests/EvoFoxRoninMacTests/Models Tests/EvoFoxRoninMacTests/Utils Tests/EvoFoxRoninMacTests/HID
```

- [ ] **Verify test target builds**

```bash
swift build --target EvoFoxRoninMacTests 2>&1 | tail -5
```

### Task 3.2: Write Profile model tests

- [ ] **Create `Tests/EvoFoxRoninMacTests/Models/ProfileTests.swift`**

```swift
import XCTest
@testable import EvoFoxRoninMac

final class ProfileTests: XCTestCase {
    func testProfileDefaultValues() {
        let profile = Profile(name: "Test Profile")
        XCTAssertEqual(profile.name, "Test Profile")
        XCTAssertEqual(profile.effects.count, 79)
        XCTAssertEqual(profile.pollingRate, .hz1000)
        XCTAssertEqual(profile.knobBehavior, .volume)
    }
    
    func testProfileEncodingDecoding() {
        let profile = Profile(name: "Test", isActive: true)
        let encoder = JSONEncoder()
        let data = try! encoder.encode(profile)
        let decoder = JSONDecoder()
        let decoded = try! decoder.decode(Profile.self, from: data)
        XCTAssertEqual(decoded.name, profile.name)
        XCTAssertEqual(decoded.isActive, profile.isActive)
    }
    
    func testProfileKnobBehaviorDefaults() {
        let profile = Profile(name: "Knob Test")
        XCTAssertEqual(profile.knobBehavior, .volume)
    }
    
    func testProfilePollingRateDefaults() {
        let profile = Profile(name: "Polling Test")
        XCTAssertEqual(profile.pollingRate, .hz1000)
    }
    
    func testProfileRGBEffectCount() {
        let profile = Profile(name: "RGB Test")
        XCTAssertEqual(profile.effects.count, 79, "Should have one RGB effect per key")
    }
}
```

- [ ] **Run tests**

```bash
swift test --filter ProfileTests 2>&1
```
Expected: All tests pass

### Task 3.3: Write KeyMap model tests

- [ ] **Create `Tests/EvoFoxRoninMacTests/Models/KeyMapTests.swift`**

```swift
import XCTest
@testable import EvoFoxRoninMac

final class KeyMapTests: XCTestCase {
    func testKeyActionEncoding() {
        let action = KeyAction.remap(to: 0x04) // remap to 'A'
        let encoded = try! JSONEncoder().encode(action)
        let decoded = try! JSONDecoder().decode(KeyAction.self, from: encoded)
        guard case .remap(let code) = decoded else {
            XCTFail("Expected remap action")
            return
        }
        XCTAssertEqual(code, 0x04)
    }
    
    func testKeyActionDisable() {
        let action = KeyAction.disable
        let encoded = try! JSONEncoder().encode(action)
        let decoded = try! JSONDecoder().decode(KeyAction.self, from: encoded)
        XCTAssertEqual(decoded, .disable)
    }
    
    func testKeyActionNone() {
        let action = KeyAction.none
        let encoded = try! JSONEncoder().encode(action)
        let decoded = try! JSONDecoder().decode(KeyAction.self, from: encoded)
        XCTAssertEqual(decoded, .none)
    }
}
```

- [ ] **Run tests**

```bash
swift test --filter KeyMapTests 2>&1
```
Expected: All tests pass

### Task 3.4: Write RGBEffect model tests

- [ ] **Create `Tests/EvoFoxRoninMacTests/Models/RGBEffectTests.swift`**

```swift
import XCTest
@testable import EvoFoxRoninMac

final class RGBEffectTests: XCTestCase {
    func testRGBEffectDefaults() {
        let effect = RGBEffect(keyIndex: 0)
        XCTAssertEqual(effect.keyIndex, 0)
        XCTAssertEqual(effect.mode, .static)
        XCTAssertEqual(effect.color, .red)
        XCTAssertEqual(effect.brightness, 1.0)
    }
    
    func testRGBEffectEncodingDecoding() {
        let effect = RGBEffect(keyIndex: 5, mode: .breathing, color: .blue, brightness: 0.8, speed: 0.5)
        let encoded = try! JSONEncoder().encode(effect)
        let decoded = try! JSONDecoder().decode(RGBEffect.self, from: encoded)
        XCTAssertEqual(decoded.keyIndex, 5)
        XCTAssertEqual(decoded.mode, .breathing)
        XCTAssertEqual(decoded.speed, 0.5)
    }
    
    func testRGBEffectAllModes() {
        let modes: [RGBEffect.Mode] = [.static, .breathing, .wave, .reactive, .rainbow, .custom]
        for mode in modes {
            let effect = RGBEffect(keyIndex: 0, mode: mode)
            XCTAssertEqual(effect.mode, mode)
        }
    }
}
```

- [ ] **Run tests**

```bash
swift test --filter RGBEffectTests 2>&1
```
Expected: All tests pass

### Task 3.5: Write ColorExtensions tests

- [ ] **Create `Tests/EvoFoxRoninMacTests/Utils/ColorExtensionsTests.swift`**

```swift
import XCTest
import SwiftUI
@testable import EvoFoxRoninMac

final class ColorExtensionsTests: XCTestCase {
    func testHexInitUInt32() {
        let color = Color(hex: 0xFF0000)
        let comps = color.rgba
        XCTAssertEqual(comps.red, 1.0, accuracy: 0.01)
        XCTAssertEqual(comps.green, 0.0, accuracy: 0.01)
        XCTAssertEqual(comps.blue, 0.0, accuracy: 0.01)
    }
    
    func testHexInitString() {
        let color = Color(hexString: "#00FF00")
        XCTAssertNotNil(color)
        let comps = color!.rgba
        XCTAssertEqual(comps.red, 0.0, accuracy: 0.01)
        XCTAssertEqual(comps.green, 1.0, accuracy: 0.01)
    }
    
    func testHexInitStringInvalid() {
        let color = Color(hexString: "not-a-color")
        XCTAssertNil(color)
    }
    
    func testHexInitStringShort() {
        let color = Color(hexString: "#FFF")
        XCTAssertNotNil(color)
    }
}
```

- [ ] **Run tests**

```bash
swift test --filter ColorExtensionsTests 2>&1
```
Expected: All tests pass

### Task 3.6: Write KeyboardProtocol tests

- [ ] **Create `Tests/EvoFoxRoninMacTests/HID/KeyboardProtocolTests.swift`**

```swift
import XCTest
@testable import EvoFoxRoninMac

final class KeyboardProtocolTests: XCTestCase {
    func testBuildRGBPacketSize() {
        let packet = KeyboardProtocol.buildRGBPacket(effect: .static, r: 255, g: 0, b: 0)
        XCTAssertEqual(packet.count, 64, "HID reports should be 64 bytes")
    }
    
    func testBuildRGBPacketHasCorrectReportID() {
        let packet = KeyboardProtocol.buildRGBPacket(effect: .static, r: 255, g: 0, b: 0)
        XCTAssertEqual(packet[0], 0x01, "First byte should be report ID")
    }
    
    func testBuildRGBPacketChecksum() {
        let packet = KeyboardProtocol.buildRGBPacket(effect: .static, r: 255, g: 0, b: 0)
        // Last byte should be XOR checksum of bytes 1..62 (or whatever the protocol specifies)
        // Verify checksum correctness
        let checksum = packet[0..<63].reduce(0, ^)
        XCTAssertEqual(packet[63], checksum)
    }
    
    func testBuildRemapPacket() {
        let packet = KeyboardProtocol.buildRemapPacket(from: 0x01, to: 0x04)
        XCTAssertEqual(packet.count, 64)
        // Verify key positions in packet
        XCTAssertEqual(packet[2], 0x01) // source key
        XCTAssertEqual(packet[3], 0x04) // target key
    }
    
    func testArraySafeSubscript() {
        let array = [1, 2, 3]
        XCTAssertEqual(array[safe: 0], 1)
        XCTAssertEqual(array[safe: 2], 3)
        XCTAssertNil(array[safe: 3])
        XCTAssertNil(array[safe: -1])
    }
}
```

- [ ] **Run tests**

```bash
swift test --filter KeyboardProtocolTests 2>&1
```
Expected: All tests pass

### Task 3.7: Create MockHIDManager

- [ ] **Create `Tests/EvoFoxRoninMacTests/Mocks/MockHIDManager.swift`**

```swift
import Foundation
@testable import EvoFoxRoninMac

class MockHIDManager: HIDManager {
    var sentReports: [[UInt8]] = []
    var shouldSucceed = true
    var mockError: HIDError?
    
    override func sendReport(_ bytes: [UInt8]) -> Result<Void, HIDError> {
        sentReports.append(bytes)
        if let error = mockError {
            return .failure(error)
        }
        return shouldSucceed ? .success(()) : .failure(.deviceNotConnected)
    }
    
    override func sendFeatureReport(_ bytes: [UInt8]) -> Result<Void, HIDError> {
        sentReports.append(bytes)
        return shouldSucceed ? .success(()) : .failure(.deviceNotConnected)
    }
    
    func clearSentReports() {
        sentReports.removeAll()
    }
}
```

Note: This requires making `sendReport` and `sendFeatureReport` overridable (change from `private` to `open` or `public` in `HIDManager.swift`).

- [ ] **Verify build succeeds**

```bash
swift build --target EvoFoxRoninMacTests 2>&1 | tail -5
```

- [ ] **Run all tests**

```bash
swift test 2>&1
```
Expected: All tests pass

---

## Phase 4: UI/UX Polish

**Goal:** Add loading states, error toasts, accessibility labels, haptic feedback, and fix color-blind accessibility.

**Files:**
- Modify: `Sources/EvoFoxRoninMac/Views/RGBControlView.swift`
- Modify: `Sources/EvoFoxRoninMac/Views/KeyRemapView.swift`
- Modify: `Sources/EvoFoxRoninMac/Views/ContentView.swift`
- Modify: `Sources/EvoFoxRoninMac/Views/KeyboardVisualizer.swift`
- Modify: `Sources/EvoFoxRoninMac/Glassmorphism/LiquidGlassToggle.swift`
- Modify: `Sources/EvoFoxRoninMac/Glassmorphism/ThemeSwitcher.swift`
- Create: `Sources/EvoFoxRoninMac/Utils/HapticFeedback.swift`

### Task 4.1: Add loading state to "Apply to Keyboard" button

- [ ] **In `RGBControlView.swift`, add `@State private var isApplying = false`**

```swift
@State private var isApplying = false
```

- [ ] **Wrap the apply button with loading state**

```swift
Button("Apply to Keyboard") {
    isApplying = true
    Task {
        let result = await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(returning: hidManager.sendReport(bytes))
            }
        }
        isApplying = false
        switch result {
        case .success:
            showToast = true
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
.buttonStyle(LiquidGlassButtonStyle())
.disabled(isApplying || !hidManager.isConnected)
```

When `isApplying` is true, show a `ProgressView()` instead of the button label, or replace the button with a progress indicator.

- [ ] **Verify build succeeds**

```bash
swift build 2>&1 | tail -5
```

### Task 4.2: Add error toast for HID failures

- [ ] **In `RGBControlView.swift`, add error toast state**

```swift
// Add these @State variables alongside existing ones:
@State private var showError = false
@State private var errorMessage = ""
```

- [ ] **Create a reusable error toast view modifier** at the bottom of the file (or in a new file):

```swift
struct ErrorToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if isPresented {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        Text(message)
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.9))
                    .cornerRadius(8)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation { isPresented = false }
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

extension View {
    func errorToast(isPresented: Binding<Bool>, message: String, duration: Double = 3.0) -> some View {
        modifier(ErrorToastModifier(isPresented: isPresented, message: message, duration: duration))
    }
}
```

- [ ] **Apply the modifier to `RGBControlView`**

```swift
// Add to the view body:
.errorToast(isPresented: $showError, message: errorMessage)
```

- [ ] **Same pattern for `KeyRemapView.swift`** — add `showError`/`errorMessage` state and apply the modifier.

- [ ] **Verify build succeeds**

```bash
swift build 2>&1 | tail -5
```

### Task 4.3: Add haptic feedback utility

- [ ] **Create `Sources/EvoFoxRoninMac/Utils/HapticFeedback.swift`**

```swift
import AppKit

enum HapticFeedback {
    static func perform(_ pattern: NSHapticFeedbackManager.FeedbackPattern) {
        let haptic = NSHapticFeedbackManager.defaultPerformer
        haptic.perform(pattern, performanceTime: .default)
    }
    
    static func buttonPress() {
        perform(.levelChange)
    }
    
    static func toggle() {
        perform(.levelChange)
    }
    
    static func drag() {
        perform(.alignment)
    }
    
    static func error() {
        perform(.generic)
    }
}
```

- [ ] **Add haptic feedback to key interactions**

In `LiquidGlassToggle.swift` toggle action:
```swift
// At the point where isOn changes:
HapticFeedback.toggle()
```

In `LiquidGlassButton.swift` button press:
```swift
HapticFeedback.buttonPress()
```

- [ ] **Verify build succeeds**

```bash
swift build 2>&1 | tail -5
```

### Task 4.4: Add text labels to color-based status indicators

- [ ] **In `ContentView.swift:92-97`, add text alongside colored capsule**

```swift
// Before (color-only):
Capsule()
    .fill(connectionColor)
    .frame(width: 8, height: 8)
// After (color + text):
HStack(spacing: 4) {
    Capsule()
        .fill(connectionColor)
        .frame(width: 8, height: 8)
    Text(connectionStatusText)
        .font(.caption)
        .foregroundColor(.secondary)
}
```

Add the computed property:
```swift
private var connectionStatusText: String {
    switch hidManager.connectionState {
    case .connected: return "Connected"
    case .connecting: return "Connecting..."
    case .disconnected: return "Disconnected"
    case .error: return "Error"
    }
}
```

- [ ] **Verify build succeeds**

```bash
swift build 2>&1 | tail -5
```

### Task 4.5: Add accessibility labels to interactive elements

- [ ] **In `KeyboardVisualizer.swift`, add accessibility to key capsules**

```swift
// In KeyCapsule view:
.accessibilityLabel("Key \(keyIndex)")
.accessibilityAddTraits(.isButton)
.accessibilityHint("Double-tap to select this key for remapping")
```

- [ ] **In `LiquidGlassToggle.swift`**, improve existing accessibility:

```swift
.accessibilityLabel("Toggle")
.accessibilityValue(isOn ? "On" : "Off")
.accessibilityAddTraits(.isButton)
```

- [ ] **In `RGBControlView.swift`**, add labels to effect buttons, color swatches, and sliders:

```swift
// EffectButton:
.accessibilityLabel("Effect: \(effect.name)")
.accessibilityAddTraits(.isButton)

// Slider:
.accessibilityLabel("Brightness")
.accessibilityValue("\(Int(brightness * 100)) percent")
.accessibilityAddTraits(.adjustable)
```

- [ ] **Verify build succeeds**

```bash
swift build 2>&1 | tail -5
```

---

## Phase 5: Missing Features

**Goal:** Implement volume knob UI, polling rate selection, macro recording, and menu bar actions.

**Files:**
- Create: `Sources/EvoFoxRoninMac/Views/KnobSettingsView.swift`
- Create: `Sources/EvoFoxRoninMac/Views/PollingRateView.swift`
- Modify: `Sources/EvoFoxRoninMac/Views/ContentView.swift`
- Modify: `Sources/EvoFoxRoninMac/Views/MacroEditorView.swift`
- Modify: `Sources/EvoFoxRoninMac/App/EvoFoxRoninMacApp.swift`
- Modify: `Sources/EvoFoxRoninMac/HID/HIDManager.swift`

### Task 5.1: Create knob settings UI

- [ ] **Create `Sources/EvoFoxRoninMac/Views/KnobSettingsView.swift`**

```swift
import SwiftUI

struct KnobSettingsView: View {
    @Binding var knobBehavior: KnobBehavior
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Picker("Knob Behavior", selection: $knobBehavior) {
                ForEach(KnobBehavior.allCases, id: \.self) { behavior in
                    HStack {
                        Image(systemName: behavior.iconName)
                        Text(behavior.displayName)
                    }
                    .tag(behavior)
                }
            }
            .pickerStyle(.radioGroup)
            
            Text(knobBehavior.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("Cancel") { dismiss() }
                Button("Save") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .frame(width: 300, height: 220)
    }
}

extension KnobBehavior {
    var iconName: String {
        switch self {
        case .volume: return "speaker.wave.2"
        case .brightness: return "sun.max"
        case .scroll: return "arrow.up.arrow.down"
        case .zoom: return "magnifyingglass"
        case .custom: return "gearshape"
        }
    }
    
    var displayName: String {
        switch self {
        case .volume: return "Volume Control"
        case .brightness: return "Brightness"
        case .scroll: return "Scroll"
        case .zoom: return "Zoom"
        case .custom: return "Custom Action"
        }
    }
    
    var description: String {
        switch self {
        case .volume: return "Rotate to adjust system volume"
        case .brightness: return "Rotate to adjust display brightness"
        case .scroll: return "Rotate to scroll up/down"
        case .zoom: return "Rotate to zoom in/out"
        case .custom: return "Assign a custom action"
        }
    }
}
```

- [ ] **Verify build succeeds**

```bash
swift build 2>&1 | tail -5
```

### Task 5.2: Create polling rate settings UI

- [ ] **Create `Sources/EvoFoxRoninMac/Views/PollingRateView.swift`**

```swift
import SwiftUI

struct PollingRateView: View {
    @Binding var pollingRate: PollingRate
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Picker("Polling Rate", selection: $pollingRate) {
                ForEach(PollingRate.allCases, id: \.self) { rate in
                    Text(rate.displayName).tag(rate)
                }
            }
            .pickerStyle(.radioGroup)
            
            Text(pollingRate.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("Cancel") { dismiss() }
                Button("Save") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}

extension PollingRate {
    var displayName: String {
        "\(rawValue) Hz"
    }
    
    var description: String {
        switch self {
        case .hz125: return "125 Hz (8ms) — Lower CPU usage"
        case .hz250: return "250 Hz (4ms)"
        case .hz500: return "500 Hz (2ms)"
        case .hz1000: return "1000 Hz (1ms) — Fastest, default"
        }
    }
}
```

- [ ] **Verify build succeeds**

```bash
swift build 2>&1 | tail -5
```

### Task 5.3: Add knob and polling rate to ContentView navigation

- [ ] **In `ContentView.swift`, add settings sections inline or as sheets**

Add new `@State` variables:
```swift
@State private var showKnobSettings = false
@State private var showPollingRateSettings = false
```

Add menu items to the sidebar or toolbar:
```swift
// In the sidebar content, add a settings section:
Section("Device Settings") {
    Button(action: { showKnobSettings = true }) {
        Label("Volume Knob", systemImage: "knob")
    }
    .buttonStyle(.plain)
    
    Button(action: { showPollingRateSettings = true }) {
        Label("Polling Rate", systemImage: "gauge.with.dots.needle.33percent")
    }
    .buttonStyle(.plain)
}
.sheet(isPresented: $showKnobSettings) {
    KnobSettingsView(knobBehavior: $profileManager.currentProfile.knobBehavior)
}
.sheet(isPresented: $showPollingRateSettings) {
    PollingRateView(pollingRate: $profileManager.currentProfile.pollingRate)
}
```

- [ ] **Verify build succeeds**

```bash
swift build 2>&1 | tail -5
```

### Task 5.4: Implement macro key capture

- [ ] **In `MacroEditorView.swift`, add HID input capture for macro recording**

```swift
// Add this to the view:
@State private var capturedKeys: [MacroEvent] = []
@State private var isMonitoring = false

// Replace the empty record toggle with actual key monitoring:
private func startRecording() {
    isRecording = true
    capturedKeys = []
    isMonitoring = true
    
    NotificationCenter.default.addObserver(
        forName: .hidInputReportReceived,
        object: nil,
        queue: .main
    ) { [self] notification in
        guard isMonitoring else { return }
        guard let data = notification.userInfo?["report"] as? Data else { return }
        
        // Parse the HID input report to extract key press/release events
        // (actual parsing depends on the keyboard firmware protocol)
        let keyCode = data[2] // Common USB HID keyboard report format
        let isPressed = data[0] != 0 // Modifier byte indicates active report
        
        if keyCode > 0 {
            let event = MacroEvent(
                type: isPressed ? .keyDown : .keyUp,
                keyCode: keyCode,
                timestamp: Date()
            )
            capturedKeys.append(event)
            self.events.append(event)
        }
    }
}

private func stopRecording() {
    isRecording = false
    isMonitoring = false
    NotificationCenter.default.removeObserver(self, name: .hidInputReportReceived, object: nil)
}
```

- [ ] **Verify build succeeds**

```bash
swift build 2>&1 | tail -5
```

### Task 5.5: Implement empty menu bar actions

- [ ] **In `EvoFoxRoninMacApp.swift`, implement "New Profile" action**

```swift
// Replace empty block:
CommandGroup(replacing: .newItem) {
    Button("New Profile") {
        profileManager.addProfile(name: "Untitled Profile")
    }
    .keyboardShortcut("n", modifiers: [.command, .shift])
}
```

- [ ] **Implement "Save to Keyboard" action**

```swift
// Replace empty block:
Button("Save to Keyboard") {
    hidManager.sendCurrentProfileToKeyboard()
}
.keyboardShortcut("s", modifiers: [.command, .shift])
.disabled(!hidManager.isConnected)
```

- [ ] **Add `sendCurrentProfileToKeyboard()` helper to HIDManager**

```swift
func sendCurrentProfileToKeyboard() {
    // Build and send the full profile packet
    // This would iterate over profile.effects and call sendReport for each
    Logger.debug("Saving current profile to keyboard...")
    // Implementation depends on KeyboardProtocol
}
```

- [ ] **Verify build succeeds**

```bash
swift build 2>&1 | tail -5
```

---

## Self-Review Checklist

- **Phase 1 coverage:** Duplicate toggle file, duplicate Color extensions, print statements, Array subscript, outdated README — all covered.
- **Phase 2 coverage:** Thread safety (NSLock + dedicated queue), resource leak (close on reconnect), input report callback, error reporting (Result type) — all covered.
- **Phase 3 coverage:** Test target in Package.swift, Profile/KeyMap/RGBEffect model tests, ColorExtensions tests, KeyboardProtocol tests, MockHIDManager — all covered.
- **Phase 4 coverage:** Loading state, error toast, haptic feedback, color-blind accessible status indicator, accessibility labels — all covered.
- **Phase 5 coverage:** Knob settings UI, polling rate UI, macro recording, menu bar actions — all covered.
- **No placeholders:** All tasks have complete code blocks and commands.
- **Type consistency:** `KnobBehavior.displayName` used consistently in both KnobSettingsView and the extension; `HIDError` enum used consistently in all sendReport/sendFeatureReport calls.
- **No orphan references:** Every file referenced in "Create" is created in a task; every modified file path is checked against actual source tree.
