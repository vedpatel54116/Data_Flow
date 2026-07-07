/**
 GlassTokens.swift

 Shared design constants for the liquid glass effect.
 All values are tunable — adjust these to change the glass appearance globally.
 */

import SwiftUI

// MARK: - Liquid Glass Material Type

public enum LiquidGlassMaterial {
    case container
    case button
    case floating
}

// MARK: - Glass Tokens

public enum GlassTokens {

    // MARK: Noise Layer

    /// Opacity of the noise texture overlay (0.0 = invisible, 1.0 = fully opaque)
    public static let noiseOpacity: Double = 0.03

    /// Base frequency for the fractal noise (higher = finer grain)
    public static let noiseBaseFrequency: Double = 0.9

    /// Number of noise octaves (higher = more detail, more cost)
    public static let noiseOctaves: Int = 4

    /// Size of the noise texture in points (tiled across the surface)
    public static let noiseSize: CGFloat = 100

    // MARK: Highlight Layer

    /// Opacity of the top-edge highlight line
    public static let highlightTopOpacity: Double = 0.30

    /// Opacity of the inner glow gradient
    public static let highlightGradientOpacity: Double = 0.08

    /// Height of the inner glow as a fraction of container height
    public static let highlightGradientHeight: CGFloat = 0.35

    /// Width of the top highlight line as a fraction of container width (centered)
    public static let highlightWidth: CGFloat = 0.70

    // MARK: Border

    /// Width of the glass border stroke
    public static let borderWidth: CGFloat = 0.5

    /// Opacity of the glass border stroke
    public static let borderOpacity: Double = 0.15

    /// Corner radius for glass cards
    public static let cornerRadiusCard: CGFloat = 24

    /// Corner radius for glass buttons
    public static let cornerRadiusButton: CGFloat = 12

    /// Corner radius for small elements (pills, badges)
    public static let cornerRadiusSmall: CGFloat = 10
}
