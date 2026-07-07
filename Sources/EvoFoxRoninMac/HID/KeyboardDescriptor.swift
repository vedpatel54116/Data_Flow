/// Describes a specific keyboard model and its communication protocol.
public struct KeyboardDescriptor: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let manufacturer: String
    public let model: String
    public let vendorID: UInt16
    public let productID: UInt16
    public let capabilities: KeyboardCapabilities
    public let layout: KeyboardLayoutType
    public let protocolVersion: UInt8
    public let maxMacros: Int
    public let maxProfiles: Int
    public let rgbZones: Int
    public let firmwareURL: String?
    public let communityVerified: Bool

    public enum KeyboardLayoutType: String, Codable, Sendable {
        case fullSize, tenkeyless, compact75, compact60, ergonomic
    }
}
