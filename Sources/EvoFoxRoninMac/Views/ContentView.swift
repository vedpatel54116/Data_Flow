/**
 ContentView.swift

 Main window content for the EvoFox Ronin Controller.

 Design:
 - Full-bleed animated mesh gradient background (replicates CSS moveBackground)
 - Liquid glass sidebar on the left with icon-based pill navigation
 - Content panels on the right (NO glass on content layer — Apple's rule)
 - Liquid glass cards for content sections

 Physics:
 - Sidebar uses navigation spring
 - Panel switching uses morph spring
 - Button interactions use interactive spring
 - Card entrance uses content spring with staggered cascade
 */

import SwiftUI
import AppKit
import UniformTypeIdentifiers

enum SidebarItem: String, CaseIterable, Identifiable {
    case connection = "Connection"
    case rgb = "RGB Lighting"
    case remap = "Key Remap"
    case macros = "Macros"
    case profiles = "Profiles"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .connection: return "bolt.fill"
        case .rgb: return "lightbulb.fill"
        case .remap: return "keyboard.fill"
        case .macros: return "record.circle.fill"
        case .profiles: return "square.stack.3d.up.fill"
        }
    }
}

struct ContentView: View {
    @Environment(HIDManager.self) private var hidManager
    @Environment(ProfileManager.self) private var profileManager

    @State private var selectedItem: SidebarItem = .connection
    @State private var showKnobSettings = false
    @State private var showPollingRateSettings = false

    @Namespace private var animation

    var body: some View {
        ZStack {
            // Animated mesh gradient background — the liquid glass will sample this
            LiquidGlassBackground()
                .ignoresSafeArea()

            // Main layout: sidebar + content
            HStack(spacing: 0) {
                // Glass Sidebar (Navigation layer — glass is OK here)
                sidebar
                    .zIndex(1)

                // Content area (NO glass on content layer)
                contentPanel
                    .zIndex(0)
            }
        }
        .onAppear {
            Logger.debug("ContentView.onAppear — calling hidManager.connect()")
            hidManager.connect()
        }
    }

    // MARK: - Sidebar (Liquid Glass Nav)

    private var sidebar: some View {
        VStack(spacing: 0) {
            // App icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)

                Image(systemName: "keyboard.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .vibrantText()
            }
            .padding(.top, 24)
            .padding(.bottom, 16)

            // Connection indicator — compact dot with tooltip
            Capsule()
                .fill(connectionIndicatorColor)
                .frame(width: 8, height: 8)
                .shadow(color: connectionIndicatorColor.opacity(0.5), radius: 4)
                .accessibilityLabel(connectionStatusText)
                .help(connectionStatusText)
                .padding(.bottom, 28)

            // Navigation icons
            VStack(spacing: 8) {
                ForEach(SidebarItem.allCases) { item in
                    NavPillButton(
                        item: item,
                        isSelected: selectedItem == item
                    ) {
                        withAnimation(.spring(Physics.navigation)) {
                            selectedItem = item
                        }
                    }
                    .help(item.rawValue)
                }
            }

            Spacer()

            // Bottom section
            VStack(spacing: 8) {
                // Device settings
                Button(action: { showKnobSettings = true }) {
                    Image(systemName: "knob")
                        .font(.system(size: 16))
                        .vibrantText(isSecondary: true)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Configure Volume Knob")

                Button(action: { showPollingRateSettings = true }) {
                    Image(systemName: "gauge.with.dots.needle.33percent")
                        .font(.system(size: 16))
                        .vibrantText(isSecondary: true)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Configure Polling Rate")

                Divider()
                    .frame(width: 24)

                if let profile = profileManager.activeProfile {
                    Text(profile.name)
                        .font(.system(size: 9, weight: .medium))
                        .vibrantText(isSecondary: true)
                        .lineLimit(1)
                }

                CompactThemeSwitcher()
            }
            .padding(.bottom, 20)
        }
        .frame(width: 80)
        .background(
            LiquidGlassContainer(material: .container, cornerRadius: 0, padding: 0) {
                Color.clear
            }
        )
        .sheet(isPresented: $showKnobSettings) {
            if let profile = profileManager.activeProfile {
                KnobSettingsView(knobBehavior: Binding(
                    get: { profile.knobBehavior },
                    set: { newValue in
                        var updated = profile
                        updated.knobBehavior = newValue
                        profileManager.updateProfile(updated)
                    }
                ))
                .environment(profileManager)
            }
        }
        .sheet(isPresented: $showPollingRateSettings) {
            if let profile = profileManager.activeProfile {
                PollingRateView(pollingRate: Binding(
                    get: { profile.pollingRate },
                    set: { newValue in
                        var updated = profile
                        updated.pollingRate = newValue
                        profileManager.updateProfile(updated)
                    }
                ))
                .environment(profileManager)
            }
        }
    }

    // MARK: - Content Panel

    @ViewBuilder
    private var contentPanel: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                switch selectedItem {
                case .connection:
                    ConnectionView()
                case .rgb:
                    RGBControlView()
                case .remap:
                    KeyRemapView()
                case .macros:
                    MacroEditorView()
                case .profiles:
                    ProfileManagerView()
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear) // No glass on content layer
    }

    // MARK: - Connection Status Helpers

    private var connectionIndicatorColor: Color {
        switch hidManager.connectionState {
        case .connected: return .green
        case .connecting, .scanning: return .yellow
        case .disconnected: return .red
        case .error: return .orange
        }
    }

    private var connectionStatusText: String {
        switch hidManager.connectionState {
        case .connected(let name): return name
        case .connecting: return "Connecting..."
        case .scanning: return "Scanning..."
        case .disconnected: return "Disconnected"
        case .error(let error): return error.description
        }
    }
}

// MARK: - Nav Pill Button

struct NavPillButton: View {
    let item: SidebarItem
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            action()
            withAnimation(.spring(response: 0.13, dampingFraction: 0.5)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        }) {
            Image(systemName: item.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white.opacity(0.6))
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            isSelected
                                ? Color.white
                                : (isHovered
                                    ? Color.white.opacity(0.15)
                                    : Color.white.opacity(0.06))
                        )
                )
                .scaleEffect(isPressed ? 0.75 : (isHovered ? 0.88 : 1.0))
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.spring(Physics.interactive)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(HIDManager(mockMode: true))
        .environment(ProfileManager())
        .frame(width: 1100, height: 720)
}
