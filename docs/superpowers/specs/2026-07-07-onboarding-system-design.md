# Onboarding System Design

## Overview

Add a first-launch onboarding flow, contextual help overlay, permission management, "What's New" sheet, and keyboard shortcut cheat sheet to the EvoFox Ronin Controller macOS app.

## Files

### New: `Sources/EvoFoxRoninMac/Onboarding/OnboardingView.swift`

First-launch tutorial presented as a `.sheet` from `ContentView`. Triggered when `UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")` is `false`.

**Steps:**
1. **Connect your keyboard via USB** — Icon: `cable.connector`, instructs user to physically connect the keyboard
2. **Grant Input Monitoring permission** — Icon: `lock.shield.fill`, includes button to open System Settings via deep link (`x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent`)
3. **Customize your RGB lighting** — Icon: `lightbulb.fill`, static screenshot/icon preview of RGB panel (informational only, no interaction)
4. **Create your first macro** — Icon: `record.circle.fill`, static screenshot/icon preview of macro editor (informational only, no interaction)

**UI pattern:**
- Uses `LiquidGlassCard` for step content (matches existing glassmorphism)
- Step indicator at bottom (dots or progress bar)
- "Skip" button and "Continue"/"Finish" button
- Physics-based step transitions using `Physics.navigation` spring
- `@Environment(HIDManager.self)` for permission status checking
- On completion, sets `UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")`

### New: `Sources/EvoFoxRoninMac/Onboarding/HelpOverlay.swift`

Contextual help view modifier for adding tooltips and optional highlight borders to any view.

```swift
struct HelpOverlay: ViewModifier {
    let tooltip: String
    let showHighlight: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    if showHighlight {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: 2)
                            .background(Color.accentColor.opacity(0.1))
                    }
                }
            )
            .help(tooltip)
    }
}
```

**Usage:**
```swift
Text("Some content")
    .modifier(HelpOverlay(tooltip: "This is helpful", showHighlight: true))
```

### New: `Sources/EvoFoxRoninMac/Onboarding/PermissionManager.swift`

Actor-based permission manager for macOS Input Monitoring permissions.

```swift
public enum PermissionStatus {
    case unknown, granted, denied, notDetermined
}

public actor PermissionManager {
    public static let shared = PermissionManager()

    public func requestInputMonitoring() async -> PermissionStatus {
        // Uses AXIsProcessTrustedWithOptions to check/request permission
        // Returns .granted if trusted, .denied if not, .notDetermined if first request
    }

    public func openSystemPreferences() {
        // Opens x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent
    }
}
```

**Integration:** Replace existing permission logic in `AppDelegate.checkInputMonitoringPermission()` with calls to `PermissionManager.shared`.

### New: `Sources/EvoFoxRoninMac/Onboarding/ShortcutCheatSheet.swift`

Sheet view listing all keyboard shortcuts. Triggered by Cmd+? command.

**Shortcuts displayed:**
| Shortcut | Action |
|----------|--------|
| Cmd+K | Connect keyboard |
| Cmd+Shift+D | Disconnect keyboard |
| Cmd+Shift+N | New profile |
| Cmd+Shift+S | Save profile to keyboard |
| Cmd+? | Show keyboard shortcuts |
| Cmd+Q | Quit app |

**UI:** Presented as a sheet, uses `LiquidGlassCard` with monospaced key styling.

### Modified: `Sources/EvoFoxRoninMac/Views/ContentView.swift`

- Add `@State private var showOnboarding = false`
- Add `@State private var showShortcutCheatSheet = false`
- On `onAppear`: check `UserDefaults` for `hasCompletedOnboarding`, set `showOnboarding = true` if false
- Add `.sheet(isPresented: $showOnboarding)` for `OnboardingView`
- Add `.sheet(isPresented: $showShortcutCheatSheet)` for `ShortcutCheatSheet`

### Modified: `Sources/EvoFoxRoninMac/App/EvoFoxRoninMacApp.swift`

- Add Cmd+? command in `CommandMenu` for shortcut cheat sheet
- Refactor `AppDelegate.checkInputMonitoringPermission()` to use `PermissionManager`

### What's New Sheet

- Check `UserDefaults.standard.string(forKey: "lastSeenVersion")` against `Bundle.main.infoDictionary?["CFBundleShortVersionString"]`
- If different (or nil), show "What's New" sheet with version number and key changes
- On dismiss, update `lastSeenVersion` to current version
- Triggered from `ContentView.onAppear`

## UserDefaults Keys

| Key | Type | Purpose |
|-----|------|---------|
| `hasCompletedOnboarding` | `Bool` | Whether onboarding has been completed |
| `lastSeenVersion` | `String` | Last version shown in "What's New" sheet |

## Dependencies

- Existing: `LiquidGlassCard`, `LiquidGlassButtonStyle`, `Physics`, `HIDManager`, `Logger`
- No new external dependencies

## Testing

- Unit test `PermissionManager.requestInputMonitoring()` returns correct status
- Unit test UserDefaults-based onboarding/completion detection
- UI test onboarding sheet presents on first launch
- UI test cheat sheet opens with Cmd+?
