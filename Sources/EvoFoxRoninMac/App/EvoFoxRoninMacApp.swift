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
                .frame(minWidth: 1100, minHeight: 720)
                .onAppear {
                    Logger.debug("EvoFoxRoninMacApp body onAppear — hidManager instance: \(Unmanaged.passUnretained(hidManager).toOpaque())")
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandMenu("Keyboard") {
                Button("Connect") {
                    hidManager.connect()
                }
                .keyboardShortcut("K", modifiers: .command)

                Button("Disconnect") {
                    hidManager.disconnect()
                }
                .keyboardShortcut("D", modifiers: [.command, .shift])

                Divider()

                Button("Enable Mock Mode") {
                    hidManager.enableMockMode()
                }

                Button("Disable Mock Mode") {
                    hidManager.disableMockMode()
                }
            }

            CommandMenu("Profile") {
                Button("New Profile") {
                    // Trigger new profile creation
                }
                .keyboardShortcut("N", modifiers: [.command, .shift])

                Button("Save to Keyboard") {
                    // Save active profile to keyboard memory
                }
                .keyboardShortcut("S", modifiers: [.command, .shift])
            }
        }

        #if os(macOS)
        MenuBarExtra("EvoFox Ronin", systemImage: "keyboard.fill") {
            VStack {
                Text("EvoFox Ronin Controller")
                    .font(.headline)
                Text(hidManager.connectionState.displayText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                Button("Open Window") {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    if let window = NSApplication.shared.windows.first {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .keyboardShortcut("O", modifiers: .command)

                Divider()

                Button("Connect") {
                    hidManager.connect()
                }
                .disabled(hidManager.connectionState.isConnected)

                Button("Disconnect") {
                    hidManager.disconnect()
                }
                .disabled(!hidManager.connectionState.isConnected)

                Divider()

                Button("Start at Login") {
                    toggleStartAtLogin()
                }

                Divider()

                Button("Quit") {
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
        // macOS requires Input Monitoring permission for HID device access.
        // We test by attempting to open an IOHIDManager — if permission is denied,
        // IOHIDManagerOpen returns kIOReturnNotPermitted.
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(manager, nil)
        
        guard let runLoop = CFRunLoopGetMain() else { return }
        IOHIDManagerScheduleWithRunLoop(manager, runLoop, CFRunLoopMode.defaultMode.rawValue)
        
        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        
        if result == kIOReturnSuccess {
            Logger.info("Input Monitoring permission: GRANTED")
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        } else if result == kIOReturnNotPermitted {
            Logger.warning("Input Monitoring permission: NOT GRANTED")
            // Show system prompt for Input Monitoring permission
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        } else {
            Logger.warning("HID Manager open failed with code: 0x\(String(format: "%08X", result))")
        }
    }
}
