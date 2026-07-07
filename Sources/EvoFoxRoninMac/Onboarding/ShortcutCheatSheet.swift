/**
 ShortcutCheatSheet.swift

 Sheet listing all keyboard shortcuts for the EvoFox Ronin Controller.
 Triggered by Cmd+? command.
 */

import SwiftUI

struct ShortcutCheatSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let shortcuts: [(key: String, modifiers: EventModifiers, action: String)] = [
        ("K", .command, String(localized: "shortcuts.connect")),
        ("D", [.command, .shift], String(localized: "shortcuts.disconnect")),
        ("N", [.command, .shift], String(localized: "shortcuts.newProfile")),
        ("S", [.command, .shift], String(localized: "shortcuts.saveToKeyboard")),
        ("?", .command, String(localized: "shortcuts.showShortcuts")),
        ("Q", .command, String(localized: "shortcuts.quit")),
    ]

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("shortcuts.title")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .vibrantText()

                    Text("shortcuts.subtitle")
                        .font(.system(size: 14, weight: .regular))
                        .vibrantText(isSecondary: true)
                }
                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .vibrantText(isSecondary: true)
                }
                .buttonStyle(PlainButtonStyle())
            }

            LiquidGlassCard {
                VStack(spacing: 0) {
                    ForEach(Array(shortcuts.enumerated()), id: \.offset) { index, shortcut in
                        HStack {
                            Text(shortcut.action)
                                .font(.system(size: 14, weight: .regular))
                                .vibrantText()

                            Spacer()

                            ShortcutKeyCombo(key: shortcut.key, modifiers: shortcut.modifiers)
                        }
                        .padding(.vertical, 10)

                        if index < shortcuts.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.1))
                        }
                    }
                }
            }

            Spacer(minLength: 20)
        }
        .padding(32)
        .frame(width: 480, height: 440)
    }
}

// MARK: - Shortcut Key Combo

private struct ShortcutKeyCombo: View {
    let key: String
    let modifiers: EventModifiers

    var body: some View {
        HStack(spacing: 4) {
            if modifiers.contains(.command) {
                KeyBadge(symbol: "\u{2318}")
            }
            if modifiers.contains(.shift) {
                KeyBadge(symbol: "\u{21E7}")
            }
            if modifiers.contains(.option) {
                KeyBadge(symbol: "\u{2325}")
            }
            if modifiers.contains(.control) {
                KeyBadge(symbol: "\u{2303}")
            }
            KeyBadge(symbol: key)
        }
    }
}

// MARK: - Key Badge

private struct KeyBadge: View {
    let symbol: String

    var body: some View {
        Text(symbol)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .frame(minWidth: 26, minHeight: 26)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
    }
}

#Preview {
    ShortcutCheatSheet()
        .background(Color.black)
}
