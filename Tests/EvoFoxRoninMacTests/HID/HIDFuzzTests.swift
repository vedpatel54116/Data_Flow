import XCTest
@testable import EvoFoxRoninMac

@MainActor
final class HIDFuzzTests: XCTestCase {
    let mockManager = MockHIDManager()
    lazy var protocol_ = EvoFoxRoninProtocol(hidManager: mockManager)

    func testDecodeEmptyPacket() {
        let result = protocol_.decodeResponse(packet: [])
        if case .failure(let error) = result {
            XCTAssertEqual(error, .readFailed)
        } else {
            XCTFail("Expected readFailed for empty packet")
        }
    }

    func testDecodeSingleBytePacket() {
        let result = protocol_.decodeResponse(packet: [0x07])
        if case .failure(let error) = result {
            XCTAssertEqual(error, .readFailed)
        } else {
            XCTFail("Expected readFailed for single byte packet")
        }
    }

    func testDecodeTwoBytePacket() {
        let result = protocol_.decodeResponse(packet: [0x07, 0x00])
        if case .failure(let error) = result {
            XCTAssertEqual(error, .readFailed)
        } else {
            XCTFail("Expected readFailed for two byte packet")
        }
    }

    func testDecodeThreeBytePacket() {
        let packet: [UInt8] = [0x07, 0x00, 0x01]
        let result = protocol_.decodeResponse(packet: packet)
        if case .success(let response) = result {
            XCTAssertEqual(response.reportID, 0x07)
            XCTAssertEqual(response.status, 0x00)
            XCTAssertEqual(response.commandType, 0x01)
            XCTAssertTrue(response.isSuccess)
            XCTAssertTrue(response.data.isEmpty)
        } else {
            XCTFail("Expected success for three byte packet")
        }
    }

    func testDecodeMaxSizePacket() {
        var packet = [UInt8](repeating: 0xFF, count: 4096)
        packet[0] = 0x07
        packet[1] = 0x00
        packet[2] = 0x01
        let result = protocol_.decodeResponse(packet: packet)
        if case .success(let response) = result {
            XCTAssertEqual(response.reportID, 0x07)
            XCTAssertEqual(response.status, 0x00)
            XCTAssertEqual(response.commandType, 0x01)
            XCTAssertEqual(response.data.count, 4093)
        } else {
            XCTFail("Expected success for large packet")
        }
    }

    func testDecodeAllPossibleStatusBytes() {
        for statusByte: UInt8 in 0...255 {
            let packet: [UInt8] = [0x07, statusByte, 0x01]
            let result = protocol_.decodeResponse(packet: packet)
            if case .success(let response) = result {
                let expectSuccess = (statusByte == 0x00 || statusByte == 0x01)
                XCTAssertEqual(response.isSuccess, expectSuccess,
                              "Status 0x\(String(format: "%02X", statusByte)) isSuccess should be \(expectSuccess)")
                XCTAssertEqual(response.reportID, 0x07)
                XCTAssertEqual(response.commandType, 0x01)
            } else {
                XCTFail("Expected success for status byte 0x\(String(format: "%02X", statusByte))")
            }
        }
    }

    func testDecodeRandomGarbage() {
        for seed in 0..<50 {
            var rng = SeededRNG(seed: UInt64(seed))
            let size = Int(rng.next() % 128)
            var packet = [UInt8](repeating: 0, count: size)
            for i in 0..<size {
                packet[i] = UInt8(rng.next() & 0xFF)
            }
            let result = protocol_.decodeResponse(packet: packet)
            switch result {
            case .success(let response):
                XCTAssertLessThanOrEqual(response.reportID, 0xFF)
                XCTAssertLessThanOrEqual(response.status, 0xFF)
                XCTAssertEqual(response.data.count, max(0, packet.count - 3))
            case .failure(let error):
                XCTAssertEqual(error, .readFailed)
            }
        }
    }

    func testDecodeNullBytes() {
        let packet = [UInt8](repeating: 0, count: 64)
        let result = protocol_.decodeResponse(packet: packet)
        if case .success(let response) = result {
            XCTAssertTrue(response.isSuccess, "All-zero packet should be success (status=0)")
            XCTAssertEqual(response.reportID, 0)
            XCTAssertEqual(response.status, 0)
            XCTAssertEqual(response.commandType, 0)
            XCTAssertEqual(response.data.count, 61)
        } else {
            XCTFail("Expected success for zero-filled 64-byte packet")
        }
    }

    func testDecodeOnlySuccessBytes() {
        var packet = [UInt8](repeating: 0x00, count: 64)
        packet[0] = 0x01
        let result = protocol_.decodeResponse(packet: packet)
        if case .success(let response) = result {
            XCTAssertTrue(response.isSuccess)
            XCTAssertEqual(response.reportID, 0x01)
        }
    }

    func testDecodePacketWithMaxValues() {
        var packet = [UInt8](repeating: 0xFF, count: 64)
        packet[1] = 0x00
        let result = protocol_.decodeResponse(packet: packet)
        if case .success(let response) = result {
            XCTAssertTrue(response.isSuccess)
            XCTAssertEqual(response.reportID, 0xFF)
            XCTAssertEqual(response.commandType, 0xFF)
            XCTAssertEqual(response.data.count, 61)
            XCTAssertTrue(response.data.allSatisfy { $0 == 0xFF })
        }
    }
}

/// Simple deterministic pseudo-random number generator for fuzzing.
private struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let xorshifted = ((state >> 18) ^ state) >> 27
        let rot = state >> 59
        return (xorshifted >> Int(rot)) | (xorshifted << Int((-Int64(rot)) & 63))
    }
}
