# Multi-Keyboard macOS Control App - Design Specification

## Overview

Build a best-in-class macOS keyboard control application that supports multiple gaming keyboard brands (EvoFox Ronin, Keychron, NuPhy, and extensible to others) through a unified HID framework. The app features a hybrid menubar + window UX, native liquid glassmorphism, physics-based animations, and full reverse-engineered HID protocol support.

---

## Architecture

### High-Level Structure

```
KeyboardController/
├── App/
│   ├── KeyboardControllerApp.swift          # App entry point, menubar + window setup
│   ├── AppDelegate.swift                    # Window configuration, permissions
│   └── MenuBarController.swift              # Menubar icon, quick actions, status
├── Core/
│   ├── KeyboardFramework/                   # Generic HID framework (extensible)
│   │   ├── HIDTransport.swift               # IOKit HID communication
│   │   ├── DeviceDiscovery.swift            # Device enumeration, matching, scoring
│   │   ├── ProtocolAbstraction.swift        # Command/response abstraction layer
│   │   ├── PacketBuilder.swift              # HID packet construction
│   │   └── DeviceProtocol.swift             # Per-device protocol implementations
│   ├── Models/
│   │   ├── KeyboardDevice.swift             # Device identity, capabilities
│   │   ├── KeyboardProfile.swift            # Profile with RGB, keymaps, macros
│   │   ├── RGBEffect.swift                  # Effect definitions, categories
│   │   ├── KeyMapping.swift                 # Key remapping model
│   │   └── Macro.swift                      # Macro recording/playback
│   ├── Persistence/
│   │   ├── ProfileStore.swift               # SwiftData profile persistence
│   │   ├── DeviceRegistry.swift             # Known device definitions
│   │   └── SettingsStore.swift              # App settings
│   └── Services/
│       ├── ConnectionManager.swift          # Device connection lifecycle
│       ├── ProfileSyncService.swift         # Bidirectional profile sync
│       └── FirmwareService.swift            # Firmware detection/update
├── UI/
│   ├── Menubar/
│   │   ├── MenuBarView.swift                # Menubar popover content
│   │   ├── QuickActionsView.swift           # Quick toggles, profile switcher
│   │   └── ConnectionStatusView.swift       # Live connection indicator
│   ├── Window/
│   │   ├── MainWindow.swift                 # Main window with sidebar
│   │   ├── Sidebar.swift                    # Glass sidebar navigation
│   │   ├── ContentArea.swift                # Content panels (no glass)
│   │   └── WindowController.swift           # Window management
│   ├── Panels/
│   │   ├── DashboardPanel.swift             # Overview, quick status
│   │   ├── RGBPanel.swift                   # RGB lighting control
│   │   ├── KeymapPanel.swift                # Key remapping UI
│   │   ├── MacroPanel.swift                 # Macro editor
│   │   ├── ProfilesPanel.swift              # Profile management
│   │   ├── DevicePanel.swift                # Device settings, firmware
│   │   └── SettingsPanel.swift              # App settings
│   ├── Components/
│   │   ├── KeyboardVisualizer.swift         # Animated keyboard rendering
│   │   ├── GlassCard.swift                  # Liquid glass card
│   │   ├── GlassButton.swift                # Glass button styles
│   │   ├── LiquidToggle.swift               # Physics-based toggle
│   │   ├── EffectGrid.swift                 # RGB effect selection
│   │   ├── ColorPicker.swift                # HSV color picker
│   │   ├── Slider.swift                     # Glass slider
│   │   └── KeyActionPicker.swift            # Key remapping action selector
│   └── DesignSystem/
│       ├── GlassTokens.swift                # Design constants
│       ├── Physics.swift                    # Spring constants
│       ├── ColorExtensions.swift            # Color utilities
│       └── ViewModifiers.swift              # Glass focus, press effects
├── Resources/
│   ├── KeyboardLayouts/                     # JSON layout definitions
│   │   ├── RoninTKL.json
│   │   ├── KeychronK2.json
│   │   └── NuPhyAir75.json
│   └── DeviceDefinitions/                   # Known device VID/PID/protocols
│       ├── evofox.yaml
│       ├── keychron.yaml
│       └── nupht.yaml
└── Tests/
    ├── Unit/
    │   ├── HIDTransportTests.swift
    │   ├── DeviceDiscoveryTests.swift
    │   ├── PacketBuilderTests.swift
    │   ├── ProfileStoreTests.swift
    │   └── KeyboardLayoutTests.swift
    └── Integration/
        ├── DeviceConnectionTests.swift
        └── ProfileSyncTests.swift
```

### Data Flow

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   User UI   │────▶│  ConnectionMgr   │────▶│  HIDTransport   │
│  (Panels)   │     │  (State Machine) │     │  (IOKit)        │
└─────────────┘     └──────────────────┘     └─────────────────┘
                           │                         │
                           ▼                         ▼
                    ┌──────────────┐          ┌──────────────┐
                    │ ProfileStore │◀────────▶│ Protocol     │
                    │ (SwiftData)  │  Sync    │ Abstraction  │
                    └──────────────┘          └──────────────┘
```

---

## Core Components

### 1. Keyboard Framework (Extensible HID Layer)

**DeviceDiscovery** - Enumerates all HID devices, scores matches against known device definitions, presents candidates.

**HIDTransport** - Low-level IOKit communication: open/close, send/receive reports, async callbacks, error handling, reconnection logic.

**ProtocolAbstraction** - Defines generic commands: `SetRGBEffect`, `SetKeyMapping`, `SaveMacro`, `SaveProfile`, `GetFirmwareVersion`. Each device protocol implements these.

**PacketBuilder** - Constructs 64-byte HID output reports from generic commands. Device-specific implementations handle byte layout.

**DeviceProtocol** - Protocol that each keyboard brand implements:
```swift
protocol KeyboardProtocol {
    var deviceType: DeviceType { get }
    func buildPacket(for command: KeyboardCommand) -> [UInt8]
    func parseResponse(_ data: [UInt8]) -> KeyboardResponse?
    func getCapabilities() -> DeviceCapabilities
}
```

### 2. Device Definitions (Data-Driven)

YAML files define known devices:
```yaml
# evofox.yaml
vendor_id: 0x320F
product_ids: [0x5055]
name: "EvoFox Ronin TKL"
layout: "RoninTKL"
protocol: "EvoFoxProtocol"
capabilities:
  rgb: true
  per_key_rgb: true
  macros: true
  key_remap: true
  profiles: 4
  volume_knob: true
  polling_rates: [125, 250, 500, 1000]
```

### 3. Profile System

**KeyboardProfile** - Complete configuration: RGB settings, key mappings, macros, knob behavior, polling rate. Stored locally via SwiftData, synced to keyboard on-board memory.

**ProfileSyncService** - Bidirectional sync: "Save to Keyboard" pushes full profile; "Load from Keyboard" reads on-board profile (if supported).

### 4. UI Architecture

**Menubar Controller** - Always-running, shows connection status, quick profile switch, RGB toggle, opens main window.

**Main Window** - Glass sidebar (navigation layer) + content panels (content layer, NO glass). Physics springs for all transitions.

**Panels**KeyboardVisualizer** - Real-time animated preview of RGB effects on accurate keyboard layout. Supports all effect categories.

---

## Glassmorphism Implementation

### Principles (Apple WWDC 2025)
- Glass on NAVIGATION layer only (sidebar, floating controls)
- Content layer has NO glass - opaque cards on vibrant background
- Never stack glass on glass
- Use `.behindWindow` blending for true depth
- Native `NSVisualEffectView` materials: `.sheet`, `.hudWindow`, `.menu`

### Design Tokens (GlassTokens.swift)
```swift
noiseOpacity: 0.03
highlightTopOpacity: 0.30
borderOpacity: 0.15
borderWidth: 0.5
cornerRadiusCard: 24
cornerRadiusButton: 12
```

### Physics Springs (Physics.swift)
```swift
navigation: response 0.45, damping 0.82
interactive: response 0.25, damping 0.72
morph: response 0.55, damping 0.68
content: response 0.55, damping 0.75
```

---

## HID Protocol Reverse-Engineering

### Capture Process
1. Windows VM + Wireshark + USBPcap
2. Connect keyboard, start capture
3. Use official software for each feature
4. Export packet captures per feature
5. Analyze byte patterns, build protocol implementation

### Protocol Coverage Needed
| Feature | Command Type | Priority |
|---------|--------------|----------|
| RGB Effect Select | Output Report | P0 |
| RGB Color/Speed/Brightness | Output Report | P0 |
| Per-Key RGB | Output Report (multi-packet) | P0 |
| Key Remap | Output Report | P0 |
| Macro Save | Output Report (multi-packet) | P0 |
| Profile Save/Load | Output/Feature Report | P0 |
| Volume Knob Config | Output Report | P1 |
| Polling Rate | Output Report | P1 |
| Firmware Version | Feature Report | P1 |
| Factory Reset | Output Report | P2 |

---

## Multi-Keyboard Support

### Initial Target Devices
1. **EvoFox Ronin TKL** - Primary target, 79-key, per-key RGB, macros, volume knob
2. **Keychron K2/K3/K6/K8** - Popular Mac mechanical, RGB, hot-swappable
3. **NuPhy Air75/Halo75** - Low-profile, Mac-native, good HID support

### Extensibility
New keyboard = add YAML device definition + protocol implementation + layout JSON. No core changes.

---

## Testing Strategy

### Unit Tests
- Device scoring algorithm
- Packet building/parsing per protocol
- Profile serialization/deserialization
- Layout rendering accuracy

### Integration Tests
- Device connect/disconnect cycles
- Profile round-trip (app → keyboard → app)
- Mock mode full UI exercise

### Manual Testing Checklist
- [ ] Menubar shows correct status
- [ ] Window opens/closes properly
- [ ] All panels navigate smoothly
- [ ] RGB effects preview matches keyboard
- [ ] Key remap applies and persists
- [ ] Macro records, plays back, saves
- [ ] Profile save/load works
- [ ] Mock mode exercises all UI

---

## Success Criteria

1. **Connects reliably** to EvoFox Ronin TKL on macOS 14+
2. **All 21 RGB effects** work with live preview
3. **Full key remapping** with visual keyboard UI
4. **Macro recording/editing** with on-board save
5. **Profile management** (create, switch, save to keyboard)
6. **Menubar quick access** for common actions
7. **Extensible framework** - adding Keychron takes < 1 day
8. **Native feel** - glassmorphism, physics, proper macOS conventions
9. **Mock mode** enables full UI development without hardware
10. **Documentation** for reverse-engineering new devices

---

## Non-Goals (YAGNI)

- Cross-platform (Windows/Linux) - macOS only
- Cloud sync - local only
- Firmware flashing - too risky without vendor support
- Audio-reactive RGB - requires microphone permission, complex
- Game-specific profiles - out of scope
- Scripting/automation API - maybe later

---

## Timeline Estimate

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| Foundation (Framework, Models, Persistence) | 2 weeks | Working HID transport, device discovery, SwiftData |
| EvoFox Protocol (Reverse-engineer + Implement) | 2-3 weeks | All Ronin features working |
| UI Core (Menubar, Window, Glass System) | 1.5 weeks | Navigable app with physics animations |
| Panels (RGB, Keymap, Macro, Profiles) | 2 weeks | Full feature panels |
| Multi-Keyboard (Keychron, NuPhy) | 1 week | 2 additional keyboards |
| Polish, Testing, Documentation | 1 week | Production-ready app |
| **Total** | **~9-10 weeks** | **v1.0 Release** |