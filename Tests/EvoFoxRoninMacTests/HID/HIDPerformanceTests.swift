import XCTest
@testable import EvoFoxRoninMac

@MainActor
final class HIDPerformanceTests: XCTestCase {
    let mockManager = MockHIDManager()
    lazy var protocol_ = EvoFoxRoninProtocol(hidManager: mockManager)

    func testBuildPacketAllCommands() {
        let commands: [KeyboardCommand] = [
            .setRGBEffect(effectId: 0x01),
            .setRGBColor(r: 255, g: 128, b: 64),
            .setRGBSpeed(speed: 128),
            .setRGBBrightness(brightness: 255),
            .setRGBDirection(direction: 1),
            .setRGBMode(mode: 0x05),
            .remapKey(scanCode: 0x63, targetKeyCode: 0x04),
            .setMacro(macroId: 0x01, events: [
                KeyboardMacro.MacroEvent(type: .keyDown, keyCode: 0x04, delayMs: 100),
                KeyboardMacro.MacroEvent(type: .delay, delayMs: 500),
            ]),
            .saveProfile(profileId: 0x01),
            .loadProfile(profileId: 0x02),
            .factoryReset,
            .setKnobBehavior(behavior: 0x01),
            .setPollingRate(rate: 0x03),
        ]

        measure {
            for i in 0..<100 {
                let cmd = commands[i % commands.count]
                let packet = protocol_.buildPacket(command: cmd)
                XCTAssertEqual(packet.count, 64)
            }
        }
    }

    func testBuildRGBSettingsPacket() {
        let settings = RGBSettings(
            effect: RGBEffectLibrary.effects[2],
            speed: 128,
            brightness: 255,
            primaryColor: .red,
            secondaryColor: .blue,
            direction: .right,
            isEnabled: true
        )

        measure {
            for _ in 0..<100 {
                let packet = protocol_.buildRGBSettingsPacket(settings: settings)
                XCTAssertEqual(packet.count, 64)
                XCTAssertEqual(packet[0], 0x07)
            }
        }
    }

    func testDecodeResponseThroughput() {
        var validPackets: [[UInt8]] = []
        for reportID in 0..<10 {
            for status in 0..<10 {
                var packet = [UInt8](repeating: 0, count: 64)
                packet[0] = UInt8(reportID)
                packet[1] = UInt8(status)
                packet[2] = UInt8(status)
                validPackets.append(packet)
            }
        }

        measure {
            for packet in validPackets {
                let result = protocol_.decodeResponse(packet: packet)
                if case .success(let response) = result {
                    XCTAssertEqual(response.data.count, 61)
                }
            }
        }
    }

    func testBuildPerKeyColorPacket() {
        var colors: [KeyPosition: EvoFoxRoninMac.RGBColor] = [:]
        for row in 0..<6 {
            let maxCol = RoninLayout.keys[row].count
            for col in 0..<maxCol {
                let pos = KeyPosition(row: row, col: col)
                colors[pos] = EvoFoxRoninMac.RGBColor(
                    r: UInt8((row * 40) & 0xFF),
                    g: UInt8((col * 20) & 0xFF),
                    b: 128
                )
            }
        }

        measure {
            for _ in 0..<50 {
                let packet = protocol_.buildPerKeyColorPacket(keyColors: colors)
                XCTAssertEqual(packet.count, 64)
                XCTAssertEqual(packet[0], 0x07)
                XCTAssertEqual(packet[1], 0x12)
            }
        }
    }

    func testBuildRemapPacketThroughput() {
        let mapping = KeyMapping(
            keyPosition: KeyPosition(row: 3, col: 3),
            keyScanCode: 0x63,
            assignedAction: .standardKey(keyCode: 0x04)
        )

        measure {
            for _ in 0..<200 {
                let packet = protocol_.buildRemapPacket(mapping: mapping)
                XCTAssertEqual(packet.count, 64)
            }
        }
    }
}
