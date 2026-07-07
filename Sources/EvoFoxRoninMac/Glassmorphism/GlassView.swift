/**
 GlassView.swift

 Core glassmorphism component using native NSVisualEffectView.

 This is NOT a CSS blur hack. It uses macOS's actual window server compositing
 to achieve real glass material that samples the desktop wallpaper, windows behind,
 and app content with proper light refraction.

 Implementation Notes:
 - Uses NSVisualEffectView.Material.sheet for primary glass surfaces
 - Uses NSVisualEffectView.Material.hudWindow for floating controls
 - blendingMode = .behindWindow allows the glass to see through the window
 - state = .active ensures the effect is always rendered
 - Never nest glass inside glass (Apple's #1 rule)
 - Glass belongs on the NAVIGATION layer, not the content layer

 macOS Version Compatibility:
 - macOS 13+: Uses .sheet, .hudWindow, .menu materials
 - macOS 14+: Additional materials available
 - macOS 15+ (Tahoe): Liquid Glass materials automatically available
 */

import SwiftUI
import AppKit

// MARK: - Glass Material Types

public enum GlassMaterial {
    /// Primary glass for main panels, sidebars. Moderate blur, good legibility.
    case sheet

    /// Floating glass for controls, badges, floating buttons. Higher blur.
    case hudWindow

    /// Menu glass for dropdowns, popovers. Light blur with subtle tint.
    case menu

    /// Titlebar glass for window chrome. Matches system titlebar.
    case titlebar

    /// Content background glass. Subtle, for content cards on vibrant backgrounds.
    case contentBackground

    /// Under-window glass for the window background itself.
    case underWindowBackground

    var nsMaterial: NSVisualEffectView.Material {
        switch self {
        case .sheet: return .sheet
        case .hudWindow: return .hudWindow
        case .menu: return .menu
        case .titlebar: return .titlebar
        case .contentBackground: return .contentBackground
        case .underWindowBackground: return .underWindowBackground
        }
    }
}

public enum GlassBlendingMode {
    /// Glass samples content behind the window (sees desktop/wallpaper)
    case behindWindow

    /// Glass samples content within the window (sees sibling views)
    case withinWindow

    var nsBlendingMode: NSVisualEffectView.BlendingMode {
        switch self {
        case .behindWindow: return .behindWindow
        case .withinWindow: return .withinWindow
        }
    }
}

// MARK: - NSVisualEffectView Representable

/// Wraps NSVisualEffectView for use in SwiftUI
public struct GlassView: NSViewRepresentable {
    public var material: GlassMaterial
    public var blendingMode: GlassBlendingMode
    public var state: NSVisualEffectView.State
    public var cornerRadius: CGFloat
    public var isEmphasized: Bool

    public init(
        material: GlassMaterial = .sheet,
        blendingMode: GlassBlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active,
        cornerRadius: CGFloat = 16,
        isEmphasized: Bool = true
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
        self.cornerRadius = cornerRadius
        self.isEmphasized = isEmphasized
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material.nsMaterial
        view.blendingMode = blendingMode.nsBlendingMode
        view.state = state
        view.isEmphasized = isEmphasized
        view.wantsLayer = true
        view.layer?.cornerRadius = cornerRadius
        view.layer?.masksToBounds = true

        // Add subtle border for depth definition (Apple's approach on dark backgrounds)
        view.layer?.borderWidth = 0.5
        view.layer?.borderColor = NSColor.white.withAlphaComponent(0.08).cgColor

        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material.nsMaterial
        nsView.blendingMode = blendingMode.nsBlendingMode
        nsView.state = state
        nsView.isEmphasized = isEmphasized
        nsView.layer?.cornerRadius = cornerRadius
    }
}

// MARK: - Glass Container (Multiple Elements)

/// Groups multiple glass elements so they share a sampling region.
/// Per Apple's WWDC 2025 guidance: "glass cannot sample other glass" —
/// elements within a container share their sampling region for consistent
/// appearance and enable fluid morphing transitions.
public struct GlassContainer<Content: View>: View {
    public var spacing: CGFloat
    public var material: GlassMaterial
    public var cornerRadius: CGFloat
    public var content: Content

    public init(
        spacing: CGFloat = 20,
        material: GlassMaterial = .sheet,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.material = material
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .padding(spacing)
            .background(
                GlassView(
                    material: material,
                    blendingMode: .behindWindow,
                    cornerRadius: cornerRadius
                )
            )
    }
}

// MARK: - Glass Card

/// A pre-styled glass card with proper padding, corner radius, and shadow.
/// Use this for content panels that float above the main background.
public struct GlassCard<Content: View>: View {
    public var material: GlassMaterial
    public var cornerRadius: CGFloat
    public var padding: CGFloat
    public var content: Content

    @State private var isHovered = false

    public init(
        material: GlassMaterial = .sheet,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 24,
        @ViewBuilder content: () -> Content
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Primary glass layer
                    GlassView(
                        material: material,
                        blendingMode: .behindWindow,
                        cornerRadius: cornerRadius
                    )

                    // Subtle inner glow for depth (top edge light reflection)
                    VStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 1)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .allowsHitTesting(false)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
            .shadow(
                color: Color.black.opacity(0.15),
                radius: isHovered ? 24 : 16,
                x: 0,
                y: isHovered ? 12 : 8
            )
            .glassFocus(isFocused: isHovered)
            .onHover { hovering in
                withAnimation(.spring(Physics.morph)) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Glass Sidebar

/// A sidebar panel with glass material — used for navigation.
/// Positioned on the left, with proper glass material and vibrant text.
public struct GlassSidebar<Content: View>: View {
    public var width: CGFloat
    public var content: Content

    public init(width: CGFloat = 220, @ViewBuilder content: () -> Content) {
        self.width = width
        self.content = content()
    }

    public var body: some View {
        content
            .frame(width: width)
            .background(
                GlassView(
                    material: .sheet,
                    blendingMode: .behindWindow,
                    cornerRadius: 0
                )
            )
    }
}

// MARK: - Glass Button Style

/// A button style that renders a glass pill/capsule button.
/// Uses the proper `.glassProminent` equivalent with native visual effects.
public struct GlassButtonStyle: ButtonStyle {
    public var isProminent: Bool
    public var tint: Color
    public var cornerRadius: CGFloat

    public init(
        isProminent: Bool = false,
        tint: Color = .accentColor,
        cornerRadius: CGFloat = 12
    ) {
        self.isProminent = isProminent
        self.tint = tint
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if isProminent {
                        // Prominent: filled with subtle glass tint
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(0.25))
                            .background(
                                GlassView(
                                    material: .hudWindow,
                                    blendingMode: .behindWindow,
                                    cornerRadius: cornerRadius
                                )
                            )
                    } else {
                        // Standard: pure glass
                        GlassView(
                            material: .hudWindow,
                            blendingMode: .behindWindow,
                            cornerRadius: cornerRadius
                        )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .pressEffect(isPressed: configuration.isPressed)
            .contentAnimation(value: configuration.isPressed)
    }
}

// MARK: - Vibrant Text Modifier

/// Ensures text remains legible on glass backgrounds by using
/// the system vibrant foreground style. This is critical for
/// accessibility on dynamic backgrounds.
public struct VibrantText: ViewModifier {
    public var isSecondary: Bool

    public init(isSecondary: Bool = false) {
        self.isSecondary = isSecondary
    }

    public func body(content: Content) -> some View {
        if isSecondary {
            content
                .foregroundStyle(.secondary)
        } else {
            content
                .foregroundStyle(.primary)
        }
    }
}

extension View {
    public func vibrantText(isSecondary: Bool = false) -> some View {
        self.modifier(VibrantText(isSecondary: isSecondary))
    }
}

// MARK: - Preview

#if DEBUG
struct GlassmorphismPreview: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Background gradient (simulating a colorful desktop)
            LinearGradient(
                colors: [.purple.opacity(0.4), .blue.opacity(0.3), .teal.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            HStack(spacing: 0) {
                // Glass sidebar
                GlassSidebar(width: 200) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("EvoFox Ronin")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .vibrantText()
                            .padding(.top, 24)
                            .padding(.horizontal, 16)

                        ForEach(["RGB Lighting", "Key Remap", "Macros", "Profiles"], id: \.self) { item in
                            Button(item) {
                                selectedTab = ["RGB Lighting", "Key Remap", "Macros", "Profiles"].firstIndex(of: item) ?? 0
                            }
                            .buttonStyle(GlassButtonStyle(isProminent: selectedTab == ["RGB Lighting", "Key Remap", "Macros", "Profiles"].firstIndex(of: item)))
                            .padding(.horizontal, 12)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                // Main content area with glass cards
                ScrollView {
                    VStack(spacing: 24) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Connection Status")
                                    .font(.headline)
                                    .vibrantText()

                                HStack {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                    Text("EvoFox Ronin TKL Connected")
                                        .vibrantText(isSecondary: true)
                                    Spacer()
                                }
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("RGB Effects")
                                    .font(.headline)
                                    .vibrantText()

                                HStack(spacing: 12) {
                                    ForEach(0..<5) { i in
                                        Button("Effect \(i + 1)") {}
                                            .buttonStyle(GlassButtonStyle())
                                    }
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(32)
                }
            }
        }
        .frame(width: 900, height: 600)
    }
}

#Preview {
    GlassmorphismPreview()
}
#endif

// MARK: - Liquid Glass Background

/// The animated mesh gradient background that glass samples from.
public struct LiquidGlassBackground: View {
    public init() {}

    public var body: some View {
        LinearGradient(
            colors: [.purple.opacity(0.4), .blue.opacity(0.3), .teal.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
