import SwiftUI

/// A view modifier that applies a themed gradient background.
public struct GlassBackground: ViewModifier {
    @Environment(\.theme) var theme

    public init() {}

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
    /// Applies a theme-aware gradient background.
    public func glassBackground() -> some View {
        modifier(GlassBackground())
    }
}

/// Maps GlassMaterialType to the corresponding ThemedGlassMaterial.
extension GlassMaterialType {
    func toThemedMaterial() -> ThemedGlassMaterial {
        switch self {
        case .sidebar: return .sidebar
        case .card: return .card
        case .floating: return .floating
        case .menu: return .menu
        case .titlebar: return .titlebar
        }
    }
}

extension View {
    /// Applies a theme-aware glass material background.
    public func glassBackground(_ material: GlassMaterialType = .card) -> some View {
        self.modifier(GlassBackgroundMaterialModifier(material: material))
    }
}

private struct GlassBackgroundMaterialModifier: ViewModifier {
    let material: GlassMaterialType
    @Environment(\.theme) var theme

    func body(content: Content) -> some View {
        let glassMaterial = material.toThemedMaterial()
        content.background(
            GlassView(
                material: glassMaterial.glassMaterial,
                blendingMode: .behindWindow,
                cornerRadius: glassMaterial.cornerRadius,
                isEmphasized: glassMaterial.isEmphasized
            )
        )
    }
}

#if DEBUG
#Preview("Glass Background") {
    Text("Glass Background")
        .glassBackground(.card)
        .padding(40)
}
#endif
