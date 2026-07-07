/**
 KeyboardProtocol.swift

 Defines the HID packet protocol for the EvoFox Ronin keyboard.

 IMPORTANT: This protocol is based on common gaming keyboard HID patterns.
 The actual EvoFox Ronin protocol may differ. This file provides the
 ABSTRACTION layer — update the packet construction methods once you have
 captured the real USB HID packets.

 Common Gaming Keyboard HID Packet Structure (64-byte report):
 Byte 0:   Report ID / Command Type
 Byte 1:   Sub-command / Effect ID
 Byte 2:   Parameter 1 (speed, brightness, etc.)
 Byte 3:   Parameter 2 (direction, color index, etc.)
 Byte 4-6: RGB values (R, G, B)
 Byte 7:   Reserved / Checksum
 Byte 8-63: Additional data (key mappings, macro data, etc.)

 Commands to implement:
 - RGB Effect Select
 - RGB Color Set
 - RGB Speed/Brightness Set
 - Key Remap
 - Macro Save
 - Profile Save/Load
 - Factory Reset

 How to reverse-engineer:
 1. Install official EvoFox software on Windows VM or PC
 2. Install Wireshark with USBPcap
 3. Start USB capture on the keyboard's USB bus
 4. Change RGB effect in software → capture packet
 5. Change RGB color → capture packet
 6. Map key → capture packet
 7. Save macro → capture packet
 8. Compare packets to identify command structure
 */

import Foundation

// MARK: - Packet Builder

public class KeyboardProtocol: @unchecked Sendable {
    private let reportSize: Int = 64

    public init() {}

    /// Builds an HID output report for the given command.
    /// Returns a 64-byte array ready to be sent via HIDManager.
    public func buildPacket(command: KeyboardCommand) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: reportSize)

        switch command {
        case .setRGBEffect(let effectId):
            packet[0] = 0x07  // Common RGB report ID
            packet[1] = command.commandId
            packet[2] = effectId

        case .setRGBColor(let r, let g, let b):
            packet[0] = 0x07
            packet[1] = command.commandId
            packet[2] = r
            packet[3] = g
            packet[4] = b

        case .setRGBSpeed(let speed):
            packet[0] = 0x07
            packet[1] = command.commandId
            packet[2] = speed

        case .setRGBBrightness(let brightness):
            packet[0] = 0x07
            packet[1] = command.commandId
            packet[2] = brightness

        case .setRGBDirection(let direction):
            packet[0] = 0x07
            packet[1] = command.commandId
            packet[2] = direction

        case .setRGBMode(let mode):
            packet[0] = 0x07
            packet[1] = command.commandId
            packet[2] = mode

        case .remapKey(let scanCode, let targetKeyCode):
            packet[0] = 0x08
            packet[1] = command.commandId
            packet[2] = scanCode
            packet[3] = UInt8(targetKeyCode & 0xFF)
            packet[4] = UInt8((targetKeyCode >> 8) & 0xFF)

        case .setMacro(let macroId, let events):
            packet[0] = 0x09
            packet[1] = command.commandId
            packet[2] = macroId
            // Encode events into remaining bytes (simplified)
            var offset = 3
            for event in events.prefix(20) {
                if offset + 4 >= reportSize { break }
                packet[offset] = UInt8(event.type.rawValue.prefix(1).uppercased().utf8.first ?? 0)
                packet[offset + 1] = UInt8(event.keyCode ?? 0)
                packet[offset + 2] = UInt8(event.delayMs & 0xFF)
                packet[offset + 3] = UInt8((event.delayMs >> 8) & 0xFF)
                offset += 4
            }

        case .saveProfile(let profileId):
            packet[0] = 0x0A
            packet[1] = command.commandId
            packet[2] = profileId

        case .loadProfile(let profileId):
            packet[0] = 0x0A
            packet[1] = command.commandId
            packet[2] = profileId

        case .factoryReset:
            packet[0] = 0xFF
            packet[1] = command.commandId
            // Safety: require specific pattern to prevent accidental reset
            packet[2] = 0x52 // 'R'
            packet[3] = 0x45 // 'E'
            packet[4] = 0x53 // 'S'
            packet[5] = 0x45 // 'E'
            packet[6] = 0x54 // 'T'

        case .setKnobBehavior(let behavior):
            packet[0] = 0x0B
            packet[1] = command.commandId
            packet[2] = behavior

        case .setPollingRate(let rate):
            packet[0] = 0x0C
            packet[1] = command.commandId
            packet[2] = rate
        }

        return packet
    }

    /// Builds a complete RGB settings packet from an RGBSettings model.
    public func buildRGBSettingsPacket(settings: RGBSettings) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: reportSize)
        packet[0] = 0x07
        packet[1] = 0x01 // Set full RGB config
        packet[2] = settings.effect.effectId
        packet[3] = settings.speed
        packet[4] = settings.brightness
        packet[5] = settings.isEnabled ? 1 : 0
        packet[6] = settings.primaryColor.r
        packet[7] = settings.primaryColor.g
        packet[8] = settings.primaryColor.b
        packet[9] = settings.secondaryColor.r
        packet[10] = settings.secondaryColor.g
        packet[11] = settings.secondaryColor.b
        packet[12] = settings.direction.rawValue
        return packet
    }

    /// Builds a per-key color packet for custom lighting.
    public func buildPerKeyColorPacket(keyColors: [KeyPosition: RGBColor]) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: reportSize)
        packet[0] = 0x07
        packet[1] = 0x12 // Custom per-key mode
        packet[2] = 0x01 // Update packet

        // Pack key colors into remaining bytes
        // Each key takes 4 bytes: scanCode, R, G, B
        var offset = 3
        for (position, color) in keyColors.sorted(by: { $0.key.row < $1.key.row || ($0.key.row == $1.key.row && $0.key.col < $1.key.col) }) {
            if offset + 4 >= reportSize { break }
            if let key = RoninLayout.keys[safe: position.row]?[safe: position.col] {
                packet[offset] = key.scanCode
                packet[offset + 1] = color.r
                packet[offset + 2] = color.g
                packet[offset + 3] = color.b
                offset += 4
            }
        }
        return packet
    }

    /// Builds a key remapping packet for a single key.
    public func buildRemapPacket(mapping: KeyMapping) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: reportSize)
        packet[0] = 0x08
        packet[1] = 0x10
        packet[2] = mapping.keyScanCode

        switch mapping.assignedAction {
        case .standardKey(let keyCode):
            packet[3] = 0x01 // Type: standard key
            packet[4] = UInt8(keyCode & 0xFF)
            packet[5] = UInt8((keyCode >> 8) & 0xFF)
        case .mediaKey(let media):
            packet[3] = 0x02 // Type: media
            packet[4] = UInt8(media.hashValue)
        case .macro(let macroId):
            packet[3] = 0x03 // Type: macro
            // Would need macro ID mapping
        case .disabled:
            packet[3] = 0x00 // Type: disabled
        default:
            packet[3] = 0x01
            packet[4] = 0x00
        }

        return packet
    }

    /// Decodes a response packet from the keyboard.
    public func decodeResponse(packet: [UInt8]) -> KeyboardResponse? {
        guard packet.count >= 3 else { return nil }

        let reportID = packet[0]
        let status = packet[1]
        let commandType = packet[2]

        return KeyboardResponse(
            reportID: reportID,
            status: status,
            commandType: commandType,
            data: Array(packet[3...])
        )
    }
}


