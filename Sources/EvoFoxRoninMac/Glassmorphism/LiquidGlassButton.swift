/**
 LiquidGlassButton.swift

 Enhanced glass button with the liquid glass treatment:
 - Standard variant: glass material + noise overlay + top highlight
 - Prominent variant: colored fill + noise overlay + colored shadow
 - Hover state: brighter highlights
 - Press state: scale + reduced opacity
 */

import SwiftUI

// MARK: - Liquid Glass Button Style

public struct LiquidGlassButtonStyle: ButtonStyle {
    let isProminent: Bool
    let tint: Color
    let cornerRadius: CGFloat

    @State private var isHovered = false

    public init(
        isProminent: Bool = false,
        tint: Color = .accentColor,
        cornerRadius: CGFloat = GlassTokens.cornerRadiusButton
    ) {
        self.isProminent = isProminent
        self.tint = tint
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .foregroundStyle(isProminent ? Color.white : tint)
            .background(
                ZStack {
                    if isProminent {
                        // Prominent: colored fill + noise
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(configuration.isPressed ? 0.9 : 1.0))
                            .overlay(
                                NoiseOverlay(opacity: 0.04, cornerRadius: cornerRadius)
                            )
                            .shadow(
                                color: tint.opacity(0.3),
                                radius: configuration.isPressed ? 4 : 12,
                                x: 0,
                                y: configuration.isPressed ? 2 : 6
                            )
                    } else {
                        // Standard: glass + noise + highlight
                        ZStack {
                            GlassView(
                                material: .hudWindow,
                                blendingMode: .behindWindow,
                                cornerRadius: cornerRadius
                            )

                            NoiseOverlay(opacity: 0.03, cornerRadius: cornerRadius)

                            // Top highlight — brighter on hover
                            VStack {
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(isHovered ? 0.20 : 0.10),
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
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        Color.white.opacity(
                            isProminent ? 0 : (configuration.isPressed ? 0.15 : GlassTokens.borderOpacity)
                        ),
                        lineWidth: GlassTokens.borderWidth
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
