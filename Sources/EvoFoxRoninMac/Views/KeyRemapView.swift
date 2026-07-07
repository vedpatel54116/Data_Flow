/**
 KeyRemapView.swift

 Key remapping interface for the EvoFox Ronin TKL.

 Shows a visual keyboard where users can click any key to assign a new
 action: standard key, media control, mouse button, or macro trigger.

 Uses LiquidGlassCard for the config panel, LiquidGlassButtonStyle for actions,
 and physics-based spring animations for all interactions.
 */

import SwiftUI

struct KeyRemapView: View {
    @Environment(HIDManager.self) private var hidManager
    @Environment(ProfileManager.self) private var profileManager

    @State private var selectedKey: KeyInfo?
    @State private var showKeyActionSheet = false
    @State private var searchText = ""
    @State private var remappedCount = 0

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("remap.title")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .vibrantText()

                    Text("remap.subtitle")
                        .font(.system(size: 14, weight: .regular))
                        .vibrantText(isSecondary: true)
                }

                Spacer()

                HStack(spacing: 12) {
                    Text("remap.keysRemapped \(remappedCount)")
                        .font(.system(size: 12, weight: .medium))
                        .vibrantText(isSecondary: true)

                    Button("remap.resetAll") {
                        resetAllMappings()
                    }
                    .buttonStyle(LiquidGlassButtonStyle(tint: .orange))
                }
            }

            // Visual keyboard for remapping
            LiquidGlassCard {
                VStack(spacing: 16) {
                    Text("remap.clickHint")
                        .font(.system(size: 13, weight: .medium))
                        .vibrantText(isSecondary: true)

                    RemapKeyboardGrid(
                        selectedKey: $selectedKey,
                        onKeySelected: { key in
                            selectedKey = key
                            showKeyActionSheet = true
                        }
                    )
                    .frame(height: 280)
                }
            }

            // Current mappings list
            if let profile = profileManager.activeProfile, !profile.keyMappings.isEmpty {
                LiquidGlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("remap.mappings")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .vibrantText()

                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(spacing: 8) {
                                ForEach(profile.keyMappings.filter { mapping in
                                    if let key = RoninLayout.allKeys.first(where: { $0.scanCode == mapping.keyScanCode }) {
                                        return mapping.assignedAction != .standardKey(keyCode: key.defaultKeyCode)
                                    }
                                    return false
                                }) { mapping in
                                    MappingRow(mapping: mapping)
                                        .contentAnimation(value: mapping.id)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                }
            }

            Spacer(minLength: 40)
        }
        .frame(maxWidth: 800)
        .sheet(isPresented: $showKeyActionSheet) {
            if let key = selectedKey {
                KeyActionSheet(key: key) { action in
                    assignAction(action, to: key)
                }
            }
        }
    }

    private func assignAction(_ action: KeyAction, to key: KeyInfo) {
        var profile = profileManager.activeProfile ?? KeyboardProfile.default()

        if let index = profile.keyMappings.firstIndex(where: { $0.keyScanCode == key.scanCode }) {
            profile.keyMappings[index].assignedAction = action
        } else {
            let mapping = KeyMapping(
                keyPosition: key.position,
                keyScanCode: key.scanCode,
                assignedAction: action
            )
            profile.keyMappings.append(mapping)
        }

        profileManager.updateProfile(profile)
        remappedCount = profile.keyMappings.filter { mapping in
            if let k = RoninLayout.allKeys.first(where: { $0.scanCode == mapping.keyScanCode }) {
                return mapping.assignedAction != .standardKey(keyCode: k.defaultKeyCode)
            }
            return false
        }.count

        // Send to keyboard
        if hidManager.connectionState.isConnected {
            let mapping = KeyMapping(
                keyPosition: key.position,
                keyScanCode: key.scanCode,
                assignedAction: action
            )
            let kbProtocol = KeyboardProtocol()
            let packet = kbProtocol.buildRemapPacket(mapping: mapping)
            if case .failure(let error) = hidManager.sendReport(data: packet) {
                Logger.error("Failed to send remap packet: \(error.description)")
            }
        }
    }

    private func resetAllMappings() {
        guard var profile = profileManager.activeProfile else { return }
        profile.keyMappings = RoninLayout.allKeys.map { key in
            KeyMapping(
                keyPosition: key.position,
                keyScanCode: key.scanCode,
                assignedAction: .standardKey(keyCode: key.defaultKeyCode)
            )
        }
        profileManager.updateProfile(profile)
        remappedCount = 0
    }
}

// MARK: - Remap Keyboard Grid

struct RemapKeyboardGrid: View {
    @Binding var selectedKey: KeyInfo?
    let onKeySelected: (KeyInfo) -> Void

    var body: some View {
        GeometryReader { geometry in
            let keyUnit: CGFloat = min(geometry.size.width / 16, 40)
            let spacing: CGFloat = 3

            VStack(spacing: spacing) {
                ForEach(0..<RoninLayout.keys.count, id: \.self) { rowIndex in
                    HStack(spacing: spacing) {
                        ForEach(0..<RoninLayout.keys[rowIndex].count, id: \.self) { colIndex in
                            let key = RoninLayout.keys[rowIndex][colIndex]
                            RemapKeyButton(
                                key: key,
                                unit: keyUnit,
                                isSelected: selectedKey?.scanCode == key.scanCode
                            ) {
                                onKeySelected(key)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct RemapKeyButton: View {
    let key: KeyInfo
    let unit: CGFloat
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var widthMultiplier: CGFloat {
        switch key.size {
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
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.4) : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(
                                isSelected ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 1.5 : 0.5
                            )
                    )
                    .shadow(color: isSelected ? Color.accentColor.opacity(0.5) : .clear, radius: 8, x: 0, y: 4)

                Text(key.defaultLabel)
                    .font(.system(size: max(8, unit * 0.2), weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: unit * widthMultiplier, height: unit)
        .scaleEffect(isHovered ? 1.08 : 1.0)
        .animation(.spring(Physics.interactive), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Key Action Sheet

struct KeyActionSheet: View {
    let key: KeyInfo
    let onSelect: (KeyAction) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0

    var body: some View {
        LiquidGlassCard {
            VStack(spacing: 20) {
                HStack {
                    Text("remap.action.title \(key.defaultLabel)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .vibrantText()

                    Spacer()

                    Button("general.cancel") {
                        dismiss()
                    }
                    .buttonStyle(LiquidGlassButtonStyle())
                }

                Picker("remap.action.type", selection: $selectedTab) {
                    Text("remap.action.standard").tag(0)
                    Text("remap.action.media").tag(1)
                    Text("remap.action.mouse").tag(2)
                    Text("remap.action.macro").tag(3)
                    Text("remap.action.disable").tag(4)
                }
                .pickerStyle(.segmented)
                .interactiveAnimation(value: selectedTab)

                ScrollView {
                    VStack(spacing: 10) {
                        switch selectedTab {
                        case 0:
                            StandardKeyGrid { keyCode in
                                onSelect(.standardKey(keyCode: keyCode))
                                dismiss()
                            }
                        case 1:
                            MediaKeyGrid { media in
                                onSelect(.mediaKey(media: media))
                                dismiss()
                            }
                        case 2:
                            MouseButtonGrid { button in
                                onSelect(.mouseButton(button: button))
                                dismiss()
                            }
                        case 3:
                            Text("remap.action.macroHint")
                                .vibrantText(isSecondary: true)
                                .padding(40)
                        case 4:
                            Button("remap.action.disableKey") {
                                onSelect(.disabled)
                                dismiss()
                            }
                            .buttonStyle(LiquidGlassButtonStyle(isProminent: true, tint: .red))
                            .padding(40)
                        default:
                            EmptyView()
                        }
                    }
                }
            }
            .padding(24)
        }
        .frame(width: 500, height: 400)
        .padding(40)
    }
}

// MARK: - Action Grids

struct StandardKeyGrid: View {
    let onSelect: (UInt16) -> Void

    let keys: [(String, UInt16)] = [
        ("A", 0x00), ("B", 0x01), ("C", 0x02), ("D", 0x03), ("E", 0x04),
        ("F", 0x05), ("G", 0x06), ("H", 0x07), ("I", 0x08), ("J", 0x09),
        ("K", 0x0A), ("L", 0x0B), ("M", 0x0C), ("N", 0x0D), ("O", 0x0E),
        ("P", 0x0F), ("Q", 0x10), ("R", 0x11), ("S", 0x12), ("T", 0x13),
        ("U", 0x14), ("V", 0x15), ("W", 0x16), ("X", 0x17), ("Y", 0x18),
        ("Z", 0x19), ("1", 0x1A), ("2", 0x1B), ("3", 0x1C), ("4", 0x1D),
        ("5", 0x1E), ("6", 0x1F), ("7", 0x20), ("8", 0x21), ("9", 0x22),
        ("0", 0x23), ("Enter", 0x24), ("Esc", 0x25), ("Back", 0x26),
        ("Tab", 0x27), ("Space", 0x28), ("F1", 0x35), ("F2", 0x36),
        ("F3", 0x37), ("F4", 0x38), ("F5", 0x39), ("F6", 0x3A),
        ("F7", 0x3B), ("F8", 0x3C), ("F9", 0x3D), ("F10", 0x3E),
        ("F11", 0x3F), ("F12", 0x40)
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
            ForEach(keys, id: \.1) { key in
                Button(key.0) {
                    onSelect(key.1)
                }
                .buttonStyle(LiquidGlassButtonStyle())
            }
        }
    }
}

struct MediaKeyGrid: View {
    let onSelect: (KeyAction.MediaKey) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 8) {
            ForEach(KeyAction.MediaKey.allCases, id: \.self) { media in
                Button(media.rawValue) {
                    onSelect(media)
                }
                .buttonStyle(LiquidGlassButtonStyle())
            }
        }
    }
}

struct MouseButtonGrid: View {
    let onSelect: (KeyAction.MouseButton) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 8) {
            ForEach(KeyAction.MouseButton.allCases, id: \.self) { button in
                    Button("remap.mouse.button \(button.rawValue)") {
                    onSelect(button)
                }
                .buttonStyle(LiquidGlassButtonStyle())
            }
        }
    }
}

// MARK: - Mapping Row

struct MappingRow: View {
    let mapping: KeyMapping

    var body: some View {
        HStack {
            if let key = RoninLayout.allKeys.first(where: { $0.scanCode == mapping.keyScanCode }) {
                Text(key.defaultLabel)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .vibrantText()
                    .frame(width: 80, alignment: .leading)

                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .vibrantText(isSecondary: true)

                Text(mapping.assignedAction.displayLabel)
                    .font(.system(size: 13, weight: .regular))
                    .vibrantText(isSecondary: true)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    KeyRemapView()
        .environment(HIDManager(mockMode: true))
        .environment(ProfileManager())
        .frame(width: 800, height: 700)
        .background(Color.black)
}
