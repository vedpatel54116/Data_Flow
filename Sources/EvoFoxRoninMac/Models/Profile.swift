/**
 Profile.swift

 Defines a complete keyboard profile that can be saved to the keyboard's
 on-board memory. Each profile contains RGB settings, key mappings, and macros.

 The EvoFox Ronin has on-board memory that stores profiles directly on the
 keyboard, so settings persist across computers without software.

 A profile includes:
 - Name and ID
 - RGB lighting settings
 - Key remapping configuration
 - Macro definitions
 - Volume knob behavior
 - Polling rate setting
 */

import Foundation

public struct KeyboardProfile: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var rgbSettings: RGBSettings
    public var keyMappings: [KeyMapping]
    public var macros: [KeyboardMacro]
    public var knobBehavior: KnobBehavior
    public var pollingRate: PollingRate
    public var isDefault: Bool
    public var createdAt: Date
    public var modifiedAt: Date

    public enum KnobBehavior: String, Codable, CaseIterable {
        case volumeControl = "Volume Control"
        case brightnessControl = "Brightness Control"
        case scrollControl = "Scroll Control"
        case zoomControl = "Zoom Control"
        case custom = "Custom (Macro)"
    }

    public enum PollingRate: Int, Codable, CaseIterable {
        case hz125 = 125
        case hz250 = 250
        case hz500 = 500
        case hz1000 = 1000

        public var displayName: String {
            return "\(self.rawValue)Hz"
        }
    }

    public init(
        id: UUID = UUID(),
        name: String,
        rgbSettings: RGBSettings = RGBSettings(),
        keyMappings: [KeyMapping] = [],
        macros: [KeyboardMacro] = [],
        knobBehavior: KnobBehavior = .volumeControl,
        pollingRate: PollingRate = .hz1000,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.rgbSettings = rgbSettings
        self.keyMappings = keyMappings
        self.macros = macros
        self.knobBehavior = knobBehavior
        self.pollingRate = pollingRate
        self.isDefault = isDefault
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    /// Returns a default profile with factory settings
    public static func `default`(name: String = "Default") -> KeyboardProfile {
        KeyboardProfile(
            name: name,
            rgbSettings: RGBSettings(
                effect: RGBEffectLibrary.effects[1], // Breathing
                speed: 128,
                brightness: 255,
                primaryColor: .blue,
                secondaryColor: .white
            ),
            keyMappings: RoninLayout.allKeys.map { key in
                KeyMapping(
                    keyPosition: key.position,
                    keyScanCode: key.scanCode,
                    assignedAction: .standardKey(keyCode: key.defaultKeyCode)
                )
            },
            knobBehavior: .volumeControl,
            pollingRate: .hz1000,
            isDefault: true
        )
    }
}

// MARK: - Macro Model

public struct KeyboardMacro: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var triggerKey: KeyPosition?
    public var events: [MacroEvent]
    public var repeatCount: UInt8
    public var delayBetweenRepeats: UInt16 // milliseconds
    public var isActive: Bool

    public enum MacroEventType: String, Codable, Equatable {
        case keyDown
        case keyUp
        case delay
        case mouseDown
        case mouseUp
        case mouseMove
    }

    public struct MacroEvent: Codable, Equatable {
        public var type: MacroEventType
        public var keyCode: UInt16?
        public var modifiers: [KeyAction.ModifierKey]
        public var delayMs: UInt16
        public var mouseX: Int16?
        public var mouseY: Int16?
        public var mouseButton: KeyAction.MouseButton?

        public init(
            type: MacroEventType,
            keyCode: UInt16? = nil,
            modifiers: [KeyAction.ModifierKey] = [],
            delayMs: UInt16 = 0,
            mouseX: Int16? = nil,
            mouseY: Int16? = nil,
            mouseButton: KeyAction.MouseButton? = nil
        ) {
            self.type = type
            self.keyCode = keyCode
            self.modifiers = modifiers
            self.delayMs = delayMs
            self.mouseX = mouseX
            self.mouseY = mouseY
            self.mouseButton = mouseButton
        }
    }

    public init(
        id: UUID = UUID(),
        name: String = "New Macro",
        triggerKey: KeyPosition? = nil,
        events: [MacroEvent] = [],
        repeatCount: UInt8 = 1,
        delayBetweenRepeats: UInt16 = 0,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.triggerKey = triggerKey
        self.events = events
        self.repeatCount = repeatCount
        self.delayBetweenRepeats = delayBetweenRepeats
        self.isActive = isActive
    }

    public var totalDurationMs: UInt16 {
        events.reduce(0) { $0 + $1.delayMs }
    }
}

// MARK: - Profile Manager

@Observable
public class ProfileManager {
    public var profiles: [KeyboardProfile] = []
    public var activeProfileId: UUID?

    public var activeProfile: KeyboardProfile? {
        profiles.first { $0.id == activeProfileId }
    }

    public init() {
        loadProfiles()
        if profiles.isEmpty {
            profiles.append(KeyboardProfile.default())
            activeProfileId = profiles.first?.id
        }
    }

    public func createProfile(name: String) -> KeyboardProfile {
        let profile = KeyboardProfile.default(name: name)
        profiles.append(profile)
        saveProfiles()
        return profile
    }

    public func deleteProfile(id: UUID) {
        profiles.removeAll { $0.id == id }
        if activeProfileId == id {
            activeProfileId = profiles.first?.id
        }
        saveProfiles()
    }

    public func updateProfile(_ profile: KeyboardProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            var updated = profile
            updated.modifiedAt = Date()
            profiles[index] = updated
            saveProfiles()
        }
    }

    public func setActiveProfile(id: UUID) {
        activeProfileId = id
        saveProfiles()
    }

    private func saveProfiles() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(profiles) else {
            Logger.error("Failed to encode profiles")
            return
        }
        let url = profilesFileURL()
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
        } catch {
            Logger.error("Failed to save profiles: \(error.localizedDescription)")
        }
    }

    private func loadProfiles() {
        let url = profilesFileURL()
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else {
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode([KeyboardProfile].self, from: data) else {
            Logger.error("Failed to decode profiles")
            return
        }
        profiles = decoded
        if let firstId = profiles.first?.id {
            activeProfileId = firstId
        }
    }

    private func profilesFileURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("EvoFoxRoninMac/profiles.json")
    }
}
