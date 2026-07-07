/**
 Logger.swift

 Simple debug logging utility for the EvoFox Ronin app.

 Logs HID communication, profile changes, and errors to help with
 troubleshooting and reverse-engineering the keyboard protocol.

 Usage:
   Logger.log("Connecting to keyboard...")
   Logger.log("Sent packet: \(packet)", level: .debug)
   Logger.error("HID device not found")
*/

import Foundation

public enum LogLevel: String, CaseIterable, Sendable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"

    public var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

public struct Logger {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    public static nonisolated(unsafe) var isEnabled: Bool = true
    public static nonisolated(unsafe) var minimumLevel: LogLevel = .debug

    public static func log(_ message: String, level: LogLevel = .info, file: String = #file, line: Int = #line) {
        guard isEnabled else { return }
        guard shouldLog(level: level) else { return }

        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        print("[\(timestamp)] \(level.emoji) [\(level.rawValue)] \(fileName):\(line) — \(message)")
    }

    public static func debug(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .debug, file: file, line: line)
    }

    public static func info(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .info, file: file, line: line)
    }

    public static func warning(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .warning, file: file, line: line)
    }

    public static func error(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .error, file: file, line: line)
    }

    public static func logHIDPacket(_ packet: [UInt8], direction: String) {
        let hexString = packet.map { String(format: "%02X", $0) }.joined(separator: " ")
        log("HID \(direction): \(hexString)", level: .debug)
    }

    private static func shouldLog(level: LogLevel) -> Bool {
        let levels = LogLevel.allCases
        guard let currentIndex = levels.firstIndex(of: level),
              let minimumIndex = levels.firstIndex(of: minimumLevel) else {
            return true
        }
        return currentIndex >= minimumIndex
    }
}
