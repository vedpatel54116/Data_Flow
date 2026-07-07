import Foundation
@testable import EvoFoxRoninMac

@MainActor
class MockHIDManager: HIDManager {
    var sentReports: [[UInt8]] = []
    var shouldSucceed: Bool = true
    var mockError: HIDError?

    override init() {
        super.init(mockMode: true)
    }

    override func sendReport(data: [UInt8]) -> Result<Void, HIDError> {
        sentReports.append(data)
        if let error = mockError {
            return .failure(error)
        }
        return shouldSucceed ? .success(()) : .failure(.deviceNotFound)
    }

    override func sendFeatureReport(data: [UInt8], reportID: UInt8) -> Result<Void, HIDError> {
        sentReports.append(data)
        return shouldSucceed ? .success(()) : .failure(.deviceNotFound)
    }

    func clearSentReports() {
        sentReports.removeAll()
    }
}
