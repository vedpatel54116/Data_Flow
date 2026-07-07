# EvoFox Ronin Controller for macOS

> A native macOS control application for the **EvoFox Ronin TKL Wired Mechanical Keyboard** — built with proper Apple glassmorphism, physics-based animations, and direct HID communication.

![Platform](https://img.shields.io/badge/platform-macOS%2014+-blue)
![Language](https://img.shields.io/badge/language-Swift%205.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## The Problem

The EvoFox Ronin keyboard ships with **Windows-only software**. Its advanced features — per-key RGB, macro programming, key remapping, and on-board profiles — are inaccessible to Mac users. This app fixes that.

---

## Features

| Feature | Description |
|---------|-------------|
| **Per-Key RGB** | Control all 79 keys individually with 21 built-in effects + custom modes |
| **Macro Programming** | Record and assign macros to any key with on-board memory storage |
| **Key Remapping** | Remap any key to any other key, function, or macro |
| **Profile Management** | Save, load, and switch between multiple profiles |
| **Volume Knob** | Configure the dedicated volume/brightness controller behavior |
| **Live Preview** | See RGB changes in real-time before saving to keyboard |
| **Apple Glassmorphism** | Native `NSVisualEffectView` with proper materials, vibrancy, and depth |
| **Physics Animations** | Spring-based animations with proper mass, stiffness, and damping |

---

## Architecture

```
EvoFoxRoninMac/
├── Sources/
│   ├── App/
│   │   └── EvoFoxRoninMacApp.swift          # App entry point
│   ├── Glassmorphism/
│   │   ├── GlassView.swift                  # NSVisualEffectView wrapper
│   │   ├── GlassTokens.swift                # Design tokens (radius, padding, fonts)
│   │   ├── ThemeEnvironment.swift           # Theme environment injection
│   │   ├── ThemeSwitcher.swift              # Theme picker UI
│   │   ├── LiquidGlassButton.swift          # Liquid glass button style
│   │   ├── LiquidGlassCard.swift            # Glass card component
│   │   ├── LiquidGlassContainer.swift       # Glass container with conditional blur
│   │   ├── LiquidGlassSidebar.swift         # Glass sidebar navigation
│   │   ├── LiquidGlassToggle.swift          # Duplicate (use LiquidToggle instead)
│   │   └── NoiseOverlay.swift              # Subtle noise texture overlay
│   ├── Physics/
│   │   └── Physics.swift                    # Spring animation constants
│   ├── HID/
│   │   ├── HIDManager.swift                 # IOKit HID communication
│   │   └── KeyboardProtocol.swift           # HID packet building + protocol abstraction
│   ├── Models/
│   │   ├── Profile.swift                    # Keyboard profile model
│   │   ├── RGBEffect.swift                  # RGB effect definitions
│   │   └── KeyMap.swift                     # Key remapping model
│   ├── Views/
│   │   ├── ContentView.swift                # Main window content
│   │   ├── ConnectionView.swift             # Device connection status
│   │   ├── RGBControlView.swift             # RGB lighting controls
│   │   ├── KeyRemapView.swift               # Key remapping UI
│   │   ├── MacroEditorView.swift            # Macro programming UI
│   │   ├── ProfileManagerView.swift         # Profile management
│   │   └── KeyboardVisualizer.swift         # 79-key visual keyboard
│   └── Utils/
│       ├── ColorExtensions.swift            # SwiftUI color helpers
│       ├── Logger.swift                     # Debug logging
│       └── ArraySafeSubscript.swift         # Safe array subscript
├── Package.swift
└── README.md
```

---

## Glassmorphism Implementation

This app uses **native macOS glassmorphism** — not CSS `backdrop-filter` blur. We use:

- `NSVisualEffectView` with `.sheet` / `.hudWindow` / `.menu` materials
- `blendingMode = .behindWindow` for true depth
- `Vibrancy` for foreground content adaptation
- `CALayer` with `cornerRadius` and `masksToBounds`
- **Never stack glass on glass** (Apple's golden rule)

### Physics Parameters

All animations use tuned spring physics:

```swift
// Navigation transitions
static let navigationSpring = Spring(mass: 1.0, stiffness: 150, damping: 15)

// Interactive feedback (button presses, toggles)
static let interactiveSpring = Spring(mass: 1.0, stiffness: 300, damping: 20)

// Glass morphing (sidebar, panel expansions)
static let morphSpring = Spring(mass: 1.0, stiffness: 200, damping: 18)

// Content appearance (lists, cards entering)
static let contentSpring = Spring(mass: 1.0, stiffness: 120, damping: 14)
```

---

## Building

### Prerequisites
- macOS 14.0 (Sonoma) or later
- Xcode 15.0+ with Swift 5.9+

### Build Steps

```bash
cd /Users/vedpatelicloud.com/Documents/app/EvoFoxRoninMac

# Option 1: Build with Swift Package Manager
swift build

# Option 2: Open in Xcode and build
# 1. Open Package.swift in Xcode
# 2. Select Product → Build (Cmd+B)
# 3. Run with Product → Run (Cmd+R)
```

---

## HID Protocol Note

The EvoFox Ronin HID protocol is **not publicly documented**. This app includes:

1. **Protocol Abstraction Layer** — Easy to adapt once packets are captured
2. **USB Packet Capture Guide** — Instructions for reverse-engineering
3. **Mock Mode** — Test all UI without a physical keyboard connected

To reverse-engineer the protocol on Windows:

1. Install [Wireshark](https://www.wireshark.org/) with USBPcap
2. Connect the keyboard to a Windows PC with the official EvoFox software
3. Capture USB HID traffic while changing RGB, remapping keys, etc.
4. Export the packet data and update `KeyboardProtocol.swift`

---

## Keyboard Specs (EvoFox Ronin TKL Wired)

| Spec | Value |
|------|-------|
| Layout | 79-key Tenkeyless (TKL) |
| Switches | Silent Outemu Red Dust Proof (hot-swappable) |
| RGB | Per-key RGB with 21 effects |
| Polling Rate | 1000Hz |
| Connection | Detachable braided USB-C |
| Features | Volume knob, nKey Rollover, on-board memory |
| OS Support | Windows (official) / macOS (this app) |

---

## License

MIT License. See LICENSE file for details.

---

> Built with native macOS glassmorphism, physics-based animations, and love for mechanical keyboards.
