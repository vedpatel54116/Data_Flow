import Foundation

/// Defines the interface for communicating with a specific keyboard model.
public protocol KeyboardCommunicationProtocol: AnyObject {
    /// Describes which keyboard this protocol instance targets.
    var descriptor: KeyboardDescriptor { get }

    /// Connect to a discovered HID device.
    func connect(to device: HIDDeviceInfo) async -> Result<Void, HIDError>

    /// Disconnect from the keyboard.
    func disconnect() async

    /// Set the full RGB lighting configuration.
    func setRGB(_ settings: RGBSettings) async -> Result<Void, HIDError>

    /// Read the current RGB configuration from the keyboard.
    func getRGB() async -> Result<RGBSettings, HIDError>

    /// Remap a single key.
    func setKeyMapping(_ mapping: KeyMapping) async -> Result<Void, HIDError>

    /// Retrieve the current key mappings.
    func getKeyMappings() async -> Result<[KeyMapping], HIDError>

    /// Save a macro to the keyboard.
    func setMacro(_ macro: KeyboardMacro) async -> Result<Void, HIDError>

    /// Retrieve saved macros from the keyboard.
    func getMacros() async -> Result<[KeyboardMacro], HIDError>

    /// Set the USB polling rate.
    func setPollingRate(_ rate: KeyboardProfile.PollingRate) async -> Result<Void, HIDError>

    /// Get the current polling rate.
    func getPollingRate() async -> Result<KeyboardProfile.PollingRate, HIDError>

    /// Persist current settings to onboard memory.
    func saveToOnboardMemory() async -> Result<Void, HIDError>
}
