# Liquid Glass Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign all 5 views (Connection, RGB, Key Remap, Macros, Profiles) with liquid glass effect — noise texture overlay, inner highlights, enhanced shadows.

**Architecture:** 4-layer glass stack: Background → NSVisualEffectView → Noise texture → Inner highlights. Shared design tokens. Components updated once, views inherit automatically.

**Tech Stack:** SwiftUI, NSVisualEffectView, Core Graphics (CGImage for noise texture)

---

## File Structure

| File | Action | Purpose |
|------|--------|---------|
| `Sources/.../Glassmorphism/GlassTokens.swift` | Create | Shared design constants |
| `Sources/.../Glassmorphism/NoiseOverlay.swift` | Create | Reusable noise texture view |
| `Sources/.../Glassmorphism/LiquidGlassCard.swift` | Create | Extracted + enhanced card |
| `Sources/.../Glassmorphism/LiquidGlassButton.swift` | Create | Extracted + enhanced button |
| `Sources/.../Glassmorphism/LiquidGlassContainer.swift` | Create | Extracted + enhanced container |
| `Sources/.../Glassmorphism/LiquidGlassSidebar.swift` | Create | Extracted + enhanced sidebar |
| `Sources/.../Glassmorphism/GlassView.swift` | Modify | Remove extracted types, keep core GlassView |
| `Sources/.../Glassmorphism/LiquidGlassToggle.swift` | Modify | Add noise + shadows |
| `Sources/.../Views/ConnectionView.swift` | Modify | Apply liquid glass |
| `Sources/.../Views/RGBControlView.swift` | Modify | Apply liquid glass |
| `Sources/.../Views/KeyRemapView.swift` | Modify | Apply liquid glass |
| `Sources/.../Views/MacroEditorView.swift` | Modify | Apply liquid glass |
| `Sources/.../Views/ProfileManagerView.swift` | Modify | Apply liquid glass |

---

### Task 1: Create GlassTokens.swift

**Files:**
- Create: `Sources/EvoFoxRoninMac/Glassmorphism/GlassTokens.swift`

- [ ] **Step 1: Create the tokens file**

```swift
// GlassTokens.swift
// Shared design constants for liquid glass effect

import SwiftUI

public enum GlassTokens {
    // MARK: - Noise Layer
    public static let noiseOpacity: Double = 0.03
    public static let noiseBaseFrequency: Double = 0.9
    public static let noiseOctaves: Int = 4
    public static let noiseSize: CGFloat = 100

    // MARK: - Highlight Layer
    public static let highlightTopOpacity: Double = 0.30
    public static let highlightGradientOpacity: Double = 0.08
    public static let highlightGradientHeight: CGFloat = 0.35
    public static let highlightWidth: CGFloat = 0.70

    // MARK: - Border
    public static let borderWidth: CGFloat = 0.5
    public static let borderOpacity: Double = 0.15
    public static let cornerRadiusCard: CGFloat = 24
    public static let cornerRadiusButton: CGFloat = 12
    public static let cornerRadiusSmall: CGFloat = 10
}
```

- [ ] **Step 2: Build to verify no errors**

Run: `swift build 2>&1 | head -20`
Expected: Compiles (new file, no references yet)

- [ ] **Step 3: Commit**

```bash
git add Sources/EvoFoxRoninMac/Glassmorphism/GlassTokens.swift
git commit -m "feat(glass): add shared liquid glass design tokens"
```

---

### Task 2: Create NoiseOverlay.swift

**Files:**
- Create: `Sources/EvoFoxRoninMac/Glassmorphism/NoiseOverlay.swift`

- [ ] **Step 1: Create the noise overlay view**

```swift
// NoiseOverlay.swift
// Reusable noise texture overlay for liquid glass effect

import SwiftUI

/// Generates a tiled noise texture using Core Graphics.
/// The noise is generated once and cached as a CGImage.
public struct NoiseOverlay: View {
    let opacity: Double
    let cornerRadius: CGFloat

    public init(opacity: Double = GlassTokens.noiseOpacity, cornerRadius: CGFloat = 0) {
        self.opacity = opacity
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        GeometryReader { geo in
            Image(decorative: noiseImage, scale: 1, orientation: .up, interpolatioHighQuality: true)
                .resizable()
                .interpolation(.high)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .opacity(opacity)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .allowsHitTesting(false)
    }

    /// Generates a 100x100 noise texture using Core Graphics
    private var noiseImage: CGImage {
        let size = Int(GlassTokens.noiseSize)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)

        guard let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return UIImage(systemName: "circle.fill")!.cgImage!
        }

        guard let data = context.data else {
            return UIImage(systemName: "circle.fill")!.cgImage!
        }

        let buffer = data.bindMemory(to: UInt8.self, capacity: size * size)

        for y in 0..<size {
            for x in 0..<size {
                let value = UInt8.random(in: 0...255)
                buffer[y * size + x] = value
            }
        }

        return context.makeImage() ?? UIImage(systemName: "circle.fill")!.cgImage!
    }
}

// MARK: - View Extension

extension View {
    /// Applies liquid glass noise overlay
    public func liquidNoise(opacity: Double = GlassTokens.noiseOpacity, cornerRadius: CGFloat = 0) -> some View {
        self.overlay(
            NoiseOverlay(opacity: opacity, cornerRadius: cornerRadius)
        )
    }
}
```

- [ ] **Step 2: Build to verify no errors**

Run: `swift build 2>&1 | head -20`
Expected: Compiles

- [ ] **Step 3: Commit**

```bash
git add Sources/EvoFoxRoninMac/Glassmorphism/NoiseOverlay.swift
git commit -m "feat(glass): add reusable noise texture overlay"
```

---

### Task 3: Create LiquidGlassCard.swift

**Files:**
- Create: `Sources/EvoFoxRoninMac/Glassmorphism/LiquidGlassCard.swift`

- [ ] **Step 1: Create the enhanced card component**

```swift
// LiquidGlassCard.swift
// Enhanced glass card with noise overlay, inner highlights, and shadows

import SwiftUI

public struct LiquidGlassCard<Content: View>: View {
    let material: LiquidGlassMaterial
    let cornerRadius: CGFloat
    let padding: CGFloat
    let content: Content

    @State private var isHovered = false

    public init(
        material: LiquidGlassMaterial = .container,
        cornerRadius: CGFloat = GlassTokens.cornerRadiusCard,
        padding: CGFloat = 24,
        @ViewBuilder content: () -> Content
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Layer 1: Glass material
                    GlassView(
                        material: .sheet,
                        blendingMode: .behindWindow,
                        cornerRadius: cornerRadius
                    )

                    // Layer 2: Noise texture
                    NoiseOverlay(
                        opacity: GlassTokens.noiseOpacity,
                        cornerRadius: cornerRadius
                    )

                    // Layer 3: Top edge highlight (1px gradient line)
                    VStack {
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(GlassTokens.highlightTopOpacity),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 1)
                        .padding(.horizontal, cornerRadius * 2)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .allowsHitTesting(false)

                    // Layer 4: Inner glow gradient (top 35%)
                    VStack {
                        LinearGradient(
                            colors: [
                                .white.opacity(GlassTokens.highlightGradientOpacity),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(maxHeight: .infinity)
                        .frame(height: GlassTokens.highlightGradientHeight * 300)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .allowsHitTesting(false)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(GlassTokens.borderOpacity), lineWidth: GlassTokens.borderWidth)
            )
            .shadow(
                color: Color.black.opacity(0.15),
                radius: isHovered ? 24 : 16,
                x: 0,
                y: isHovered ? 12 : 8
            )
            .onHover { hovering in
                withAnimation(.spring(Physics.morph)) {
                    isHovered = hovering
                }
            }
    }
}
```

- [ ] **Step 2: Build to verify no errors**

Run: `swift build 2>&1 | head -20`
Expected: Compiles (duplicate type error with GlassView.swift — fixed in Task 7)

- [ ] **Step 3: Commit**

```bash
git add Sources/EvoFoxRoninMac/Glassmorphism/LiquidGlassCard.swift
git commit -m "feat(glass): add enhanced LiquidGlassCard with noise + highlights"
```

---

### Task 4: Create LiquidGlassButton.swift

**Files:**
- Create: `Sources/EvoFoxRoninMac/Glassmorphism/LiquidGlassButton.swift`

- [ ] **Step 1: Create the enhanced button style**

```swift
// LiquidGlassButton.swift
// Enhanced glass button with noise overlay and inner highlights

import SwiftUI

public struct LiquidGlassButtonStyle: ButtonStyle {
    let isProminent: Bool
    let tint: Color
    let cornerRadius: CGFloat

    @State private var isHovered = false

    public init(
        isProminent: Bool = false,
        tint: Color = .accentColor,
        cornerRadius: CGFloat = GlassTokens.cornerRadiusButton
    ) {
        self.isProminent = isProminent
        self.tint = tint
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .foregroundStyle(isProminent ? Color.white : tint)
            .background(
                ZStack {
                    if isProminent {
                        // Prominent: colored fill + noise
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(configuration.isPressed ? 0.9 : 1.0))
                            .overlay(
                                NoiseOverlay(opacity: 0.04, cornerRadius: cornerRadius)
                            )
                            .shadow(
                                color: tint.opacity(0.3),
                                radius: configuration.isPressed ? 4 : 12,
                                x: 0, y: configuration.isPressed ? 2 : 6
                            )
                    } else {
                        // Standard: glass + noise + highlight
                        ZStack {
                            GlassView(
                                material: .hudWindow,
                                blendingMode: .behindWindow,
                                cornerRadius: cornerRadius
                            )

                            NoiseOverlay(opacity: 0.03, cornerRadius: cornerRadius)

                            // Top highlight
                            VStack {
                                LinearGradient(
                                    colors: [.clear, .white.opacity(isHovered ? 0.2 : 0.1), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(height: 1)
                                .padding(.horizontal, cornerRadius)
                                Spacer()
                            }
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                            .allowsHitTesting(false)
                        }
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(isProminent ? 0 : (configuration.isPressed ? 0.15 : GlassTokens.borderOpacity)), lineWidth: GlassTokens.borderWidth)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
```

- [ ] **Step 2: Build to verify no errors**

Run: `swift build 2>&1 | head -20`
Expected: Compiles (duplicate type — fixed in Task 7)

- [ ] **Step 3: Commit**

```bash
git add Sources/EvoFoxRoninMac/Glassmorphism/LiquidGlassButton.swift
git commit -m "feat(glass): add enhanced LiquidGlassButtonStyle with noise + highlights"
```

---

### Task 5: Create LiquidGlassContainer.swift

**Files:**
- Create: `Sources/EvoFoxRoninMac/Glassmorphism/LiquidGlassContainer.swift`

- [ ] **Step 1: Create the enhanced container**

```swift
// LiquidGlassContainer.swift
// Enhanced glass container with noise overlay and highlights

import SwiftUI

public struct LiquidGlassContainer<Content: View>: View {
    let material: LiquidGlassMaterial
    let cornerRadius: CGFloat
    let padding: CGFloat
    let content: Content

    public init(
        material: LiquidGlassMaterial = .container,
        cornerRadius: CGFloat = 30,
        padding: CGFloat = 24,
        @ViewBuilder content: () -> Content
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    GlassView(
                        material: .sheet,
                        blendingMode: .behindWindow,
                        cornerRadius: cornerRadius
                    )

                    NoiseOverlay(opacity: GlassTokens.noiseOpacity, cornerRadius: cornerRadius)

                    // Top edge highlight
                    VStack {
                        LinearGradient(
                            colors: [.clear, .white.opacity(GlassTokens.highlightTopOpacity), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 1)
                        .padding(.horizontal, cornerRadius)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .allowsHitTesting(false)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(GlassTokens.borderOpacity), lineWidth: GlassTokens.borderWidth)
            )
    }
}
```

- [ ] **Step 2: Build to verify no errors**

Run: `swift build 2>&1 | head -20`
Expected: Compiles (duplicate — fixed in Task 7)

- [ ] **Step 3: Commit**

```bash
git add Sources/EvoFoxRoninMac/Glassmorphism/LiquidGlassContainer.swift
git commit -m "feat(glass): add enhanced LiquidGlassContainer with noise + highlights"
```

---

### Task 6: Create LiquidGlassSidebar.swift

**Files:**
- Create: `Sources/EvoFoxRoninMac/Glassmorphism/LiquidGlassSidebar.swift`

- [ ] **Step 1: Create the enhanced sidebar**

```swift
// LiquidGlassSidebar.swift
// Enhanced glass sidebar with noise overlay and edge highlights

import SwiftUI

public struct LiquidGlassSidebar<Content: View>: View {
    let width: CGFloat
    let content: Content

    public init(width: CGFloat = 220, @ViewBuilder content: () -> Content) {
        self.width = width
        self.content = content()
    }

    public var body: some View {
        content
            .frame(width: width)
            .background(
                ZStack {
                    GlassView(
                        material: .sheet,
                        blendingMode: .behindWindow,
                        cornerRadius: 0
                    )

                    // Full-height noise (largest glass surface)
                    NoiseOverlay(opacity: GlassTokens.noiseOpacity, cornerRadius: 0)

                    // Right-edge border highlight
                    HStack {
                        Spacer()
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.12)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(width: 1)
                    }
                    .allowsHitTesting(false)
                }
            )
    }
}
```

- [ ] **Step 2: Build to verify no errors**

Run: `swift build 2>&1 | head -20`
Expected: Compiles (duplicate — fixed in Task 7)

- [ ] **Step 3: Commit**

```bash
git add Sources/EvoFoxRoninMac/Glassmorphism/LiquidGlassSidebar.swift
git commit -m "feat(glass): add enhanced LiquidGlassSidebar with noise + edge highlights"
```

---

### Task 7: Clean up GlassView.swift

**Files:**
- Modify: `Sources/EvoFoxRoninMac/Glassmorphism/GlassView.swift`

- [ ] **Step 1: Remove extracted types from GlassView.swift**

Remove the following sections from `GlassView.swift` (they now live in their own files):
- Lines 428–435: `LiquidGlassMaterial` enum → already in GlassTokens or shared via the new files
- Lines 438–494: `LiquidGlassCard` → moved to `LiquidGlassCard.swift`
- Lines 497–530: `LiquidGlassContainer` → moved to `LiquidGlassContainer.swift`
- Lines 597–617: `LiquidGlassSidebar` → moved to `LiquidGlassSidebar.swift`

Keep in `GlassView.swift`:
- `GlassMaterial` enum
- `GlassBlendingMode` enum
- `GlassView` (NSVisualEffectView wrapper)
- `GlassContainer`
- `GlassCard`
- `GlassSidebar`
- `GlassButtonStyle`
- `VibrantText` modifier
- `LiquidGlassBackground`
- `LiquidGlassMaterial` enum (shared type — move to GlassTokens or keep here)

After cleanup, add `LiquidGlassMaterial` to `GlassTokens.swift` if it's not already there:

```swift
// Add to GlassTokens.swift
public enum LiquidGlassMaterial {
    case container
    case button
    case floating
}
```

- [ ] **Step 2: Build to verify no errors**

Run: `swift build 2>&1 | head -30`
Expected: Compiles clean — no duplicate types

- [ ] **Step 3: Commit**

```bash
git add Sources/EvoFoxRoninMac/Glassmorphism/GlassView.swift Sources/EvoFoxRoninMac/Glassmorphism/GlassTokens.swift
git commit -m "refactor(glass): extract LiquidGlass types to separate files"
```

---

### Task 8: Update LiquidGlassToggle with noise

**Files:**
- Modify: `Sources/EvoFoxRoninMac/Glassmorphism/LiquidGlassToggle.swift`

- [ ] **Step 1: Add noise overlay to toggle track**

In `LiquidGlassToggle.swift`, find the `indicatorBackground` computed property (around line 332) and add noise:

```swift
private var indicatorBackground: some View {
    Capsule()
        .fill(dynamicColor)
        .overlay(
            NoiseOverlay(opacity: 0.02, cornerRadius: 9999)
        )
}
```

- [ ] **Step 2: Add noise to cover layer**

Find the cover layer in `liquidIndicatorLayer` (around line 454) and add noise:

```swift
Capsule()
    .fill(.white.opacity(0.85))
    .frame(width: indicatorWidth, height: indicatorHeight)
    .position(
        x: containerX + indicatorWidth / 2 + containerTranslateX,
        y: containerY + indicatorHeight / 2
    )
    .opacity(coverOpacity)
    .overlay(
        NoiseOverlay(opacity: 0.02, cornerRadius: 9999)
    )
    .animation(.easeInOut(duration: 0.15), value: isPressed)
```

- [ ] **Step 3: Build to verify no errors**

Run: `swift build 2>&1 | head -20`
Expected: Compiles

- [ ] **Step 4: Commit**

```bash
git add Sources/EvoFoxRoninMac/Glassmorphism/LiquidGlassToggle.swift
git commit -m "feat(glass): add noise texture to LiquidGlassToggle"
```

---

### Task 9: Update ConnectionView

**Files:**
- Modify: `Sources/EvoFoxRoninMac/Views/ConnectionView.swift`

- [ ] **Step 1: Add green glow to status indicator**

In `ConnectionView.swift`, find the `statusIcon` computed property (around line 248). Update the circle fill to have a glow:

```swift
@ViewBuilder
private var statusIcon: some View {
    ZStack {
        Circle()
            .fill(statusColor.opacity(0.2))
            .frame(width: 56, height: 56)
            .shadow(color: statusColor.opacity(0.3), radius: 12, x: 0, y: 0)

        Circle()
            .stroke(statusColor.opacity(0.4), lineWidth: 1)
            .frame(width: 56, height: 56)

        Image(systemName: statusIconName)
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(statusColor)
    }
}
```

- [ ] **Step 2: Build to verify no errors**

Run: `swift build 2>&1 | head -20`
Expected: Compiles

- [ ] **Step 3: Commit**

```bash
git add Sources/EvoFoxRoninMac/Views/ConnectionView.swift
git commit -m "feat(connection): add glow effect to status indicator"
```

---

### Task 10: Update RGBControlView

**Files:**
- Modify: `Sources/EvoFoxRoninMac/Views/RGBControlView.swift`

- [ ] **Step 1: Add glow to selected effect button**

In `RGBControlView.swift`, find the `EffectButton` struct. Update the background of selected buttons to include a glow:

```swift
.background(
    RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05), lineWidth: 0.5)
        )
        .shadow(color: isSelected ? effectCategoryColor.opacity(0.3) : .clear, radius: 8, x: 0, y: 0)
)
```

Add a computed property for the category color:

```swift
private var effectCategoryColor: Color {
    switch effect.category {
    case .staticColor: return .white
    case .dynamic: return .purple
    case .reactive: return .blue
    case .audio: return .orange
    case .custom: return .green
    }
}
```

- [ ] **Step 2: Build to verify no errors**

Run: `swift build 2>&1 | head -20`
Expected: Compiles

- [ ] **Step 3: Commit**

```bash
git add Sources/EvoFoxRoninMac/Views/RGBControlView.swift
git commit -m "feat(rgb): add glow effect to selected lighting effect"
```

---

### Task 11: Update KeyRemapView

**Files:**
- Modify: `Sources/EvoFoxRoninMac/Views/KeyRemapView.swift`

- [ ] **Step 1: Add glow to selected key**

In `KeyRemapView.swift`, find the `RemapKeyButton` struct. Update the selected state:

```swift
.background(
    RoundedRectangle(cornerRadius: 4, style: .continuous)
        .fill(isSelected ? Color.accentColor.opacity(0.4) : Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(
                    isSelected ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.1),
                    lineWidth: isSelected ? 1.5 : 0.5
                )
        )
        .shadow(color: isSelected ? Color.accentColor.opacity(0.4) : .clear, radius: 6, x: 0, y: 0)
)
```

- [ ] **Step 2: Build to verify no errors**

Run: `swift build 2>&1 | head -20`
Expected: Compiles

- [ ] **Step 3: Commit**

```bash
git add Sources/EvoFoxRoninMac/Views/KeyRemapView.swift
git commit -m "feat(remap): add glow effect to selected keyboard key"
```

---

### Task 12: Update MacroEditorView

**Files:**
- Modify: `Sources/EvoFoxRoninMac/Views/MacroEditorView.swift`

- [ ] **Step 1: Add glow to selected macro card**

In `MacroEditorView.swift`, find the `MacroCard` struct. Update the selected state background:

```swift
.background(
    RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: isSelected ? Color.green.opacity(0.3) : .clear, radius: 8, x: 0, y: 0)
)
```

- [ ] **Step 2: Build to verify no errors**

Run: `swift build 2>&1 | head -20`
Expected: Compiles

- [ ] **Step 3: Commit**

```bash
git add Sources/EvoFoxRoninMac/Views/MacroEditorView.swift
git commit -m "feat(macros): add glow effect to selected macro card"
```

---

### Task 13: Update ProfileManagerView

**Files:**
- Modify: `Sources/EvoFoxRoninMac/Views/ProfileManagerView.swift`

- [ ] **Step 1: Add glow to active profile card**

In `ProfileManagerView.swift`, find the `ProfileCard` struct. Update the overlay stroke for active profiles:

```swift
.overlay(
    RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(isActive ? Color.green.opacity(0.3) : Color.white.opacity(0.08), lineWidth: isActive ? 1.5 : 0.5)
)
.shadow(color: isActive ? Color.green.opacity(0.2) : .clear, radius: 12, x: 0, y: 0)
```

- [ ] **Step 2: Build to verify no errors**

Run: `swift build 2>&1 | head -20`
Expected: Compiles

- [ ] **Step 3: Commit**

```bash
git add Sources/EvoFoxRoninMac/Views/ProfileManagerView.swift
git commit -m "feat(profiles): add glow effect to active profile card"
```

---

### Task 14: Final verification

- [ ] **Step 1: Full build**

Run: `swift build`
Expected: Clean build, no errors

- [ ] **Step 2: Visual verification**

Open the app and verify:
- All 5 views show noise texture overlay on glass cards
- Inner highlights visible on card top edges
- Selected items (RGB effects, keyboard keys, macros, profiles) have colored glow
- Status indicator on Connection view has glow
- Toggle still works with added noise
- No text legibility issues

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat: complete liquid glass redesign across all views"
```
