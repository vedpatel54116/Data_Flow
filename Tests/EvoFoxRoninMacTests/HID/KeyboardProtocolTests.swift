import XCTest
@testable import EvoFoxRoninMac

@MainActor
final class KeyboardProtocolTests: XCTestCase {
    let mockManager = MockHIDManager()
    lazy var kbProtocol = EvoFoxRoninProtocol(hidManager: mockManager)

    func testBuildPacketReturns64Bytes() {
        let packet = kbProtocol.buildPacket(command: .setRGBEffect(effectId: 0x01))
        XCTAssertEqual(packet.count, 64, "HID reports should be 64 bytes")
    }

    func testBuildRGBEffectPacket() {
        let packet = kbProtocol.buildPacket(command: .setRGBEffect(effectId: 0x05))
        XCTAssertEqual(packet[0], 0x07)
        XCTAssertEqual(packet[1], 0x01)
        XCTAssertEqual(packet[2], 0x05)
    }

    func testBuildRGBColorPacket() {
        let packet = kbProtocol.buildPacket(command: .setRGBColor(r: 255, g: 128, b: 64))
        XCTAssertEqual(packet[2], 255)
        XCTAssertEqual(packet[3], 128)
        XCTAssertEqual(packet[4], 64)
    }

    func testBuildRemapPacket() {
        let pos = KeyPosition(row: 3, col: 3)
        let mapping = KeyMapping(keyPosition: pos, keyScanCode: 0x63, assignedAction: .standardKey(keyCode: 0x04))
        let packet = kbProtocol.buildRemapPacket(mapping: mapping)
        XCTAssertEqual(packet.count, 64)
        XCTAssertEqual(packet[0], 0x08)
        XCTAssertEqual(packet[2], 0x63)
        XCTAssertEqual(packet[3], 0x01)
    }

    func testBuildRemapPacketDisable() {
        let pos = KeyPosition(row: 0, col: 0)
        let mapping = KeyMapping(keyPosition: pos, keyScanCode: 0x01, assignedAction: .disabled)
        let packet = kbProtocol.buildRemapPacket(mapping: mapping)
        XCTAssertEqual(packet[3], 0x00)
    }

    func testBuildRGBSettingsPacket() {
        let settings = RGBSettings(effect: RGBEffectLibrary.effects[0])
        let packet = kbProtocol.buildRGBSettingsPacket(settings: settings)
        XCTAssertEqual(packet.count, 64)
        XCTAssertEqual(packet[0], 0x07)
        XCTAssertEqual(packet[2], settings.effect.effectId)
        XCTAssertEqual(packet[3], settings.speed)
    }

    func testBuildPerKeyColorPacket() {
        let colors = [KeyPosition(row: 2, col: 3): RGBColor.red]
        let packet = kbProtocol.buildPerKeyColorPacket(keyColors: colors)
        XCTAssertEqual(packet.count, 64)
        XCTAssertEqual(packet[0], 0x07)
        XCTAssertEqual(packet[1], 0x12)
    }

    func testFactoryResetSafety() {
        let packet = kbProtocol.buildPacket(command: .factoryReset)
        XCTAssertEqual(packet[0], 0xFF)
        XCTAssertEqual(packet[2], 0x52)
        XCTAssertEqual(packet[3], 0x45)
        XCTAssertEqual(packet[4], 0x53)
        XCTAssertEqual(packet[5], 0x45)
        XCTAssertEqual(packet[6], 0x54)
    }

    func testDecodeResponse() {
        var packet = [UInt8](repeating: 0, count: 64)
        packet[0] = 0x07
        packet[1] = 0x01
        packet[2] = 0x01
        let response = kbProtocol.decodeResponse(packet: packet)
        switch response {
        case .success(let decoded):
            XCTAssertTrue(decoded.isSuccess)
            XCTAssertEqual(decoded.reportID, 0x07)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testArraySafeSubscript() {
        let array = [1, 2, 3]
        XCTAssertEqual(array[safe: 0], 1)
        XCTAssertEqual(array[safe: 2], 3)
        XCTAssertNil(array[safe: 3])
        XCTAssertNil(array[safe: -1])
    }
}
