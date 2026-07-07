# Build Instructions

## Prerequisites

- **macOS 13.0 (Ventura)** or later
- **Xcode 15.0+** with Swift 5.9+
- **Swift Package Manager** (included with Xcode)

## Quick Start

### Option 1: Command Line (SPM)

```bash
cd /Users/vedpatelicloud.com/Documents/app/EvoFoxRoninMac

# Build the project
swift build

# Run the app
swift run

# Or use Make
make build
make run
```

### Option 2: Xcode

```bash
# Open in Xcode
open Package.swift

# Or use Make
make xcode
```

Then in Xcode:
1. Select **Product → Build** (Cmd+B)
2. Select **Product → Run** (Cmd+R)

## Permissions

The first time you run the app, macOS will prompt for **Input Monitoring** permission. This is required because the app communicates with USB HID devices (your keyboard).

1. Open **System Settings → Privacy & Security → Input Monitoring**
2. Click the **+** button
3. Navigate to and select the EvoFoxRoninMac app
4. Enable the checkbox
5. Restart the app

## Mock Mode

If you don't have the keyboard connected, you can test the app UI by enabling **Mock Mode**:

- From the menu: **Keyboard → Enable Mock Mode**
- All UI features will work, but no actual HID packets are sent

## Troubleshooting

### Build Errors

**Error: `No such module 'IOKit'`**
- Ensure you're building on macOS (not Linux or iOS simulator)
- IOKit is a macOS-only framework

**Error: `Package.swift has no Package.swift manifest`**
- Make sure you're in the correct directory: `cd /Users/vedpatelicloud.com/Documents/app/EvoFoxRoninMac`

**Error: `unable to spawn process`**
- Run `xcode-select --install` to ensure command line tools are installed

### Runtime Issues

**Keyboard not found**
- Ensure the keyboard is connected via USB-C (not wireless)
- Try a different USB port
- Check System Information → USB for the device
- Enable Mock Mode to test without hardware

**Permission denied**
- Grant Input Monitoring permission as described above
- The app cannot communicate with HID devices without this permission

## Architecture Notes

### Glassmorphism Implementation

The app uses native `NSVisualEffectView` (not CSS blur):
- `GlassView.swift` wraps `NSVisualEffectView` for SwiftUI
- `GlassCard` provides styled panels with inner glow and border
- `GlassButtonStyle` renders capsule glass buttons
- Never stacks glass on glass (Apple's rule)
- Glass is only on the navigation layer (sidebar, toolbars)

### Physics Animations

All animations use tuned spring constants defined in `Physics.swift`:
- `navigation` spring: sidebar/panel transitions (0.45s, 0.82 damping)
- `interactive` spring: button press/hover (0.25s, 0.72 damping)
- `morph` spring: glass panel expansion (0.55s, 0.68 damping)
- `content` spring: list/card entrance (0.55s, 0.75 damping)

### HID Protocol

The actual EvoFox Ronin HID protocol is **not publicly documented**. The app provides:
1. `KeyboardProtocol.swift` — abstraction layer with packet builder
2. `HIDManager.swift` — IOKit device communication
3. Mock mode for testing without hardware

To add real support, reverse-engineer the USB packets using Wireshark on Windows with the official software, then update the packet builder methods.

## Project Structure

```
EvoFoxRoninMac/
├── Package.swift                 # SPM manifest
├── Makefile                     # Build shortcuts
├── README.md                      # Project overview
├── BUILD.md                       # This file
├── Sources/EvoFoxRoninMac/
│   ├── App/
│   │   └── EvoFoxRoninMacApp.swift     # @main entry point
│   ├── Glassmorphism/
│   │   └── GlassView.swift             # NSVisualEffectView wrapper
│   ├── Physics/
│   │   └── Physics.swift               # Spring animation constants
│   ├── HID/
│   │   ├── HIDManager.swift            # IOKit USB communication
│   │   └── KeyboardProtocol.swift      # HID packet builder
│   ├── Models/
│   │   ├── RGBEffect.swift             # 21 built-in RGB effects
│   │   ├── KeyMap.swift                # 79-key layout definition
│   │   └── Profile.swift               # Profile + macro models
│   ├── Views/
│   │   ├── ContentView.swift           # Main window with sidebar
│   │   ├── ConnectionView.swift        # Device status & troubleshooting
│   │   ├── RGBControlView.swift        # RGB lighting controls
│   │   ├── KeyboardVisualizer.swift    # 79-key visual preview
│   │   ├── KeyRemapView.swift          # Key remapping UI
│   │   ├── MacroEditorView.swift       # Macro programming
│   │   └── ProfileManagerView.swift    # Profile save/load
│   └── Utils/
│       ├── ColorExtensions.swift       # Color helpers
│       └── Logger.swift                # Debug logging
```

## License

MIT License
