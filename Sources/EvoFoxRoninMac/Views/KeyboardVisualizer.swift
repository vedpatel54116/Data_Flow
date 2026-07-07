/**
 KeyboardVisualizer.swift

 Renders a visual representation of the 79-key EvoFox Ronin TKL layout.
 Each key is drawn as a glass capsule that lights up based on the selected
 RGB effect, simulating how the keyboard will look.

 Features:
 - Accurate 75% TKL layout with proper key sizing
 - Animated effect preview (wave, breathing, ripple, etc.)
 - Per-key hover highlighting
 - Glass material keys with physical depth
 - Physics-based cascade animations for key lighting

 Layout dimensions (approximate relative units):
 - Standard key: 1u = 48pt
 - Key spacing: 4pt
 - Total width: ~15u = ~780pt
 - Total height: ~6 rows + spacing = ~340pt
*/

import SwiftUI

struct KeyboardVisualizer: View {
    let selectedEffect: RGBEffect
    let primaryColor: Color
    let secondaryColor: Color
    let isEnabled: Bool

    @State private var animationPhase: Double = 0
    @State private var rippleOrigin: KeyPosition? = nil

    var body: some View {
        GeometryReader { geometry in
            let keyUnit: CGFloat = min(geometry.size.width / 16, 44)
            let keySpacing: CGFloat = 4

            ZStack {
                // Keyboard base plate (dark glass chassis)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )

                // Keys
                VStack(spacing: keySpacing) {
                    ForEach(0..<RoninLayout.keys.count, id: \.self) { rowIndex in
                        HStack(spacing: keySpacing) {
                            ForEach(0..<RoninLayout.keys[rowIndex].count, id: \.self) { colIndex in
                                let key = RoninLayout.keys[rowIndex][colIndex]
                                let position = KeyPosition(row: rowIndex, col: colIndex)
                                let keyColor = keyColor(at: position, unit: keyUnit)

                                KeyCapsule(
                                    label: key.defaultLabel,
                                    color: isEnabled ? keyColor : Color.gray.opacity(0.3),
                                    unit: keyUnit,
                                    size: key.size
                                )
                                .onTapGesture {
                                    triggerRipple(at: position)
                                }
                            }
                        }
                    }
                }
                .padding(keySpacing * 3)
            }
            .onAppear {
                startAnimation()
            }
            .onChange(of: selectedEffect.id) {
                animationPhase = 0
                startAnimation()
            }
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        guard selectedEffect.category != .staticColor else { return }

        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
    }

    private func triggerRipple(at position: KeyPosition) {
        rippleOrigin = position
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            rippleOrigin = nil
        }
    }

    // MARK: - Color Calculation

    private func keyColor(at position: KeyPosition, unit: CGFloat) -> Color {
        let x = CGFloat(position.col)
        let y = CGFloat(position.row)

        switch selectedEffect.category {
        case .staticColor:
            return primaryColor

        case .dynamic:
            return dynamicColor(x: x, y: y)

        case .reactive:
            return reactiveColor(x: x, y: y)

        case .audio:
            return audioColor(x: x, y: y)

        case .custom:
            return primaryColor
        }
    }

    private func dynamicColor(x: CGFloat, y: CGFloat) -> Color {
        switch selectedEffect.id {
        case "wave":
            let wave = sin((x + y * 0.5) * 0.5 + animationPhase * 3) * 0.5 + 0.5
            return blend(color1: primaryColor, color2: secondaryColor, factor: wave)

        case "breathing":
            let breath = sin(animationPhase * 2) * 0.5 + 0.5
            return primaryColor.opacity(0.3 + breath * 0.7)

        case "rainbow":
            let hue = fmod((x + y + animationPhase * 2) / 15, 1.0)
            return Color(hue: hue, saturation: 0.8, brightness: 0.9)

        case "scanner":
            let scanX = sin(animationPhase * 3) * 7 + 7
            let dist = abs(x - scanX)
            let intensity = max(0, 1 - dist / 2)
            return blend(color1: secondaryColor, color2: primaryColor, factor: intensity)

        case "circle":
            let centerX: CGFloat = 7
            let centerY: CGFloat = 2.5
            let dist = sqrt(pow(x - centerX, 2) + pow(y - centerY, 2))
            let wave = sin(dist * 0.8 - animationPhase * 4) * 0.5 + 0.5
            return blend(color1: primaryColor, color2: secondaryColor, factor: wave)

        case "fire":
            let flicker = CGFloat.random(in: 0.5...1.0) * sin(animationPhase * 5 + x)
            return Color(hue: 0.05 + flicker * 0.08, saturation: 0.9, brightness: 0.5 + flicker * 0.5)

        default:
            return primaryColor
        }
    }

    private func reactiveColor(x: CGFloat, y: CGFloat) -> Color {
        if let origin = rippleOrigin {
            let dist = sqrt(pow(CGFloat(origin.col) - x, 2) + pow(CGFloat(origin.row) - y, 2))
            let ripple = exp(-dist * 0.5) * cos(dist * 2 - animationPhase * 8)
            return primaryColor.opacity(max(0.3, ripple))
        }
        return secondaryColor.opacity(0.2)
    }

    private func audioColor(x: CGFloat, y: CGFloat) -> Color {
        let bar = sin(animationPhase * 4 + x * 0.8) * 0.5 + 0.5
        let threshold = 1 - (y / 5)
        if bar > threshold {
            return primaryColor
        }
        return secondaryColor.opacity(0.15)
    }

    // MARK: - Color Helpers

    private func blend(color1: Color, color2: Color, factor: CGFloat) -> Color {
        let c1 = NSColor(color1).cgColor.components ?? [0, 0, 0, 1]
        let c2 = NSColor(color2).cgColor.components ?? [1, 1, 1, 1]
        let r = c1[0] + (c2[0] - c1[0]) * factor
        let g = c1[1] + (c2[1] - c1[1]) * factor
        let b = c1[2] + (c2[2] - c1[2]) * factor
        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Key Capsule

struct KeyCapsule: View {
    let label: String
    let color: Color
    let unit: CGFloat
    let size: KeyInfo.KeySize

    @State private var isHovered = false

    var widthMultiplier: CGFloat {
        switch size {
        case .standard, .fn: return 1.0
        case .wide: return 1.25
        case .wider: return 1.5
        case .widest: return 1.75
        case .space: return 2.0
        case .spaceLarge: return 2.25
        case .spaceXL: return 2.75
        case .spaceFull: return 6.25
        case .enter: return 2.25
        case .shift: return 2.25
        case .ctrl: return 1.25
        }
    }

    var body: some View {
        ZStack {
            // Key base with glass effect
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(color.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: color.opacity(0.4), radius: isHovered ? 8 : 4, x: 0, y: 2)

            // Key label
            Text(label)
                .font(.system(size: max(9, unit * 0.22), weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(width: unit * widthMultiplier, height: unit)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(Physics.interactive), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - fmod helper

func fmod(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
    a - b * floor(a / b)
}

#Preview {
    KeyboardVisualizer(
        selectedEffect: RGBEffectLibrary.effects[2],
        primaryColor: .blue,
        secondaryColor: .purple,
        isEnabled: true
    )
    .frame(width: 800, height: 300)
    .background(Color.black)
}
