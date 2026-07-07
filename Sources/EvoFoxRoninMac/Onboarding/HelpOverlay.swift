/**
 HelpOverlay.swift

 Contextual help view modifier for adding tooltips and optional
 highlight borders to any view.
 */

import SwiftUI

public struct HelpOverlay: ViewModifier {
    let tooltip: String
    let showHighlight: Bool

    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    if showHighlight {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: 2)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            )
            .help(tooltip)
    }
}

public extension View {
    /// Adds a contextual help tooltip with optional highlight border.
    func helpOverlay(_ tooltip: String, showHighlight: Bool = false) -> some View {
        modifier(HelpOverlay(tooltip: tooltip, showHighlight: showHighlight))
    }
}
