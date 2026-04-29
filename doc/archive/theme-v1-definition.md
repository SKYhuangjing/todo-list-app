# Theme V1 Definition Archive

> Archived on 2026-04-29.
>
> This document preserves the V1 theme model that existed before the Theme V2 recipe model in `doc/DESIGN-SYSTEM.md`.
> It is historical reference only. Current implementation and future design decisions should use the V2 definition in `doc/DESIGN-SYSTEM.md`.

## Theme Model

The Theme is three independent dimensions composed together. Users change any dimension; the app resolves to live tokens.

```text
Theme = Accent x Typography x Density
```

## Accent Palette

| Token | Hex (light) | Hex (dark) | When to pick |
|---|---|---|---|
| `porcelainBlue` **(default)** | `#3A6FE0` | `#6C93F2` | Clean + premium. Neutral-cool. Think Things 3 / Linear. |
| `warmOrange` | `#F08A2C` | `#FFA347` | Warm, food-for-thought. Legacy brand color. |
| `forestGreen` | `#2F9E65` | `#45C281` | Productivity-forward. Caution: collides with Done semantics. |
| `violet` | `#7C5AE8` | `#A48CFF` | Showcases Liquid Glass refraction most dramatically. |
| `systemAccent` | `NSColor.controlAccentColor` | same | Fully native. User controls in System Settings. No brand opinion. |

## Typography Family

| Token | Display / Title | Body | Numbers |
|---|---|---|---|
| `sfPro` **(default)** | SF Pro | SF Pro | SF Mono |
| `sfProRounded` | SF Pro Rounded | SF Pro | SF Mono |
| `newYork` | New York (serif) | SF Pro | SF Mono |

## Density

| Token | Task row height | Section padding | Sidebar row height | Max tasks per screen @1200pt tall |
|---|---|---|---|---|
| `compact` | 36pt | 10 / 14 | 32pt | ~15 |
| `balanced` **(default)** | 48pt | 14 / 18 | 36pt | ~10 |
| `comfortable` | 62pt | 18 / 22 | 42pt | ~7 |

## Presets

| Preset | Accent | Typography | Density | Feel |
|---|---|---|---|---|
| **Porcelain** (default) | porcelainBlue | sfPro | balanced | Clean, restrained, premium |
| **Ember** | warmOrange | sfPro | comfortable | Warm, approachable, magazine-y |
| **Sumi** | systemAccent (near-black via Graphite UI) | sfPro | compact | Monochrome, high-information |

## Color Tokens

Foreground and surface are derived from system colors. V1 did not define a theme-owned surface palette.

```text
foreground.primary      = NSColor.labelColor
foreground.secondary    = NSColor.secondaryLabelColor
foreground.tertiary     = NSColor.tertiaryLabelColor
foreground.quaternary   = NSColor.quaternaryLabelColor

canvas.base             = NSColor.textBackgroundColor
canvas.elevated         = NSColor.underPageBackgroundColor

separator.soft          = NSColor.separatorColor.withAlpha(0.35)
separator.regular       = NSColor.separatorColor.withAlpha(0.65)

accent                  = Theme.accent
```

Semantic colors are fixed and theme-independent:

```text
priority.p1 = systemRed
priority.p2 = systemOrange
priority.p3 = systemBlue
priority.p4 = systemGray

status.done     = systemGreen
status.overdue  = systemOrange
status.info     = systemBlue
```

## Settings Surface

The Settings window exposes theme selection through three dimensions, each with a live preview on the right:

```text
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

