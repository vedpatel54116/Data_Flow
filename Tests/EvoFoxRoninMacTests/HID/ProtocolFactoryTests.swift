import XCTest
@testable import EvoFoxRoninMac

@MainActor
final class ProtocolFactoryTests: XCTestCase {
    let mockManager = MockHIDManager()

    func testCreatesEvoFoxProtocolForExactMatch() {
        let device = HIDDeviceInfo(
            name: "EvoFox Ronin",
            vendorID: 0x1234,
            productID: 0x5678,
            usagePage: 0xFF01,
            usage: 0,
            reportSize: 64,
            transport: "USB",
            manufacturer: "EvoFox"
        )
        let descriptor = KeyboardDatabase.descriptor(for: device)
        XCTAssertNotNil(descriptor)
        XCTAssertEqual(descriptor?.id, "evofox.ronin.v1")

        let proto = KeyboardDatabase.makeProtocol(for: descriptor!, hidManager: mockManager)
        XCTAssertTrue(proto is EvoFoxRoninProtocol)
    }

    func testFallsBackToGenericForUnknownVendorWithRGBPage() {
        let device = HIDDeviceInfo(
            name: "Unknown Gaming KB",
            vendorID: 0xDEAD,
            productID: 0xBEEF,
            usagePage: 0xFF01,
            usage: 0,
            reportSize: 64,
            transport: "USB",
            manufacturer: "Generic"
        )
        let descriptor = KeyboardDatabase.descriptor(for: device)
        XCTAssertNotNil(descriptor)
        XCTAssertEqual(descriptor?.id, "generic.hid.rgb")
    }

    func testReturnsNilForUnknownDeviceWithoutRGBPage() {
        let device = HIDDeviceInfo(
            name: "Standard Keyboard",
            vendorID: 0x05AC,
            productID: 0x0220,
            usagePage: 0x01,
            usage: 0x06,
            reportSize: 64,
            transport: "USB",
            manufacturer: "Apple"
        )
        let descriptor = KeyboardDatabase.descriptor(for: device)
        XCTAssertNil(descriptor)
    }

    func testSupportedKeyboardsListIsPopulated() {
        XCTAssertFalse(KeyboardDatabase.supportedKeyboards.isEmpty)
    }

    func testEvoFoxDescriptorHasAllExpectedCapabilities() {
        let evofox = KeyboardDatabase.supportedKeyboards.first { $0.id == "evofox.ronin.v1" }
        XCTAssertNotNil(evofox)
        XCTAssertTrue(evofox!.capabilities.contains(.rgbLighting))
        XCTAssertTrue(evofox!.capabilities.contains(.perKeyRGB))
        XCTAssertTrue(evofox!.capabilities.contains(.macroProgramming))
        XCTAssertTrue(evofox!.capabilities.contains(.keyRemapping))
        XCTAssertTrue(evofox!.capabilities.contains(.mediaKnob))
        XCTAssertTrue(evofox!.capabilities.contains(.pollingRateConfig))
        XCTAssertTrue(evofox!.capabilities.contains(.onboardMemory))
    }

    func testMakeProtocolHandlesAllDescriptors() {
        for descriptor in KeyboardDatabase.supportedKeyboards {
            let proto = KeyboardDatabase.makeProtocol(for: descriptor, hidManager: mockManager)
            XCTAssertTrue(proto is EvoFoxRoninProtocol, "Unexpected protocol for \(descriptor.id)")
        }
    }

    func testMatchByVendorIDOnly() {
        let device = HIDDeviceInfo(
            name: "Some Razer Device",
            vendorID: 0x1532,
            productID: 0x024E,
            usagePage: 0xFF01,
            usage: 0,
            reportSize: 64,
            transport: "USB",
            manufacturer: "Razer"
        )
        let descriptor = KeyboardDatabase.descriptor(for: device)
        XCTAssertNotNil(descriptor)
        XCTAssertEqual(descriptor?.id, "razer.blackwidow.v3")
    }
}
