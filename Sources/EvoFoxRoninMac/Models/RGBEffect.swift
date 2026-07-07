/**
 RGBEffect.swift

 Defines all 21 built-in RGB lighting effects for the EvoFox Ronin keyboard,
 plus custom per-key lighting modes. These map to the keyboard's on-board
 effect memory.

 The EvoFox Ronin supports:
 - 21 pre-programmed dynamic effects (wave, breathing, ripple, etc.)
 - Per-key static color
 - Audio-reactive sync mode
 - Custom color palettes

 Each effect has:
 - effectId: The HID packet ID sent to the keyboard
 - name: Human-readable display name
 - category: Static, Dynamic, Reactive, or Audio
 - defaultSpeed: Animation speed (0-255)
 - defaultBrightness: Brightness level (0-255)
 - defaultColor: Primary color (RGB)
 - supportsDirection: Whether direction can be changed
 - supportsColorChange: Whether user can customize colors
 */

import SwiftUI

public struct RGBEffect: Identifiable, Codable, Equatable, Hashable {
    public let id: String
    public let effectId: UInt8
    public let name: String
    public let category: EffectCategory
    public let defaultSpeed: UInt8
    public let defaultBrightness: UInt8
    public let defaultColor: RGBColor
    public let supportsDirection: Bool
    public let supportsColorChange: Bool
    public let description: String

    public enum EffectCategory: String, Codable, CaseIterable {
        case staticColor = "Static"
        case dynamic = "Dynamic"
        case reactive = "Reactive"
        case audio = "Audio"
        case custom = "Custom"
    }

    public enum Direction: UInt8, Codable, CaseIterable {
        case left = 0
        case right = 1
        case up = 2
        case down = 3
        case inward = 4
        case outward = 5
    }
}

public struct RGBColor: Codable, Equatable, Hashable {
    public var r: UInt8
    public var g: UInt8
    public var b: UInt8

    public init(r: UInt8, g: UInt8, b: UInt8) {
        self.r = r
        self.g = g
        self.b = b
    }

    public var swiftUIColor: Color {
        Color(red: Double(r) / 255.0, green: Double(g) / 255.0, blue: Double(b) / 255.0)
    }

    public static let red = RGBColor(r: 255, g: 0, b: 0)
    public static let green = RGBColor(r: 0, g: 255, b: 0)
    public static let blue = RGBColor(r: 0, g: 0, b: 255)
    public static let white = RGBColor(r: 255, g: 255, b: 255)
    public static let off = RGBColor(r: 0, g: 0, b: 0)
    public static let purple = RGBColor(r: 128, g: 0, b: 128)
    public static let cyan = RGBColor(r: 0, g: 255, b: 255)
    public static let magenta = RGBColor(r: 255, g: 0, b: 255)
    public static let yellow = RGBColor(r: 255, g: 255, b: 0)
    public static let orange = RGBColor(r: 255, g: 165, b: 0)
    public static let pink = RGBColor(r: 255, g: 192, b: 203)
}

public struct RGBSettings: Codable, Equatable {
    public var effect: RGBEffect
    public var speed: UInt8
    public var brightness: UInt8
    public var primaryColor: RGBColor
    public var secondaryColor: RGBColor
    public var direction: RGBEffect.Direction
    public var isEnabled: Bool

    public init(
        effect: RGBEffect = RGBEffectLibrary.effects[0],
        speed: UInt8 = 128,
        brightness: UInt8 = 255,
        primaryColor: RGBColor = .white,
        secondaryColor: RGBColor = .blue,
        direction: RGBEffect.Direction = .right,
        isEnabled: Bool = true
    ) {
        self.effect = effect
        self.speed = speed
        self.brightness = brightness
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.direction = direction
        self.isEnabled = isEnabled
    }
}

// MARK: - Built-in Effect Library

public enum RGBEffectLibrary {
    public static let effects: [RGBEffect] = [
        RGBEffect(id: "static", effectId: 0x00, name: "Static Color", category: .staticColor, defaultSpeed: 0, defaultBrightness: 255, defaultColor: .white, supportsDirection: false, supportsColorChange: true, description: "Solid color across all keys"),
        RGBEffect(id: "breathing", effectId: 0x01, name: "Breathing", category: .dynamic, defaultSpeed: 128, defaultBrightness: 255, defaultColor: .blue, supportsDirection: false, supportsColorChange: true, description: "Gentle fade in and out"),
        RGBEffect(id: "wave", effectId: 0x02, name: "Color Wave", category: .dynamic, defaultSpeed: 150, defaultBrightness: 255, defaultColor: .blue, supportsDirection: true, supportsColorChange: true, description: "Rainbow wave flowing across keys"),
        RGBEffect(id: "ripple", effectId: 0x03, name: "Ripple", category: .reactive, defaultSpeed: 200, defaultBrightness: 255, defaultColor: .blue, supportsDirection: false, supportsColorChange: true, description: "Ripples from pressed keys"),
        RGBEffect(id: "raindrop", effectId: 0x04, name: "Raindrop", category: .dynamic, defaultSpeed: 100, defaultBrightness: 255, defaultColor: .green, supportsDirection: false, supportsColorChange: true, description: "Random drops like rain"),
        RGBEffect(id: "snake", effectId: 0x05, name: "Snake", category: .dynamic, defaultSpeed: 180, defaultBrightness: 255, defaultColor: .green, supportsDirection: true, supportsColorChange: true, description: "Snake-like trail moving across keys"),
        RGBEffect(id: "reactive", effectId: 0x06, name: "Reactive", category: .reactive, defaultSpeed: 0, defaultBrightness: 255, defaultColor: .red, supportsDirection: false, supportsColorChange: true, description: "Keys light up on press and fade"),
        RGBEffect(id: "aurora", effectId: 0x07, name: "Aurora", category: .dynamic, defaultSpeed: 120, defaultBrightness: 255, defaultColor: .green, supportsDirection: true, supportsColorChange: true, description: "Northern lights flowing effect"),
        RGBEffect(id: "starlight", effectId: 0x08, name: "Starlight", category: .dynamic, defaultSpeed: 80, defaultBrightness: 255, defaultColor: .white, supportsDirection: false, supportsColorChange: true, description: "Stars twinkling across keyboard"),
        RGBEffect(id: "reactive ripple", effectId: 0x09, name: "Reactive Ripple", category: .reactive, defaultSpeed: 150, defaultBrightness: 255, defaultColor: .blue, supportsDirection: false, supportsColorChange: true, description: "Ripple from pressed key with color fade"),
        RGBEffect(id: "rainbow", effectId: 0x0A, name: "Rainbow", category: .dynamic, defaultSpeed: 140, defaultBrightness: 255, defaultColor: .white, supportsDirection: true, supportsColorChange: false, description: "Full spectrum rainbow cycle"),
        RGBEffect(id: "circle", effectId: 0x0B, name: "Circle", category: .dynamic, defaultSpeed: 160, defaultBrightness: 255, defaultColor: .purple, supportsDirection: true, supportsColorChange: true, description: "Circles expanding from center"),
        RGBEffect(id: "cross", effectId: 0x0C, name: "Cross", category: .dynamic, defaultSpeed: 130, defaultBrightness: 255, defaultColor: .red, supportsDirection: true, supportsColorChange: true, description: "Cross pattern sweeping across"),
        RGBEffect(id: "single on", effectId: 0x0D, name: "Single On", category: .reactive, defaultSpeed: 0, defaultBrightness: 255, defaultColor: .white, supportsDirection: false, supportsColorChange: true, description: "Only pressed key lights up"),
        RGBEffect(id: "single off", effectId: 0x0E, name: "Single Off", category: .reactive, defaultSpeed: 0, defaultBrightness: 255, defaultColor: .white, supportsDirection: false, supportsColorChange: true, description: "Pressed key turns off, others stay lit"),
        RGBEffect(id: "fire", effectId: 0x0F, name: "Fire", category: .dynamic, defaultSpeed: 110, defaultBrightness: 255, defaultColor: .red, supportsDirection: false, supportsColorChange: false, description: "Flame-like flickering effect"),
        RGBEffect(id: "scanner", effectId: 0x10, name: "Scanner", category: .dynamic, defaultSpeed: 170, defaultBrightness: 255, defaultColor: .green, supportsDirection: true, supportsColorChange: true, description: "Scanner bar moving across keys"),
        RGBEffect(id: "reactive aurora", effectId: 0x11, name: "Reactive Aurora", category: .reactive, defaultSpeed: 100, defaultBrightness: 255, defaultColor: .green, supportsDirection: false, supportsColorChange: true, description: "Aurora triggered by key presses"),
        RGBEffect(id: "custom", effectId: 0x12, name: "Custom Per-Key", category: .custom, defaultSpeed: 0, defaultBrightness: 255, defaultColor: .white, supportsDirection: false, supportsColorChange: true, description: "User-defined per-key colors"),
        RGBEffect(id: "audio", effectId: 0x13, name: "Audio Sync", category: .audio, defaultSpeed: 0, defaultBrightness: 255, defaultColor: .blue, supportsDirection: false, supportsColorChange: true, description: "Reacts to system audio")
    ]
}
