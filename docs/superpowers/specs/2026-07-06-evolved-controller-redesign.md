# EvoFox Ronin Controller — Evolutionary Redesign Spec

**Date:** 2026-07-06
**Status:** In Progress
**Approach:** B — Layered Rewrite (Keep Core, Rewrite Views)

---

## 1. Why This Approach?

The current app has a **rock-solid foundation** (HID layer, glassmorphism system, physics animations) but its **views and user-facing features are the weak point** — basic keyboard visualizer, no real-time feedback, simple macro editor, manual profile syncing. A Layered Rewrite keeps what works and rewrites the rest.

**What We Keep:**
- `HID/` layer (device discovery, scoring, mock mode, background threading)
- `Glassmorphism/` system (GlassTokens, GlassView, NoiseOverlay — integrated properly)
- `Models/` base (RGBEffect, KeyMap, Profile — with versioning added)
- `Physics.swift` (proven physics constants)

**What We Rewrite:**
- All 5 views (Connection, RGB, Key Remap, Macros, Profiles)
- `KeyboardVisualizer` — real-time key press feedback, better animations
- `MacroEditorView` — full scripting editor
- `ProfileManager` — iCloud sync, versioning, migration
- `AppDelegate` / `EvoFoxRoninMacApp` — onboarding flow
- Data layer — versioned persistence + cloud sync

---

## 2. Architecture Overview

```
┌─────────────────────────────────────┐
│           SwiftUI Views (NEW)        │
│  Connection  RGB  KeyRemap  Macros  Profiles  Onboarding
├─────────────────────────────────────┤
│     ViewModels (NEW) — @Observable   │
│  KeyboardViewModel, MacroViewModel   │
├─────────────────────────────────────┤
│     Services (NEW/MODIFIED)          │
│  RealTimeKeyTracker, CloudSyncService│
│  MacroScriptEngine, ProfileMigrator  │
├─────────────────────────────────────┤
│     Core (KEEP — partially)          │
│  HIDManager, KeyboardProtocol        │
│  (Glassmorphism components polished) │
├─────────────────────────────────────┤
│     Data Layer (NEW)                 │
│  VersionedPersistence, iCloudSync    │
└─────────────────────────────────────┘
```

### Key Architectural Principles

1. **Single Source of Truth:** `ProfileManager` is the single source of truth. All views read from it, write through it. No direct mutations in views.
2. **ViewModel Layer:** Each view has a `@Observable` `ViewModel` that acts as the intermediary between the view and the services.
3. **Service Layer:** Services handle domain logic (e.g., `MacroScriptEngine` validates and runs macro scripts). Views NEVER call HID directly.
4. **Versioned Persistence:** Profiles are versioned. Old profiles are automatically migrated on load. Cloud sync is transparent.
5. **Real-Time Feedback:** A `RealTimeKeyTracker` service listens to global keyboard events and publishes key press state. `KeyboardVisualizer` subscribes to this.

---

## 3. Feature Specs

### 3.1 Real-Time Keyboard Feedback
- **What:** When a key is pressed on the physical keyboard, the corresponding key in the `KeyboardVisualizer` lights up in real-time.
- **How:** `RealTimeKeyTracker` uses `CGEventTap` to listen for global keyboard events. It maps the key code to the `KeyInfo` position and publishes a `KeyPressEvent`.
- **Performance:** Events are debounced (16ms) to prevent UI flooding. Visualizer uses `CATransaction` for 60fps updates.
- **Privacy:** Only key codes (not characters) are tracked. No data is logged or transmitted. A prominent toggle in Settings disables this.

### 3.2 Cloud Sync & Backup (iCloud)
- **What:** Profiles automatically sync to iCloud. Users can restore on a new Mac.
- **How:** `CloudSyncService` uses `NSUbiquitousKeyValueStore` for lightweight sync and `NSFileCoordinator` + `NSMetadataQuery` for the full profile JSON file.
- **Conflict Resolution:** Last-write-wins with a merge strategy for non-conflicting changes. Conflicting changes show a merge UI.
- **Offline:** Full offline support. Changes are queued and synced when online.

### 3.3 Advanced Macro Editor
- **What:** A full scripting editor for macros with delays, mouse events, if/else logic, and conditionals.
- **How:** `MacroScriptEngine` defines a DSL (Domain Specific Language) for macros. Macros are compiled to a bytecode-like format and sent to the keyboard.
- **Features:**
  - **Record:** Record keyboard and mouse events.
  - **Edit:** Drag-and-drop event reordering.
  - **Script:** Write macros in a simple script (e.g., `repeat 5 { key "A"; delay 100ms; }`).
  - **Conditions:** `if key "Shift" pressed { ... }`.
- **Safety:** Maximum 255 events per macro. Recursion is not allowed.

### 3.4 Per-Key LED Customization
- **What:** Paint individual keys with different colors and save as custom presets.
- **How:** `KeyboardVisualizer` enters "paint mode". Clicking a key opens a color picker. The `perKeyColor` map in `KeyboardProfile` stores the colors.
- **Presets:** Users can save the current per-key layout as a named preset. Presets appear in the effect grid.

### 3.5 Game Mode
- **What:** A per-profile toggle that disables the Windows key, sets N-key rollover, and applies a custom polling rate.
- **How:** `GameModeService` sends the appropriate HID packets when enabled. A visual indicator (small badge on the app icon) shows when Game Mode is active.
- **Profile Link:** Game Mode settings are part of `KeyboardProfile`. Switching profiles switches Game Mode settings.

### 3.6 Onboarding / Welcome Wizard
- **What:** A first-run wizard that guides users through connecting the keyboard, setting up their first profile, and explaining features.
- **How:** `OnboardingView` is a multi-step SwiftUI view. Progress is saved to `UserDefaults`. The wizard can be re-opened from the Help menu.
- **Steps:**
  1. Welcome + app overview
  2. Connect keyboard + permission setup
  3. Choose first RGB effect + colors
  4. Optional: Set up key remapping
  5. Optional: Record first macro
  6. Finish — link to docs + community

---

## 4. UI/UX Design System

### 4.1 Philosophy: Apple-Native Glass
- Use pure `NSVisualEffectView` + macOS native materials.
- Minimal noise, no SVG filters. Let macOS handle the glass.
- Focus on clarity, legibility, and accessibility.

### 4.2 Component System
Replace the current mix of `GlassCard`, `LiquidGlassCard`, `GlassButton`, `LiquidGlassButton` with a single, unified component library:

| Component | Role | Material |
|-----------|------|----------|
| `Panel` | Content containers | `.sheet` |
| `Sidebar` | Navigation | `.sidebar` (macOS 15+) or `.sheet` |
| `Card` | Floating content panels | `.hudWindow` |
| `Button.primary` | Main actions | `.control` (prominent) |
| `Button.secondary` | Secondary actions | `.control` |
| `Toggle` | On/Off switches | `.control` |
| `Slider` | Value adjustments | `.control` |

All components use `GlassTokens` for sizing, spacing, and animation constants.

### 4.3 Accessibility
- **VoiceOver:** All interactive elements have clear labels and hints.
- **Reduce Motion:** All animations respect `prefersReducedMotion`.
- **High Contrast:** All glass surfaces have sufficient contrast ratios.
- **Keyboard Navigation:** Full keyboard navigation through all tabs and settings.

---

## 5. Data & Persistence

### 5.1 Versioned Persistence

Profiles are stored as versioned JSON:

```json
{
  "version": 2,
  "profiles": [
    {
      "id": "...",
      "name": "Gaming",
      "rgbSettings": { ... },
      "keyMappings": [ ... ],
      "macros": [ ... ],
      "gameMode": { ... },
      "perKeyColors": { ... }
    }
  ]
}
```

On load, `ProfileMigrator` checks the version. If `version < currentVersion`, it runs the migration chain.

### 5.2 Migration Chain
- `v1 -> v2:` Add `gameMode` and `perKeyColors` fields with defaults.
- `v2 -> v3:` Add macro script version field.

### 5.3 iCloud Sync
- Uses `NSFileCoordinator` for conflict-free file access.
- `CloudSyncService` listens for `NSMetadataQuery` updates.
- Sync is automatic and transparent. A small cloud icon in the status bar shows sync state.

---

## 6. New Service Layer

### 6.1 RealTimeKeyTracker
```swift
@Observable
class RealTimeKeyTracker {
    var activeKeys: Set<KeyPosition> = []

    func startTracking() { /* CGEventTap */ }
    func stopTracking() { /* Remove tap */ }
}
```

### 6.2 MacroScriptEngine
```swift
class MacroScriptEngine {
    func compile(script: String) -> Result<MacroBytecode, MacroError>
    func execute(bytecode: MacroBytecode) -> [MacroEvent]
}
```

### 6.3 CloudSyncService
```swift
@Observable
class CloudSyncService {
    var syncState: SyncState = .idle

    func syncProfiles(_ profiles: [KeyboardProfile]) async
    func downloadProfiles() async -> [KeyboardProfile]
}
```

### 6.4 ProfileMigrator
```swift
class ProfileMigrator {
    static func migrate(profileData: Data) -> Result<KeyboardProfile, MigrationError>
}
```

---

## 7. Performance & Reliability

### 7.1 Performance Targets
- **UI Thread:** 60fps animation, <16ms response to user input.
- **HID Communication:** <50ms command-to-keyboard latency.
- **Cold Start:** <2 seconds from launch to fully interactive.

### 7.2 Reliability
- **Crash Recovery:** If the app crashes during a profile save, the last known good state is restored from a backup.
- **HID Reconnection:** Automatic reconnection on device disconnect/reconnect.
- **Data Integrity:** Checksums on all profile JSON. Corrupted profiles are quarantined and reported.

---

## 8. Testing Strategy

- **Unit Tests:** All ViewModels, Services, and the ProfileMigrator.
- **Integration Tests:** Cloud sync round-trip, HID command encoding, macro script compilation.
- **UI Tests (XCUITest):** Onboarding flow, profile switching, macro recording.

---

## 9. Implementation Phases

### Phase 1: Foundation (Week 1-2)
- [ ] Set up versioned persistence + migration
- [ ] Refactor `ProfileManager` to use new data layer
- [ ] Create `RealTimeKeyTracker` service
- [ ] Implement new `KeyboardVisualizer` with real-time feedback

### Phase 2: Core Features (Week 3-4)
- [ ] Rewrite `RGBControlView` with per-key customization
- [ ] Rewrite `MacroEditorView` with script support
- [ ] Rewrite `KeyRemapView` with search and better UX
- [ ] Rewrite `ProfileManagerView` with cloud backup UI

### Phase 3: Polish & Sync (Week 5-6)
- [ ] Implement `CloudSyncService` (iCloud)
- [ ] Add Game Mode toggle and settings
- [ ] Build Onboarding flow
- [ ] Accessibility pass (VoiceOver, Reduce Motion)

### Phase 4: Release & Iterate (Week 7+)
- [ ] Beta testing with real users
- [ ] Performance tuning
- [ ] Documentation update
- [ ] App Store submission

---

## 10. App Store Submission Plan

### 10.1 Pre-Submission Checklist
- [ ] **Code Signing:** Valid Apple Developer ID certificate for distribution outside App Store, or App Store certificate for Mac App Store.
- [ ] **App Sandbox & Entitlements:**
  - [ ] `com.apple.security.device.usb` — for HID device access
  - [ ] `com.apple.security.app-sandbox` — required for Mac App Store
  - [ ] `com.apple.security.temporary-exception.mach-lookup.global-name` — may be needed for IOKit
- [ ] **Privacy Manifest (PrivacyInfo.xcprivacy):**
  - Declares no data collection (keyboard events are processed locally, never transmitted)
  - If keyboard input tracking is implemented, must declare `NSPrivacyAccessedAPICategoryKeyboardEventTap`
- [ ] **Screenshots:** 5 screenshots (1280x800) for each locale showing Connection, RGB, Key Remap, Macros, and Profiles tabs.
- [ ] **App Icon:** 1024x1024 PNG, following Apple Human Interface Guidelines.
- [ ] **Description & Keywords:**
  - **Title:** EvoFox Ronin Controller for Mac
  - **Subtitle:** RGB, macros & key remapping for your EvoFox keyboard
  - **Keywords:** EvoFox, Ronin, mechanical keyboard, RGB, macro, key remap, gaming keyboard, TKL, macOS keyboard software
- [ ] **Age Rating:** 4+ (no violence, no mature content)

### 10.2 Notarization (if distributing outside App Store)
- Build with `swift build -c release`
- Sign with `codesign --force --deep --sign "Developer ID Application: ..."`
- Notarize with `xcrun notarytool submit`
- Staple with `xcrun stapler staple`

### 10.3 In-App Purchase / Monetization
- **Free:** Basic RGB control, single profile, key remapping
- **Pro (one-time IAP ~$4.99):** Unlimited profiles, cloud sync, advanced macro scripting, per-key LED
- **Pro+ subscription ($1.99/month):** Everything + priority support, future beta access, community presets

### 10.4 Review Preparation
- **Review Notes:** Explain that the app requires USB HID access for keyboard communication. Provide a demo video of the app functionality.
- **Demo Account:** Not applicable (no online account required).
- **Contact:** Support email for Apple review team.

## 11. Open Questions

1. **Script DSL Syntax:** What should the macro scripting language look like? Simple key-value or more expressive?
2. **iCloud Quota:** Should we warn users if their profile collection exceeds iCloud's free tier?
3. **Beta Distribution:** TestFlight for internal testing, or direct Xcode builds?
4. **Free vs. Pro Feature Split:** Is the current monetization model acceptable, or should everything be free with donations?
5. **Windows Port:** Should the architecture be designed with a future Windows version in mind (e.g., abstracted HID layer)?

---

## 12. Summary

This spec outlines an **evolutionary rewrite** of the EvoFox Ronin Controller. We keep the proven HID and glassmorphism layers, add a robust service layer for new features, and completely rewrite the user-facing views for a modern, accessible, and delightful experience. The architecture is designed for testability, offline-first use, and future extensibility.

---

## 11. Summary

This spec outlines an **evolutionary rewrite** of the EvoFox Ronin Controller. We keep the proven HID and glassmorphism layers, add a robust service layer for new features, and completely rewrite the user-facing views for a modern, accessible, and delightful experience. The architecture is designed for testability, offline-first use, and future extensibility.
