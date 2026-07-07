/**
 PermissionManager.swift
 
 Actor-based manager for macOS Input Monitoring permissions.
 Uses AXIsProcessTrustedWithOptions to check and request permission.
 */

@preconcurrency import Foundation
@preconcurrency import ApplicationServices
import AppKit

public enum PermissionStatus: Sendable {
    case unknown
    case granted
    case denied
    case notDetermined
}

public actor PermissionManager {
    public static let shared = PermissionManager()

    private var hasRequested = false

    public init() {}

    /// Check current Input Monitoring permission status without prompting.
    public func checkInputMonitoring() -> PermissionStatus {
        let trusted = AXIsProcessTrusted()
        if trusted {
            return .granted
        }
        return hasRequested ? .denied : .notDetermined
    }

    /// Request Input Monitoring permission (shows system prompt on first call).
    public func requestInputMonitoring() async -> PermissionStatus {
        let trusted = await MainActor.run {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }
        hasRequested = true

        if trusted {
            Logger.info("Input Monitoring permission: GRANTED")
            return .granted
        } else {
            Logger.warning("Input Monitoring permission: NOT GRANTED")
            return .denied
        }
    }

    /// Open System Settings > Privacy & Security > Input Monitoring.
    public func openSystemPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }
}
