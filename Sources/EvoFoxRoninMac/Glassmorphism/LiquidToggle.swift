/**
 LiquidToggle.swift

 A faithful SwiftUI port of Jhey Tompkins' Liquid Toggle Switch.
 Based on the reference implementation with:
 - SVG Goo filter (feGaussianBlur + feColorMatrix)
 - Knockout filter for transparent window
 - Liquid merging animation with GSAP-style spring/bounce
 - Draggable interaction with momentum

 Architecture (mirrors HTML/CSS exactly):
 ──────────────────────────────────────────
 Back layer:   .indicator          → full-size colored capsule
                .knockout           → filter removes black (transparent window)
                .indicator--masked  → colored background
                  .mask             → black sliding rect (reveals/hides color)
 Middle layer: .indicator__liquid  → sliding container
                  .shadow           → complex inner box-shadow (shown on press)
                  .wrapper          → clip-path capsule, blur(6)→blur(0)
                    .liquids        → filter: goo (blur + alpha threshold)
                      .liquid__shadow → inner shadow
                      .liquid__track  → FULL-SIZE colored capsule that TRANSLATES
                .cover            → white overlay (opacity 1→0 on press)

 The goo filter: feGaussianBlur(13) + feColorMatrix(0,0,0,13,-10)
 → blur merges overlapping shapes, alpha threshold sharpens edges back
 → creates liquid merging effect

 SwiftUI simulation: compositingGroup + blur + contrast + opacity threshold

 Reference transitions (from CSS):
 - indicator__liquid: translate based on --complete
 - wrapper: clip-path capsule, filter blur(6px) → blur(0) on press
 - liquid__track: translates with --complete, full-size
 - mask: height/width/margin transitions for scale effect
 - shadow: opacity 0 → 1 on press
 - cover: opacity 1 → 0 on press
 */

import SwiftUI

// MARK: - Physics Constants (matching GSAP custom ease)

private struct LiquidPhysics {
    static let springResponse: Double = 0.35
    static let springDamping: Double = 0.7
    static let fastSpringResponse: Double = 0.2
    static let fastSpringDamping: Double = 0.75
    static let pressDuration: Double = 0.12
    static let releaseDelay: Double = 0.04
    static let tapThreshold: Double = 0.15
    static let maxDelta: CGFloat = 12
    static let scaleFactor: CGFloat = 1.65
    static let deltaScaleFactor: CGFloat = 0.025
}

// MARK: - Liquid Toggle

public struct LiquidToggle: View {
    @Binding var isOn: Bool
    let tintColor: Color
    let size: ToggleSize
    let bounceEnabled: Bool

    // GSAP/Interaction Config (matches JS config)
    let hue: Double
    let deviation: CGFloat
    let alpha: CGFloat
    let bubble: Bool
    let mapped: Bool
    let debug: Bool

    @State private var isPressed = false
    @State private var isActive = false
    @State private var complete: CGFloat = 0
    @State private var isDragging = false
    @State private var pressTime: Date?
    @State private var deltaValue: CGFloat = 0
    @State private var dragDelta: CGFloat = 0
    @State private var dragStartX: CGFloat = 0
    @State private var dragBounds: CGFloat = 0
    @State private var lastDragX: CGFloat = 0

    // MARK: - Enums & Constants

    public enum ToggleSize {
        case small, medium, large

        var width: CGFloat {
            switch self {
            case .small: return 52
            case .medium: return 140
            case .large: return 180
            }
        }

        var height: CGFloat {
            switch self {
            case .small: return 28
            case .medium: return 60
            case .large: return 76
            }
        }

        var borderWidth: CGFloat {
            switch self {
            case .small: return 2.5
            case .medium: return 5.0
            case .large: return 6.5
            }
        }

        var gooBlur: CGFloat {
            switch self {
            case .small: return 5
            case .medium: return 13
            case .large: return 16
            }
        }

        var wrapperBlur: CGFloat {
            switch self {
            case .small: return 3
            case .medium: return 6
            case .large: return 8
            }
        }

        var indicatorRatio: CGFloat { 0.6 }

        var shadowBlur: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 4
            }
        }
    }

    // MARK: - Initialization

    public init(
        isOn: Binding<Bool>,
        tintColor: Color = .green,
        size: ToggleSize = .medium,
        bounceEnabled: Bool = true,
        hue: Double = 144,
        deviation: CGFloat = 2,
        alpha: CGFloat = 16,
        bubble: Bool = true,
        mapped: Bool = false,
        debug: Bool = false
    ) {
        self._isOn = isOn
        self.tintColor = tintColor
        self.size = size
        self.bounceEnabled = bounceEnabled
        self.hue = hue
        self.deviation = deviation
        self.alpha = alpha
        self.bubble = bubble
        self.mapped = mapped
        self.debug = debug
    }

    // MARK: - Computed Layout & Colors

    private var trackWidth: CGFloat { size.width }
    private var trackHeight: CGFloat { size.height }
    private var border: CGFloat { size.borderWidth }
    private var indicatorW: CGFloat { trackWidth * size.indicatorRatio - border * 2 }
    private var indicatorH: CGFloat { trackHeight - border * 2 }
    private var maxTravel: CGFloat { trackWidth - indicatorW - border * 2 }

    private var tintHue: Double {
        let nsColor = NSColor(tintColor)
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else { return 0.5 }
        var h: CGFloat = 0
        rgbColor.getHue(&h, saturation: nil, brightness: nil, alpha: nil)
        return Double(h) * 360
    }

    private var checkedColor: Color {
        let saturation = 0.08 + (complete / 100 * 0.92)
        let lightness = 0.81 - (complete / 100 * 0.38)
        return Color(hue: hue / 360, saturation: saturation, brightness: lightness)
    }

    private var uncheckedColor: Color {
        Color(hue: 218/360, saturation: 0.08, brightness: 0.81)
    }

    private var dynamicColor: Color {
        // Interpolate between unchecked and checked based on complete
        if complete <= 0 { return uncheckedColor }
        if complete >= 100 { return checkedColor }
        return Color(hue: (218 + (hue - 218) * (complete / 100)) / 360,
                     saturation: 0.08 + (complete / 100) * 0.92,
                     brightness: 0.81 - (complete / 100) * 0.38)
    }

    private var currentWrapperBlur: CGFloat {
        (isPressed || isActive) ? 0 : size.wrapperBlur
    }
    private var coverOpacity: Double { (isPressed || isActive) ? 0 : 1 }
    private var shadowOpacity: Double { (isPressed || isActive) ? 1 : 0 }

    private var activeScale: CGFloat {
        (isPressed || isActive) ? (1.65 + (deltaValue * 0.025)) : 1.0
    }

    // MARK: - Layout Transitions

    private var trackTranslateX: CGFloat {
        (complete / 100) * (trackWidth - indicatorW - border * 6)
    }

    private var containerTranslateX: CGFloat {
        (complete / 100) * (trackWidth - indicatorW - border * 2)
    }

    private var maskTranslateX: CGFloat {
        border + (complete / 100) * (trackWidth - border * 2 - indicatorW)
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            mainContent
        }
        .frame(width: trackWidth, height: trackHeight)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.3), radius: isPressed ? 2 : 5, y: isPressed ? 1 : 3)
        // Keyboard support - matches JS keydown/keyup handlers
        .focusable()
        .onKeyPress(.space) {
            handleKeyPress()
            return .handled
        }
        .onKeyPress(.return) {
            handleKeyPress()
            return .handled
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        Button(action: {}) {
            ZStack {
                indicatorBackground
                knockoutLayer
                liquidIndicatorLayer
                innerShadows
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Toggle")
        .accessibilityValue(isOn ? "On" : "Off")
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.easeInOut(duration: LiquidPhysics.pressDuration)) {
                isPressed = pressing
                if pressing {
                    pressTime = Date()
                    isActive = true
                } else {
                    // On release, if not dragging, check tap threshold
                    if !isDragging {
                        let elapsed = pressTime.map { Date().timeIntervalSince($0) } ?? 0
                        if elapsed <= LiquidPhysics.tapThreshold {
                            // The toggleState will be called from the gesture end
                        }
                    }
                }
            }
        }, perform: {})
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleDragChanged(value)
                }
                .onEnded { value in
                    handleDragEnded(value)
                }
        )
        .onChange(of: isOn) { _, newValue in
            if !isDragging {
                withAnimation(.spring(response: LiquidPhysics.springResponse, dampingFraction: LiquidPhysics.springDamping)) {
                    complete = newValue ? 100 : 0
                }
            }
        }
        .onAppear {
            complete = isOn ? 100 : 0
        }
    }

    private func handleKeyPress() {
        guard !isDragging else { return }
        
        isActive = true
        isPressed = true
        pressTime = Date()
        
        // Animate the press
        withAnimation(.easeInOut(duration: LiquidPhysics.pressDuration)) {
            complete = isOn ? 0 : 100
        }
        
        // Release after a short delay (matching JS keyup behavior)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPressed = false
            DispatchQueue.main.asyncAfter(deadline: .now() + LiquidPhysics.releaseDelay) {
                isOn.toggle()
                withAnimation(.easeOut(duration: 0.2)) {
                    isActive = false
                }
            }
        }
    }

    // MARK: - Interaction Handlers

    private func handleDragChanged(_ value: DragGesture.Value) {
        if !isDragging {
            // On drag start - calculate bounds like JS Draggable
            isDragging = true
            pressTime = Date()
            isActive = true
            dragStartX = value.startLocation.x
            lastDragX = value.location.x
        }
        
        lastDragX = value.location.x
        
        // Map drag to completion percentage (matching JS logic)
        let indicatorStart = border
        let indicatorEnd = trackWidth - border - indicatorW
        let range = indicatorEnd - indicatorStart
        
        var newComplete: CGFloat
        if isOn {
            // Dragging left decreases completion
            let dragDistance = indicatorStart + (1 - complete/100) * range - value.location.x
            newComplete = 100 - (dragDistance / range) * 100
        } else {
            // Dragging right increases completion
            let dragDistance = value.location.x - indicatorStart
            newComplete = (dragDistance / range) * 100
        }
        
        complete = max(0, min(100, newComplete))
        
        // Calculate delta for scale effect (matching JS deltaX)
        let deltaX = value.location.x - lastDragX
        dragDelta = min(abs(deltaX), LiquidPhysics.maxDelta)
        deltaValue = dragDelta
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        let elapsed = pressTime.map { Date().timeIntervalSince($0) } ?? 0
        
        if elapsed < LiquidPhysics.tapThreshold && abs(value.translation.width) < 5 {
            // Treat as tap
            toggleState()
        } else {
            // Drag release - snap to nearest (matching JS onDragEnd)
            let target: CGFloat = complete >= 50 ? 100 : 0
            withAnimation(.spring(response: LiquidPhysics.fastSpringResponse, dampingFraction: LiquidPhysics.fastSpringDamping)) {
                complete = target
            }
            
            // Match JS delay for state updates
            DispatchQueue.main.asyncAfter(deadline: .now() + LiquidPhysics.releaseDelay) {
                isOn = target == 100
                withAnimation(.easeOut(duration: 0.2)) {
                    isActive = false
                    deltaValue = 0
                    dragDelta = 0
                }
            }
        }
        isDragging = false
    }

    private func toggleState() {
        guard !isDragging else { return }
        
        isActive = true
        
        // Use spring animation matching CSS transition with bounce
        let animation: Animation = bounceEnabled 
            ? .spring(response: LiquidPhysics.springResponse, dampingFraction: LiquidPhysics.springDamping)
            : .easeInOut(duration: LiquidPhysics.pressDuration)
        
        withAnimation(animation) {
            complete = isOn ? 0 : 100
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + LiquidPhysics.releaseDelay) {
            isOn.toggle()
            withAnimation(.easeOut(duration: 0.2)) {
                isActive = false
            }
        }
    }

    // MARK: - Visual Layers

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
                    .frame(width: maskWidth, height: maskHeight)
                    .offset(x: maskMarginLeft)
                    .position(
                        x: maskTranslateX + indicatorW / 2,
                        y: geo.size.height / 2
                    )
                    .clipShape(Capsule())
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isActive)
            }
            .compositingGroup()
            .blendMode(.destinationOut)
        }
        .allowsHitTesting(false)
    }

    private var liquidIndicatorLayer: some View {
        GeometryReader { geo in
            let containerX = border
            let containerY = border

            ZStack {
                // Shadow capsule (appears on press) - matches .indicator__liquid .shadow
                Capsule()
                    .fill(Color.black.opacity(0.05))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            .overlay(
                                Capsule()
                                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
                                    .offset(y: 1)
                            )
                    )
                    .frame(width: indicatorW, height: indicatorH)
                    .position(
                        x: containerX + indicatorW / 2 + containerTranslateX,
                        y: containerY + indicatorH / 2
                    )
                    .opacity(shadowOpacity)
                    .animation(.easeInOut(duration: 0.15), value: isPressed)
                    .scaleEffect(x: activeScaleX, y: activeScaleY, anchor: .center)
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isActive)

                // Liquid goo effect (blurred merged track) - matches .liquids with #goo filter
                ZStack {
                    // Track: full-width colored capsule - matches .liquid__track
                    Capsule()
                        .fill(dynamicColor)
                        .frame(width: trackWidth - border * 6, height: trackHeight - border * 2)
                        .offset(x: trackTranslateX)

                    // Leading blob (merges with track via goo filter)
                    Circle()
                        .fill(dynamicColor)
                        .frame(width: indicatorH * 0.7, height: indicatorH * 0.7)
                        .offset(
                            x: trackTranslateX + (isOn ? -indicatorH * 0.25 : indicatorH * 0.25),
                            y: 0
                        )

                    // Trailing blob (smaller, merges via goo)
                    Circle()
                        .fill(dynamicColor.opacity(0.8))
                        .frame(width: indicatorH * 0.45, height: indicatorH * 0.45)
                        .offset(
                            x: trackTranslateX + (isOn ? indicatorH * 0.3 : -indicatorH * 0.3),
                            y: 0
                        )
                }
                // Simulate SVG goo filter: blur + contrast (alpha threshold)
                .compositingGroup()
                .blur(radius: currentWrapperBlur)
                .blur(radius: size.gooBlur)
                .contrast(30)  // Higher contrast = sharper goo edges (like feColorMatrix alpha threshold)
                .mask(
                    Capsule()
                        .frame(width: indicatorW + size.gooBlur * 2, height: indicatorH + size.gooBlur * 2)
                        .position(
                            x: containerX + indicatorW / 2 + containerTranslateX,
                            y: containerY + indicatorH / 2
                        )
                )
                .position(
                    x: containerX + indicatorW / 2,
                    y: containerY + indicatorH / 2
                )
                // Apply active scale (matches [data-active=true] .indicator__liquid scale)
                .scaleEffect(x: activeScaleX, y: activeScaleY, anchor: .center)
                .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isActive)

                // Cover (white overlay, fades on press) - matches .cover
                Capsule()
                    .fill(.white.opacity(0.85))
                    .overlay(
                        NoiseOverlay(opacity: 0.02)
                            .clipShape(Capsule())
                            .allowsHitTesting(false)
                    )
                    .frame(width: indicatorW, height: indicatorH)
                    .position(
                        x: containerX + indicatorW / 2 + containerTranslateX,
                        y: containerY + indicatorH / 2
                    )
                    .opacity(coverOpacity)
                    .animation(.easeInOut(duration: 0.15), value: isPressed)
                    .scaleEffect(x: activeScaleX, y: activeScaleY, anchor: .center)
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isActive)
            }
        }
        .allowsHitTesting(false)
    }

    // Active scale factors matching CSS: scale: calc(1.65 + (var(--delta, 0) * 0.025)) calc(1.65 - (var(--delta, 0) * 0.025))
    private var activeScaleX: CGFloat {
        guard isPressed || isActive else { return 1.0 }
        return LiquidPhysics.scaleFactor + (deltaValue * LiquidPhysics.deltaScaleFactor)
    }

    private var activeScaleY: CGFloat {
        guard isPressed || isActive else { return 1.0 }
        return LiquidPhysics.scaleFactor - (deltaValue * LiquidPhysics.deltaScaleFactor)
    }

    // Mask scale for indicator--masked (matches CSS: height/width/margin transitions)
    private var maskScale: CGFloat {
        guard isPressed || isActive else { return 1.0 }
        return LiquidPhysics.scaleFactor
    }

    private var maskWidth: CGFloat {
        (indicatorW) * maskScale
    }

    private var maskHeight: CGFloat {
        (indicatorH) * maskScale
    }

    private var maskMarginLeft: CGFloat {
        -(indicatorW) * (maskScale - 1) / 2
    }

    private var innerShadows: some View {
        ZStack {
            VStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.25), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: trackHeight * 0.4)
                Spacer()
            }

            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.22)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: trackHeight * 0.35)
            }

            HStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.1), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: trackWidth * 0.1)
                Spacer()
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: trackWidth * 0.1)
            }
        }
        .clipShape(Capsule())
        .allowsHitTesting(false)
    }
}

// MARK: - Toggle Style

public struct LiquidToggleStyle: ToggleStyle {
    let tintColor: Color
    let size: LiquidToggle.ToggleSize
    let bounceEnabled: Bool

    public init(
        tintColor: Color = .green,
        size: LiquidToggle.ToggleSize = .medium,
        bounceEnabled: Bool = true
    ) {
        self.tintColor = tintColor
        self.size = size
        self.bounceEnabled = bounceEnabled
    }

    public func makeBody(configuration: Configuration) -> some View {
        LiquidToggle(
            isOn: configuration.$isOn,
            tintColor: tintColor,
            size: size,
            bounceEnabled: bounceEnabled
        )
    }
}

extension View {
    func liquidToggleStyle(
        tintColor: Color = .green,
        size: LiquidToggle.ToggleSize = .medium,
        bounceEnabled: Bool = true
    ) -> some View {
        self.toggleStyle(LiquidToggleStyle(tintColor: tintColor, size: size, bounceEnabled: bounceEnabled))
    }
}

// MARK: - Preview

#if DEBUG
struct LiquidTogglePreview: View {
    @State private var isEnabled = true
    @State private var isSmallEnabled = false
    @State private var isLargeEnabled = true
    @State private var isNoBounceEnabled = false
    @State private var hue: Double = 144
    @State private var deviation: CGFloat = 2
    @State private var alpha: CGFloat = 16
    @State private var debug = false

    var body: some View {
        VStack(spacing: 40) {
            Text("Liquid Glass Toggle")
                .font(.title2.bold())
                .foregroundStyle(.white)

            HStack(spacing: 16) {
                LiquidToggle(
                    isOn: $isEnabled,
                    tintColor: .green,
                    hue: hue,
                    deviation: deviation,
                    alpha: alpha,
                    bubble: true,
                    mapped: false,
                    debug: debug
                )
                Text("RGB Lighting (Default)")
                    .foregroundStyle(.white)
            }

            HStack(spacing: 16) {
                LiquidToggle(
                    isOn: $isSmallEnabled,
                    tintColor: .blue,
                    size: .small,
                    hue: hue,
                    deviation: deviation,
                    alpha: alpha
                )
                Text("Small Blue")
                    .foregroundStyle(.white)
            }

            HStack(spacing: 16) {
                LiquidToggle(
                    isOn: $isLargeEnabled,
                    tintColor: .orange,
                    size: .large,
                    hue: hue,
                    deviation: deviation,
                    alpha: alpha
                )
                Text("Large Orange")
                    .foregroundStyle(.white)
            }

            HStack(spacing: 16) {
                LiquidToggle(
                    isOn: $isNoBounceEnabled,
                    tintColor: .purple,
                    bounceEnabled: false,
                    hue: hue,
                    deviation: deviation,
                    alpha: alpha
                )
                Text("Static")
                    .foregroundStyle(.white)
            }

            Toggle("Using ToggleStyle", isOn: $isEnabled)
                .toggleStyle(LiquidToggleStyle(tintColor: .green))
                .frame(width: 200)
        }
        .padding(40)
    }
}

#Preview {
    LiquidTogglePreview()
        .frame(width: 500, height: 500)
        .background(Color.black)
}
#endif
