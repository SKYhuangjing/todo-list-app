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

## 2. Themes (User-Selectable)

The Theme is three independent dimensions composed together. Users change any dimension; the app resolves to live tokens.

```
Theme = Accent × Typography × Density
```

### Accent palette

| Token | Hex (light) | Hex (dark) | When to pick |
|---|---|---|---|
| `porcelainBlue` **(default)** | `#3A6FE0` | `#6C93F2` | Clean + premium. Neutral-cool. Think Things 3 / Linear. |
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

### Presets (one-click shortcut)

| Preset | Accent | Typography | Density | Feel |
|---|---|---|---|---|
| **Porcelain** (default) | porcelainBlue | sfPro | balanced | Clean, restrained, premium |
| **Ember** | warmOrange | sfPro | comfortable | Warm, approachable, magazine-y |
| **Sumi** | systemAccent (near-black via Graphite UI) | sfPro | compact | Monochrome, high-information |

---

## 3. Color Tokens

Foreground and surface are **derived from system colors**. We do not invent greys.

```
foreground.primary      = NSColor.labelColor
foreground.secondary    = NSColor.secondaryLabelColor
foreground.tertiary     = NSColor.tertiaryLabelColor
foreground.quaternary   = NSColor.quaternaryLabelColor

canvas.base             = NSColor.textBackgroundColor          # near-white / near-black
canvas.elevated         = NSColor.underPageBackgroundColor     # used behind Quick Add sheet

separator.soft          = NSColor.separatorColor.withAlpha(0.35)
separator.regular       = NSColor.separatorColor.withAlpha(0.65)

accent                  = Theme.accent              # single source for brand tint
```

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

The Settings window exposes theme selection through three dimensions, each with a live preview on the right:

```
Appearance section
├── Preset (Porcelain / Ember / Sumi / Custom)
├── Accent       (5 swatches)
├── Typography   (3 samples showing "Today · 3 tasks")
└── Density      (3 list previews)
```

Changing any individual dimension switches the preset to `Custom` automatically.

Settings state extends `AppSettingsSnapshot` with:

```swift
struct ThemePreferences: Codable, Sendable {
    var accent: AccentToken        // .porcelainBlue (default)
    var typography: TypographyToken // .sfPro
    var density: DensityToken       // .balanced
}
```

Persisted via the existing `settings` SQLite table as four new keys:
`theme_preset`, `theme_accent`, `theme_typography`, `theme_density`.

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
