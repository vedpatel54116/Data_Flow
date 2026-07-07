import XCTest
import SwiftUI
@testable import EvoFoxRoninMac

final class ColorExtensionsTests: XCTestCase {
    func testHexInitUInt32() {
        let color = Color(hex: 0xFF0000 as UInt32)
        let comps = color.rgba
        XCTAssertEqual(comps.red, 1.0, accuracy: 0.01)
        XCTAssertEqual(comps.green, 0.0, accuracy: 0.01)
        XCTAssertEqual(comps.blue, 0.0, accuracy: 0.01)
    }

    func testHexInitString6Char() {
        let color = Color(hex: "00FF00")
        let comps = color.rgba
        XCTAssertEqual(comps.red, 0.0, accuracy: 0.01)
        XCTAssertEqual(comps.green, 1.0, accuracy: 0.01)
        XCTAssertEqual(comps.blue, 0.0, accuracy: 0.01)
    }

    func testHexInitStringWithHash() {
        let color = Color(hex: "#0000FF")
        let comps = color.rgba
        XCTAssertEqual(comps.red, 0.0, accuracy: 0.01)
        XCTAssertEqual(comps.green, 0.0, accuracy: 0.01)
        XCTAssertEqual(comps.blue, 1.0, accuracy: 0.01)
    }

    func testHexInitString3Char() {
        let color = Color(hex: "F00")
        let comps = color.rgba
        XCTAssertEqual(comps.red, 1.0, accuracy: 0.01)
        XCTAssertEqual(comps.green, 0.0, accuracy: 0.01)
        XCTAssertEqual(comps.blue, 0.0, accuracy: 0.01)
    }

    func testHexInitStringInvalid() {
        let color = Color(hex: "xyz")
        let comps = color.rgba
        // Invalid hex parses as 0, 3-char branch gives r=g=b=0
        XCTAssertEqual(comps.red, 0.0, accuracy: 0.001)
        XCTAssertEqual(comps.green, 0.0, accuracy: 0.001)
        XCTAssertEqual(comps.blue, 0.0, accuracy: 0.001)
    }

    func testRGBColorConversion() {
        let color = Color(hex: 0xFF0000 as UInt32)
        let rgb = color.rgbColor
        XCTAssertEqual(rgb.r, 255)
        XCTAssertEqual(rgb.g, 0)
        XCTAssertEqual(rgb.b, 0)
    }

    func testHexStringOutput() {
        let color = Color(hex: 0xFF0000 as UInt32)
        XCTAssertEqual(color.hexString, "#FF0000")
    }
}
