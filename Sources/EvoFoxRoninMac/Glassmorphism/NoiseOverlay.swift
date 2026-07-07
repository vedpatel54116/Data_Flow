/**
 NoiseOverlay.swift

 Reusable noise texture overlay for the liquid glass effect.

 Generates a 100×100 grayscale noise texture using Core Graphics
 and tiles it across the view. The noise adds organic grain that
 mimics the SVG feTurbulence filter from CSS liquid glass implementations.
 */

import SwiftUI

// MARK: - Noise Overlay View

/// A view that renders a tiled noise texture at low opacity.
/// Used as an overlay on glass surfaces to add organic grain.
public struct NoiseOverlay: View {
    let opacity: Double
    let cornerRadius: CGFloat

    public init(opacity: Double = GlassTokens.noiseOpacity, cornerRadius: CGFloat = 0) {
        self.opacity = opacity
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        GeometryReader { geo in
            Image(decorative: Self.noiseImage, scale: 1)
                .resizable()
                .interpolation(.high)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .opacity(opacity)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .allowsHitTesting(false)
    }

    // MARK: - Noise Generation

    /// Cached noise image — generated once, reused for all overlays
    private static let noiseImage: CGImage = {
        let size = Int(GlassTokens.noiseSize)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)

        guard let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            fatalError("Failed to create CGContext for noise texture")
        }

        guard let data = context.data else {
            fatalError("Failed to get CGContext data for noise texture")
        }

        let buffer = data.bindMemory(to: UInt8.self, capacity: size * size)

        for y in 0..<size {
            for x in 0..<size {
                buffer[y * size + x] = UInt8.random(in: 0...255)
            }
        }

        return context.makeImage()!
    }()
}

// MARK: - View Extension

extension View {
    /// Applies a liquid glass noise texture overlay at the given opacity.
    public func liquidNoise(opacity: Double = GlassTokens.noiseOpacity, cornerRadius: CGFloat = 0) -> some View {
        self.overlay(
            NoiseOverlay(opacity: opacity, cornerRadius: cornerRadius)
        )
    }
}
