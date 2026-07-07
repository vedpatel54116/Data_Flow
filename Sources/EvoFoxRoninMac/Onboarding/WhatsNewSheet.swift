/**
 WhatsNewSheet.swift

 Sheet shown after app updates with version number and key changes.
 Checks UserDefaults for lastSeenVersion against current bundle version.
 */

import SwiftUI

struct WhatsNewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let version: String

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("whatsNew.title")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .vibrantText()

                    Text("whatsNew.version \(version)")
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
                VStack(alignment: .leading, spacing: 16) {
                    WhatsNewFeature(
                        icon: "keyboard.fill",
                        title: String(localized: "whatsNew.feature.onboarding"),
                        description: String(localized: "whatsNew.feature.onboarding.desc")
                    )

                    WhatsNewFeature(
                        icon: "questionmark.circle.fill",
                        title: String(localized: "whatsNew.feature.shortcuts"),
                        description: String(localized: "whatsNew.feature.shortcuts.desc")
                    )

                    WhatsNewFeature(
                        icon: "lock.shield.fill",
                        title: String(localized: "whatsNew.feature.permissions"),
                        description: String(localized: "whatsNew.feature.permissions.desc")
                    )
                }
            }

            Button("whatsNew.gotIt") {
                dismiss()
            }
            .buttonStyle(LiquidGlassButtonStyle(isProminent: true))

            Spacer(minLength: 20)
        }
        .padding(32)
        .frame(width: 480, height: 440)
    }
}

// MARK: - Whats New Feature Row

private struct WhatsNewFeature: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .vibrantText()

                Text(description)
                    .font(.system(size: 12, weight: .regular))
                    .vibrantText(isSecondary: true)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - UserDefaults Helpers

enum WhatsNewManager {
    private static let lastSeenKey = "lastSeenVersion"

    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var shouldShow: Bool {
        let lastSeen = UserDefaults.standard.string(forKey: lastSeenKey)
        return lastSeen != currentVersion
    }

    static func markSeen() {
        UserDefaults.standard.set(currentVersion, forKey: lastSeenKey)
    }
}

#Preview {
    WhatsNewSheet(version: "1.0")
        .background(Color.black)
}
