/**
 LiquidGlassSidebar.swift

 Enhanced glass sidebar with noise overlay and edge highlights.
 The sidebar is the largest glass surface — the noise texture
 matters most here for visual consistency.
 */

import SwiftUI

// MARK: - Liquid Glass Sidebar

public struct LiquidGlassSidebar<Content: View>: View {
    let width: CGFloat
    let content: Content

    public init(width: CGFloat = 220, @ViewBuilder content: () -> Content) {
        self.width = width
        self.content = content()
    }

    public var body: some View {
        content
            .frame(width: width)
            .background(
                ZStack {
                    // Layer 1: Native glass material
                    GlassView(
                        material: .sheet,
                        blendingMode: .behindWindow,
                        cornerRadius: 0
                    )

                    // Layer 2: Full-height noise overlay (largest glass surface)
                    NoiseOverlay(opacity: GlassTokens.noiseOpacity, cornerRadius: 0)

                    // Layer 3: Right-edge border highlight
                    HStack {
                        Spacer()
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.12)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(width: 1)
                    }
                    .allowsHitTesting(false)
                }
            )
    }
}
