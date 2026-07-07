/**
 ColorExtensions.swift

 Utility extensions for Color and related types used throughout the app.

 Provides:
 - Hex color initialization
 - Color component extraction
 - NSColor/Color bridging
 - Glass-friendly color palettes
*/

import SwiftUI
import AppKit

extension Color {
    /// Creates a Color from a hex integer (e.g., 0xFF5733)
    public init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    /// Creates a Color from a hex string (e.g., "#E8E8E9", "E8E8E9", "RGB", "AARRGGBB")
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Extracts RGBA components as doubles (0.0 - 1.0)
    public var rgba: (red: Double, green: Double, blue: Double, alpha: Double) {
        let nsColor = NSColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }

    /// Converts to RGBColor model
    public var rgbColor: RGBColor {
        let c = rgba
        return RGBColor(
            r: UInt8(c.red * 255),
            g: UInt8(c.green * 255),
            b: UInt8(c.blue * 255)
        )
    }

    /// Returns a hex string representation
    public var hexString: String {
        let c = rgba
        return String(
            format: "#%02X%02X%02X",
            Int(c.red * 255),
            Int(c.green * 255),
            Int(c.blue * 255)
        )
    }
}

extension NSColor {
    /// Creates an NSColor from a hex integer
    public convenience init(hex: UInt32) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - Glass-Friendly Color Palette

/// Colors that work well on glass backgrounds with proper vibrancy
public enum GlassPalette: Sendable {
    /// Accent colors for primary actions on glass
    public static let accentBlue = Color(hex: 0x0A84FF)
    public static let accentGreen = Color(hex: 0x30D158)
    public static let accentOrange = Color(hex: 0xFF9F0A)
    public static let accentRed = Color(hex: 0xFF453A)
    public static let accentPurple = Color(hex: 0xBF5AF2)
    public static let accentTeal = Color(hex: 0x64D2FF)
    public static let accentYellow = Color(hex: 0xFFD60A)

    /// Background colors for dark mode glass
    public static let darkBase = Color(hex: 0x1C1C1E)
    public static let darkElevated = Color(hex: 0x2C2C2E)
    public static let darkSurface = Color(hex: 0x3A3A3C)

    /// Text colors with proper contrast on glass
    public static let primaryText = Color.white
    public static let secondaryText = Color.white.opacity(0.6)
    public static let tertiaryText = Color.white.opacity(0.3)
}

// MARK: - Gradient Presets

/// Pre-built gradients for animated backgrounds and glass effects
public enum GlassGradients: Sendable {
    /// Deep space gradient for the main app background
    public static let deepSpace = LinearGradient(
        colors: [
            Color(hex: 0x0B0B1A),
            Color(hex: 0x1A1A2E),
            Color(hex: 0x16213E)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Aurora gradient for accent panels
    public static let aurora = LinearGradient(
        colors: [
            Color(hex: 0x0F3460).opacity(0.6),
            Color(hex: 0x533483).opacity(0.4),
            Color(hex: 0xE94560).opacity(0.2)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle gradient for inactive glass panels
    public static let subtle = LinearGradient(
        colors: [
            Color.white.opacity(0.05),
            Color.white.opacity(0.02)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}
