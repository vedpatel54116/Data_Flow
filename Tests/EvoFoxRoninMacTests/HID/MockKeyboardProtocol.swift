import Foundation
@testable import EvoFoxRoninMac

final class MockKeyboardProtocol: @preconcurrency KeyboardCommunicationProtocol {
    let descriptor: KeyboardDescriptor
    var shouldFail = false
    var failCount = 0
    private var callCount = 0

    var setRGBCalls: [RGBSettings] = []
    var setKeyMappingCalls: [KeyMapping] = []
    var setMacroCalls: [KeyboardMacro] = []
    var setPollingRateCalls: [KeyboardProfile.PollingRate] = []
    var saveToOnboardMemoryCalls = 0

    init(descriptor: KeyboardDescriptor = KeyboardDescriptor(
        id: "evofox.ronin.v1",
        manufacturer: "EvoFox",
        model: "Ronin TKL",
        vendorID: 0x1234,
        productID: 0x5678,
        capabilities: [.rgbLighting, .perKeyRGB, .macroProgramming, .keyRemapping, .mediaKnob, .pollingRateConfig, .onboardMemory, .nKeyRollover],
        layout: .tenkeyless,
        protocolVersion: 1,
        maxMacros: 20,
        maxProfiles: 4,
        rgbZones: 1,
        firmwareURL: nil,
        communityVerified: true
    )) {
        self.descriptor = descriptor
    }

    func connect(to device: HIDDeviceInfo) async -> Result<Void, HIDError> {
        if shouldFail {
            return .failure(.connectionFailed)
        }
        return .success(())
    }

    func disconnect() async {}

    func setRGB(_ settings: RGBSettings) async -> Result<Void, HIDError> {
        setRGBCalls.append(settings)
        return await maybeFail()
    }

    func getRGB() async -> Result<RGBSettings, HIDError> {
        if shouldFail { return .failure(.invalidResponse) }
        return .success(RGBSettings())
    }

    func setKeyMapping(_ mapping: KeyMapping) async -> Result<Void, HIDError> {
        setKeyMappingCalls.append(mapping)
        return await maybeFail()
    }

    func getKeyMappings() async -> Result<[KeyMapping], HIDError> {
        if shouldFail { return .failure(.invalidResponse) }
        return .success([])
    }

    func setMacro(_ macro: KeyboardMacro) async -> Result<Void, HIDError> {
        setMacroCalls.append(macro)
        return await maybeFail()
    }

    func getMacros() async -> Result<[KeyboardMacro], HIDError> {
        if shouldFail { return .failure(.invalidResponse) }
        return .success([])
    }

    func setPollingRate(_ rate: KeyboardProfile.PollingRate) async -> Result<Void, HIDError> {
        setPollingRateCalls.append(rate)
        return await maybeFail()
    }

    func getPollingRate() async -> Result<KeyboardProfile.PollingRate, HIDError> {
        if shouldFail { return .failure(.invalidResponse) }
        return .success(.hz1000)
    }

    func saveToOnboardMemory() async -> Result<Void, HIDError> {
        saveToOnboardMemoryCalls += 1
        return await maybeFail()
    }

    private func maybeFail() async -> Result<Void, HIDError> {
        callCount += 1
        if shouldFail && callCount <= failCount {
            return .failure(.timeout)
        }
        return .success(())
    }

    func reset() {
        shouldFail = false
        failCount = 0
        callCount = 0
        setRGBCalls = []
        setKeyMappingCalls = []
        setMacroCalls = []
        setPollingRateCalls = []
        saveToOnboardMemoryCalls = 0
    }
}
