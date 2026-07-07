/**
 Physics.swift

 Defines the proper spring physics for all animations in the EvoFox Ronin app.

 Apple's glassmorphism isn't just visual — it's physical. The interface must feel
 like real glass: weighty, responsive, and fluid. These constants are tuned to
 match the physics of macOS native spring animations.

 Reference:
 - NSSpringAnimation (AppKit)
 - CASpringAnimation (Core Animation)
 - SwiftUI .spring() modifier
 - WWDC 2025: "Build a SwiftUI app with the new design"

 Golden Rules:
 1. Never use linear animations for UI transitions
 2. Use lower stiffness for large movements, higher for small interactions
 3. Damping ratio should be ~0.7-0.9 for natural feel (underdamped, no oscillation)
 4. Mass should always be 1.0 for UI elements (they're not physical objects)
 5. Glass morphing should feel "liquid" — slightly bouncy but controlled
 */

import Foundation
import SwiftUI

// MARK: - Spring Physics Constants

public struct Physics {

    // MARK: Navigation Layer (sidebar, panel transitions)
    /// Used for: sidebar opening/closing, main panel switching, window transitions
    /// Feel: Smooth, deliberate, professional
    public static let navigation = Spring(
        response: 0.45,
        dampingRatio: 0.82
    )

    // MARK: Interactive Feedback (buttons, toggles, sliders)
    /// Used for: button press, toggle switch, slider drag, hover states
    /// Feel: Snappy, immediate, tactile
    public static let interactive = Spring(
        response: 0.25,
        dampingRatio: 0.72
    )

    // MARK: Glass Morphing (glass panels expanding, contracting, blending)
    /// Used for: glass card expansion, floating panel morphing, toolbar item transitions
    /// Feel: Liquid, slightly bouncy, delightful
    public static let morph = Spring(
        response: 0.55,
        dampingRatio: 0.68
    )

    // MARK: Content Appearance (lists, cards, grids entering)
    /// Used for: list item appearance, card entrance, grid layout changes
    /// Feel: Light, airy, cascading
    public static let content = Spring(
        response: 0.55,
        dampingRatio: 0.75
    )

    // MARK: Staggered Cascade (keyboard keys lighting up, multiple items)
    /// Used for: keyboard key highlight sequence, profile switch preview
    /// Feel: Wave-like, rhythmic
    public static let cascadeDelay: TimeInterval = 0.025

    // MARK: Scale Physics (button press down/up, glass element focus)
    /// Used for: button press scale, glass element focus zoom
    /// Feel: Soft, cushioned, organic
    public static let pressScale: CGFloat = 0.96
    public static let focusScale: CGFloat = 1.02

    // MARK: Opacity Physics (fade in/out of glass elements)
    /// Used for: glass panel fade, tooltip appearance, notification banner
    public static let opacityDuration: TimeInterval = 0.3

    // MARK: Rotation Physics (knob controls, dial interfaces)
    /// Used for: volume knob visual rotation, effect dial
    public static let rotationSpring = Spring(
        response: 0.35,
        dampingRatio: 0.80
    )

    // MARK: - Custom Spring Extension
    /// Creates a spring with specified response time and damping ratio.
    /// Response: how fast the spring reaches equilibrium (seconds)
    /// Damping ratio: 0 = perpetual oscillation, 1 = critically damped, >1 = overdamped
    public static func customSpring(response: Double, dampingRatio: Double) -> Spring {
        return Spring(response: response, dampingRatio: dampingRatio)
    }
}

// MARK: - View Modifiers for Physics

extension View {
    /// Applies the navigation spring animation to any view
    public func navigationAnimation<Value: Equatable>(value: Value) -> some View {
        self.animation(.spring(Physics.navigation), value: value)
    }

    /// Applies the interactive spring animation to any view
    public func interactiveAnimation<Value: Equatable>(value: Value) -> some View {
        self.animation(.spring(Physics.interactive), value: value)
    }

    /// Applies the morph spring animation to any view
    public func morphAnimation<Value: Equatable>(value: Value) -> some View {
        self.animation(.spring(Physics.morph), value: value)
    }

    /// Applies the content spring animation to any view
    public func contentAnimation<Value: Equatable>(value: Value) -> some View {
        self.animation(.spring(Physics.content), value: value)
    }

    /// Adds a press-down physics effect (scale + opacity)
    public func pressEffect(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? Physics.pressScale : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(.spring(Physics.interactive), value: isPressed)
    }

    /// Adds a glass focus effect (subtle scale + glow)
    public func glassFocus(isFocused: Bool) -> some View {
        self
            .scaleEffect(isFocused ? Physics.focusScale : 1.0)
            .animation(.spring(Physics.morph), value: isFocused)
    }
}

// MARK: - Matched Geometry for Liquid Transitions

/// Namespace for glass morphing transitions between views
public struct GlassNamespace {
    public static let sidebar = "sidebar"
    public static let panel = "panel"
    public static let control = "control"
    public static let keyboard = "keyboard"
}
