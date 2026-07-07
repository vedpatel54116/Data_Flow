import SwiftUI

/// Animated thumb indicator for the liquid toggle switch.
/// Renders shadow, gooey liquid layer, and cover overlay with spring animations.
public struct LiquidToggleThumb: View {
    /// Dynamic tint color of the thumb.
    let dynamicColor: Color
    /// Size configuration for the toggle.
    let size: ToggleSize
    /// Completion percentage (0–100) for thumb position.
    let complete: CGFloat
    /// Whether the thumb is being pressed.
    let isPressed: Bool
    /// Whether the thumb is in an active/dragging state.
    let isActive: Bool
    /// Delta value for scale deformation during drag.
    let deltaValue: CGFloat
    /// Whether the toggle is in the "on" position.
    let isOn: Bool

    private var border: CGFloat { size.borderWidth }
    private var indicatorW: CGFloat { size.width * size.indicatorRatio - border * 2 }
    private var indicatorH: CGFloat { size.height - border * 2 }
    private var trackWidth: CGFloat { size.width }
    private var trackHeight: CGFloat { size.height }

    /// Creates a liquid toggle thumb with the given visual and state parameters.
    public init(dynamicColor: Color, size: ToggleSize, complete: CGFloat, isPressed: Bool, isActive: Bool, deltaValue: CGFloat, isOn: Bool) {
        self.dynamicColor = dynamicColor; self.size = size; self.complete = complete
        self.isPressed = isPressed; self.isActive = isActive; self.deltaValue = deltaValue; self.isOn = isOn
    }

    public var body: some View {
        GeometryReader { geo in
            let cx = border, cy = border
            let ctx = (complete / 100) * (trackWidth - indicatorW - border * 2)
            ZStack {
                shadowCapsule(cx: cx, cy: cy, ctx: ctx)
                liquidGooLayer(cx: cx, cy: cy, ctx: ctx)
                coverOverlay(cx: cx, cy: cy, ctx: ctx)
            }
        }
        .allowsHitTesting(false)
    }

    private func shadowCapsule(cx: CGFloat, cy: CGFloat, ctx: CGFloat) -> some View {
        Capsule().fill(Color.black.opacity(0.05))
            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
                .overlay(Capsule().stroke(Color.black.opacity(0.15), lineWidth: 1).offset(y: 1)))
            .frame(width: indicatorW, height: indicatorH)
            .position(x: cx + indicatorW / 2 + ctx, y: cy + indicatorH / 2)
            .opacity((isPressed || isActive) ? 1 : 0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .scaleEffect(x: activeScaleX, y: activeScaleY, anchor: .center)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isActive)
    }

    private func liquidGooLayer(cx: CGFloat, cy: CGFloat, ctx: CGFloat) -> some View {
        let ttx = (complete / 100) * (trackWidth - indicatorW - border * 6)
        let wb: CGFloat = (isPressed || isActive) ? 0 : size.wrapperBlur
        return ZStack {
            Capsule().fill(Color.white.opacity(0.1))
                .frame(width: indicatorW + 4, height: indicatorH + 4)
                .position(x: cx + indicatorW / 2 + ctx, y: cy + indicatorH / 2).blur(radius: 2)
            Capsule().fill(dynamicColor)
                .frame(width: trackWidth - border * 6, height: trackHeight - border * 2).offset(x: ttx)
            Circle().fill(dynamicColor)
                .frame(width: indicatorH * 0.7, height: indicatorH * 0.7)
                .offset(x: ttx + (isOn ? -indicatorH * 0.25 : indicatorH * 0.25), y: 0)
            Circle().fill(dynamicColor.opacity(0.8))
                .frame(width: indicatorH * 0.45, height: indicatorH * 0.45)
                .offset(x: ttx + (isOn ? indicatorH * 0.3 : -indicatorH * 0.3), y: 0)
        }
        .compositingGroup().blur(radius: wb).blur(radius: size.gooBlur).contrast(30)
        .mask(Capsule().frame(width: indicatorW + size.gooBlur * 2, height: indicatorH + size.gooBlur * 2)
            .position(x: cx + indicatorW / 2 + ctx, y: cy + indicatorH / 2))
        .position(x: cx + indicatorW / 2, y: cy + indicatorH / 2)
        .scaleEffect(x: activeScaleX, y: activeScaleY, anchor: .center)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isActive)
    }

    private func coverOverlay(cx: CGFloat, cy: CGFloat, ctx: CGFloat) -> some View {
        Capsule().fill(.white.opacity(0.85))
            .overlay(NoiseOverlay(opacity: 0.02).clipShape(Capsule()).allowsHitTesting(false))
            .frame(width: indicatorW, height: indicatorH)
            .position(x: cx + indicatorW / 2 + ctx, y: cy + indicatorH / 2)
            .opacity((isPressed || isActive) ? 0 : 1)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .scaleEffect(x: activeScaleX, y: activeScaleY, anchor: .center)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isActive)
    }

    private var activeScaleX: CGFloat {
        (isPressed || isActive) ? LiquidTogglePhysics.scaleFactor + (deltaValue * LiquidTogglePhysics.deltaScaleFactor) : 1.0
    }

    private var activeScaleY: CGFloat {
        (isPressed || isActive) ? LiquidTogglePhysics.scaleFactor - (deltaValue * LiquidTogglePhysics.deltaScaleFactor) : 1.0
    }
}

#if DEBUG
#Preview("Toggle Thumb") {
    LiquidToggleThumb(dynamicColor: .green, size: .medium, complete: 50, isPressed: false, isActive: false, deltaValue: 0, isOn: true)
        .frame(width: 140, height: 60).padding(20).background(Color.black)
}
#endif
