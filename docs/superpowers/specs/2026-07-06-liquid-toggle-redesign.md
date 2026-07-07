# Liquid Toggle Redesign Specification

## Overview
Replace the existing `LiquidGlassToggle` with a new `LiquidToggle` that faithfully replicates the visual style and behavior of Jhey Tompkins' Liquid Toggle Switch using SwiftUI-native effects (compositingGroup, blur, contrast, masking) rather than exact SVG filter replication.

## Requirements

### Functional
- **Slide animation**: Smooth spring-based transition between on/off states
- **Gooey bounce on press**: Knob expands/contracts with 1.65x scale and delta-based asymmetry
- **Draggable knob**: Drag to toggle with real-time visual feedback
- **Click to toggle**: Tap/click toggles state with bounce animation
- **Dynamic hue-based colors**: Color transitions based on `--complete` (0-100) using HSL interpolation
- **Debug visualization**: Optional 3D transform showing layer structure

### Non-Functional
- Drop-in replacement for `LiquidGlassToggle` (same public API)
- Works on macOS 14+ with stable SwiftUI APIs
- Follows existing codebase patterns (Glassmorphism folder, vibrantText modifiers, Physics springs)

## Architecture

### File Structure
```
Sources/EvoFoxRoninMac/Glassmorphism/
├── LiquidToggle.swift          # New implementation (replaces LiquidGlassToggle.swift)
├── LiquidToggleStyle.swift     # ToggleStyle conformance
└── (existing files unchanged)
```

### Public API (unchanged for compatibility)
```swift
public struct LiquidToggle: View {
    @Binding var isOn: Bool
    let tintColor: Color
    let size: ToggleSize        // .small, .medium, .large
    let bounceEnabled: Bool
    let hue: Double             // 0-360
    let deviation: CGFloat      // goo blur amount
    let alpha: CGFloat          // contrast threshold
    let bounce: Bool            // bounce animation
    let delta: Bool             // asymmetric scale
    let bubble: Bool            // show press effect
    let mapped: Bool            // stepped progress
    let debug: Bool             // show layers
}

public enum ToggleSize {
    case small, medium, large
}
```

## Visual Layer Architecture (mirrors HTML/CSS exactly)

```
ZStack (back to front):
├── 1. indicatorBackground          → Full capsule, dynamic color
├── 2. knockoutLayer                → Colored capsule + black sliding mask (destinationOut blend)
├── 3. liquidIndicatorLayer         → Sliding container with goo effect
│   ├── shadow (opacity on press)
│   ├── wrapper (clip-path capsule, blur 6→0 on press)
│   │   └── liquids (goo filter: blur + contrast)
│   │       ├── liquid__shadow (inner shadow)
│   │       └── liquid__track (FULL-WIDTH capsule, translates with --complete)
│   └── cover (white overlay, opacity 1→0 on press)
└── 4. innerShadows                 → Subtle depth gradients
```

### Goo Effect Simulation (SwiftUI)
```swift
// Replaces SVG: feGaussianBlur(13) + feColorMatrix(values: "0 0 0 13 -10")
.liquids
    .compositingGroup()
    .blur(radius: deviation)        // deviation = 13 default
    .contrast(alpha)                // alpha = 16 default
    .mask(capsuleShape)             // clips to capsule
```

### Knockout Effect Simulation
```swift
// Replaces SVG: feColorMatrix + feComponentTransfer (threshold)
knockoutLayer
    .compositingGroup()
    .blendMode(.destinationOut)     // removes black = transparent window
```

## Color System

### Dynamic Checked Color (based on `--complete` 0-100)
- **Hue**: From `tintColor` or `hue` parameter (default 144° = green)
- **Saturation**: `8% + (complete/100 * 92%)` → 8% → 100%
- **Lightness**: `81% - (complete/100 * 38%)` → 81% → 43%

### Unchecked Color
- `hsl(218°, 8%, 81%)` — muted blue-gray

### Track Color
- Always uses dynamic checked color (follows knob)

## Animation Specifications

### State Transitions
| Trigger | Animation | Duration/Params |
|---------|-----------|-----------------|
| Auto-toggle (click) | Spring slide | response: 0.35, damping: 0.7 |
| Press down | Scale + blur→0 + cover fade | easeInOut 0.12s |
| Drag | Real-time `--complete` update | No animation (direct) |
| Drag end → settle | Spring to 0 or 100 | response: 0.2, damping: 0.75 |
| Bounce phase | Scale 1.02 x/y | response: 0.4, damping: 0.5 |

### Bounce Physics (matches CSS `linear()` easing)
- Scale X: `1.65 + (delta * 0.025)`
- Scale Y: `1.65 - (delta * 0.025)`
- `delta` = min(|dragDeltaX|, 12)

## Gesture Handling

### Click/Tap (press < 150ms)
1. Set `isPressed = true`, `isActive = true`
2. Animate `--complete` to target (0 or 100)
3. Trigger bounce phase
4. After 50ms: toggle `isOn`, reset `isActive`, `isPressed`

### Drag
1. `onDragStart`: Calculate `dragBounds` based on current state
2. `onDragChanged`: Map drag distance → `complete` (0-100), update `deltaValue`
3. `onDragEnd`: Spring to nearest end (0 or 100), then toggle `isOn`

### Keyboard
- Space/Enter: Triggers click toggle

## Debug Mode (`debug: true`)

Applies 3D transform to main container:
- `rotateX(-24deg) rotateY(24deg)`
- Shows knockout layer at `translateZ(-200px)`
- Shows liquid layer at `translateZ(200px)`
- Layer labels visible

## Integration Points

### RGBControlView (line 58)
```swift
// Before
LiquidGlassToggle(isOn: $isEnabled, tintColor: primaryColor, size: .medium)

// After (same API)
LiquidToggle(isOn: $isEnabled, tintColor: primaryColor, size: .medium)
```

### ToggleStyle Conformance
```swift
public struct LiquidToggleStyle: ToggleStyle {
    // Wraps LiquidToggle for .toggleStyle() usage
}
```

## Migration Checklist
- [ ] Create `LiquidToggle.swift` with new implementation
- [ ] Create `LiquidToggleStyle.swift` (can be in same file)
- [ ] Update `RGBControlView.swift` import (same module, no change needed)
- [ ] Delete `LiquidGlassToggle.swift`
- [ ] Verify preview works
- [ ] Run build

## Success Criteria
1. Visual parity with HTML reference (gooey bounce, slide, color transitions)
2. All gestures work: click, drag, keyboard
3. Drop-in replacement — no call site changes
4. Debug mode shows layer structure
5. Performance: 60fps on M1/M2/M3 Macs

## Out of Scope
- Exact SVG filter replication (per user choice)
- iOS/iPadOS specific optimizations
- Haptic feedback (macOS only)
- Audio-reactive colors