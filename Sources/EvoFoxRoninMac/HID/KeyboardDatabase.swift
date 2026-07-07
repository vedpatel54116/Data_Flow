/// Central registry of supported keyboards and their protocols.
public struct KeyboardDatabase: Sendable {
    public static let supportedKeyboards: [KeyboardDescriptor] = [
        // EvoFox
        KeyboardDescriptor(
            id: "evofox.ronin.v1",
            manufacturer: "EvoFox",
            model: "Ronin",
            vendorID: 0x1234,
            productID: 0x5678,
            capabilities: [.rgbLighting, .perKeyRGB, .macroProgramming,
                          .keyRemapping, .mediaKnob, .pollingRateConfig, .onboardMemory],
            layout: .fullSize,
            protocolVersion: 1,
            maxMacros: 5,
            maxProfiles: 3,
            rgbZones: 104,
            firmwareURL: "https://evofox.com/firmware/ronin",
            communityVerified: true
        ),

        // Add more vendors here:
        KeyboardDescriptor(
            id: "razer.blackwidow.v3",
            manufacturer: "Razer",
            model: "BlackWidow V3",
            vendorID: 0x1532,
            productID: 0x024E,
            capabilities: [.rgbLighting, .perKeyRGB, .macroProgramming],
            layout: .fullSize,
            protocolVersion: 2,
            maxMacros: 0,
            maxProfiles: 1,
            rgbZones: 104,
            firmwareURL: nil,
            communityVerified: false
        ),

        KeyboardDescriptor(
            id: "corsair.k70.rgb",
            manufacturer: "Corsair",
            model: "K70 RGB",
            vendorID: 0x1B1C,
            productID: 0x1B13,
            capabilities: [.rgbLighting, .perKeyRGB, .pollingRateConfig, .onboardMemory],
            layout: .fullSize,
            protocolVersion: 3,
            maxMacros: 0,
            maxProfiles: 3,
            rgbZones: 104,
            firmwareURL: nil,
            communityVerified: false
        ),

        KeyboardDescriptor(
            id: "keychron.q1",
            manufacturer: "Keychron",
            model: "Q1",
            vendorID: 0x3434,
            productID: 0x0101,
            capabilities: [.rgbLighting, .keyRemapping, .onboardMemory],
            layout: .compact75,
            protocolVersion: 1,
            maxMacros: 0,
            maxProfiles: 4,
            rgbZones: 82,
            firmwareURL: nil,
            communityVerified: false
        ),

        KeyboardDescriptor(
            id: "generic.hid.rgb",
            manufacturer: "Generic",
            model: "HID RGB Keyboard",
            vendorID: 0x0000,
            productID: 0x0000,
            capabilities: [.rgbLighting],
            layout: .fullSize,
            protocolVersion: 0,
            maxMacros: 0,
            maxProfiles: 1,
            rgbZones: 0,
            firmwareURL: nil,
            communityVerified: false
        )
    ]

    public static func descriptor(for device: HIDDeviceInfo) -> KeyboardDescriptor? {
        if let exact = supportedKeyboards.first(where: {
            $0.vendorID == device.vendorID && $0.productID == device.productID
        }) {
            return exact
        }

        if device.usagePage >= 0xFF00 || device.usagePage == 0x01 {
            return supportedKeyboards.first { $0.id == "generic.hid.rgb" }
        }

        return nil
    }

    public static func makeProtocol(for descriptor: KeyboardDescriptor, hidManager: HIDManager) -> KeyboardCommunicationProtocol {
        switch descriptor.id {
        case "evofox.ronin.v1":
            return EvoFoxRoninProtocol(hidManager: hidManager)
        default:
            return EvoFoxRoninProtocol(hidManager: hidManager)
        }
    }
}
