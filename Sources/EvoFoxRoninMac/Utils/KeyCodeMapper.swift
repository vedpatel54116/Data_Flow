import Foundation
import Carbon

struct KeyCodeMapper: Sendable {
    private static let macToScanCode: [UInt16: UInt8] = {
        var map: [UInt16: UInt8] = [:]

        for row in RoninLayout.keys {
            for key in row {
                map[key.macKeyCode] = key.scanCode
            }
        }
        return map
    }()

    static func scanCode(for nsEventKeyCode: UInt16) -> UInt8? {
        macToScanCode[nsEventKeyCode]
    }

    static func displayName(for nsEventKeyCode: UInt16) -> String {
        macKeyNames[nsEventKeyCode] ?? "Key 0x\(String(nsEventKeyCode, radix: 16))"
    }
}

private let macKeyNames: [UInt16: String] = [
    0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H",
    0x05: "G", 0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V",
    0x0A: "B", 0x0B: "Q", 0x0C: "W", 0x0D: "E", 0x0E: "R",
    0x0F: "Y", 0x10: "T", 0x11: "1", 0x12: "2", 0x13: "3",
    0x14: "4", 0x15: "6", 0x16: "5", 0x17: "=", 0x18: "9",
    0x19: "7", 0x1A: "-", 0x1B: "8", 0x1C: "0", 0x1D: "]",
    0x1E: "O", 0x1F: "U", 0x20: "[", 0x21: "I", 0x22: "P",
    0x23: "Return", 0x24: "L", 0x25: "J", 0x26: "\"",
    0x27: "K", 0x28: ";", 0x29: "\\", 0x2A: ",", 0x2B: "/",
    0x2C: "N", 0x2D: "M", 0x2E: ".", 0x2F: "Tab",
    0x30: "Space", 0x31: "`", 0x32: "Backspace", 0x33: "Esc",
    0x34: "F17", 0x35: "Keypad .", 0x36: "F18",
    0x37: "F19", 0x38: "F20", 0x39: "F5", 0x3A: "F6",
    0x3B: "F7", 0x3C: "F3", 0x3D: "F8", 0x3E: "F9",
    0x3F: "F11", 0x40: "F13", 0x41: "F16", 0x42: "F14",
    0x43: "F10", 0x44: "F12", 0x45: "F15", 0x46: "Help",
    0x47: "Home", 0x48: "Page Up", 0x49: "Delete",
    0x4A: "F4", 0x4B: "End", 0x4C: "F2", 0x4D: "Page Down",
    0x4E: "F1", 0x4F: "Left", 0x50: "Right", 0x51: "Down",
    0x52: "Up", 0x53: "F17",
]

extension KeyInfo {
    var macKeyCode: UInt16 {
        switch defaultLabel {
        case "A": return 0x00
        case "S": return 0x01
        case "D": return 0x02
        case "F": return 0x03
        case "H": return 0x04
        case "G": return 0x05
        case "Z": return 0x06
        case "X": return 0x07
        case "C": return 0x08
        case "V": return 0x09
        case "B": return 0x0A
        case "Q": return 0x0B
        case "W": return 0x0C
        case "E": return 0x0D
        case "R": return 0x0E
        case "Y": return 0x0F
        case "T": return 0x10
        case "1": return 0x11
        case "2": return 0x12
        case "3": return 0x13
        case "4": return 0x14
        case "6": return 0x15
        case "5": return 0x16
        case "=": return 0x17
        case "9": return 0x18
        case "7": return 0x19
        case "-": return 0x1A
        case "8": return 0x1B
        case "0": return 0x1C
        case "]": return 0x1D
        case "O": return 0x1E
        case "U": return 0x1F
        case "[": return 0x20
        case "I": return 0x21
        case "P": return 0x22
        case "Enter": return 0x24
        case "L": return 0x25
        case "J": return 0x26
        case "\"": return 0x27
        case "K": return 0x28
        case ";": return 0x29
        case "\\": return 0x2A
        case ",": return 0x2B
        case "/": return 0x2C
        case "N": return 0x2D
        case "M": return 0x2E
        case ".": return 0x2F
        case "Tab": return 0x30
        case "Space": return 0x31
        case "`": return 0x32
        case "Backspace": return 0x33
        case "Esc": return 0x35
        case "F17", "F18", "F19", "F20": return 0x34
        case "F5": return 0x39
        case "F6": return 0x3A
        case "F7": return 0x3B
        case "F3": return 0x3C
        case "F8": return 0x3D
        case "F9": return 0x3E
        case "F11": return 0x3F
        case "F13": return 0x40
        case "F16": return 0x41
        case "F14": return 0x42
        case "F10": return 0x43
        case "F12": return 0x44
        case "F15": return 0x45
        case "Help": return 0x46
        case "Home": return 0x47
        case "Page Up": return 0x48
        case "Delete": return 0x49
        case "F4": return 0x4A
        case "End": return 0x4B
        case "F2": return 0x4C
        case "Page Down": return 0x4D
        case "F1": return 0x4E
        case "Left": return 0x4F
        case "Right": return 0x50
        case "Down": return 0x51
        case "Up": return 0x52
        default: return 0xFF
        }
    }
}
