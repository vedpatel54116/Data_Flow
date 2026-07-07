/// Defines capabilities that a keyboard may or may not support.
/// Used to conditionally show/hide UI features.
public struct KeyboardCapabilities: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: UInt32

    public static let rgbLighting      = KeyboardCapabilities(rawValue: 1 << 0)
    public static let perKeyRGB        = KeyboardCapabilities(rawValue: 1 << 1)
    public static let macroProgramming = KeyboardCapabilities(rawValue: 1 << 2)
    public static let keyRemapping     = KeyboardCapabilities(rawValue: 1 << 3)
    public static let mediaKnob        = KeyboardCapabilities(rawValue: 1 << 4)
    public static let pollingRateConfig = KeyboardCapabilities(rawValue: 1 << 5)
    public static let onboardMemory    = KeyboardCapabilities(rawValue: 1 << 6)
    public static let nKeyRollover     = KeyboardCapabilities(rawValue: 1 << 7)
    public static let wireless         = KeyboardCapabilities(rawValue: 1 << 8)

    public init(rawValue: UInt32) { self.rawValue = rawValue }

    /// The capabilities that are enabled in this set, in display order.
    public var enabledCapabilities: [KeyboardCapabilities] {
        KeyboardCapabilities.allCases.filter { contains($0) }
    }
}

extension KeyboardCapabilities: CaseIterable {
    public static let allCases: [KeyboardCapabilities] = [
        .rgbLighting, .perKeyRGB, .macroProgramming, .keyRemapping,
        .mediaKnob, .pollingRateConfig, .onboardMemory,
        .nKeyRollover, .wireless,
    ]
}
