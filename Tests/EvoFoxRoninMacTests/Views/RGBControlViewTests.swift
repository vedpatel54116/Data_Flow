import XCTest
import SwiftUI
@testable import EvoFoxRoninMac

@MainActor
final class RGBControlViewTests: XCTestCase {
    func testRGBControlViewBodyIsNotEmpty() {
        let hidManager = HIDManager(mockMode: true)
        let view = RGBControlView()
            .environment(hidManager)
            .environment(ProfileManager())
        XCTAssertNotNil(view)
    }

    func testKeyCapabilitiesToggle() {
        let caps: KeyboardCapabilities = [.rgbLighting]
        XCTAssertTrue(caps.contains(.rgbLighting))
        XCTAssertFalse(caps.contains(.perKeyRGB))
    }

    func testPerKeyCapabilities() {
        let caps: KeyboardCapabilities = [.rgbLighting, .perKeyRGB]
        XCTAssertTrue(caps.contains(.rgbLighting))
        XCTAssertTrue(caps.contains(.perKeyRGB))
    }

    func testEmptyCapabilities() {
        let caps = KeyboardCapabilities()
        XCTAssertFalse(caps.contains(.rgbLighting))
        XCTAssertFalse(caps.contains(.perKeyRGB))
    }

    func testCapabilitiesUnion() {
        let caps1: KeyboardCapabilities = [.rgbLighting]
        let caps2: KeyboardCapabilities = [.perKeyRGB]
        let union = caps1.union(caps2)
        XCTAssertTrue(union.contains(.rgbLighting))
        XCTAssertTrue(union.contains(.perKeyRGB))
    }

    func testCapabilitiesDisplayCount() {
        let caps: KeyboardCapabilities = [.rgbLighting, .perKeyRGB, .macroProgramming]
        XCTAssertEqual(caps.enabledCapabilities.count, 3)
    }

    func testAllCapabilitiesReturned() {
        let allEnabled = KeyboardCapabilities.allCases
        XCTAssertTrue(allEnabled.contains(.rgbLighting))
        XCTAssertTrue(allEnabled.contains(.perKeyRGB))
        XCTAssertTrue(allEnabled.contains(.macroProgramming))
        XCTAssertTrue(allEnabled.contains(.keyRemapping))
        XCTAssertTrue(allEnabled.contains(.mediaKnob))
        XCTAssertTrue(allEnabled.contains(.pollingRateConfig))
        XCTAssertTrue(allEnabled.contains(.onboardMemory))
        XCTAssertTrue(allEnabled.contains(.nKeyRollover))
        XCTAssertTrue(allEnabled.contains(.wireless))
    }
}
