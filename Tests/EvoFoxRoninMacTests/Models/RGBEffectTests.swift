import XCTest
@testable import EvoFoxRoninMac

final class RGBEffectTests: XCTestCase {
    func testRGBColorConstants() {
        XCTAssertEqual(RGBColor.red, RGBColor(r: 255, g: 0, b: 0))
        XCTAssertEqual(RGBColor.green, RGBColor(r: 0, g: 255, b: 0))
        XCTAssertEqual(RGBColor.blue, RGBColor(r: 0, g: 0, b: 255))
    }

    func testRGBColorEncodingDecoding() throws {
        let color = RGBColor(r: 128, g: 64, b: 32)
        let data = try JSONEncoder().encode(color)
        let decoded = try JSONDecoder().decode(RGBColor.self, from: data)
        XCTAssertEqual(decoded, color)
    }

    func testRGBEffectCount() {
        XCTAssertEqual(RGBEffectLibrary.effects.count, 20, "Should have 20 built-in effects")
    }

    func testRGBEffectCategories() {
        let categories = Set(RGBEffectLibrary.effects.map { $0.category })
        XCTAssertTrue(categories.contains(.staticColor))
        XCTAssertTrue(categories.contains(.dynamic))
        XCTAssertTrue(categories.contains(.reactive))
        XCTAssertTrue(categories.contains(.custom))
        XCTAssertTrue(categories.contains(.audio))
    }

    func testRGBSettingsDefaults() {
        let settings = RGBSettings()
        XCTAssertEqual(settings.speed, 128)
        XCTAssertEqual(settings.brightness, 255)
        XCTAssertTrue(settings.isEnabled)
    }

    func testEffectDirectionCases() {
        XCTAssertEqual(RGBEffect.Direction.allCases.count, 6)
        XCTAssertEqual(RGBEffect.Direction.left.rawValue, 0)
        XCTAssertEqual(RGBEffect.Direction.right.rawValue, 1)
        XCTAssertEqual(RGBEffect.Direction.outward.rawValue, 5)
    }
}
