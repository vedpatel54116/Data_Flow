/**
 ProfileManagerView.swift

 Profile management interface for saving and loading keyboard configurations.

 The EvoFox Ronin has on-board memory for profiles. This view manages
 local profiles and syncs them to the keyboard memory.

 Features:
 - Create, rename, duplicate, delete profiles
 - Save profile to keyboard on-board memory
 - Load profile from keyboard
 - Import/export profiles as JSON
 - Set active profile

 Uses GlassCard for profile cards, spring physics for transitions.
*/

import SwiftUI

struct ProfileManagerView: View {
    @Environment(HIDManager.self) private var hidManager
    @Environment(ProfileManager.self) private var profileManager

    @State private var showNewProfileSheet = false
    @State private var newProfileName = ""
    @State private var showDeleteConfirmation = false
    @State private var profileToDelete: KeyboardProfile?

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profile Manager")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .vibrantText()

                    Text("Save and switch between keyboard configurations")
                        .font(.system(size: 14, weight: .regular))
                        .vibrantText(isSecondary: true)
                }

                Spacer()

                Button("New Profile") {
                    showNewProfileSheet = true
                }
                .buttonStyle(GlassButtonStyle(isProminent: true, tint: .green))
            }

            // Profile grid
            if profileManager.profiles.isEmpty {
                GlassCard {
                    VStack(spacing: 16) {
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 48))
                            .vibrantText(isSecondary: true)

                        Text("No profiles yet")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .vibrantText()

                        Text("Create a profile to save your keyboard settings")
                            .font(.system(size: 14, weight: .regular))
                            .vibrantText(isSecondary: true)
                    }
                    .padding(40)
                }
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 16) {
                    ForEach(profileManager.profiles) { profile in
                        ProfileCard(
                            profile: profile,
                            isActive: profileManager.activeProfileId == profile.id
                        ) {
                            profileManager.setActiveProfile(id: profile.id)
                        } onSaveToKeyboard: {
                            saveProfileToKeyboard(profile)
                        } onDelete: {
                            profileToDelete = profile
                            showDeleteConfirmation = true
                        }
                        .contentAnimation(value: profileManager.activeProfileId)
                    }
                }
            }

            Spacer(minLength: 40)
        }
        .frame(maxWidth: 800)
        .sheet(isPresented: $showNewProfileSheet) {
            NewProfileSheet { name in
                let profile = profileManager.createProfile(name: name)
                profileManager.setActiveProfile(id: profile.id)
            }
        }
        .alert("Delete Profile?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let profile = profileToDelete {
                    profileManager.deleteProfile(id: profile.id)
                }
            }
        } message: {
            if let profile = profileToDelete {
                Text("Are you sure you want to delete '\(profile.name)'? This cannot be undone.")
            }
        }
    }

    private func saveProfileToKeyboard(_ profile: KeyboardProfile) {
        guard hidManager.connectionState.isConnected else { return }

        let kbProtocol = KeyboardProtocol()
        let packet = kbProtocol.buildPacket(command: .saveProfile(profileId: 0x01))
        if case .failure(let error) = hidManager.sendReport(data: packet) {
            Logger.error("Failed to save profile: \(error.description)")
        }

        // Also save individual settings
        let rgbPacket = kbProtocol.buildRGBSettingsPacket(settings: profile.rgbSettings)
        if case .failure(let error) = hidManager.sendReport(data: rgbPacket) {
            Logger.error("Failed to save RGB settings: \(error.description)")
        }
    }
}

// MARK: - Profile Card

struct ProfileCard: View {
    let profile: KeyboardProfile
    let isActive: Bool
    let onActivate: () -> Void
    let onSaveToKeyboard: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(isActive ? Color.green.opacity(0.2) : Color.white.opacity(0.08))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(isActive ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                        .shadow(color: isActive ? Color.green.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)

                    Image(systemName: isActive ? "checkmark.circle.fill" : "square.stack")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isActive ? Color.green : Color.white.opacity(0.6))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.system(size: 15, weight: .semibold))
                        .vibrantText(isSecondary: !isActive)

                    Text("Modified \(formatDate(profile.modifiedAt))")
                        .font(.system(size: 11, weight: .regular))
                        .vibrantText(isSecondary: true)
                }

                Spacer()

                if isActive {
                    Text("Active")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.15))
                        )
                }
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // Profile details
            HStack(spacing: 16) {
                ProfileDetailItem(
                    icon: "lightbulb.fill",
                    label: profile.rgbSettings.effect.name
                )

                ProfileDetailItem(
                    icon: "keyboard.fill",
                    label: "\(profile.keyMappings.count) remaps"
                )

                ProfileDetailItem(
                    icon: "record.circle",
                    label: "\(profile.macros.count) macros"
                )
            }

            // Actions
            HStack(spacing: 10) {
                Button(isActive ? "Active" : "Activate") {
                    onActivate()
                }
                .buttonStyle(GlassButtonStyle(isProminent: !isActive, tint: .blue))
                .disabled(isActive)

                Button("Save to KB") {
                    onSaveToKeyboard()
                }
                .buttonStyle(GlassButtonStyle())

                Spacer()

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.red.opacity(0.7))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(8)
                .background(
                    Circle()
                        .fill(Color.red.opacity(0.1))
                )
            }
        }
        .padding(16)
        .background(
            GlassView(
                material: .sheet,
                blendingMode: .behindWindow,
                cornerRadius: 16
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isActive ? Color.green.opacity(0.3) : Color.white.opacity(0.08), lineWidth: isActive ? 1.5 : 0.5)
        )
        .shadow(color: isActive ? Color.green.opacity(0.2) : .clear, radius: 16, x: 0, y: 8)
        .glassFocus(isFocused: isHovered)
        .onHover { hovering in
            withAnimation(.spring(Physics.interactive)) {
                isHovered = hovering
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Profile Detail Item

struct ProfileDetailItem: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .vibrantText(isSecondary: true)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .vibrantText(isSecondary: true)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.06))
        )
    }
}

// MARK: - New Profile Sheet

struct NewProfileSheet: View {
    let onCreate: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""

    var body: some View {
        GlassCard {
            VStack(spacing: 20) {
                Text("New Profile")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .vibrantText()

                TextField("Profile name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 260)

                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(GlassButtonStyle())

                    Button("Create") {
                        if !name.isEmpty {
                            onCreate(name)
                            dismiss()
                        }
                    }
                    .buttonStyle(GlassButtonStyle(isProminent: true, tint: .green))
                }
            }
            .padding(24)
        }
        .frame(width: 320)
        .padding(40)
    }
}

#Preview {
    ProfileManagerView()
        .environment(HIDManager(mockMode: true))
        .environment(ProfileManager())
        .frame(width: 800, height: 700)
        .background(Color.black)
}
