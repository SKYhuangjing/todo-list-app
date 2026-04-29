# Todo List — Design System

> Visual language for the native macOS app. This document is the single source of truth.
> When code and this document disagree, **this document wins**. Fix the code.
>
> Implementation root: `apple/TodoList/Sources/DesignSystem/`.

---

## 1. Design Soul — "Glass on Paper"

Todo List is not a dashboard. It is not an "operator board". It is a quiet sheet of paper with a few glass beads floating on top.

Two layers, never mixed:

| Layer | Role | Visual |
|---|---|---|
| **Paper (Canvas)** | Task titles, notes, metadata, list | Flat, near-white (light) or near-black (dark). No gradient, no shadow, no material. |
| **Glass (Chrome)** | Toolbar buttons, filter pills, primary CTA, Quick Add panel, selected sidebar item | Liquid Glass (macOS 26+) or `.regularMaterial` fallback. Rounded or capsule. Subtle specular highlight. |

Hard rules:

1. **Glass never stacks on glass.** Two glass elements side-by-side must be wrapped in `GlassChromeCluster` (→ `GlassEffectContainer`).
2. **Paper never wraps paper.** No card-in-card. Sections are separated by whitespace and hairline dividers, not nested surfaces.
3. **Tint is rare and load-bearing.** The brand Accent only shows on: the active sidebar item, the primary CTA, the selected task row's priority bar, and the Quick Add save button. Everything else is neutral.
4. **Typography carries the hierarchy, not boxes.** If you're about to add a border to separate two things, use spacing and type weight instead.

---

## 2. Themes V2 (User-Selectable)

V1 treated a theme as three independent controls:

```
Theme V1 = Accent × Typography × Density
```

That model is no longer enough. It makes presets look too similar because most visible surfaces still resolve from global neutral colors. V2 treats a theme as a complete **Design Recipe**: one user choice maps to palette, typography, density, glass, motion, and elevation tokens.

```
Theme V2 = ThemeRecipe × Optional Overrides

ThemeRecipe = Palette + Accent + Typography + Density + LiquidGlass + Motion + Elevation
```

Rules:

1. A preset must be visually recognizable in the main window without opening Settings.
2. A preset must affect canvas, sidebar, controls, selected state, hover state, and modal surfaces.
3. Manual edits are overrides on top of a preset. The UI should say "Custom based on Porcelain", not lose the source recipe.
4. Semantic colors stay theme-independent. Done, overdue, and priority colors do not become brand colors.
5. Accessibility overrides win over theme style: reduce transparency, reduce motion, and high contrast must be applied last.

### Accent palette

| Token | Hex (light) | Hex (dark) | When to pick |
|---|---|---|---|
| `inkNavy` **(default light)** | `#1E3A5F` | `#8FAED4` | Quiet, premium, work-focused. |
| `graphite` | `#3E4654` | `#B2BCCE` | Neutral monochrome. Useful for Sumi-like surfaces. |
| `cypress` | `#2B5750` | `#7FB3A9` | Deep green without colliding as strongly with Done. |
| `porcelainBlue` **(default dark)** | `#3A6FE0` | `#6C93F2` | Clean + premium. Neutral-cool. Think Things 3 / Linear. |
| `warmOrange` | `#F08A2C` | `#FFA347` | Warm, food-for-thought. Legacy brand color. |
| `forestGreen` | `#2F9E65` | `#45C281` | Productivity-forward. Caution: collides with Done semantics. |
| `violet` | `#7C5AE8` | `#A48CFF` | Showcases Liquid Glass refraction most dramatically. |
| `systemAccent` | `NSColor.controlAccentColor` | same | Fully native. User controls in System Settings. No brand opinion. |

### Typography family

| Token | Display / Title | Body | Numbers |
|---|---|---|---|
| `sfPro` **(default)** | SF Pro | SF Pro | SF Mono |
| `sfProRounded` | SF Pro Rounded | SF Pro | SF Mono |
| `newYork` | New York (serif) | SF Pro | SF Mono |

### Density

| Token | Task row height | Section padding | Sidebar row height | Max tasks per screen @1200pt tall |
|---|---|---|---|---|
| `compact` | 36pt | 10 / 14 | 32pt | ~15 |
| `balanced` **(default)** | 48pt | 14 / 18 | 36pt | ~10 |
| `comfortable` | 62pt | 18 / 22 | 42pt | ~7 |

### Liquid Glass profile

Liquid Glass is not a boolean. It is a surface behavior profile.

| Token | macOS 26 Glass | Fallback material | Use |
|---|---|---|---|
| `clear` | Neutral `.regular` / `.regular.interactive()` | Material + low-opacity neutral overlay | Default. Minimal distraction. |
| `tinted` | Accent-tinted glass with stronger tint | Material + accent overlay + accent border | User wants visible brand glass. |
| `vivid` | Strong tint, clearer edge, higher depth | Material + stronger accent overlay + stronger shadow | Optional future mode. Preview first; may be too expressive for daily work. |
| `reduced` | No glass tint, flatter material | Solid or near-solid themed surface | Accessibility / Reduce Transparency. |

### Presets as recipes

| Preset | Palette | Accent | Typography | Density | Liquid Glass | Motion | Feel |
|---|---|---|---|---|---|---|---|
| **Porcelain** (default) | Warm paper, low contrast sidebar, ivory selected state | light `inkNavy`, dark `porcelainBlue` | `sfPro` | `comfortable` | `clear` | Calm crossfade + short selection spring | Quiet, premium, writing-first |
| **Ember** | Warm amber paper, deeper warm sidebar, saturated selected state | light `warmOrange`, dark `forestGreen` | `sfProRounded` | `balanced` | `tinted` | Slightly warmer hover and glass morph | Approachable, warmer, more expressive |
| **Sumi** | Cool graphite paper, high contrast sidebar, crisp selected state | light `graphite`, dark `violet` | `newYork` for headings, SF Pro body | `compact` | `clear` or `reduced` | Minimal movement | Dense, monochrome, high-information |
| **Custom** | Starts from a recipe, then applies overrides | User-selected | User-selected | User-selected | User-selected | Inherits source recipe | User-owned combination |

### Recipe token contract

Each preset must resolve these runtime tokens. Views consume the resolved `Theme`, not raw preset branches.

```swift
struct ThemeRecipe: Codable, Sendable {
    var preset: ThemePreset
    var palette: PaletteRecipe
    var lightAccent: AccentToken
    var darkAccent: AccentToken
    var typography: TypographyToken
    var density: DensityToken
    var liquidGlass: LiquidGlassToken
    var motion: MotionToken
    var elevation: ElevationToken
}

struct ThemeOverrides: Codable, Sendable {
    var basePreset: ThemePreset
    var lightAccent: AccentToken?
    var darkAccent: AccentToken?
    var typography: TypographyToken?
    var density: DensityToken?
    var liquidGlass: LiquidGlassToken?
    var reduceTransparency: Bool?
    var reduceMotion: Bool?
    var highContrast: Bool?
}
```

---

## 2.1 Theme V2 UX

Settings should present themes as a recipe first, controls second.

```
Appearance section
├── Display mode        (System / Light / Dark)
├── Theme recipe        (Porcelain / Ember / Sumi / Custom)
│   └── Live app preview: sidebar + list + detail + Quick Add CTA
├── Liquid Glass        (Reduced / Clear / Tinted / Vivid)
└── Advanced            (collapsed by default)
    ├── Accent
    ├── Typography
    ├── Density
    └── Accessibility overrides
```

Interaction rules:

1. Selecting a recipe updates the live preview immediately.
2. Applying a recipe updates the whole app in one transaction.
3. Changing an advanced control creates `Custom based on <last preset>`.
4. Theme transition uses crossfade for palette, short spring for selected controls, and no layout animation for typography or density.
5. Liquid Glass must always show a side-by-side preview because the difference is material behavior, not just color.

---

## 3. Color Tokens

Foreground is derived from system colors. Surfaces are resolved by the active Theme V2 palette.

```
foreground.primary      = NSColor.labelColor
foreground.secondary    = NSColor.secondaryLabelColor
foreground.tertiary     = NSColor.tertiaryLabelColor
foreground.quaternary   = NSColor.quaternaryLabelColor

canvas.base             = theme.palette.canvas
canvas.elevated         = theme.palette.canvasElevated
surface.sidebar         = theme.palette.sidebar
surface.recessedControl = theme.palette.recessedControl
surface.selectedControl = theme.palette.selectedControl

separator.soft          = theme.palette.separator.opacity(0.65)
separator.regular       = theme.palette.separator

accent                  = Theme.accent              # single source for brand tint
```

Palette recipes:

| Token | Responsibility |
|---|---|
| `canvas` | Main paper layer behind task content. No material, no shadow. |
| `canvasElevated` | Detail sections, Quick Add base, modal content bases. |
| `sidebar` | Sidebar/navigation background. Must visibly differ per recipe. |
| `recessedControl` | Text fields, hover rows, neutral setting controls. |
| `selectedControl` | Selected setting cards and low-emphasis selected surfaces. |
| `separator` | Hairline separators and low-emphasis outlines. |

Semantic colors are **fixed, theme-independent**:

```
priority.p1 = systemRed
priority.p2 = systemOrange
priority.p3 = systemBlue          # note: this is not the accent — priority is its own axis
priority.p4 = systemGray

status.done     = systemGreen
status.overdue  = systemOrange
status.info     = systemBlue
```

---

## 4. Typography Scale

Always use `theme.type.*`. Never write `.font(.system(size: 13))` in views.

| Token | Size | Weight | Tracking | Purpose |
|---|---|---|---|---|
| `display` | 30 | semibold | -0.4 | Main page titles (Today / Upcoming / Tag name) |
| `title` | 22 | semibold | -0.2 | Detail pane task title, Quick Add header |
| `headline` | 16 | semibold | 0 | Task row title |
| `body` | 13.5 | regular | 0 | Notes, descriptions |
| `callout` | 12 | medium | 0 | Chip labels, meta text |
| `caption` | 11 | medium | 0 | Timestamps, hints |
| `microLabel` | 10.5 | bold | 0.8 | Uppercase section headers — **use sparingly, max 2 per screen** |
| `number` | inherits size | semibold | -0.1 | Counts, dates — always SF Mono |
| `keycap` | 11 | semibold | 0 | ⌘N, keyboard hint — SF Mono |

Rounded theme multiplies display/title sizes by 1.0 but swaps family to rounded; scale stays identical so layouts are stable across themes.

---

## 5. Spacing & Layout Scale

One scale for the whole app. Views pick from it — no magic numbers.

```
space.xs  =  4
space.sm  =  8
space.md  = 12
space.lg  = 16
space.xl  = 20
space.xxl = 28
space.xxxl = 40
```

Layout targets:

| Surface | Width (min / ideal / max) | Notes |
|---|---|---|
| Sidebar | 200 / 220 / 240 | Uses `.sidebar` material |
| Main column | 640 / 780 / 960 | Canvas layer |
| Detail | 320 / 360 / 400 | Canvas layer with one glass header |
| Quick Add sheet | 580 × 700 | Glass sheet over paper |

---

## 6. Radius Scale

```
radius.xs       =  6     # inline tags, tiny pills
radius.sm       = 10     # buttons
radius.md       = 14     # inputs, chips, pills
radius.lg       = 20     # cards, task rows (rare)
radius.xl       = 28     # Quick Add sheet, detail glass header
radius.capsule  = 999
```

Everything uses `.continuous` corner style.

---

## 7. Elevation

Three levels. Paper uses none. Glass layers automatically inherit Liquid Glass depth; stop adding shadows on top of them.

| Token | Shape | y | blur | opacity (light) | opacity (dark) | Use |
|---|---|---|---|---|---|---|
| `elev.hover` | — | 1 | 6 | 0.04 | 0.24 | Task row hover (subtle) |
| `elev.chrome` | — | 6 | 24 | 0.08 | 0.28 | Floating glass toolbar **only if** Liquid Glass unavailable |
| `elev.modal` | — | 20 | 48 | 0.16 | 0.40 | Quick Add panel backdrop |

---

## 8. Motion

```
motion.selection  = spring(response: 0.32, damping: 0.86)   # sidebar & row selection
motion.reveal     = spring(response: 0.42, damping: 0.82)   # sheet enter / exit
motion.hover      = .easeOut(duration: 0.12)                # colors, opacity
motion.glassMorph = spring(response: 0.38, damping: 0.80)   # glass transitions
```

Signature moment: **sidebar selection** uses `matchedGeometryEffect` on a single glass pill that glides between items. This is the one place we show off.

---

## 9. Liquid Glass API

All glass goes through one wrapper. Views **must not** call `.glassEffect` directly.

```swift
view
  .glassChrome(in: .capsule)                       // neutral chrome
  .glassChrome(in: shape, tint: theme.accent)      // selected / CTA
  .glassSheet(in: shape)                           // heavier, for modals
  .glassInteractive(in: shape)                     // adds .interactive() variant

GlassChromeCluster {                               // wraps adjacent glass (→ GlassEffectContainer)
  Button(...).glassChrome(in: .capsule)
  Button(...).glassChrome(in: .capsule)
}
```

Fallback (macOS < 26):
- `.glassChrome` → `.regularMaterial` + 1px 10%-white stroke + `elev.chrome` shadow
- `.glassSheet` → `.thickMaterial` + 1px 14%-white stroke + `elev.modal`
- `glassInteractive` adds scale(0.98) on press
- `GlassChromeCluster` is transparent (just ZStack)

---

## 10. Component Inventory

Reusable primitives live in `apple/TodoList/Sources/Views/Components/`.

| Component | Responsibility |
|---|---|
| `CanvasPage` | Wraps a scrollable paper page with standard horizontal padding and safe-area insets. |
| `ChromeBar` | Floating glass toolbar (title + glass cluster of actions). |
| `GlassChromeCluster` | Wraps adjacent glass elements so they merge correctly. |
| `Pill` | Capsule with optional icon, count, and tint. Used for filters and status chips. |
| `TaskRow` | Single task row — priority bar, checkbox, title, notes preview, meta chips. Never a card. |
| `SidebarItem` | One sidebar navigation row. |
| `SidebarSelectionIndicator` | The single matched-geometry glass pill that slides between selected items. |
| `PriorityBar` | 3pt left color bar — replaces the old colored dot + circle. |
| `SectionLabel` | The uppercase micro-label. Used at most twice per screen. |
| `InspectorField` | Two-column metadata row (label top, value below) — no card surface. |
| `EmptyState` | Small icon + one sentence. No card. No subtitle. |

---

## 11. Anti-Patterns (Deprecated, Do Not Use)

These are legacy and will be removed after the migration completes. `PasteTheme.swift` will remain only as a deprecation bridge.

| Deprecated | Replace with |
|---|---|
| `PasteBackdrop` | `CanvasPage` (solid canvas, no gradient) |
| `workbenchColumn`, `workbenchPanel`, `workbenchInset`, `workbenchRow`, `workbenchField`, `workbenchBadge` | `CanvasPage` / `Pill` / `TaskRow` / plain `TextField` styling |
| `pastePanel`, `pasteInsetPanel` | `glassSheet` / plain spacing |
| `MetricDock` | `ChromeBar` filter pills |
| `AdaptivePrimaryButtonStyle`, `AdaptiveGlassToolbarButtonStyle` | `.glassChrome(tint: theme.accent)` directly |

Removing filler copy is also part of the migration:

- Sidebar: delete `"Operator board"`, `"Fast scope switching for the board."`, `"Secondary slices. Keep them sparse."`
- Main list: no section subtitle, scope description lives only in the sidebar footer
- Quick Add: delete `"QUICK ADD"` micro-label, `"Capture the task and move on."`, `"This panel should help you..."`
- Inspector empty state: single line only

---

## 12. Settings Surface

The Settings window exposes theme selection as recipes with optional advanced overrides:

```
Appearance section
├── Display mode
├── Theme recipe
│   ├── Porcelain
│   ├── Ember
│   ├── Sumi
│   └── Custom based on <recipe>
├── Liquid Glass profile
└── Advanced overrides
    ├── Accent
    ├── Typography
    ├── Density
    └── Accessibility
```

Changing any advanced dimension switches the preset to `Custom based on <last recipe>` automatically.

Settings state extends `AppSettingsSnapshot` with:

```swift
struct ThemePreferences: Codable, Sendable {
    var preset: ThemePreset          // .porcelain
    var basePreset: ThemePreset?     // set when preset == .custom
    var lightAccent: AccentToken?
    var darkAccent: AccentToken?
    var typography: TypographyToken?
    var density: DensityToken?
    var liquidGlass: LiquidGlassToken?
    var reduceTransparency: Bool?
    var reduceMotion: Bool?
    var highContrast: Bool?
}
```

Persisted via the existing `settings` SQLite table as separate keys:
`theme_preset`, `theme_base_preset`, `theme_light_accent`, `theme_dark_accent`,
`theme_typography`, `theme_density`, `theme_liquid_glass`,
`theme_reduce_transparency`, `theme_reduce_motion`, `theme_high_contrast`.

---

## 13. Contribution Checklist

Before opening a PR that touches visuals, verify:

- [ ] No new `Color(red:green:blue:)` literals. Use `theme.*` or semantic tokens.
- [ ] No new `.font(.system(size:))`. Use `theme.type.*`.
- [ ] No card nested inside a card. If you need to group, use spacing + `SectionLabel`.
- [ ] No `.glassEffect` called directly. Use `.glassChrome` / `.glassSheet`.
- [ ] Any new copy went through the "does the user gain information from this line?" test. Delete if no.
- [ ] Screenshot added to PR for light + dark mode.

---

## 14. References

- [Human Interface Guidelines — Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [WWDC25 — Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025) *(session list — consult latest)*
- Things 3, Linear, Notion Calendar — industry baselines for premium minimalist todo UX
