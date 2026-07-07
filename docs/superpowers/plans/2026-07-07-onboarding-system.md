# Onboarding System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add first-launch onboarding, contextual help overlay, permission management, "What's New" sheet, and keyboard shortcut cheat sheet to the EvoFox Ronin Controller macOS app.

**Architecture:** Four new files under `Sources/EvoFoxRoninMac/Onboarding/` (OnboardingView, HelpOverlay, PermissionManager, ShortcutCheatSheet) plus a WhatsNewSheet. ContentView triggers onboarding and sheets on first launch via UserDefaults. EvoFoxRoninMacApp adds Cmd+? command and refactors permission handling.

**Tech Stack:** SwiftUI, Swift 6.0 strict concurrency, actors, @Observable, existing glassmorphism components (LiquidGlassCard, LiquidGlassButtonStyle, Physics).

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `Sources/EvoFoxRoninMac/Onboarding/PermissionManager.swift` | Create | Actor for Input Monitoring permission check/request |
| `Sources/EvoFoxRoninMac/Onboarding/HelpOverlay.swift` | Create | ViewModifier for tooltips + highlight borders |
| `Sources/EvoFoxRoninMac/Onboarding/OnboardingView.swift` | Create | 4-step first-launch tutorial sheet |
| `Sources/EvoFoxRoninMac/Onboarding/ShortcutCheatSheet.swift` | Create | Keyboard shortcut cheat sheet |
| `Sources/EvoFoxRoninMac/Onboarding/WhatsNewSheet.swift` | Create | Version update notification sheet |
| `Sources/EvoFoxRoninMac/App/EvoFoxRoninMacApp.swift` | Modify | Add Cmd+? command, refactor permission check |
| `Sources/EvoFoxRoninMac/Views/ContentView.swift` | Modify | Add onboarding/sheet triggers on appear |
| `Tests/EvoFoxRoninMacTests/Onboarding/PermissionManagerTests.swift` | Create | Unit tests for PermissionManager |
| `Tests/EvoFoxRoninMacTests/Onboarding/OnboardingTests.swift` | Create | Unit tests for UserDefaults onboarding state |

---

### Task 1: Create PermissionManager

**Files:**
- Create: `Sources/EvoFoxRoninMac/Onboarding/PermissionManager.swift`

- [ ] **Step 1: Create the Onboarding directory**

```bash
mkdir -p Sources/EvoFoxRoninMac/Onboarding
```

- [ ] **Step 2: Create PermissionManager.swift**

```swift
/**
 PermissionManager.swift

 Actor-based manager for macOS Input Monitoring permissions.
 Uses AXIsProcessTrustedWithOptions to check and request permission.
 */

import Foundation
import ApplicationServices

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
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
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
```

- [ ] **Step 3: Verify it compiles**

Run: `swift build 2>&1 | head -30`
Expected: Compiles without errors (PermissionManager is a standalone actor with no dependencies on other new files)

- [ ] **Step 4: Commit**

```bash
git add Sources/EvoFoxRoninMac/Onboarding/PermissionManager.swift
git commit -m "feat: add PermissionManager actor for Input Monitoring permissions"
```

---

### Task 2: Create HelpOverlay

**Files:**
- Create: `Sources/EvoFoxRoninMac/Onboarding/HelpOverlay.swift`

- [ ] **Step 1: Create HelpOverlay.swift**

```swift
/**
 HelpOverlay.swift

 Contextual help view modifier for adding tooltips and optional
 highlight borders to any view.
 */

import SwiftUI

public struct HelpOverlay: ViewModifier {
    let tooltip: String
    let showHighlight: Bool

    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    if showHighlight {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: 2)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            )
            .help(tooltip)
    }
}

public extension View {
    /// Adds a contextual help tooltip with optional highlight border.
    func helpOverlay(_ tooltip: String, showHighlight: Bool = false) -> some View {
        modifier(HelpOverlay(tooltip: tooltip, showHighlight: showHighlight))
    }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `swift build 2>&1 | head -30`
Expected: Compiles without errors

- [ ] **Step 3: Commit**

```bash
git add Sources/EvoFoxRoninMac/Onboarding/HelpOverlay.swift
git commit -m "feat: add HelpOverlay view modifier for contextual help"
```

---

### Task 3: Create ShortcutCheatSheet

**Files:**
- Create: `Sources/EvoFoxRoninMac/Onboarding/ShortcutCheatSheet.swift`

- [ ] **Step 1: Create ShortcutCheatSheet.swift**

```swift
/**
 ShortcutCheatSheet.swift

 Sheet listing all keyboard shortcuts for the EvoFox Ronin Controller.
 Triggered by Cmd+? command.
 */

import SwiftUI

struct ShortcutCheatSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let shortcuts: [(key: String, modifiers: EventModifiers, action: String)] = [
        ("K", .command, String(localized: "shortcuts.connect")),
        ("D", [.command, .shift], String(localized: "shortcuts.disconnect")),
        ("N", [.command, .shift], String(localized: "shortcuts.newProfile")),
        ("S", [.command, .shift], String(localized: "shortcuts.saveToKeyboard")),
        ("?", .command, String(localized: "shortcuts.showShortcuts")),
        ("Q", .command, String(localized: "shortcuts.quit")),
    ]

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("shortcuts.title")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .vibrantText()

                    Text("shortcuts.subtitle")
                        .font(.system(size: 14, weight: .regular))
                        .vibrantText(isSecondary: true)
                }
                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .vibrantText(isSecondary: true)
                }
                .buttonStyle(PlainButtonStyle())
            }

            LiquidGlassCard {
                VStack(spacing: 0) {
                    ForEach(Array(shortcuts.enumerated()), id: \.offset) { index, shortcut in
                        HStack {
                            Text(shortcut.action)
                                .font(.system(size: 14, weight: .regular))
                                .vibrantText()

                            Spacer()

                            ShortcutKeyCombo(key: shortcut.key, modifiers: shortcut.modifiers)
                        }
                        .padding(.vertical, 10)

                        if index < shortcuts.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.1))
                        }
                    }
                }
            }

            Spacer(minLength: 20)
        }
        .padding(32)
        .frame(width: 480, height: 440)
    }
}

// MARK: - Shortcut Key Combo

private struct ShortcutKeyCombo: View {
    let key: String
    let modifiers: EventModifiers

    var body: some View {
        HStack(spacing: 4) {
            if modifiers.contains(.command) {
                KeyBadge(symbol: "\u{2318}")
            }
            if modifiers.contains(.shift) {
                KeyBadge(symbol: "\u{21E7}")
            }
            if modifiers.contains(.option) {
                KeyBadge(symbol: "\u{2325}")
            }
            if modifiers.contains(.control) {
                KeyBadge(symbol: "\u{2303}")
            }
            KeyBadge(symbol: key)
        }
    }
}

// MARK: - Key Badge

private struct KeyBadge: View {
    let symbol: String

    var body: some View {
        Text(symbol)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .frame(minWidth: 26, minHeight: 26)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
    }
}

#Preview {
    ShortcutCheatSheet()
        .background(Color.black)
}
```

- [ ] **Step 2: Verify it compiles**

Run: `swift build 2>&1 | head -30`
Expected: Compiles without errors

- [ ] **Step 3: Commit**

```bash
git add Sources/EvoFoxRoninMac/Onboarding/ShortcutCheatSheet.swift
git commit -m "feat: add ShortcutCheatSheet with all keyboard shortcuts"
```

---

### Task 4: Create WhatsNewSheet

**Files:**
- Create: `Sources/EvoFoxRoninMac/Onboarding/WhatsNewSheet.swift`

- [ ] **Step 1: Create WhatsNewSheet.swift**

```swift
/**
 WhatsNewSheet.swift

 Sheet shown after app updates with version number and key changes.
 Checks UserDefaults for lastSeenVersion against current bundle version.
 */

import SwiftUI

struct WhatsNewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let version: String

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("whatsNew.title")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .vibrantText()

                    Text("whatsNew.version \(version)")
                        .font(.system(size: 14, weight: .regular))
                        .vibrantText(isSecondary: true)
                }
                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .vibrantText(isSecondary: true)
                }
                .buttonStyle(PlainButtonStyle())
            }

            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    WhatsNewFeature(
                        icon: "keyboard.fill",
                        title: String(localized: "whatsNew.feature.onboarding"),
                        description: String(localized: "whatsNew.feature.onboarding.desc")
                    )

                    WhatsNewFeature(
                        icon: "questionmark.circle.fill",
                        title: String(localized: "whatsNew.feature.shortcuts"),
                        description: String(localized: "whatsNew.feature.shortcuts.desc")
                    )

                    WhatsNewFeature(
                        icon: "lock.shield.fill",
                        title: String(localized: "whatsNew.feature.permissions"),
                        description: String(localized: "whatsNew.feature.permissions.desc")
                    )
                }
            }

            Button("whatsNew.gotIt") {
                dismiss()
            }
            .buttonStyle(LiquidGlassButtonStyle(isProminent: true))

            Spacer(minLength: 20)
        }
        .padding(32)
        .frame(width: 480, height: 440)
    }
}

// MARK: - Whats New Feature Row

private struct WhatsNewFeature: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .vibrantText()

                Text(description)
                    .font(.system(size: 12, weight: .regular))
                    .vibrantText(isSecondary: true)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - UserDefaults Helpers

enum WhatsNewManager {
    private static let lastSeenKey = "lastSeenVersion"

    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var shouldShow: Bool {
        let lastSeen = UserDefaults.standard.string(forKey: lastSeenKey)
        return lastSeen != currentVersion
    }

    static func markSeen() {
        UserDefaults.standard.set(currentVersion, forKey: lastSeenKey)
    }
}

#Preview {
    WhatsNewSheet(version: "1.0")
        .background(Color.black)
}
```

- [ ] **Step 2: Verify it compiles**

Run: `swift build 2>&1 | head -30`
Expected: Compiles without errors

- [ ] **Step 3: Commit**

```bash
git add Sources/EvoFoxRoninMac/Onboarding/WhatsNewSheet.swift
git commit -m "feat: add WhatsNewSheet for app update notifications"
```

---

### Task 5: Create OnboardingView

**Files:**
- Create: `Sources/EvoFoxRoninMac/Onboarding/OnboardingView.swift`

- [ ] **Step 1: Create OnboardingView.swift**

```swift
/**
 OnboardingView.swift

 First-launch tutorial presented as a sheet from ContentView.
 Four steps: Connect USB, Grant Permission, Customize RGB, Create Macro.
 */

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(HIDManager.self) private var hidManager

    @State private var currentStep = 0
    @State private var permissionStatus: PermissionStatus = .notDetermined

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 32) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("onboarding.title")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .vibrantText()

                    Text("onboarding.subtitle")
                        .font(.system(size: 14, weight: .regular))
                        .vibrantText(isSecondary: true)
                }
                Spacer()
            }

            // Step content
            LiquidGlassCard {
                VStack(spacing: 20) {
                    stepContent
                }
                .frame(maxWidth: .infinity, minHeight: 260)
            }

            // Step indicator + navigation
            HStack {
                // Skip button
                Button("onboarding.skip") {
                    completeOnboarding()
                }
                .buttonStyle(LiquidGlassButtonStyle())
                .opacity(currentStep < totalSteps - 1 ? 1 : 0)

                Spacer()

                // Step dots
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? Color.accentColor : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.spring(Physics.interactive), value: currentStep)
                    }
                }

                Spacer()

                // Continue / Finish button
                Button(currentStep < totalSteps - 1 ? "onboarding.continue" : "onboarding.finish") {
                    if currentStep < totalSteps - 1 {
                        withAnimation(.spring(Physics.navigation)) {
                            currentStep += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                }
                .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
            }
        }
        .padding(32)
        .frame(width: 560, height: 520)
        .task {
            permissionStatus = await PermissionManager.shared.checkInputMonitoring()
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0: stepConnect
        case 1: stepPermission
        case 2: stepRGB
        case 3: stepMacro
        default: EmptyView()
        }
    }

    // MARK: - Step 1: Connect USB

    private var stepConnect: some View {
        VStack(spacing: 16) {
            Image(systemName: "cable.connector")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.accentColor)
                .padding(.top, 16)

            Text("onboarding.step1.title")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .vibrantText()

            Text("onboarding.step1.description")
                .font(.system(size: 14, weight: .regular))
                .vibrantText(isSecondary: true)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Step 2: Grant Permission

    private var stepPermission: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(permissionStatus == .granted ? .green : .orange)
                .padding(.top, 16)

            Text("onboarding.step2.title")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .vibrantText()

            Text("onboarding.step2.description")
                .font(.system(size: 14, weight: .regular))
                .vibrantText(isSecondary: true)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if permissionStatus != .granted {
                Button("onboarding.step2.openSettings") {
                    Task {
                        await PermissionManager.shared.openSystemPreferences()
                    }
                }
                .buttonStyle(LiquidGlassButtonStyle(isProminent: true, tint: .orange))
                .padding(.top, 8)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("onboarding.step2.granted")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Step 3: RGB Lighting

    private var stepRGB: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.purple)
                .padding(.top, 16)

            Text("onboarding.step3.title")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .vibrantText()

            Text("onboarding.step3.description")
                .font(.system(size: 14, weight: .regular))
                .vibrantText(isSecondary: true)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Static preview of RGB controls
            HStack(spacing: 12) {
                PreviewBadge(color: .red, label: "R")
                PreviewBadge(color: .green, label: "G")
                PreviewBadge(color: .blue, label: "B")
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Step 4: Create Macro

    private var stepMacro: some View {
        VStack(spacing: 16) {
            Image(systemName: "record.circle.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.red)
                .padding(.top, 16)

            Text("onboarding.step4.title")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .vibrantText()

            Text("onboarding.step4.description")
                .font(.system(size: 14, weight: .regular))
                .vibrantText(isSecondary: true)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Static preview of macro steps
            HStack(spacing: 8) {
                MacroStepBadge(icon: "arrow.down.circle.fill", label: "Key Down")
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                MacroStepBadge(icon: "clock", label: "50ms")
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                MacroStepBadge(icon: "arrow.up.circle.fill", label: "Key Up")
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Helpers

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        dismiss()
    }
}

// MARK: - Preview Badges

private struct PreviewBadge: View {
    let color: Color
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.8))
            )
    }
}

private struct MacroStepBadge: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .vibrantText(isSecondary: true)
        }
        .frame(width: 72, height: 52)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}

#Preview {
    OnboardingView()
        .environment(HIDManager(mockMode: true))
        .background(Color.black)
}
```

- [ ] **Step 2: Verify it compiles**

Run: `swift build 2>&1 | head -30`
Expected: Compiles without errors

- [ ] **Step 3: Commit**

```bash
git add Sources/EvoFoxRoninMac/Onboarding/OnboardingView.swift
git commit -m "feat: add OnboardingView with 4-step first-launch tutorial"
```

---

### Task 6: Modify ContentView to trigger onboarding and sheets

**Files:**
- Modify: `Sources/EvoFoxRoninMac/Views/ContentView.swift:59-90`

- [ ] **Step 1: Add state properties to ContentView**

In `ContentView.swift`, add these properties after line 66 (`@State private var showPollingRateSettings = false`):

```swift
    @State private var showOnboarding = false
    @State private var showShortcutCheatSheet = false
    @State private var showWhatsNew = false
```

- [ ] **Step 2: Add onAppear logic for triggering sheets**

Replace the existing `.onAppear` block (lines 86-89) with:

```swift
        .onAppear {
            Logger.debug("ContentView.onAppear — calling hidManager.connect()")
            hidManager.connect()

            // Check if onboarding is needed
            if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                showOnboarding = true
            }

            // Check if What's New should be shown
            if WhatsNewManager.shouldShow {
                showWhatsNew = true
            }
        }
```

- [ ] **Step 3: Add sheet modifiers to ContentView body**

Add these sheet modifiers right after the `.onAppear` block (before the closing `}` of the `body` property's ZStack):

```swift
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
                .environment(hidManager)
        }
        .sheet(isPresented: $showShortcutCheatSheet) {
            ShortcutCheatSheet()
        }
        .sheet(isPresented: $showWhatsNew) {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            WhatsNewSheet(version: version)
                .onDisappear {
                    WhatsNewManager.markSeen()
                }
        }
```

- [ ] **Step 4: Verify it compiles**

Run: `swift build 2>&1 | head -30`
Expected: Compiles without errors

- [ ] **Step 5: Commit**

```bash
git add Sources/EvoFoxRoninMac/Views/ContentView.swift
git commit -m "feat: trigger onboarding, shortcuts, and whats-new sheets from ContentView"
```

---

### Task 7: Modify EvoFoxRoninMacApp for Cmd+? and PermissionManager

**Files:**
- Modify: `Sources/EvoFoxRoninMac/App/EvoFoxRoninMacApp.swift`

- [ ] **Step 1: Add a Notification.Name for shortcut cheat sheet**

Add this extension at the end of the file (after the `AppDelegate` class):

```swift
// MARK: - Notification for Shortcut Cheat Sheet

extension Notification.Name {
    static let showShortcutCheatSheet = Notification.Name("com.evofox.ronin.showShortcutCheatSheet")
}
```

- [ ] **Step 2: Add Cmd+? command to CommandMenu**

In the `CommandMenu("app.menu.keyboard")` block, add a new button after the "Disable Mock Mode" button (after line 60):

```swift
                Divider()

                Button("app.menu.shortcuts") {
                    NotificationCenter.default.post(name: .showShortcutCheatSheet, object: nil)
                }
                .keyboardShortcut("?", modifiers: .command)
```

- [ ] **Step 3: Refactor AppDelegate to use PermissionManager**

Replace the `checkInputMonitoringPermission()` method in `AppDelegate` (lines 161-184) with:

```swift
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
```

- [ ] **Step 4: Update ContentView to listen for the notification**

In `ContentView.swift`, add a notification listener in the `.onAppear` block (after the existing sheet triggers):

```swift
            // Listen for shortcut cheat sheet notification from menu
            NotificationCenter.default.addObserver(
                forName: .showShortcutCheatSheet,
                object: nil,
                queue: .main
            ) { _ in
                showShortcutCheatSheet = true
            }
```

- [ ] **Step 5: Verify it compiles**

Run: `swift build 2>&1 | head -30`
Expected: Compiles without errors

- [ ] **Step 6: Commit**

```bash
git add Sources/EvoFoxRoninMac/App/EvoFoxRoninMacApp.swift Sources/EvoFoxRoninMac/Views/ContentView.swift
git commit -m "feat: add Cmd+? shortcut and refactor permission check to use PermissionManager"
```

---

### Task 8: Add unit tests

**Files:**
- Create: `Tests/EvoFoxRoninMacTests/Onboarding/PermissionManagerTests.swift`
- Create: `Tests/EvoFoxRoninMacTests/Onboarding/OnboardingTests.swift`

- [ ] **Step 1: Create test directory**

```bash
mkdir -p Tests/EvoFoxRoninMacTests/Onboarding
```

- [ ] **Step 2: Create PermissionManagerTests.swift**

```swift
/**
 PermissionManagerTests.swift

 Tests for the PermissionManager actor.
 */

import Testing
@testable import EvoFoxRoninMac

@Suite("PermissionManager")
struct PermissionManagerTests {

    @Test("PermissionManager shared instance exists")
    func sharedInstanceExists() async {
        let manager = PermissionManager.shared
        let status = await manager.checkInputMonitoring()
        // Status depends on system state, just verify it returns a valid value
        #expect(status == .granted || status == .denied || status == .notDetermined || status == .unknown)
    }

    @Test("PermissionManager checkInputMonitoring returns PermissionStatus")
    func checkReturnsValidStatus() async {
        let manager = PermissionManager()
        let status = await manager.checkInputMonitoring()
        #expect(status == .granted || status == .denied || status == .notDetermined || status == .unknown)
    }
}
```

- [ ] **Step 3: Create OnboardingTests.swift**

```swift
/**
 OnboardingTests.swift

 Tests for onboarding UserDefaults state management.
 */

import Testing
@testable import EvoFoxRoninMac

@Suite("Onboarding State")
struct OnboardingTests {

    @Test("Onboarding completion persists in UserDefaults")
    func onboardingCompletionPersists() async {
        let key = "hasCompletedOnboarding"
        // Set to completed
        UserDefaults.standard.set(true, forKey: key)
        #expect(UserDefaults.standard.bool(forKey: key) == true)

        // Reset for other tests
        UserDefaults.standard.removeObject(forKey: key)
    }

    @Test("Onboarding not completed by default")
    func onboardingNotCompletedByDefault() async {
        let key = "hasCompletedOnboarding"
        UserDefaults.standard.removeObject(forKey: key)
        #expect(UserDefaults.standard.bool(forKey: key) == false)
    }

    @Test("WhatsNewManager detects version correctly")
    func whatsNewManagerVersionDetection() async {
        let version = WhatsNewManager.currentVersion
        #expect(!version.isEmpty)
    }

    @Test("WhatsNewManager markSeen updates UserDefaults")
    func whatsNewManagerMarkSeen() async {
        let key = "lastSeenVersion"
        let version = WhatsNewManager.currentVersion
        WhatsNewManager.markSeen()
        #expect(UserDefaults.standard.string(forKey: key) == version)

        // Reset for other tests
        UserDefaults.standard.removeObject(forKey: key)
    }
}
```

- [ ] **Step 4: Run tests**

Run: `swift test 2>&1 | tail -20`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add Tests/EvoFoxRoninMacTests/Onboarding/
git commit -m "test: add unit tests for PermissionManager and onboarding state"
```

---

### Task 9: Build verification and final commit

- [ ] **Step 1: Full build**

Run: `swift build 2>&1`
Expected: Build succeeds with no errors

- [ ] **Step 2: Run all tests**

Run: `swift test 2>&1`
Expected: All tests pass

- [ ] **Step 3: Final commit if any fixups needed**

```bash
git add -A
git commit -m "fix: address build/test issues from onboarding integration"
```
