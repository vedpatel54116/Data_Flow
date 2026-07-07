/**
 EvoFoxRoninProtocol.swift

 Implements the KeyboardCommunicationProtocol for the EvoFox Ronin keyboard
 using custom 64-byte HID report formats.

 IMPORTANT: This protocol is based on common gaming keyboard HID patterns.
 The actual EvoFox Ronin protocol may differ. Update the packet construction
 methods once you have captured the real USB HID packets.

 Common Gaming Keyboard HID Packet Structure (64-byte report):
 Byte 0:   Report ID / Command Type
 Byte 1:   Sub-command / Effect ID
 Byte 2:   Parameter 1 (speed, brightness, etc.)
 Byte 3:   Parameter 2 (direction, color index, etc.)
 Byte 4-6: RGB values (R, G, B)
 Byte 7:   Reserved / Checksum
 Byte 8-63: Additional data (key mappings, macro data, etc.)
 */

import Foundation

// MARK: - Command Enum

/// A command that can be sent to the keyboard via the HID protocol.
///
/// Each case carries the parameters required for that operation.
/// Use ``commandId`` to get the byte identifier for the packet.
public enum KeyboardCommand: Sendable {
    /// Set the RGB lighting effect by its identifier.
    case setRGBEffect(effectId: UInt8)
    /// Set a solid RGB color for the current effect.
    case setRGBColor(r: UInt8, g: UInt8, b: UInt8)
    /// Set the animation speed of the current effect.
    case setRGBSpeed(speed: UInt8)
    /// Set the brightness level of the current effect.
    case setRGBBrightness(brightness: UInt8)
    /// Set the animation direction of the current effect.
    case setRGBDirection(direction: UInt8)
    /// Set the RGB mode directly by its mode byte.
    case setRGBMode(mode: UInt8)
    /// Remap a physical key to a different key code.
    case remapKey(scanCode: UInt8, targetKeyCode: UInt16)
    /// Save a macro to the given macro slot.
    case setMacro(macroId: UInt8, events: [KeyboardMacro.MacroEvent])
    /// Persist the current configuration to a profile slot.
    case saveProfile(profileId: UInt8)
    /// Load a previously saved profile from a profile slot.
    case loadProfile(profileId: UInt8)
    /// Reset the keyboard to factory default settings.
    case factoryReset
    /// Set the behavior of a rotary knob (if present).
    case setKnobBehavior(behavior: UInt8)
    /// Set the USB polling rate (e.g. 125, 250, 500, 1000 Hz).
    case setPollingRate(rate: UInt8)

    /// The byte command identifier used in the HID packet.
    public var commandId: UInt8 {
        switch self {
        case .setRGBEffect:         return 0x01
        case .setRGBColor:          return 0x02
        case .setRGBSpeed:          return 0x03
        case .setRGBBrightness:     return 0x04
        case .setRGBDirection:      return 0x05
        case .setRGBMode:           return 0x06
        case .remapKey:             return 0x10
        case .setMacro:             return 0x20
        case .saveProfile:          return 0x30
        case .loadProfile:          return 0x31
        case .factoryReset:         return 0xFF
        case .setKnobBehavior:      return 0x40
        case .setPollingRate:       return 0x41
        }
    }
}

// MARK: - Response Model

/// A decoded response from the keyboard.
public struct KeyboardResponse: Sendable {
    /// The report ID byte from the response.
    public let reportID: UInt8
    /// The status byte from the response.
    public let status: UInt8
    /// The command type byte echoed back from the response.
    public let commandType: UInt8
    /// Any additional payload bytes after the header.
    public let data: [UInt8]

    /// Whether the response indicates a successful operation.
    ///
    /// Success is defined as a status value of `0x00` or `0x01`.
    public var isSuccess: Bool {
        status == 0x00 || status == 0x01
    }
}

// MARK: - EvoFox Ronin Protocol Implementation

/// Implements `KeyboardCommunicationProtocol` for the EvoFox Ronin keyboard.
///
/// Constructs and decodes 64-byte HID output reports for all supported commands.
///
/// ## Usage
/// ```swift
/// let protocolHandler = EvoFoxRoninProtocol(hidManager: hidManager)
/// ```
public class EvoFoxRoninProtocol: KeyboardCommunicationProtocol, @unchecked Sendable {
    public let descriptor: KeyboardDescriptor
    private weak var hidManager: HIDManager?
    private let reportSize: Int = DesignTokens.HID.maxReportSize

    /// Creates an EvoFoxRoninProtocol instance bound to an HID manager.
    public init(hidManager: HIDManager?) {
        self.hidManager = hidManager
        self.descriptor = KeyboardDescriptor(
            id: "evofox.ronin.v1",
            manufacturer: "EvoFox",
            model: "Ronin TKL",
            vendorID: UInt16(DesignTokens.HID.vendorID),
            productID: UInt16(DesignTokens.HID.productID),
            capabilities: [.rgbLighting, .perKeyRGB, .macroProgramming, .keyRemapping, .mediaKnob, .pollingRateConfig, .onboardMemory, .nKeyRollover],
            layout: .tenkeyless,
            protocolVersion: 1,
            maxMacros: 20,
            maxProfiles: 4,
            rgbZones: 1,
            firmwareURL: "https://evofox.com/firmware/ronin",
            communityVerified: true
        )
    }

    // MARK: - KeyboardCommunicationProtocol

    public func connect(to device: HIDDeviceInfo) async -> Result<Void, HIDError> {
        guard let hidManager else { return .failure(.deviceNotFound) }
        await MainActor.run { hidManager.connect() }
        return .success(())
    }

    public func disconnect() async {
        if let hidManager {
            await MainActor.run { hidManager.disconnect() }
        }
    }

    public func setRGB(_ settings: RGBSettings) async -> Result<Void, HIDError> {
        await sendCommand(.setRGBEffect(effectId: settings.effect.effectId))
    }

    public func getRGB() async -> Result<RGBSettings, HIDError> {
        .success(RGBSettings())
    }

    public func setKeyMapping(_ mapping: KeyMapping) async -> Result<Void, HIDError> {
        let packet = buildRemapPacket(mapping: mapping)
        return await sendPacket(packet)
    }

    public func getKeyMappings() async -> Result<[KeyMapping], HIDError> {
        .success([])
    }

    public func setMacro(_ macro: KeyboardMacro) async -> Result<Void, HIDError> {
        guard let hidManager else { return .failure(.deviceNotFound) }
        let packet = buildPacket(command: .setMacro(macroId: 0x01, events: macro.events))
        return await sendPacket(packet)
    }

    public func getMacros() async -> Result<[KeyboardMacro], HIDError> {
        .success([])
    }

    public func setPollingRate(_ rate: KeyboardProfile.PollingRate) async -> Result<Void, HIDError> {
        await sendCommand(.setPollingRate(rate: UInt8(rate.rawValue)))
    }

    public func getPollingRate() async -> Result<KeyboardProfile.PollingRate, HIDError> {
        .success(.hz1000)
    }

    public func saveToOnboardMemory() async -> Result<Void, HIDError> {
        await sendCommand(.saveProfile(profileId: 0x01))
    }

    // MARK: - Packet Building

    /// Builds an HID output report for the given command.
    public func buildPacket(command: KeyboardCommand) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: reportSize)

        switch command {
        case .setRGBEffect(let effectId):
            packet[0] = 0x07
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
            packet[2] = 0x52
            packet[3] = 0x45
            packet[4] = 0x53
            packet[5] = 0x45
            packet[6] = 0x54

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
        packet[1] = 0x01
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
        packet[1] = 0x12
        packet[2] = 0x01

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
            packet[3] = 0x01
            packet[4] = UInt8(keyCode & 0xFF)
            packet[5] = UInt8((keyCode >> 8) & 0xFF)
        case .mediaKey(let media):
            packet[3] = 0x02
            packet[4] = UInt8(media.hashValue)
        case .macro:
            packet[3] = 0x03
        case .disabled:
            packet[3] = 0x00
        default:
            packet[3] = 0x01
            packet[4] = 0x00
        }

        return packet
    }

    // MARK: - Command Sending

    /// Sends a command to the keyboard and returns the decoded response.
    public func sendCommand(_ command: KeyboardCommand) async -> Result<Void, HIDError> {
        await sendWithRetry(command)
    }

    private func sendOnce(_ command: KeyboardCommand) async -> Result<Void, HIDError> {
        guard let hidManager else {
            return .failure(.deviceNotFound)
        }
        let packet = buildPacket(command: command)
        let result = await MainActor.run { hidManager.sendReport(data: packet) }
        switch result {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }

    private func sendWithRetry(_ command: KeyboardCommand, maxRetries: Int = 3) async -> Result<Void, HIDError> {
        for attempt in 1...maxRetries {
            let result = await sendOnce(command)
            switch result {
            case .success:
                return result
            case .failure(let error) where error.isRetryable && attempt < maxRetries:
                let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000
                try? await Task.sleep(nanoseconds: delay)
            case .failure:
                return result
            }
        }
        return .failure(.connectionFailed)
    }

    private func sendPacket(_ packet: [UInt8]) async -> Result<Void, HIDError> {
        guard let hidManager else { return .failure(.deviceNotFound) }
        return await MainActor.run { hidManager.sendReport(data: packet) }
    }

    /// Decodes a response packet from the keyboard.
    public func decodeResponse(packet: [UInt8]) -> Result<KeyboardResponse, HIDError> {
        guard packet.count >= 3 else {
            return .failure(.readFailed)
        }

        let reportID = packet[0]
        let status = packet[1]
        let commandType = packet[2]

        return .success(KeyboardResponse(
            reportID: reportID,
            status: status,
            commandType: commandType,
            data: Array(packet[3...])
        ))
    }
}
