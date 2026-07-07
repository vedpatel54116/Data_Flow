import Foundation

public actor KeyboardDatabaseLoader {
    public static let shared = KeyboardDatabaseLoader()

    private var cachedDatabase: [KeyboardDescriptor]?

    private let remoteDatabaseURL = URL(string: "https://raw.githubusercontent.com/anomalyco/EvoFoxRoninMac/main/Resources/KeyboardDatabase.json")!
    private let cacheFilename = "cached_keyboard_database.json"

    public func loadDatabase() async throws -> [KeyboardDescriptor] {
        if let cached = cachedDatabase { return cached }

        if let bundled = try? loadBundledDatabase() {
            cachedDatabase = bundled
            return bundled
        }

        let remote = try? await fetchRemoteDatabase()
        if let remote = remote {
            try? saveToCache(remote)
            cachedDatabase = remote
            return remote
        }

        return KeyboardDatabase.supportedKeyboards
    }

    public func forceReload() async throws -> [KeyboardDescriptor] {
        cachedDatabase = nil
        return try await loadDatabase()
    }

    private func loadBundledDatabase() throws -> [KeyboardDescriptor] {
        guard let url = Bundle.main.url(forResource: "KeyboardDatabase", withExtension: "json") else {
            throw LoadError.bundledResourceNotFound
        }
        let data = try Data(contentsOf: url)
        let container = try JSONDecoder().decode(KeyboardDatabaseContainer.self, from: data)
        return container.keyboards.map { $0.toDescriptor() }
    }

    private func fetchRemoteDatabase() async throws -> [KeyboardDescriptor] {
        var request = URLRequest(url: remoteDatabaseURL)
        request.timeoutInterval = 10
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw LoadError.remoteFetchFailed
        }
        let container = try JSONDecoder().decode(KeyboardDatabaseContainer.self, from: data)
        return container.keyboards.map { $0.toDescriptor() }
    }

    private func saveToCache(_ descriptors: [KeyboardDescriptor]) throws {
        let data = try JSONEncoder().encode(descriptors)
        try data.write(to: cacheFileURL(), options: .atomic)
    }

    private func cacheFileURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("EvoFoxRoninMac/\(cacheFilename)")
    }

    public enum LoadError: Error, LocalizedError, Sendable {
        case bundledResourceNotFound
        case remoteFetchFailed

        public var errorDescription: String? {
            switch self {
            case .bundledResourceNotFound: return "Keyboard database not found in app bundle"
            case .remoteFetchFailed: return "Failed to fetch keyboard database from remote"
            }
        }
    }
}

private struct KeyboardDatabaseContainer: Decodable {
    let version: String
    let keyboards: [RawKeyboardDescriptor]
}

private struct RawKeyboardDescriptor: Decodable {
    let id: String
    let manufacturer: String
    let model: String
    let vendorID: String
    let productID: String
    let capabilities: [String]
    let layout: String
    let protocolVersion: UInt8
    let maxMacros: Int
    let maxProfiles: Int
    let rgbZones: Int
    let firmwareURL: String?
    let communityVerified: Bool

    func toDescriptor() -> KeyboardDescriptor {
        KeyboardDescriptor(
            id: id,
            manufacturer: manufacturer,
            model: model,
            vendorID: parseHex(vendorID),
            productID: parseHex(productID),
            capabilities: parseCapabilities(capabilities),
            layout: KeyboardDescriptor.KeyboardLayoutType(rawValue: layout) ?? .fullSize,
            protocolVersion: protocolVersion,
            maxMacros: maxMacros,
            maxProfiles: maxProfiles,
            rgbZones: rgbZones,
            firmwareURL: firmwareURL,
            communityVerified: communityVerified
        )
    }

    private func parseHex(_ string: String) -> UInt16 {
        let cleaned = string.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "0x", with: "")
            .replacingOccurrences(of: "0X", with: "")
        return UInt16(cleaned, radix: 16) ?? 0
    }

    private func parseCapabilities(_ strings: [String]) -> KeyboardCapabilities {
        var value: UInt32 = 0
        for s in strings {
            switch s {
            case "rgbLighting":      value |= KeyboardCapabilities.rgbLighting.rawValue
            case "perKeyRGB":        value |= KeyboardCapabilities.perKeyRGB.rawValue
            case "macroProgramming": value |= KeyboardCapabilities.macroProgramming.rawValue
            case "keyRemapping":     value |= KeyboardCapabilities.keyRemapping.rawValue
            case "mediaKnob":        value |= KeyboardCapabilities.mediaKnob.rawValue
            case "pollingRateConfig": value |= KeyboardCapabilities.pollingRateConfig.rawValue
            case "onboardMemory":    value |= KeyboardCapabilities.onboardMemory.rawValue
            case "nKeyRollover":     value |= KeyboardCapabilities.nKeyRollover.rawValue
            case "wireless":         value |= KeyboardCapabilities.wireless.rawValue
            default: break
            }
        }
        return KeyboardCapabilities(rawValue: value)
    }
}
