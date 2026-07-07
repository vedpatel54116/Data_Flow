/**
 EvoFoxRoninMacApp.swift

 Main app entry point for the EvoFox Ronin Controller.

 Sets up the macOS app with:
 - Native window chrome with glassmorphism
 - Proper menu bar
 - State management via environment objects
 - Initial keyboard connection attempt
*/

import SwiftUI
import AppKit
import ApplicationServices
import IOKit
import IOKit.hid
import ServiceManagement

@main
struct EvoFoxRoninMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var hidManager = HIDManager(mockMode: false)
    @State private var profileManager = ProfileManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(hidManager)
                .environment(profileManager)
                .environment(\.layoutDirection, .leftToRight)
                .frame(minWidth: 1100, minHeight: 720)
                .onAppear {
                    Logger.debug("EvoFoxRoninMacApp body onAppear — hidManager instance: \(Unmanaged.passUnretained(hidManager).toOpaque())")
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandMenu("app.menu.keyboard") {
                Button("app.menu.connect") {
                    hidManager.connect()
                }
                .keyboardShortcut("K", modifiers: .command)

                Button("app.menu.disconnect") {
                    hidManager.disconnect()
                }
                .keyboardShortcut("D", modifiers: [.command, .shift])

                Divider()

                Button("app.menu.enableMock") {
                    hidManager.enableMockMode()
                }

                Button("app.menu.disableMock") {
                    hidManager.disableMockMode()
                }

                Divider()

                Button("app.menu.shortcuts") {
                    NotificationCenter.default.post(name: .showShortcutCheatSheet, object: nil)
                }
                .keyboardShortcut("?", modifiers: .command)
            }

            CommandMenu("app.menu.profile") {
                Button("app.menu.newProfile") {
                }
                .keyboardShortcut("N", modifiers: [.command, .shift])

                Button("app.menu.saveToKeyboard") {
                }
                .keyboardShortcut("S", modifiers: [.command, .shift])
            }
        }

        #if os(macOS)
        MenuBarExtra("app.menubar.title", systemImage: "keyboard.fill") {
            VStack {
                Text("app.menubar.controller")
                    .font(.headline)
                Text(hidManager.connectionState.displayText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                Button("app.menubar.openWindow") {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    if let window = NSApplication.shared.windows.first {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .keyboardShortcut("O", modifiers: .command)

                Divider()

                Button("app.menu.connect") {
                    hidManager.connect()
                }
                .disabled(hidManager.connectionState.isConnected)

                Button("app.menu.disconnect") {
                    hidManager.disconnect()
                }
                .disabled(!hidManager.connectionState.isConnected)

                Divider()

                Button("app.menubar.startAtLogin") {
                    toggleStartAtLogin()
                }

                Divider()

                Button("app.menubar.quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("Q", modifiers: .command)
            }
        }
        .menuBarExtraStyle(.menu)
        .environment(hidManager)
        .environment(profileManager)
        #endif
    }

    private func toggleStartAtLogin() {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            if service.status == .enabled {
                try? service.unregister()
            } else {
                try? service.register()
            }
        }
    }
}

// MARK: - Notification for Shortcut Cheat Sheet

extension Notification.Name {
    static let showShortcutCheatSheet = Notification.Name("com.evofox.ronin.showShortcutCheatSheet")
}

// MARK: - App Delegate for Custom Window Setup

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up window appearance
        if let window = NSApplication.shared.windows.first {
            // Enable full-size content view for glassmorphism edge-to-edge
            window.styleMask.insert(.fullSizeContentView)
            window.titlebarAppearsTransparent = true
            window.backgroundColor = NSColor.clear
            window.isOpaque = false
            window.hasShadow = true

            // Set minimum window size
            window.minSize = NSSize(width: 1100, height: 720)

            // Center window on screen
            window.center()
        }

        // Request input monitoring permission if needed
        checkInputMonitoringPermission()
    }

    private func checkInputMonitoringPermission() {
        Task {
            let status = await PermissionManager.shared.requestInputMonitoring()
            switch status {
            case .granted:
                Logger.info("Input Monitoring permission: GRANTED via PermissionManager")
            case .denied:
                Logger.warning("Input Monitoring permission: DENIED via PermissionManager")
            case .notDetermined, .unknown:
                Logger.info("Input Monitoring permission: status=\(status)")
            }
        }
    }
}
