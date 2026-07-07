/**
 LiquidGlassContainer.swift

 Enhanced glass container with noise overlay and highlights.
 Used for floating elements (tooltips, popovers, floating panels).
 Inherits the liquid glass treatment from design tokens.
 */

import SwiftUI

// MARK: - Liquid Glass Container

public struct LiquidGlassContainer<Content: View>: View {
    let material: LiquidGlassMaterial
    let cornerRadius: CGFloat
    let padding: CGFloat
    let content: Content

    public init(
        material: LiquidGlassMaterial = .container,
        cornerRadius: CGFloat = 30,
        padding: CGFloat = 24,
        @ViewBuilder content: () -> Content
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Layer 1: Native glass material
                    GlassView(
                        material: .sheet,
                        blendingMode: .behindWindow,
                        cornerRadius: cornerRadius
                    )

                    // Layer 2: Noise texture
                    NoiseOverlay(
                        opacity: GlassTokens.noiseOpacity,
                        cornerRadius: cornerRadius
                    )

                    // Layer 3: Top-edge highlight
                    VStack {
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(GlassTokens.highlightTopOpacity),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 1)
                        .padding(.horizontal, cornerRadius)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .allowsHitTesting(false)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        Color.white.opacity(GlassTokens.borderOpacity),
                        lineWidth: GlassTokens.borderWidth
                    )
            )
    }
}
