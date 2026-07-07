import XCTest
@testable import EvoFoxRoninMac

final class ProfileTests: XCTestCase {
    func testProfileDefaultCreation() {
        let profile = KeyboardProfile(name: "Test Profile")
        XCTAssertEqual(profile.name, "Test Profile")
        XCTAssertEqual(profile.knobBehavior, .volumeControl)
        XCTAssertEqual(profile.pollingRate, .hz1000)
        XCTAssertFalse(profile.isDefault)
        XCTAssertFalse(profile.isDefault)
        XCTAssertTrue(profile.macros.isEmpty)
    }

    func testProfileEncodingDecoding() throws {
        let profile = KeyboardProfile(name: "Test", isDefault: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(profile)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(KeyboardProfile.self, from: data)
        XCTAssertEqual(decoded.name, profile.name)
        XCTAssertEqual(decoded.isDefault, profile.isDefault)
        XCTAssertEqual(decoded.knobBehavior, profile.knobBehavior)
        XCTAssertEqual(decoded.pollingRate, profile.pollingRate)
    }

    func testProfileKnobBehaviorCases() {
        XCTAssertEqual(KeyboardProfile.KnobBehavior.allCases.count, 5)
        XCTAssertEqual(KeyboardProfile.KnobBehavior.volumeControl.rawValue, "Volume Control")
        XCTAssertEqual(KeyboardProfile.KnobBehavior.brightnessControl.rawValue, "Brightness Control")
    }

    func testProfilePollingRateCases() {
        XCTAssertEqual(KeyboardProfile.PollingRate.allCases.count, 4)
        XCTAssertEqual(KeyboardProfile.PollingRate.hz125.rawValue, 125)
        XCTAssertEqual(KeyboardProfile.PollingRate.hz1000.rawValue, 1000)
        XCTAssertEqual(KeyboardProfile.PollingRate.hz1000.displayName, "1000Hz")
    }

    func testProfileManagerInitialState() {
        let manager = ProfileManager()
        XCTAssertFalse(manager.profiles.isEmpty)
        XCTAssertNotNil(manager.activeProfile)
    }

    func testProfileMacroTotalDuration() {
        let macro = KeyboardMacro(
            name: "Test",
            events: [
                KeyboardMacro.MacroEvent(type: .keyDown, delayMs: 100),
                KeyboardMacro.MacroEvent(type: .delay, delayMs: 500),
                KeyboardMacro.MacroEvent(type: .keyUp, delayMs: 0)
            ]
        )
        XCTAssertEqual(macro.totalDurationMs, 600)
    }

    func testProfileMacroEncodingDecoding() throws {
        let macro = KeyboardMacro(
            name: "Macro1",
            events: [KeyboardMacro.MacroEvent(type: .keyDown, keyCode: 0x04)]
        )
        let data = try JSONEncoder().encode(macro)
        let decoded = try JSONDecoder().decode(KeyboardMacro.self, from: data)
        XCTAssertEqual(decoded.name, "Macro1")
        XCTAssertEqual(decoded.events.count, 1)
        XCTAssertEqual(decoded.events[0].type, .keyDown)
        XCTAssertEqual(decoded.events[0].keyCode, 0x04)
    }
}
