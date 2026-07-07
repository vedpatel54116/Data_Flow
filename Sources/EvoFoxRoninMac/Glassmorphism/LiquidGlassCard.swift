/**
 LiquidGlassCard.swift

 Enhanced glass card with the full liquid glass treatment:
 - NSVisualEffectView for native blur + vibrancy
 - Noise texture overlay for organic grain
 - Top-edge highlight line for glass edge depth
 - Inner glow gradient for the "glass surface" effect
 - Enhanced border and shadow
 */

import SwiftUI

// MARK: - Liquid Glass Card

public struct LiquidGlassCard<Content: View>: View {
    let material: LiquidGlassMaterial
    let cornerRadius: CGFloat
    let padding: CGFloat
    let content: Content

    @State private var isHovered = false

    public init(
        material: LiquidGlassMaterial = .container,
        cornerRadius: CGFloat = GlassTokens.cornerRadiusCard,
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

                    // Layer 2: Noise texture for organic grain
                    NoiseOverlay(
                        opacity: GlassTokens.noiseOpacity,
                        cornerRadius: cornerRadius
                    )

                    // Layer 3: Top-edge highlight line (70% width, centered)
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
                        .padding(.horizontal, cornerRadius * 2)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .allowsHitTesting(false)

                    // Layer 4: Inner glow gradient (top 35%)
                    VStack {
                        LinearGradient(
                            colors: [
                                .white.opacity(GlassTokens.highlightGradientOpacity),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(maxHeight: .infinity)
                        .frame(height: GlassTokens.highlightGradientHeight * 300)
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
            .shadow(
                color: Color.black.opacity(0.15),
                radius: isHovered ? 24 : 16,
                x: 0,
                y: isHovered ? 12 : 8
            )
            .onHover { hovering in
                withAnimation(.spring(Physics.morph)) {
                    isHovered = hovering
                }
            }
    }
}
