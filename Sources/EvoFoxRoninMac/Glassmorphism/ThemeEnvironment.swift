/**
 ThemeEnvironment.swift

 Provides a SwiftUI environment for theme-aware colors and materials.
 All views can read theme values from the environment instead of hardcoding colors.
 */

import SwiftUI

// MARK: - Theme Environment Values

@MainActor
private struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = ThemeEnvironment(theme: .dark)
}

extension EnvironmentValues {
    var theme: ThemeEnvironment {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - Theme Environment

@MainActor
public struct ThemeEnvironment {
    public let theme: AppTheme
    public let backgroundColors: [Color]
    public let contentColor: Color
    public let actionColor: Color
    public let glassColor: Color
    public let glassReflexDark: Double
    public let glassReflexLight: Double
    public let saturation: Double
    
    // Semantic colors
    public let primaryText: Color
    public let secondaryText: Color
    public let tertiaryText: Color
    public let separatorColor: Color
    public let selectionColor: Color
    public let hoverColor: Color
    public let pressedColor: Color
    public let errorColor: Color
    public let warningColor: Color
    public let successColor: Color
    
    // Glass material configuration
    public let sidebarMaterial: ThemedGlassMaterial
    public let cardMaterial: ThemedGlassMaterial
    public let floatingMaterial: ThemedGlassMaterial
    
    public init(theme: AppTheme) {
        self.theme = theme
        
        switch theme {
        case .light:
            self.backgroundColors = [
                Color(hex: "E8E8E9"),
                Color(hex: "F0F0F1")
            ]
            self.contentColor = Color(hex: "222444")
            self.actionColor = Color(hex: "0052f5")
            self.glassColor = Color(hex: "bbbbbc")
            self.glassReflexDark = 1.0
            self.glassReflexLight = 1.0
            self.saturation = 1.5
            
            self.primaryText = Color(hex: "1a1a2e")
            self.secondaryText = Color(hex: "4a4a6a")
            self.tertiaryText = Color(hex: "6a6a8a")
            self.separatorColor = Color(hex: "d0d0e0")
            self.selectionColor = Color(hex: "0052f5").opacity(0.15)
            self.hoverColor = Color.black.opacity(0.04)
            self.pressedColor = Color.black.opacity(0.08)
            self.errorColor = Color(hex: "e03e3e")
            self.warningColor = Color(hex: "d69e2e")
            self.successColor = Color(hex: "38a169")
            
            self.sidebarMaterial = ThemedGlassMaterial(nsMaterial: .sheet, blendingMode: .behindWindow, cornerRadius: 0, isEmphasized: true)
            self.cardMaterial = ThemedGlassMaterial(nsMaterial: .sheet, blendingMode: .behindWindow, cornerRadius: 20, isEmphasized: true)
            self.floatingMaterial = ThemedGlassMaterial(nsMaterial: .hudWindow, blendingMode: .behindWindow, cornerRadius: 12, isEmphasized: true)
            
        case .dark:
            self.backgroundColors = [
                Color(hex: "1b1b1d"),
                Color(hex: "232326")
            ]
            self.contentColor = Color(hex: "e1e1e1")
            self.actionColor = Color(hex: "03d5ff")
            self.glassColor = Color(hex: "bbbbbc")
            self.glassReflexDark = 2.0
            self.glassReflexLight = 0.3
            self.saturation = 1.5
            
            self.primaryText = Color(hex: "f0f0f0")
            self.secondaryText = Color(hex: "b0b0b0")
            self.tertiaryText = Color(hex: "808080")
            self.separatorColor = Color(hex: "3a3a3d")
            self.selectionColor = Color(hex: "03d5ff").opacity(0.15)
            self.hoverColor = Color.white.opacity(0.06)
            self.pressedColor = Color.white.opacity(0.12)
            self.errorColor = Color(hex: "fc8181")
            self.warningColor = Color(hex: "f6e05e")
            self.successColor = Color(hex: "68d391")
            
            self.sidebarMaterial = ThemedGlassMaterial(nsMaterial: .sheet, blendingMode: .behindWindow, cornerRadius: 0, isEmphasized: true)
            self.cardMaterial = ThemedGlassMaterial(nsMaterial: .sheet, blendingMode: .behindWindow, cornerRadius: 20, isEmphasized: true)
            self.floatingMaterial = ThemedGlassMaterial(nsMaterial: .hudWindow, blendingMode: .behindWindow, cornerRadius: 12, isEmphasized: true)
            
        case .dim:
            self.backgroundColors = [
                Color(hex: "1a1a2e"),
                Color(hex: "16213e")
            ]
            self.contentColor = Color(hex: "d5dbe2")
            self.actionColor = Color(hex: "ff48a9")
            self.glassColor = Color(hex: "e8b4d4")
            self.glassReflexDark = 2.0
            self.glassReflexLight = 0.7
            self.saturation = 2.0
            
            self.primaryText = Color(hex: "e8e8f0")
            self.secondaryText = Color(hex: "a8b0c0")
            self.tertiaryText = Color(hex: "788098")
            self.separatorColor = Color(hex: "3a4a6a")
            self.selectionColor = Color(hex: "ff48a9").opacity(0.15)
            self.hoverColor = Color(hex: "ff48a9").opacity(0.08)
            self.pressedColor = Color(hex: "ff48a9").opacity(0.15)
            self.errorColor = Color(hex: "ff6b6b")
            self.warningColor = Color(hex: "ffd93d")
            self.successColor = Color(hex: "6bff9a")
            
            self.sidebarMaterial = ThemedGlassMaterial(nsMaterial: .sheet, blendingMode: .behindWindow, cornerRadius: 0, isEmphasized: true)
            self.cardMaterial = ThemedGlassMaterial(nsMaterial: .sheet, blendingMode: .behindWindow, cornerRadius: 20, isEmphasized: true)
            self.floatingMaterial = ThemedGlassMaterial(nsMaterial: .hudWindow, blendingMode: .behindWindow, cornerRadius: 12, isEmphasized: true)
        }
    }
    
    // Static current for default value
    public static var current: ThemeEnvironment {
        ThemeEnvironment(theme: ThemeManager.shared.currentTheme)
    }
}

// MARK: - Themed Glass Material Wrapper

public struct ThemedGlassMaterial {
    public let nsMaterial: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode
    public let cornerRadius: CGFloat
    public let isEmphasized: Bool
    
    public init(
        nsMaterial: NSVisualEffectView.Material,
        blendingMode: NSVisualEffectView.BlendingMode,
        cornerRadius: CGFloat,
        isEmphasized: Bool = true
    ) {
        self.nsMaterial = nsMaterial
        self.blendingMode = blendingMode
        self.cornerRadius = cornerRadius
        self.isEmphasized = isEmphasized
    }
    
    public static let sidebar = ThemedGlassMaterial(nsMaterial: .sheet, blendingMode: .behindWindow, cornerRadius: 0)
    public static let card = ThemedGlassMaterial(nsMaterial: .sheet, blendingMode: .behindWindow, cornerRadius: 20)
    public static let floating = ThemedGlassMaterial(nsMaterial: .hudWindow, blendingMode: .behindWindow, cornerRadius: 12)
    public static let menu = ThemedGlassMaterial(nsMaterial: .menu, blendingMode: .behindWindow, cornerRadius: 10)
    public static let titlebar = ThemedGlassMaterial(nsMaterial: .titlebar, blendingMode: .behindWindow, cornerRadius: 0)
}

// MARK: - View Extensions for Theme-Aware Styling

extension View {
    /// Apply theme-aware text color
    public func themeText(_ style: ThemeTextStyle = .primary) -> some View {
        self.modifier(ThemeTextModifier(style: style))
    }
    
    /// Apply theme-aware glass background
    public func themeGlassBackground(_ material: GlassMaterialType = .card) -> some View {
        self.modifier(ThemeGlassBackgroundModifier(material: material))
    }
    
    /// Apply theme-aware fill for shapes
    public func themeFill(_ style: ThemeFillStyle = .primary) -> some View {
        self.modifier(ThemeFillModifier(style: style))
    }
    
    /// Apply theme-aware stroke for shapes
    public func themeStroke(_ style: ThemeStrokeStyle = .primary) -> some View {
        self.modifier(ThemeStrokeModifier(style: style))
    }
    
    /// Apply theme-aware shadow
    public func themeShadow(_ style: ThemeShadowStyle = .card) -> some View {
        self.modifier(ThemeShadowModifier(style: style))
    }
    
    /// Apply theme-aware selection background
    public func themeSelected(_ isSelected: Bool) -> some View {
        self.modifier(ThemeSelectionModifier(isSelected: isSelected))
    }
}

// MARK: - Theme Styles

public enum ThemeTextStyle {
    case primary, secondary, tertiary, action, error, warning, success
}

public enum ThemeFillStyle {
    case primary, secondary, tertiary, selection, hover, pressed, glass, action
}

public enum ThemeStrokeStyle {
    case primary, secondary, separator, focus, action
}

public enum ThemeShadowStyle {
    case card, floating, elevated, pressed, none
}

public enum GlassMaterialType {
    case sidebar, card, floating, menu, titlebar
}

// MARK: - Theme Modifiers

private struct ThemeTextModifier: ViewModifier {
    let style: ThemeTextStyle
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        let color: Color
        switch style {
        case .primary: color = theme.primaryText
        case .secondary: color = theme.secondaryText
        case .tertiary: color = theme.tertiaryText
        case .action: color = theme.actionColor
        case .error: color = theme.errorColor
        case .warning: color = theme.warningColor
        case .success: color = theme.successColor
        }
        return content.foregroundStyle(color)
    }
}

private struct ThemeFillModifier: ViewModifier {
    let style: ThemeFillStyle
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        let fill: AnyShapeStyle
        switch style {
        case .primary:
            fill = AnyShapeStyle(theme.contentColor)
        case .secondary:
            fill = AnyShapeStyle(theme.contentColor.opacity(0.7))
        case .tertiary:
            fill = AnyShapeStyle(theme.contentColor.opacity(0.4))
        case .selection:
            fill = AnyShapeStyle(theme.selectionColor)
        case .hover:
            fill = AnyShapeStyle(theme.hoverColor)
        case .pressed:
            fill = AnyShapeStyle(theme.pressedColor)
        case .glass:
            fill = AnyShapeStyle(theme.glassColor.opacity(0.2))
        case .action:
            fill = AnyShapeStyle(
                LinearGradient(
                    colors: [theme.actionColor, theme.actionColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        return content.background(
            Rectangle()
                .fill(fill)
        )
    }
}

private struct ThemeStrokeModifier: ViewModifier {
    let style: ThemeStrokeStyle
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        let stroke: AnyShapeStyle
        let width: CGFloat
        switch style {
        case .primary:
            stroke = AnyShapeStyle(theme.separatorColor)
            width = 0.5
        case .secondary:
            stroke = AnyShapeStyle(theme.separatorColor.opacity(0.5))
            width = 0.5
        case .separator:
            stroke = AnyShapeStyle(theme.separatorColor)
            width = 1
        case .focus:
            stroke = AnyShapeStyle(theme.actionColor)
            width = 2
        case .action:
            stroke = AnyShapeStyle(theme.actionColor)
            width = 1
        }
        return content.overlay(
            Rectangle()
                .stroke(stroke, lineWidth: width)
        )
    }
}

private struct ThemeShadowModifier: ViewModifier {
    let style: ThemeShadowStyle
    @Environment(\.theme) var theme
    
    @ViewBuilder
    func body(content: Content) -> some View {
        switch style {
        case .card:
            content.shadow(
                color: Color.black.opacity(theme.glassReflexDark * 0.1),
                radius: 16, x: 0, y: 8
            )
        case .floating:
            content.shadow(
                color: Color.black.opacity(theme.glassReflexDark * 0.15),
                radius: 24, x: 0, y: 12
            )
        case .elevated:
            content.shadow(
                color: Color.black.opacity(theme.glassReflexDark * 0.2),
                radius: 32, x: 0, y: 16
            )
        case .pressed:
            content.shadow(
                color: Color.black.opacity(theme.glassReflexDark * 0.05),
                radius: 4, x: 0, y: 2
            )
        case .none:
            content
        }
    }
}

private struct ThemeSelectionModifier: ViewModifier {
    let isSelected: Bool
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        content.background(
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(theme.selectionColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(theme.actionColor.opacity(0.3), lineWidth: 0.5)
                        )
                }
            }
        )
    }
}

private struct ThemeGlassBackgroundModifier: ViewModifier {
    let material: GlassMaterialType
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        let glassMaterial: ThemedGlassMaterial
        switch material {
        case .sidebar: glassMaterial = theme.sidebarMaterial
        case .card: glassMaterial = theme.cardMaterial
        case .floating: glassMaterial = theme.floatingMaterial
        case .menu: glassMaterial = theme.cardMaterial // Use card for menus
        case .titlebar: glassMaterial = theme.sidebarMaterial
        }
        
        // Convert ThemedGlassMaterial to GlassMaterial enum
        let glassMaterialEnum = glassMaterial.toGlassMaterial()
        
        return content.background(
            GlassView(
                material: glassMaterialEnum,
                blendingMode: .behindWindow,
                cornerRadius: glassMaterial.cornerRadius,
                isEmphasized: glassMaterial.isEmphasized
            )
        )
    }
}

// Helper extension to convert ThemedGlassMaterial to GlassMaterial enum
extension ThemedGlassMaterial {
    func toGlassMaterial() -> GlassMaterial {
        switch nsMaterial {
        case .sheet: return .sheet
        case .hudWindow: return .hudWindow
        case .menu: return .menu
        case .titlebar: return .titlebar
        case .contentBackground: return .contentBackground
        case .underWindowBackground: return .underWindowBackground
        default: return .sheet
        }
    }
    
    var glassMaterial: GlassMaterial {
        toGlassMaterial()
    }
}

// MARK: - Theme-Aware Glass View

public struct ThemedGlassView: View {
    public let material: GlassMaterialType
    public let cornerRadius: CGFloat
    public let padding: CGFloat
    public let content: () -> AnyView
    
    @Environment(\.theme) var theme
    
    public init(
        material: GlassMaterialType = .card,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 24,
        @ViewBuilder content: @escaping () -> some View
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = { AnyView(content()) }
    }
    
    public var body: some View {
        content()
            .padding(padding)
            .background(
                ZStack {
                    GlassView(
                        material: themeMaterial.glassMaterial,
                        blendingMode: .behindWindow,
                        cornerRadius: cornerRadius,
                        isEmphasized: themeMaterial.isEmphasized
                    )
                    
                    // Inner highlight
                    VStack {
                        Rectangle()
                            .fill(Color.white.opacity(theme.glassReflexLight * 0.06))
                            .frame(height: 1)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .allowsHitTesting(false)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(theme.glassReflexLight * 0.08), lineWidth: 0.5)
            )
            .themeShadow(material == .card ? .card : .floating)
    }
    
    private var themeMaterial: ThemedGlassMaterial {
        switch material {
        case .sidebar: return theme.sidebarMaterial
        case .card: return theme.cardMaterial
        case .floating: return theme.floatingMaterial
        case .menu: return theme.cardMaterial
        case .titlebar: return theme.sidebarMaterial
        }
    }
}

// MARK: - Theme-Aware Background

public struct ThemedBackground: ViewModifier {
    @Environment(\.theme) var theme
    
    public func body(content: Content) -> some View {
        content.background(
            LinearGradient(
                colors: theme.backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: theme.theme)
        )
    }
}

extension View {
    public func themedBackground() -> some View {
        modifier(ThemedBackground())
    }
}

// MARK: - Theme-Aware Button Style

public struct ThemedButtonStyle: ButtonStyle {
    public var isProminent: Bool
    public var tint: Color?
    
    public init(isProminent: Bool = false, tint: Color? = nil) {
        self.isProminent = isProminent
        self.tint = tint
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        ThemedButtonStyleBody(
            configuration: configuration,
            isProminent: isProminent,
            tint: tint
        )
    }
}

private struct ThemedButtonStyleBody: View {
    let configuration: ButtonStyleConfiguration
    let isProminent: Bool
    let tint: Color?
    
    @Environment(\.theme) var theme
    @State private var isHovered = false
    
    private var effectiveTint: Color {
        tint ?? theme.actionColor
    }
    
    var body: some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .foregroundStyle(
                isProminent ? Color.white : effectiveTint
            )
            .background(
                ZStack {
                    if isProminent {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(effectiveTint.opacity(configuration.isPressed ? 0.9 : 1.0))
                            .shadow(
                                color: effectiveTint.opacity(0.3),
                                radius: configuration.isPressed ? 4 : 12,
                                x: 0, y: configuration.isPressed ? 2 : 6
                            )
                    } else {
                        GlassView(
                            material: .hudWindow,
                            blendingMode: .behindWindow,
                            cornerRadius: 12,
                            isEmphasized: true
                        )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isProminent ? Color.clear : Color.white.opacity(isHovered ? 0.15 : 0.08),
                        lineWidth: 0.5
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Preview

#Preview("Theme Environment") {
    ZStack {
        Color.clear
            .themedBackground()
        
        VStack(spacing: 30) {
            Text("Theme Environment Preview")
                .themeText(.primary)
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            HStack(spacing: 20) {
                ThemedGlassView(material: .card) {
                    VStack(spacing: 12) {
                        Text("Themed Card")
                            .themeText(.primary)
                            .font(.headline)
                        Text("Uses theme-aware glass material")
                            .themeText(.secondary)
                            .font(.caption)
                        Button("Action") {}
                            .buttonStyle(ThemedButtonStyle(isProminent: true))
                    }
                }
                .frame(width: 200)
                
                ThemedGlassView(material: .floating) {
                    VStack(spacing: 12) {
                        Text("Floating Card")
                            .themeText(.primary)
                            .font(.headline)
                        Text("Higher elevation material")
                            .themeText(.secondary)
                            .font(.caption)
                        Button("Secondary") {}
                            .buttonStyle(ThemedButtonStyle(isProminent: false))
                    }
                }
                .frame(width: 200)
            }
        }
        .padding(40)
    }
    .frame(width: 600, height: 400)
    .environment(ThemeManager.shared)
}