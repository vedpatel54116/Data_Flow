/**
 ThemeSwitcher.swift

 A liquid glass theme switcher inspired by Vadik Matveev's liquid glass design.
 Supports three themes: Light, Dark, and Dim with smooth morphing transitions.
 */

import SwiftUI
import AppKit

// MARK: - App Theme

public enum AppTheme: String, CaseIterable, Identifiable {
    case light = "light"
    case dark = "dark"
    case dim = "dim"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .light: return String(localized: "theme.light")
        case .dark: return String(localized: "theme.dark")
        case .dim: return String(localized: "theme.dim")
        }
    }

    public var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .dim: return "cloud.sun.fill"
        }
    }

    public var backgroundColors: [Color] {
        switch self {
        case .light: return [Color(hex: "E8E8E9"), Color(hex: "F0F0F1")]
        case .dark: return [Color(hex: "1b1b1d"), Color(hex: "232326")]
        case .dim: return [Color(hex: "1a1a2e"), Color(hex: "16213e")]
        }
    }

    public var contentColor: Color {
        switch self {
        case .light: return Color(hex: "222444")
        case .dark: return Color(hex: "e1e1e1")
        case .dim: return Color(hex: "d5dbe2")
        }
    }

    public var actionColor: Color {
        switch self {
        case .light: return Color(hex: "0052f5")
        case .dark: return Color(hex: "03d5ff")
        case .dim: return Color(hex: "ff48a9")
        }
    }

    public var glassColor: Color {
        switch self {
        case .light: return Color(hex: "bbbbbc")
        case .dark: return Color(hex: "bbbbbc")
        case .dim: return Color(hex: "e8b4d4")
        }
    }
}



// MARK: - Theme Manager

@Observable
@MainActor
public final class ThemeManager {
    public static let shared = ThemeManager()

    public var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
            applyTheme()
        }
    }
    
    /// Current theme environment with all computed colors
    public var environment: ThemeEnvironment {
        ThemeEnvironment(theme: currentTheme)
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: "appTheme") ?? "dark"
        self.currentTheme = AppTheme(rawValue: stored) ?? .dark
        applyTheme()
    }

    private func applyTheme() {
        NSApp.windows.forEach { window in
            switch self.currentTheme {
            case .light:
                window.appearance = NSAppearance(named: .aqua)
            case .dark:
                window.appearance = NSAppearance(named: .darkAqua)
            case .dim:
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
    }

    public func cycleTheme() {
        let allCases = AppTheme.allCases
        if let currentIndex = allCases.firstIndex(of: currentTheme) {
            let nextIndex = (currentIndex + 1) % allCases.count
            currentTheme = allCases[nextIndex]
        }
    }
}

// MARK: - Theme Switcher View

public struct ThemeSwitcher: View {
    @Bindable var themeManager = ThemeManager.shared

    @State private var privateIndex: Int = 0
    @State private var hoverIndex: Int = 0
    @State private var isAnimating = false
    @State private var ripplePosition: CGPoint = .zero

    private let themes = AppTheme.allCases
    private let optionWidth: CGFloat = 56
    private let optionHeight: CGFloat = 56
    private let spacing: CGFloat = 8

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("theme.appearance")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .glassText(.secondary)
                .tracking(0.5)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            ZStack {
                // Background track - uses theme-aware glass
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.environment.glassColor.opacity(0.12),
                                themeManager.environment.glassColor.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                Color.white.opacity(themeManager.environment.glassReflexLight * 0.1),
                                lineWidth: 0.5
                            )
                    )
                    .frame(width: totalWidth, height: optionHeight)

                // Liquid indicator
                liquidIndicator

                // Option buttons
                HStack(spacing: spacing) {
                    ForEach(Array(themes.enumerated()), id: \.element.id) { index, theme in
                        themeOption(theme: theme, index: index)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(width: totalWidth, height: optionHeight)
        }
        .onChange(of: themeManager.currentTheme) { _, newTheme in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
                privateIndex = themes.firstIndex(of: newTheme) ?? 0
            }
        }
        .onAppear {
            privateIndex = themes.firstIndex(of: themeManager.currentTheme) ?? 0
        }
    }

    private var totalWidth: CGFloat {
        CGFloat(themes.count) * optionWidth + CGFloat(themes.count - 1) * spacing + 8
    }

    // MARK: - Liquid Indicator

    private var liquidIndicator: some View {
        let currentTheme = themes[privateIndex]
        let indicatorOffset = indicatorOffset(for: privateIndex)
        let themeEnv = themeManager.environment

        return ZStack {
            // Main liquid blob
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            currentTheme.glassColor.opacity(0.35),
                            currentTheme.glassColor.opacity(0.18),
                            currentTheme.actionColor.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: optionWidth, height: optionHeight - 8)
                .offset(x: indicatorOffset)
                .shadow(
                    color: currentTheme.actionColor.opacity(0.4),
                    radius: 10,
                    x: 0,
                    y: 5
                )
                .shadow(
                    color: Color.black.opacity(themeEnv.glassReflexDark * 0.1),
                    radius: 3,
                    x: 0,
                    y: 2
                )
                .overlay(
                    // Inner highlight
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(themeEnv.glassReflexLight * 0.5),
                                    Color.white.opacity(themeEnv.glassReflexLight * 0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: optionWidth - 4, height: optionHeight - 12)
                        .offset(x: indicatorOffset, y: -2)
                        .allowsHitTesting(false)
                )

            // Ripple effect on change
            if isAnimating {
                Circle()
                    .fill(currentTheme.actionColor.opacity(0.35))
                    .frame(width: 20, height: 20)
                    .position(
                        x: indicatorOffset + optionWidth / 2 + totalWidth / 2 - optionWidth * CGFloat(themes.count) / 2 + 4,
                        y: optionHeight / 2
                    )
                    .scaleEffect(isAnimating ? 3 : 0.5)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(.easeOut(duration: 0.4), value: isAnimating)
                    .allowsHitTesting(false)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: privateIndex)
    }

    private func indicatorOffset(for index: Int) -> CGFloat {
        let startX = -(totalWidth / 2) + (optionWidth / 2) + 4
        return startX + CGFloat(index) * (optionWidth + spacing)
    }

    // MARK: - Theme Option

    private func themeOption(theme: AppTheme, index: Int) -> some View {
        let isSelected = themeManager.currentTheme == theme
        let themeEnv = themeManager.environment

        return Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                themeManager.currentTheme = theme
                triggerRipple()
            }
        } label: {
            ZStack {
                // Icon background glow when selected
                if isSelected {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    theme.actionColor.opacity(0.3),
                                    theme.actionColor.opacity(0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: optionWidth / 2
                            )
                        )
                        .frame(width: optionWidth, height: optionHeight)
                        .blur(radius: 10)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }

                // Icon
                Image(systemName: theme.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        isSelected
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [theme.actionColor, theme.actionColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            : AnyShapeStyle(themeEnv.tertiaryText)
                    )
                    .symbolEffect(.bounce, value: isSelected)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
            .frame(width: optionWidth, height: optionHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(theme.displayName)
        .accessibilityLabel(String(localized: "theme.switch \(theme.displayName)"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func triggerRipple() {
        isAnimating = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            isAnimating = false
        }
    }
}

// MARK: - Compact Theme Switcher (for toolbar)

public struct CompactThemeSwitcher: View {
    @Bindable var themeManager = ThemeManager.shared

    @State private var isExpanded = false
    @Namespace private var animation

    public init() {}

    public var body: some View {
        let themeEnv = themeManager.environment
        
        HStack(spacing: 6) {
            // Current theme indicator
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeEnv.glassColor.opacity(0.3),
                                    themeEnv.glassColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(themeEnv.glassReflexLight * 0.15), lineWidth: 0.5)
                        )

                    Image(systemName: themeManager.currentTheme.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(themeManager.currentTheme.actionColor)
                }
            }
            .buttonStyle(.plain)
            .help(String(localized: "theme.help \(themeManager.currentTheme.displayName)"))

            // Expanded options
            if isExpanded {
                HStack(spacing: 4) {
                    ForEach(AppTheme.allCases) { theme in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                themeManager.currentTheme = theme
                                isExpanded = false
                            }
                        } label: {
                            Image(systemName: theme.icon)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(
                                    themeManager.currentTheme == theme
                                        ? theme.actionColor
                                        : themeEnv.tertiaryText
                                )
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(
                                            themeManager.currentTheme == theme
                                                ? theme.actionColor.opacity(0.18)
                                                : Color.clear
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .help(theme.displayName)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeEnv.glassColor.opacity(0.2),
                                    themeEnv.glassColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(themeEnv.glassReflexLight * 0.08), lineWidth: 0.5)
                        )
                )
                .matchedGeometryEffect(id: "expanded", in: animation)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
    }
}

// MARK: - Theme-Aware Background Modifier

public struct ThemeBackground: ViewModifier {
    @Bindable var themeManager = ThemeManager.shared

    public func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: themeManager.environment.backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: themeManager.currentTheme)
            )
    }
}

extension View {
    public func themeBackground() -> some View {
        modifier(ThemeBackground())
    }
}

// MARK: - Preview

#Preview("Theme Switcher") {
    ZStack {
        LinearGradient(
            colors: [.purple.opacity(0.4), .blue.opacity(0.3), .teal.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 40) {
            ThemeSwitcher()
                .padding()

            CompactThemeSwitcher()
                .padding()
        }
    }
    .frame(width: 400, height: 300)
}