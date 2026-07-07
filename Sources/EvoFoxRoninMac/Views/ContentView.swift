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
    case connection
    case rgb
    case remap
    case macros
    case knob
    case polling
    case profiles

    var id: String { rawValue }

    var localizedKey: LocalizedStringKey {
        switch self {
        case .connection: return "sidebar.connection"
        case .rgb: return "sidebar.rgb"
        case .remap: return "sidebar.remap"
        case .macros: return "sidebar.macros"
        case .knob: return "sidebar.knob"
        case .polling: return "sidebar.polling"
        case .profiles: return "sidebar.profiles"
        }
    }

    var icon: String {
        switch self {
        case .connection: return "bolt.fill"
        case .rgb: return "lightbulb.fill"
        case .remap: return "keyboard.fill"
        case .macros: return "record.circle.fill"
        case .knob: return "knob"
        case .polling: return "gauge.with.dots.needle.33percent"
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
    @State private var showOnboarding = false
    @State private var showShortcutCheatSheet = false
    @State private var showWhatsNew = false

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

            if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                showOnboarding = true
            }

            if WhatsNewManager.shouldShow {
                showWhatsNew = true
            }

            NotificationCenter.default.addObserver(
                forName: .showShortcutCheatSheet,
                object: nil,
                queue: .main
            ) { _ in
                showShortcutCheatSheet = true
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
                .environment(hidManager)
        }
        .sheet(isPresented: $showShortcutCheatSheet) {
            ShortcutCheatSheet()
        }
        .sheet(isPresented: $showWhatsNew) {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            WhatsNewSheet(version: version)
                .onDisappear {
                    WhatsNewManager.markSeen()
                }
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
                    .help(item.localizedKey)
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
                .help("knob.title")

                Button(action: { showPollingRateSettings = true }) {
                    Image(systemName: "gauge.with.dots.needle.33percent")
                        .font(.system(size: 16))
                        .vibrantText(isSecondary: true)
                }
                .buttonStyle(PlainButtonStyle())
                .help("polling.title")

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
                case .knob:
                    KnobSettingsPanel()
                case .polling:
                    PollingRatePanel()
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
        case .connecting: return String(localized: "connection.status.connectingShort")
        case .scanning: return String(localized: "connection.status.scanningShort")
        case .disconnected: return String(localized: "connection.status.disconnectedShort")
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
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 130_000_000)
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
        .accessibilityLabel(item.localizedKey)
        .accessibilityValue(isSelected ? "nav.active" : "nav.notActive")
    }
}

// MARK: - Knob Settings Panel

private struct KnobSettingsPanel: View {
    @Environment(ProfileManager.self) private var profileManager

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("knob.title")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .vibrantText()

                    Text("knob.subtitle")
                        .font(.system(size: 14, weight: .regular))
                        .vibrantText(isSecondary: true)
                }
                Spacer()
            }

            LiquidGlassCard {
                VStack(spacing: 16) {
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
                    } else {
                        Text("general.noActiveProfile")
                            .vibrantText(isSecondary: true)
                    }
                }
            }

            Spacer(minLength: 40)
        }
        .frame(maxWidth: 800)
    }
}

// MARK: - Polling Rate Panel

private struct PollingRatePanel: View {
    @Environment(ProfileManager.self) private var profileManager

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("polling.title")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .vibrantText()

                    Text("polling.subtitle")
                        .font(.system(size: 14, weight: .regular))
                        .vibrantText(isSecondary: true)
                }
                Spacer()
            }

            LiquidGlassCard {
                VStack(spacing: 16) {
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
                    } else {
                        Text("general.noActiveProfile")
                            .vibrantText(isSecondary: true)
                    }
                }
            }

            Spacer(minLength: 40)
        }
        .frame(maxWidth: 800)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(HIDManager(mockMode: true))
        .environment(ProfileManager())
        .frame(width: 1100, height: 720)
}
