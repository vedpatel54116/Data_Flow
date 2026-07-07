/**
 RGBControlView.swift

 RGB lighting control panel with live effect preview, color picker,
 speed/brightness controls, and per-key customization.

 Features:
 - 21 built-in effect selection with animated preview
 - Color picker with hex input
 - Speed and brightness sliders with glass styling
 - Per-key color override
 - Real-time apply to keyboard

 Glassmorphism: Uses LiquidGlassCard for panels, LiquidGlassButtonStyle for controls.
 Physics: Interactive spring for sliders, content spring for effect grid.
 */

import SwiftUI

struct RGBControlView: View {
    @Environment(HIDManager.self) private var hidManager
    @Environment(ProfileManager.self) private var profileManager

    @State private var selectedEffect: RGBEffect = RGBEffectLibrary.effects[0]
    @State private var speed: Double = 128
    @State private var brightness: Double = 255
    @State private var primaryColor: Color = .blue
    @State private var secondaryColor: Color = .white
    @State private var selectedDirection: RGBEffect.Direction = .right
    @State private var isEnabled: Bool = true
    @State private var showColorPicker: Bool = false
    @State private var colorPickerTarget: ColorPickerTarget = .primary

    @State private var appliedEffect: RGBEffect?
    @State private var showAppliedToast = false
    @State private var showErrorToast = false
    @State private var errorMessage = ""
    @State private var isApplying = false

    enum ColorPickerTarget {
        case primary
        case secondary
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("rgb.title")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .vibrantText()

                    Text("rgb.subtitle")
                        .font(.system(size: 14, weight: .regular))
                        .vibrantText(isSecondary: true)
                }

                Spacer()

                LiquidToggle(isOn: $isEnabled, tintColor: primaryColor, size: .medium)
                    .interactiveAnimation(value: isEnabled)
            }

            // Keyboard Visualizer (shows effect preview)
            KeyboardVisualizer(
                selectedEffect: selectedEffect,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                isEnabled: isEnabled
            )
            .frame(height: 260)
            .contentAnimation(value: selectedEffect.id)

            // Effect Grid
            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("rgb.effects.title")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .vibrantText()

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 10) {
                        ForEach(RGBEffectLibrary.effects) { effect in
                            EffectButton(
                                effect: effect,
                                isSelected: selectedEffect.id == effect.id
                            ) {
                                withAnimation(.spring(Physics.interactive)) {
                                    selectedEffect = effect
                                }
                            }
                        }
                    }
                }
            }

            // Controls Row
            HStack(spacing: 16) {
                // Color Controls
                LiquidGlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("rgb.colors.title")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .vibrantText()

                        HStack(spacing: 20) {
                            ColorSwatch(
                                color: primaryColor,
                                label: String(localized: "rgb.colors.primary"),
                                isSelected: colorPickerTarget == .primary
                            ) {
                                colorPickerTarget = .primary
                                showColorPicker = true
                            }

                            ColorSwatch(
                                color: secondaryColor,
                                label: String(localized: "rgb.colors.secondary"),
                                isSelected: colorPickerTarget == .secondary
                            ) {
                                colorPickerTarget = .secondary
                                showColorPicker = true
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                // Sliders
                LiquidGlassCard {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("rgb.parameters.title")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .vibrantText()

                        if selectedEffect.supportsDirection {
                            HStack {
                                Text("rgb.direction.label")
                                    .font(.system(size: 13, weight: .medium))
                                    .vibrantText(isSecondary: true)
                                    .frame(width: 70, alignment: .leading)

                                Picker("", selection: $selectedDirection) {
                                    ForEach(RGBEffect.Direction.allCases, id: \.self) { dir in
                                        Text(dir.name).tag(dir)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .interactiveAnimation(value: selectedDirection)
                            }
                        }

                        LiquidGlassSlider(
                            value: $speed,
                            range: 0...255,
                            label: String(localized: "rgb.speed.label"),
                            icon: "speedometer"
                        )

                        LiquidGlassSlider(
                            value: $brightness,
                            range: 0...255,
                            label: String(localized: "rgb.brightness.label"),
                            icon: "sun.max.fill"
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Apply Button
            HStack {
                Spacer()

                Button(action: applySettings) {
                    if isApplying {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("rgb.apply.button")
                    }
                }
                .buttonStyle(LiquidGlassButtonStyle(isProminent: true, tint: .green))
                .disabled(!hidManager.connectionState.isConnected || isApplying)

                Spacer()
            }
            .padding(.top, 8)

            Spacer(minLength: 40)
        }
        .frame(maxWidth: 800)
        .sheet(isPresented: $showColorPicker) {
            ColorPickerSheet(
                color: colorPickerTarget == .primary ? $primaryColor : $secondaryColor
            )
        }
        .overlay(
            Group {
                if showAppliedToast {
                    AppliedToast()
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 2_000_000_000)
                                withAnimation(.spring(Physics.morph)) {
                                    showAppliedToast = false
                                }
                            }
                        }
                }
                if showErrorToast {
                    ErrorToast(message: errorMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 3_000_000_000)
                                withAnimation(.spring(Physics.morph)) {
                                    showErrorToast = false
                                }
                            }
                        }
                }
            }
        )
    }

    private func applySettings() {
        guard hidManager.connectionState.isConnected else { return }

        isApplying = true
        showAppliedToast = false
        showErrorToast = false

        let effect = selectedEffect
        let spd = UInt8(speed)
        let bri = UInt8(brightness)
        let pColor = RGBColor(
            r: UInt8(primaryColor.rgba.red * 255),
            g: UInt8(primaryColor.rgba.green * 255),
            b: UInt8(primaryColor.rgba.blue * 255)
        )
        let sColor = RGBColor(
            r: UInt8(secondaryColor.rgba.red * 255),
            g: UInt8(secondaryColor.rgba.green * 255),
            b: UInt8(secondaryColor.rgba.blue * 255)
        )
        let dir = selectedDirection
        let enabled = isEnabled

        Task.detached(priority: .userInitiated) { [self] in
            let kbProtocol = KeyboardProtocol()
            let settings = RGBSettings(
                effect: effect,
                speed: spd,
                brightness: bri,
                primaryColor: pColor,
                secondaryColor: sColor,
                direction: dir,
                isEnabled: enabled
            )

            let packet = kbProtocol.buildRGBSettingsPacket(settings: settings)
            let result = await MainActor.run { hidManager.sendReport(data: packet) }

            await MainActor.run {
                isApplying = false
                switch result {
                case .success:
                    appliedEffect = effect
                    withAnimation(.spring(Physics.morph)) {
                        showAppliedToast = true
                    }
                case .failure(let error):
                    errorMessage = error.description
                    withAnimation(.spring(Physics.morph)) {
                        showErrorToast = true
                    }
                }
            }
        }
    }
}

// MARK: - Effect Button

struct EffectButton: View {
    let effect: RGBEffect
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                effectIcon
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(effect.name)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                        .vibrantText(isSecondary: !isSelected)
                        .lineLimit(1)

                    Text(effect.category.rawValue)
                        .font(.system(size: 10, weight: .regular))
                        .vibrantText(isSecondary: true)
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.04))

                    if isSelected {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(effect.category == .dynamic ? Color.purple.opacity(0.15) :
                                    effect.category == .reactive ? Color.blue.opacity(0.15) :
                                    effect.category == .audio ? Color.orange.opacity(0.15) :
                                    effect.category == .custom ? Color.green.opacity(0.15) :
                                    Color.gray.opacity(0.15))
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.05), lineWidth: 0.5)
                )
                .shadow(color: isSelected ? effectCategoryColor.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            )
            .glassFocus(isFocused: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.spring(Physics.interactive)) {
                isHovered = hovering
            }
        }
        .interactiveAnimation(value: isSelected)
    }

    private var effectCategoryColor: Color {
        switch effect.category {
        case .staticColor: return .gray
        case .dynamic: return .purple
        case .reactive: return .blue
        case .audio: return .orange
        case .custom: return .green
        }
    }

    private var effectIcon: some View {
        ZStack {
            Circle()
                .fill(
                    effect.category == .dynamic ? Color.purple.opacity(0.3) :
                    effect.category == .reactive ? Color.blue.opacity(0.3) :
                    effect.category == .audio ? Color.orange.opacity(0.3) :
                    effect.category == .custom ? Color.green.opacity(0.3) :
                    Color.gray.opacity(0.3)
                )

            Image(systemName: effectIconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var effectIconName: String {
        switch effect.category {
        case .staticColor: return "circle.fill"
        case .dynamic: return "waveform"
        case .reactive: return "hand.tap.fill"
        case .audio: return "speaker.wave.2.fill"
        case .custom: return "paintbrush.fill"
        }
    }
}

// MARK: - Color Swatch

struct ColorSwatch: View {
    let color: Color
    let label: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 44, height: 44)
                        .overlay(
                            NoiseOverlay(opacity: 0.04)
                                .clipShape(Circle())
                                .allowsHitTesting(false)
                        )
                        .shadow(color: color.opacity(0.4), radius: isHovered ? 12 : 8, x: 0, y: 4)

                    if isSelected {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 50, height: 50)
                            .shadow(color: color.opacity(0.5), radius: 8, x: 0, y: 0)
                    }
                }

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .vibrantText(isSecondary: true)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.spring(Physics.interactive)) {
                isHovered = hovering
            }
        }
        .interactiveAnimation(value: isSelected)
    }
}

// MARK: - Liquid Glass Slider

struct LiquidGlassSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let label: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .vibrantText(isSecondary: true)
                    .frame(width: 20)

                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .vibrantText(isSecondary: true)

                Spacer()

                Text("\(Int(value))")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .vibrantText()
                    .frame(width: 40, alignment: .trailing)
            }

            Slider(value: $value, in: range)
                .tint(.white.opacity(0.6))
                .overlay(
                    GeometryReader { geo in
                        let progress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.white.opacity(0.15))
                            .frame(width: geo.size.width * progress, height: 6)
                            .offset(x: 0)
                            .allowsHitTesting(false)
                    }
                )
                .interactiveAnimation(value: value)
        }
    }
}

// MARK: - Color Picker Sheet

struct ColorPickerSheet: View {
    @Binding var color: Color
    @Environment(\.dismiss) private var dismiss

    @State private var hue: Double = 0.5
    @State private var saturation: Double = 0.8
    @State private var brightness: Double = 0.9

    var body: some View {
        LiquidGlassCard {
            VStack(spacing: 24) {
                Text("rgb.picker.title")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .vibrantText()

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hue: hue, saturation: saturation, brightness: brightness))
                    .frame(height: 80)
                    .shadow(color: Color(hue: hue, saturation: saturation, brightness: brightness).opacity(0.4), radius: 16, x: 0, y: 8)

                VStack(spacing: 16) {
                    LiquidGlassSlider(value: $hue, range: 0...1, label: String(localized: "rgb.picker.hue"), icon: "eyedropper")
                    LiquidGlassSlider(value: $saturation, range: 0...1, label: String(localized: "rgb.picker.saturation"), icon: "drop.fill")
                    LiquidGlassSlider(value: $brightness, range: 0...1, label: String(localized: "rgb.brightness.label"), icon: "sun.max")
                }

                HStack {
                    Button("general.cancel") {
                        dismiss()
                    }
                    .buttonStyle(LiquidGlassButtonStyle())

                    Spacer()

                    Button("rgb.picker.apply") {
                        color = Color(hue: hue, saturation: saturation, brightness: brightness)
                        dismiss()
                    }
                    .buttonStyle(LiquidGlassButtonStyle(isProminent: true, tint: .blue))
                }
            }
            .padding(24)
        }
        .frame(width: 340)
        .padding(40)
        .onAppear {
            let components = color.rgba
            let r = components.red
            let g = components.green
            let b = components.blue
            let maxVal = max(r, g, b)
            let minVal = min(r, g, b)
            let delta = maxVal - minVal
            
            brightness = Double(maxVal)
            saturation = maxVal > 0 ? Double(delta / maxVal) : 0
            if delta == 0 {
                hue = 0
            } else if maxVal == r {
                hue = Double((g - b) / delta / 6).truncatingRemainder(dividingBy: 1)
            } else if maxVal == g {
                hue = Double((b - r) / delta / 6 + 1/3).truncatingRemainder(dividingBy: 1)
            } else {
                hue = Double((r - g) / delta / 6 + 2/3).truncatingRemainder(dividingBy: 1)
            }
        }
    }
}

// MARK: - Applied Toast

struct AppliedToast: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)

            Text("rgb.toast.applied")
                .font(.system(size: 13, weight: .semibold))
                .vibrantText()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LiquidGlassContainer(material: .floating, cornerRadius: 20, padding: 0) {
                Color.clear
            }
        )
        .overlay(
            Capsule()
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .padding(.top, 16)
    }
}

// MARK: - Error Toast

struct ErrorToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)

            Text(message)
                .font(.system(size: 13, weight: .semibold))
                .vibrantText()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LiquidGlassContainer(material: .floating, cornerRadius: 20, padding: 0) {
                Color.clear
            }
        )
        .overlay(
            Capsule()
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .padding(.top, 16)
    }
}

// MARK: - Direction Extension

extension RGBEffect.Direction {
    var name: String {
        switch self {
        case .left: return String(localized: "rgb.direction.left")
        case .right: return String(localized: "rgb.direction.right")
        case .up: return String(localized: "rgb.direction.up")
        case .down: return String(localized: "rgb.direction.down")
        case .inward: return String(localized: "rgb.direction.in")
        case .outward: return String(localized: "rgb.direction.out")
        }
    }
}

#Preview {
    RGBControlView()
        .environment(HIDManager(mockMode: true))
        .environment(ProfileManager())
        .frame(width: 800, height: 900)
        .background(Color.black)
}
