import SwiftUI

/// The track background of a liquid toggle, including indicator, knockout mask, and inner shadows.
///
/// Renders the colored capsule background with a sliding knockout window that
/// reveals/hides the checked color, plus inset shadow gradients for depth.
public struct LiquidToggleTrack: View {
    let dynamicColor: Color
    let size: ToggleSize
    let complete: CGFloat
    let isActive: Bool
    let isOn: Bool

    private var border: CGFloat { size.borderWidth }
    private var indicatorW: CGFloat { size.width * size.indicatorRatio - border * 2 }
    private var indicatorH: CGFloat { size.height - border * 2 }

    public init(
        dynamicColor: Color,
        size: ToggleSize,
        complete: CGFloat,
        isActive: Bool,
        isOn: Bool
    ) {
        self.dynamicColor = dynamicColor
        self.size = size
        self.complete = complete
        self.isActive = isActive
        self.isOn = isOn
    }

    public var body: some View {
        ZStack {
            indicatorBackground
            knockoutLayer
            innerShadows
        }
    }

    private var indicatorBackground: some View {
        Capsule()
            .fill(dynamicColor)
            .overlay(
                NoiseOverlay(opacity: 0.03)
                    .clipShape(Capsule())
                    .allowsHitTesting(false)
            )
    }

    private var knockoutLayer: some View {
        GeometryReader { geo in
            ZStack {
                Capsule()
                    .fill(dynamicColor)

                Rectangle()
                    .fill(Color.black)
                    .frame(width: knockoutMaskWidth, height: knockoutMaskHeight)
                    .offset(x: knockoutMaskOffset)
                    .position(x: knockoutMaskX + indicatorW / 2, y: geo.size.height / 2)
                    .clipShape(Capsule())
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isActive)
            }
            .compositingGroup()
            .blendMode(.destinationOut)
        }
        .allowsHitTesting(false)
    }

    private var knockoutMaskScale: CGFloat {
        guard isActive else { return 1.0 }
        return LiquidTogglePhysics.scaleFactor
    }

    private var knockoutMaskWidth: CGFloat {
        indicatorW * knockoutMaskScale
    }

    private var knockoutMaskHeight: CGFloat {
        indicatorH * knockoutMaskScale
    }

    private var knockoutMaskOffset: CGFloat {
        -(indicatorW) * (knockoutMaskScale - 1) / 2
    }

    private var knockoutMaskX: CGFloat {
        border + (complete / 100) * (size.width - border * 2 - indicatorW)
    }

    private var innerShadows: some View {
        ZStack {
            VStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.25), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: size.height * 0.4)
                Spacer()
            }
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.22)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: size.height * 0.35)
            }
            HStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.1), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: size.width * 0.1)
                Spacer()
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.05)],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: size.width * 0.1)
            }
        }
        .clipShape(Capsule())
        .allowsHitTesting(false)
    }
}

#if DEBUG
#Preview("Toggle Track") {
    LiquidToggleTrack(
        dynamicColor: Color.green,
        size: .medium,
        complete: 100,
        isActive: false,
        isOn: true
    )
    .frame(width: 140, height: 60)
    .padding(40)
    .background(Color.black)
}
#endif
