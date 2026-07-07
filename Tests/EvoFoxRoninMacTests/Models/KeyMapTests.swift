import XCTest
@testable import EvoFoxRoninMac

final class KeyMapTests: XCTestCase {
    func testKeyMappingCreation() {
        let pos = KeyPosition(row: 3, col: 3)
        let mapping = KeyMapping(keyPosition: pos, keyScanCode: 0x63, assignedAction: .standardKey(keyCode: 0x03))
        XCTAssertEqual(mapping.keyPosition, pos)
        XCTAssertEqual(mapping.keyScanCode, 0x63)
        XCTAssertEqual(mapping.assignedAction, .standardKey(keyCode: 0x03))
    }

    func testKeyActionEncodingDecoding() throws {
        let action = KeyAction.standardKey(keyCode: 0x04)
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(KeyAction.self, from: data)
        XCTAssertEqual(decoded, action)
    }

    func testKeyActionDisable() {
        let action = KeyAction.disabled
        XCTAssertEqual(action.displayLabel, "Disabled")
    }

    func testKeyActionMediaKey() {
        let action = KeyAction.mediaKey(media: .playPause)
        XCTAssertEqual(action.displayLabel, "Play/Pause")
    }

    func testKeyPosition() {
        let pos = KeyPosition(row: 0, col: 0)
        XCTAssertEqual(pos.row, 0)
        XCTAssertEqual(pos.col, 0)
    }

    func testRoninLayoutKeyCount() {
        let allKeys = RoninLayout.allKeys
        XCTAssertEqual(allKeys.count, 79, "TKL layout should have 79 keys")
    }

    func testRoninLayoutRows() {
        XCTAssertEqual(RoninLayout.keys.count, 6, "TKL layout should have 6 rows")
    }

    func testKeyCodeLibrary() {
        XCTAssertEqual(KeyCodeLibrary.name(for: 0x00), "A")
        XCTAssertEqual(KeyCodeLibrary.name(for: 0x25), "Esc")
        XCTAssertEqual(KeyCodeLibrary.name(for: 0xFF), "Key 0xff")
    }
}
