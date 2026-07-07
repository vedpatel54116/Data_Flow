# Liquid Glass Redesign — Design Spec

**Date:** 2026-07-06
**Status:** Approved
**Approach:** C — Full Liquid Glass (Hybrid: NSVisualEffectView + Noise Overlay + Inner Highlights)

---

## Goal

Redesign all 5 main views (Connection, RGB Lighting, Key Remap, Macros, Profiles) to match the "liquid glass" aesthetic from the user's CSS sample. The sample uses SVG filters (feTurbulence + feDisplacementMap) for organic noise/displacement, inner box-shadows for glass edge depth, and backdrop-filter blur.

The redesign preserves the existing `NSVisualEffectView` foundation and layers on top of it to achieve the liquid glass look while staying native macOS.

---

## Architecture: 4-Layer Glass Stack

Each glass surface is composed of 4 layers (bottom → top):

### Layer 0: Background (unchanged)
- Existing `LiquidGlassBackground` animated mesh gradient
- Glass samples this for color variation

### Layer 1: Glass Material (existing, enhanced)
- `NSVisualEffectView` with `.sheet` / `.hudWindow` material
- `blendingMode = .behindWindow` for true depth
- Already implemented in `GlassView.swift`

### Layer 2: Noise Texture (new)
- SVG `feTurbulence` fractalNoise rendered as a tiled `CALayer` or SwiftUI `Image`
- Opacity: 3–5% (subtle organic grain)
- `baseFrequency`: 0.8–1.0
- `numOctaves`: 4
- `stitchTiles: stitch` for seamless tiling
- Applied as a `.compositingGroup()` overlay with `.mix(.softLight)` blend mode

### Layer 3: Inner Highlights (new)
- **Top edge highlight**: linear gradient from transparent → white(0.25–0.35) → transparent, 70% width centered, 1px height
- **Inner glow**: linear gradient from white(0.06–0.10) → transparent, top 35% of the container
- **Inner box-shadow**: `inset 2px 2px -2px white/0.8` + `inset 0 0 4px white/0.5`
- **Bottom edge**: `inset 0 -2px -2px white/0.2` for subtle depth

---

## Design Tokens

All values are tunable constants. Add these to `GlassView.swift` or a new `GlassTokens.swift`:

```swift
// Noise Layer
static let noiseOpacity: Double = 0.03
static let noiseBaseFrequency: Double = 0.9
static let noiseOctaves: Int = 4

// Highlight Layer
static let highlightTopOpacity: Double = 0.30
static let highlightGradientOpacity: Double = 0.08
static let highlightGradientHeight: CGFloat = 0.35  // 35% of container height
static let highlightWidth: CGFloat = 0.70  // 70% of container width, centered

// Shadow Layer
static let innerShadowTop = (x: 2.0, y: 2.0, blur: -2.0, color: Color.white.opacity(0.8))
static let innerShadowBlur = (x: 0, y: 0, blur: 4.0, color: Color.white.opacity(0.5))
static let innerShadowBottom = (x: 0, y: -2.0, blur: -2.0, color: Color.white.opacity(0.2))

// Border
static let borderWidth: CGFloat = 0.5
static let borderOpacity: Double = 0.15
static let cornerRadiusCard: CGFloat = 24
static let cornerRadiusButton: CGFloat = 12
```

---

## Component Changes

### 1. LiquidGlassCard

**File:** `GlassView.swift` (lines 438–494)

Changes:
- Increase `cornerRadius` from 20 → 24
- Add noise overlay as 4th layer in the ZStack background
- Add top edge highlight (1px gradient line at top)
- Add inner glow gradient (top 35%)
- Update `boxShadow` to include inner shadows: `inset 2px 2px -2px white/0.8`, `inset 0 0 4px white/0.5`
- Update border opacity from 0.08 → 0.15

### 2. LiquidGlassButtonStyle

**File:** `GlassView.swift` (lines 547–594)

Changes:
- Add noise overlay to button background
- Add top highlight gradient on hover (via `isHovered` state)
- Reduce highlight opacity on press (0.9 → 0.6)
- Prominent variant: keep colored fill + shadow, add subtle noise overlay
- Standard variant: add inner highlight + noise to glass background

### 3. LiquidGlassSidebar

**File:** `GlassView.swift` (lines 597–617)

Changes:
- Full-height noise overlay (largest glass surface — noise matters most)
- Right-edge border highlight (1px white gradient)
- Bottom shadow gradient (subtle dark gradient at bottom edge)

### 4. LiquidGlassContainer

**File:** `GlassView.swift` (lines 497–530)

Changes:
- Inherit noise/highlights from material type parameter
- Add noise overlay
- Update border opacity to match new tokens
- Used for floating elements (tooltips, popovers)

### 5. LiquidGlassToggle

**File:** `LiquidGlassToggle.swift`

Changes:
- Add noise texture to track background (very subtle, 2% opacity)
- Enhance inner shadows on knob (top highlight + bottom shadow)
- Keep existing goo/liquid effect unchanged (already complex)
- Add subtle noise to cover layer

---

## View Changes

### ConnectionView

**File:** `Views/ConnectionView.swift`

- Main status card: wrap in updated `LiquidGlassCard` (gets noise + highlights automatically)
- Status indicator: add green glow shadow (`color: .green.opacity(0.3), radius: 12`)
- QuickActionCards: already use `LiquidGlassContainer` — update to new styling
- Buttons: use updated `LiquidGlassButtonStyle`
- Permission warning banner: add noise overlay to orange background

### RGBControlView

**File:** `Views/RGBControlView.swift`

- Effect Grid card: updated `LiquidGlassCard` with noise
- Selected effect button: add colored glow shadow matching category color
- Color swatches: add inner glow shadow matching swatch color
- Sliders: add noise to track background, glass thumb with shadow
- Apply button: updated prominent button style with glass tint
- Toast notification: add noise + highlights to floating glass

### KeyRemapView

**File:** `Views/KeyRemapView.swift`

- Keyboard grid card: updated `LiquidGlassCard` with noise
- Individual keys: add noise overlay, selected key gets colored glow border
- Mapping list: each row gets subtle glass background with noise
- Action sheet: updated glass styling

### MacroEditorView

**File:** `Views/MacroEditorView.swift`

- Empty state card: updated `LiquidGlassCard`
- Macro cards: noise overlay + highlights, selected macro gets glow
- Recording state: red glow shadow on record button
- Event rows: subtle glass background with noise
- Detail sheet: full liquid glass treatment

### ProfileManagerView

**File:** `Views/ProfileManagerView.swift`

- Profile cards: full liquid glass (noise + highlights + inner shadows)
- Active profile: green glow border + green glow shadow
- Profile detail items: glass pill badges with noise
- Action buttons: updated glass button styles
- New profile sheet: glass card with noise

---

## Implementation Order

1. **GlassTokens.swift** — Create shared constants file
2. **GlassView.swift** — Update LiquidGlassCard, LiquidGlassButtonStyle, LiquidGlassSidebar, LiquidGlassContainer
3. **NoiseOverlay.swift** — Create reusable noise texture view/component
4. **LiquidGlassToggle.swift** — Add noise + enhanced shadows
5. **ConnectionView.swift** — Apply updated components
6. **RGBControlView.swift** — Apply updated components
7. **KeyRemapView.swift** — Apply updated components
8. **MacroEditorView.swift** — Apply updated components
9. **ProfileManagerView.swift** — Apply updated components

---

## Performance Considerations

- Noise texture is a small (100×100) tiled SVG — negligible GPU cost
- `NSVisualEffectView` is hardware-composited by macOS window server
- Inner highlights are pure SwiftUI shapes — trivial cost
- Total added rendering cost: minimal (no real-time shaders)
- Fallback: on older Macs without NSVisualEffectView support, the noise/highlights still render on top of the solid background

---

## Testing

- Visual inspection of all 5 views in Light, Dark, and Dim themes
- Verify noise texture renders correctly at different window sizes
- Verify highlights don't interfere with text legibility
- Verify hover/press states on buttons still feel responsive
- Verify toggle goo effect still works with added noise
- Performance check: no frame drops during animations
