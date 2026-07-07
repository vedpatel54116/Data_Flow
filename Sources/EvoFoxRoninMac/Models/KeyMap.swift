/**
 KeyMap.swift

 Defines the 79-key layout of the EvoFox Ronin TKL keyboard and the
 key remapping data model. Each key can be remapped to any other standard
 key code, mouse button, media control, or macro.

 Layout: 79-key Tenkeyless (TKL)
 - 6 rows total (including function row)
 - Standard 75% layout with compressed nav cluster
 - Dedicated volume knob (not a key, separate HID control)
 - Function row with media controls

 Keys are identified by their position (row, col) for the visual layout
 and by scan code for HID communication.
 */

import Foundation

public struct KeyPosition: Codable, Hashable, Equatable, Sendable {
    public let row: Int
    public let col: Int

    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }
}

public struct KeyInfo: Identifiable, Codable, Hashable, Sendable {
    public let id = UUID()
    public let position: KeyPosition
    public let scanCode: UInt8
    public let defaultLabel: String
    public let defaultKeyCode: UInt16
    public var size: KeySize

    public enum KeySize: String, Codable, CaseIterable, Sendable {
        case standard = "1u"
        case wide = "1.25u"
        case wider = "1.5u"
        case widest = "1.75u"
        case space = "2u"
        case spaceLarge = "2.25u"
        case spaceXL = "2.75u"
        case spaceFull = "6.25u"
        case enter = "enter"
        case shift = "shift"
        case ctrl = "ctrl"
        case fn = "fn"
    }

    public init(position: KeyPosition, scanCode: UInt8, defaultLabel: String, defaultKeyCode: UInt16, size: KeySize = .standard) {
        self.position = position
        self.scanCode = scanCode
        self.defaultLabel = defaultLabel
        self.defaultKeyCode = defaultKeyCode
        self.size = size
    }
}

public struct KeyMapping: Codable, Equatable, Identifiable, Sendable {
    public let id = UUID()
    public let keyPosition: KeyPosition
    public let keyScanCode: UInt8
    public var assignedAction: KeyAction

    public init(keyPosition: KeyPosition, keyScanCode: UInt8, assignedAction: KeyAction) {
        self.keyPosition = keyPosition
        self.keyScanCode = keyScanCode
        self.assignedAction = assignedAction
    }
}

public enum KeyAction: Codable, Equatable, Hashable, Sendable {
    case standardKey(keyCode: UInt16)
    case modifierKey(modifiers: [ModifierKey])
    case mediaKey(media: MediaKey)
    case mouseButton(button: MouseButton)
    case macro(macroId: UUID)
    case layerSwitch(layer: UInt8)
    case disabled

    public enum ModifierKey: String, Codable, CaseIterable, Sendable {
        case leftShift = "LShift"
        case rightShift = "RShift"
        case leftCtrl = "LCtrl"
        case rightCtrl = "RCtrl"
        case leftAlt = "LAlt"
        case rightAlt = "RAlt"
        case leftWin = "LWin"
        case rightWin = "RWin"
        case fn = "Fn"
    }

    public enum MediaKey: String, Codable, CaseIterable, Sendable {
        case playPause = "Play/Pause"
        case stop = "Stop"
        case nextTrack = "Next Track"
        case previousTrack = "Previous Track"
        case mute = "Mute"
        case volumeUp = "Volume Up"
        case volumeDown = "Volume Down"
        case brightnessUp = "Brightness Up"
        case brightnessDown = "Brightness Down"
        case launchMail = "Launch Mail"
        case launchCalculator = "Launch Calculator"
        case launchBrowser = "Launch Browser"
    }

    public enum MouseButton: UInt8, Codable, CaseIterable, Sendable {
        case left = 1
        case right = 2
        case middle = 3
        case back = 4
        case forward = 5
    }

    public var displayLabel: String {
        switch self {
        case .standardKey(let keyCode):
            return KeyCodeLibrary.name(for: keyCode)
        case .modifierKey(let modifiers):
            return modifiers.map { $0.rawValue }.joined(separator: "+")
        case .mediaKey(let media):
            return media.rawValue
        case .mouseButton(let button):
            return "Mouse \(button.rawValue)"
        case .macro(let macroId):
            return "Macro: \(macroId.uuidString.prefix(6))"
        case .layerSwitch(let layer):
            return "Layer \(layer)"
        case .disabled:
            return "Disabled"
        }
    }
}

// MARK: - Key Code Library

public enum KeyCodeLibrary {
    public static func name(for keyCode: UInt16) -> String {
        return keyCodeNames[keyCode] ?? "Key 0x\(String(keyCode, radix: 16))"
    }

    private static let keyCodeNames: [UInt16: String] = [
        0x00: "A", 0x01: "B", 0x02: "C", 0x03: "D", 0x04: "E",
        0x05: "F", 0x06: "G", 0x07: "H", 0x08: "I", 0x09: "J",
        0x0A: "K", 0x0B: "L", 0x0C: "M", 0x0D: "N", 0x0E: "O",
        0x0F: "P", 0x10: "Q", 0x11: "R", 0x12: "S", 0x13: "T",
        0x14: "U", 0x15: "V", 0x16: "W", 0x17: "X", 0x18: "Y",
        0x19: "Z", 0x1A: "1", 0x1B: "2", 0x1C: "3", 0x1D: "4",
        0x1E: "5", 0x1F: "6", 0x20: "7", 0x21: "8", 0x22: "9",
        0x23: "0", 0x24: "Enter", 0x25: "Esc", 0x26: "Backspace",
        0x27: "Tab", 0x28: "Space", 0x29: "-", 0x2A: "=", 0x2B: "[",
        0x2C: "]", 0x2D: "\\", 0x2E: ";", 0x2F: "'", 0x30: "`",
        0x31: ",", 0x32: ".", 0x33: "/", 0x34: "Caps Lock",
        0x35: "F1", 0x36: "F2", 0x37: "F3", 0x38: "F4", 0x39: "F5",
        0x3A: "F6", 0x3B: "F7", 0x3C: "F8", 0x3D: "F9", 0x3E: "F10",
        0x3F: "F11", 0x40: "F12", 0x41: "Print", 0x42: "Scroll Lock",
        0x43: "Pause", 0x44: "Insert", 0x45: "Home", 0x46: "Page Up",
        0x47: "Delete", 0x48: "End", 0x49: "Page Down", 0x4A: "Right",
        0x4B: "Left", 0x4C: "Down", 0x4D: "Up", 0x4E: "Num Lock",
        0x4F: "Keypad /", 0x50: "Keypad *", 0x51: "Keypad -", 0x52: "Keypad +",
        0x53: "Keypad Enter", 0x54: "Keypad 1", 0x55: "Keypad 2", 0x56: "Keypad 3",
        0x57: "Keypad 4", 0x58: "Keypad 5", 0x59: "Keypad 6", 0x5A: "Keypad 7",
        0x5B: "Keypad 8", 0x5C: "Keypad 9", 0x5D: "Keypad 0", 0x5E: "Keypad ."
    ]
}

// MARK: - Ronin TKL 79-Key Layout Definition

public enum RoninLayout {
    /// 79-key TKL layout organized by rows
    public static let keys: [[KeyInfo]] = [
        // Row 0: Function row + extras
        [
            KeyInfo(position: KeyPosition(row: 0, col: 0), scanCode: 0x35, defaultLabel: "Esc", defaultKeyCode: 0x25, size: .standard),
            KeyInfo(position: KeyPosition(row: 0, col: 1), scanCode: 0x36, defaultLabel: "F1", defaultKeyCode: 0x35, size: .standard),
            KeyInfo(position: KeyPosition(row: 0, col: 2), scanCode: 0x37, defaultLabel: "F2", defaultKeyCode: 0x36, size: .standard),
            KeyInfo(position: KeyPosition(row: 0, col: 3), scanCode: 0x38, defaultLabel: "F3", defaultKeyCode: 0x37, size: .standard),
            KeyInfo(position: KeyPosition(row: 0, col: 4), scanCode: 0x39, defaultLabel: "F4", defaultKeyCode: 0x38, size: .standard),
            KeyInfo(position: KeyPosition(row: 0, col: 5), scanCode: 0x3A, defaultLabel: "F5", defaultKeyCode: 0x39, size: .standard),
            KeyInfo(position: KeyPosition(row: 0, col: 6), scanCode: 0x3B, defaultLabel: "F6", defaultKeyCode: 0x3A, size: .standard),
            KeyInfo(position: KeyPosition(row: 0, col: 7), scanCode: 0x3C, defaultLabel: "F7", defaultKeyCode: 0x3B, size: .standard),
            KeyInfo(position: KeyPosition(row: 0, col: 8), scanCode: 0x3D, defaultLabel: "F8", defaultKeyCode: 0x3C, size: .standard),
            KeyInfo(position: KeyPosition(row: 0, col: 9), scanCode: 0x3E, defaultLabel: "F9", defaultKeyCode: 0x3D, size: .standard),
            KeyInfo(position: KeyPosition(row: 0, col: 10), scanCode: 0x3F, defaultLabel: "F10", defaultKeyCode: 0x3E, size: .standard),
            KeyInfo(position: KeyPosition(row: 0, col: 11), scanCode: 0x40, defaultLabel: "F11", defaultKeyCode: 0x3F, size: .standard),
            KeyInfo(position: KeyPosition(row: 0, col: 12), scanCode: 0x41, defaultLabel: "F12", defaultKeyCode: 0x40, size: .standard),
            KeyInfo(position: KeyPosition(row: 0, col: 13), scanCode: 0x42, defaultLabel: "PrtSc", defaultKeyCode: 0x41, size: .standard),
            KeyInfo(position: KeyPosition(row: 0, col: 14), scanCode: 0x43, defaultLabel: "Del", defaultKeyCode: 0x47, size: .standard),
        ],
        // Row 1: Number row
        [
            KeyInfo(position: KeyPosition(row: 1, col: 0), scanCode: 0x44, defaultLabel: "`", defaultKeyCode: 0x30, size: .standard),
            KeyInfo(position: KeyPosition(row: 1, col: 1), scanCode: 0x45, defaultLabel: "1", defaultKeyCode: 0x1A, size: .standard),
            KeyInfo(position: KeyPosition(row: 1, col: 2), scanCode: 0x46, defaultLabel: "2", defaultKeyCode: 0x1B, size: .standard),
            KeyInfo(position: KeyPosition(row: 1, col: 3), scanCode: 0x47, defaultLabel: "3", defaultKeyCode: 0x1C, size: .standard),
            KeyInfo(position: KeyPosition(row: 1, col: 4), scanCode: 0x48, defaultLabel: "4", defaultKeyCode: 0x1D, size: .standard),
            KeyInfo(position: KeyPosition(row: 1, col: 5), scanCode: 0x49, defaultLabel: "5", defaultKeyCode: 0x1E, size: .standard),
            KeyInfo(position: KeyPosition(row: 1, col: 6), scanCode: 0x4A, defaultLabel: "6", defaultKeyCode: 0x1F, size: .standard),
            KeyInfo(position: KeyPosition(row: 1, col: 7), scanCode: 0x4B, defaultLabel: "7", defaultKeyCode: 0x20, size: .standard),
            KeyInfo(position: KeyPosition(row: 1, col: 8), scanCode: 0x4C, defaultLabel: "8", defaultKeyCode: 0x21, size: .standard),
            KeyInfo(position: KeyPosition(row: 1, col: 9), scanCode: 0x4D, defaultLabel: "9", defaultKeyCode: 0x22, size: .standard),
            KeyInfo(position: KeyPosition(row: 1, col: 10), scanCode: 0x4E, defaultLabel: "0", defaultKeyCode: 0x23, size: .standard),
            KeyInfo(position: KeyPosition(row: 1, col: 11), scanCode: 0x4F, defaultLabel: "-", defaultKeyCode: 0x29, size: .standard),
            KeyInfo(position: KeyPosition(row: 1, col: 12), scanCode: 0x50, defaultLabel: "=", defaultKeyCode: 0x2A, size: .standard),
            KeyInfo(position: KeyPosition(row: 1, col: 13), scanCode: 0x51, defaultLabel: "Backspace", defaultKeyCode: 0x26, size: .spaceLarge),
        ],
        // Row 2: QWERTY row
        [
            KeyInfo(position: KeyPosition(row: 2, col: 0), scanCode: 0x52, defaultLabel: "Tab", defaultKeyCode: 0x27, size: .wide),
            KeyInfo(position: KeyPosition(row: 2, col: 1), scanCode: 0x53, defaultLabel: "Q", defaultKeyCode: 0x10, size: .standard),
            KeyInfo(position: KeyPosition(row: 2, col: 2), scanCode: 0x54, defaultLabel: "W", defaultKeyCode: 0x16, size: .standard),
            KeyInfo(position: KeyPosition(row: 2, col: 3), scanCode: 0x55, defaultLabel: "E", defaultKeyCode: 0x04, size: .standard),
            KeyInfo(position: KeyPosition(row: 2, col: 4), scanCode: 0x56, defaultLabel: "R", defaultKeyCode: 0x11, size: .standard),
            KeyInfo(position: KeyPosition(row: 2, col: 5), scanCode: 0x57, defaultLabel: "T", defaultKeyCode: 0x13, size: .standard),
            KeyInfo(position: KeyPosition(row: 2, col: 6), scanCode: 0x58, defaultLabel: "Y", defaultKeyCode: 0x18, size: .standard),
            KeyInfo(position: KeyPosition(row: 2, col: 7), scanCode: 0x59, defaultLabel: "U", defaultKeyCode: 0x14, size: .standard),
            KeyInfo(position: KeyPosition(row: 2, col: 8), scanCode: 0x5A, defaultLabel: "I", defaultKeyCode: 0x08, size: .standard),
            KeyInfo(position: KeyPosition(row: 2, col: 9), scanCode: 0x5B, defaultLabel: "O", defaultKeyCode: 0x0E, size: .standard),
            KeyInfo(position: KeyPosition(row: 2, col: 10), scanCode: 0x5C, defaultLabel: "P", defaultKeyCode: 0x0F, size: .standard),
            KeyInfo(position: KeyPosition(row: 2, col: 11), scanCode: 0x5D, defaultLabel: "[", defaultKeyCode: 0x2B, size: .standard),
            KeyInfo(position: KeyPosition(row: 2, col: 12), scanCode: 0x5E, defaultLabel: "]", defaultKeyCode: 0x2C, size: .standard),
            KeyInfo(position: KeyPosition(row: 2, col: 13), scanCode: 0x5F, defaultLabel: "\\", defaultKeyCode: 0x2D, size: .wide),
        ],
        // Row 3: Home row
        [
            KeyInfo(position: KeyPosition(row: 3, col: 0), scanCode: 0x60, defaultLabel: "Caps", defaultKeyCode: 0x34, size: .widest),
            KeyInfo(position: KeyPosition(row: 3, col: 1), scanCode: 0x61, defaultLabel: "A", defaultKeyCode: 0x00, size: .standard),
            KeyInfo(position: KeyPosition(row: 3, col: 2), scanCode: 0x62, defaultLabel: "S", defaultKeyCode: 0x12, size: .standard),
            KeyInfo(position: KeyPosition(row: 3, col: 3), scanCode: 0x63, defaultLabel: "D", defaultKeyCode: 0x03, size: .standard),
            KeyInfo(position: KeyPosition(row: 3, col: 4), scanCode: 0x64, defaultLabel: "F", defaultKeyCode: 0x05, size: .standard),
            KeyInfo(position: KeyPosition(row: 3, col: 5), scanCode: 0x65, defaultLabel: "G", defaultKeyCode: 0x06, size: .standard),
            KeyInfo(position: KeyPosition(row: 3, col: 6), scanCode: 0x66, defaultLabel: "H", defaultKeyCode: 0x07, size: .standard),
            KeyInfo(position: KeyPosition(row: 3, col: 7), scanCode: 0x67, defaultLabel: "J", defaultKeyCode: 0x09, size: .standard),
            KeyInfo(position: KeyPosition(row: 3, col: 8), scanCode: 0x68, defaultLabel: "K", defaultKeyCode: 0x0A, size: .standard),
            KeyInfo(position: KeyPosition(row: 3, col: 9), scanCode: 0x69, defaultLabel: "L", defaultKeyCode: 0x0B, size: .standard),
            KeyInfo(position: KeyPosition(row: 3, col: 10), scanCode: 0x6A, defaultLabel: ";", defaultKeyCode: 0x2E, size: .standard),
            KeyInfo(position: KeyPosition(row: 3, col: 11), scanCode: 0x6B, defaultLabel: "'", defaultKeyCode: 0x2F, size: .standard),
            KeyInfo(position: KeyPosition(row: 3, col: 12), scanCode: 0x6C, defaultLabel: "Enter", defaultKeyCode: 0x24, size: .enter),
        ],
        // Row 4: Shift row
        [
            KeyInfo(position: KeyPosition(row: 4, col: 0), scanCode: 0x6D, defaultLabel: "Shift", defaultKeyCode: 0xE1, size: .shift),
            KeyInfo(position: KeyPosition(row: 4, col: 1), scanCode: 0x6E, defaultLabel: "Z", defaultKeyCode: 0x19, size: .standard),
            KeyInfo(position: KeyPosition(row: 4, col: 2), scanCode: 0x6F, defaultLabel: "X", defaultKeyCode: 0x17, size: .standard),
            KeyInfo(position: KeyPosition(row: 4, col: 3), scanCode: 0x70, defaultLabel: "C", defaultKeyCode: 0x02, size: .standard),
            KeyInfo(position: KeyPosition(row: 4, col: 4), scanCode: 0x71, defaultLabel: "V", defaultKeyCode: 0x15, size: .standard),
            KeyInfo(position: KeyPosition(row: 4, col: 5), scanCode: 0x72, defaultLabel: "B", defaultKeyCode: 0x01, size: .standard),
            KeyInfo(position: KeyPosition(row: 4, col: 6), scanCode: 0x73, defaultLabel: "N", defaultKeyCode: 0x0D, size: .standard),
            KeyInfo(position: KeyPosition(row: 4, col: 7), scanCode: 0x74, defaultLabel: "M", defaultKeyCode: 0x0C, size: .standard),
            KeyInfo(position: KeyPosition(row: 4, col: 8), scanCode: 0x75, defaultLabel: ",", defaultKeyCode: 0x31, size: .standard),
            KeyInfo(position: KeyPosition(row: 4, col: 9), scanCode: 0x76, defaultLabel: ".", defaultKeyCode: 0x32, size: .standard),
            KeyInfo(position: KeyPosition(row: 4, col: 10), scanCode: 0x77, defaultLabel: "/", defaultKeyCode: 0x33, size: .standard),
            KeyInfo(position: KeyPosition(row: 4, col: 11), scanCode: 0x78, defaultLabel: "Shift", defaultKeyCode: 0xE5, size: .shift),
            KeyInfo(position: KeyPosition(row: 4, col: 12), scanCode: 0x79, defaultLabel: "Up", defaultKeyCode: 0x4D, size: .standard),
        ],
        // Row 5: Bottom row
        [
            KeyInfo(position: KeyPosition(row: 5, col: 0), scanCode: 0x7A, defaultLabel: "Ctrl", defaultKeyCode: 0xE0, size: .ctrl),
            KeyInfo(position: KeyPosition(row: 5, col: 1), scanCode: 0x7B, defaultLabel: "Win", defaultKeyCode: 0xE3, size: .ctrl),
            KeyInfo(position: KeyPosition(row: 5, col: 2), scanCode: 0x7C, defaultLabel: "Alt", defaultKeyCode: 0xE2, size: .ctrl),
            KeyInfo(position: KeyPosition(row: 5, col: 3), scanCode: 0x7D, defaultLabel: "Space", defaultKeyCode: 0x28, size: .spaceFull),
            KeyInfo(position: KeyPosition(row: 5, col: 4), scanCode: 0x7E, defaultLabel: "Alt", defaultKeyCode: 0xE6, size: .ctrl),
            KeyInfo(position: KeyPosition(row: 5, col: 5), scanCode: 0x7F, defaultLabel: "Fn", defaultKeyCode: 0xFF, size: .fn),
            KeyInfo(position: KeyPosition(row: 5, col: 6), scanCode: 0x80, defaultLabel: "Ctrl", defaultKeyCode: 0xE4, size: .ctrl),
            KeyInfo(position: KeyPosition(row: 5, col: 7), scanCode: 0x81, defaultLabel: "Left", defaultKeyCode: 0x4B, size: .standard),
            KeyInfo(position: KeyPosition(row: 5, col: 8), scanCode: 0x82, defaultLabel: "Down", defaultKeyCode: 0x4C, size: .standard),
            KeyInfo(position: KeyPosition(row: 5, col: 9), scanCode: 0x83, defaultLabel: "Right", defaultKeyCode: 0x4A, size: .standard),
        ]
    ]

    public static var allKeys: [KeyInfo] {
        keys.flatMap { $0 }
    }
}
