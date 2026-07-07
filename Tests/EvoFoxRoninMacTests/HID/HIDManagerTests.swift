import XCTest
@testable import EvoFoxRoninMac

@MainActor
final class HIDManagerTests: XCTestCase {
    var sut: HIDManager!

    override func setUp() {
        super.setUp()
        sut = HIDManager(mockMode: true)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testInitialStateIsConnectedInMockMode() {
        XCTAssertTrue(sut.isMockMode)
        XCTAssertEqual(sut.connectionState, .connected(deviceName: "EvoFox Ronin (Mock Mode)"))
    }

    func testNonMockModeStartsDisconnected() {
        let realManager = HIDManager(mockMode: false)
        XCTAssertFalse(realManager.isMockMode)
        XCTAssertEqual(realManager.connectionState, .disconnected)
    }

    func testSendReportSucceedsInMockMode() {
        let result = sut.sendReport(data: [0x07, 0x01, 0x05])
        XCTAssertTrue(result.isSuccess)
    }

    func testSendReportFailsWithoutDevice() {
        let manager = HIDManager(mockMode: false)
        let result = manager.sendReport(data: [0x07, 0x01, 0x05])
        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result {
            XCTAssertEqual(error, .deviceNotFound)
        } else {
            XCTFail("Expected deviceNotFound error")
        }
    }

    func testSendFeatureReportSucceedsInMockMode() {
        let result = sut.sendFeatureReport(data: [0x07, 0x01, 0x05], reportID: 0x01)
        XCTAssertTrue(result.isSuccess)
    }

    func testSendFeatureReportFailsWithoutDevice() {
        let manager = HIDManager(mockMode: false)
        let result = manager.sendFeatureReport(data: [0x07, 0x01, 0x05])
        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result {
            XCTAssertEqual(error, .deviceNotFound)
        } else {
            XCTFail("Expected deviceNotFound error")
        }
    }

    func testEnableMockModeTransitionsToConnected() {
        let manager = HIDManager(mockMode: false)
        XCTAssertEqual(manager.connectionState, .disconnected)
        manager.enableMockMode()
        XCTAssertTrue(manager.isMockMode)
        XCTAssertEqual(manager.connectionState, .connected(deviceName: "EvoFox Ronin (Mock Mode)"))
    }

    func testDisableMockModeSetsMockModeFalse() {
        sut.disableMockMode()
        XCTAssertFalse(sut.isMockMode)
    }

    func testDiagnosticsReportContainsState() {
        let report = sut.diagnosticsReport()
        XCTAssertTrue(report.contains("Connection State:"))
        XCTAssertTrue(report.contains("Mock Mode: true"))
    }

    func testDiagnosticsReportContainsDeviceInfo() {
        let report = sut.diagnosticsReport()
        XCTAssertTrue(report.contains("EvoFox Ronin HID Diagnostics"))
    }

    func testConnectionStateIsConnected() {
        let connected = HIDConnectionState.connected(deviceName: "Test")
        XCTAssertTrue(connected.isConnected)
    }

    func testConnectionStateDisconnectedIsNotConnected() {
        XCTAssertFalse(HIDConnectionState.disconnected.isConnected)
    }

    func testConnectionStateScanningIsNotConnected() {
        XCTAssertFalse(HIDConnectionState.scanning.isConnected)
    }

    func testConnectionStateErrorIsNotConnected() {
        XCTAssertFalse(HIDConnectionState.error(.deviceNotFound).isConnected)
    }

    func testConnectionStateDisplayText() {
        XCTAssertEqual(HIDConnectionState.disconnected.displayText, "Disconnected")
        XCTAssertEqual(HIDConnectionState.scanning.displayText, "Scanning...")
        XCTAssertEqual(HIDConnectionState.connecting.displayText, "Connecting...")
        XCTAssertEqual(HIDConnectionState.connected(deviceName: "Test").displayText, "Connected: Test")
        XCTAssertTrue(HIDConnectionState.error(.deviceNotFound).displayText.hasPrefix("Error:"))
    }

    func testHIDErrorEquality() {
        XCTAssertEqual(HIDError.deviceNotFound, HIDError.deviceNotFound)
        XCTAssertEqual(HIDError.permissionDenied, HIDError.permissionDenied)
        XCTAssertEqual(HIDError.connectionFailed(underlying: "msg"), HIDError.connectionFailed(underlying: "msg"))
        XCTAssertNotEqual(HIDError.deviceNotFound, HIDError.permissionDenied)
    }

    func testHIDErrorIsRetryable() {
        XCTAssertFalse(HIDError.permissionDenied.isRetryable)
        XCTAssertFalse(HIDError.deviceNotFound.isRetryable)
        XCTAssertFalse(HIDError.unsupportedDevice(vendorID: 0, productID: 0).isRetryable)
        XCTAssertFalse(HIDError.memoryAllocationFailed.isRetryable)
        XCTAssertTrue(HIDError.connectionFailed(underlying: "").isRetryable)
        XCTAssertTrue(HIDError.writeFailed(bytesWritten: 0, expected: 64).isRetryable)
        XCTAssertTrue(HIDError.readTimeout.isRetryable)
        XCTAssertTrue(HIDError.invalidResponse.isRetryable)
    }

    func testConnectedDeviceInfo() {
        let descriptor = KeyboardDescriptor(
            id: "test",
            manufacturer: "Test",
            model: "Test",
            vendorID: 0x1234,
            productID: 0x5678,
            capabilities: [.rgbLighting, .perKeyRGB],
            layout: .fullSize,
            protocolVersion: 1,
            maxMacros: 0,
            maxProfiles: 1,
            rgbZones: 0,
            firmwareURL: nil,
            communityVerified: false
        )
        let device = HIDManager.ConnectedDevice(capabilities: descriptor.capabilities)
        XCTAssertTrue(device.capabilities.contains(.rgbLighting))
        XCTAssertTrue(device.capabilities.contains(.perKeyRGB))
    }

    func testHIDDeviceInfoHasRGBCapability() {
        let rgbDevice = HIDDeviceInfo(
            name: "Test", vendorID: 0, productID: 0,
            usagePage: 0xFF01, usage: 0, reportSize: 64,
            transport: "USB", manufacturer: "Test"
        )
        XCTAssertTrue(rgbDevice.hasRGBCapability)

        let nonRgbDevice = HIDDeviceInfo(
            name: "Test", vendorID: 0, productID: 0,
            usagePage: 0x01, usage: 0x06, reportSize: 64,
            transport: "USB", manufacturer: "Test"
        )
        XCTAssertFalse(nonRgbDevice.hasRGBCapability)
    }
}

extension Result {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
}
