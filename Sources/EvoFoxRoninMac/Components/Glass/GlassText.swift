import SwiftUI

/// Semantic text style categories for theme-aware text rendering.
public enum GlassTextStyle {
    case primary, secondary, tertiary, action, error, warning, success
}

extension View {
    /// Applies a theme-aware foreground color based on semantic style.
    public func glassText(_ style: GlassTextStyle = .primary) -> some View {
        self.modifier(GlassTextModifier(style: style))
    }
}

private struct GlassTextModifier: ViewModifier {
    let style: GlassTextStyle
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

#if DEBUG
#Preview("Glass Text") {
    VStack(spacing: 12) {
        Text("Primary").glassText(.primary)
        Text("Secondary").glassText(.secondary)
        Text("Tertiary").glassText(.tertiary)
        Text("Action").glassText(.action)
        Text("Error").glassText(.error)
        Text("Warning").glassText(.warning)
        Text("Success").glassText(.success)
    }
    .padding(40)
    .background(Color.black)
}
#endif
