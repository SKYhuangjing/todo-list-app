import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class ThemeStore {
    private(set) var theme: Theme

    private let defaults: UserDefaults
    private let accentKey = "theme.accent"
    private let presetKey = "theme.preset"
    private let basePresetKey = "theme.basePreset"
    private let lightAccentKey = "theme.light.accent"
    private let lightCustomAccentKey = "theme.light.customAccent"
    private let darkAccentKey = "theme.dark.accent"
    private let darkCustomAccentKey = "theme.dark.customAccent"
    private let typographyKey = "theme.typography"
    private let densityKey = "theme.density"
    private let liquidGlassKey = "theme.liquidGlass"
    private let motionKey = "theme.motion"
    private let elevationKey = "theme.elevation"
    private let reduceTransparencyKey = "theme.reduceTransparency"
    private let reduceMotionKey = "theme.reduceMotion"
    private let highContrastKey = "theme.highContrast"
    private let accentMigrationKey = "theme.accent.migratedTo.inkNavy"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if !defaults.bool(forKey: accentMigrationKey) {
            let stored = defaults.string(forKey: accentKey)
            if stored == AccentToken.porcelainBlue.rawValue
                || stored == AccentToken.systemAccent.rawValue
                || stored == nil {
                defaults.set(AccentToken.inkNavy.rawValue, forKey: accentKey)
            }
            defaults.set(true, forKey: accentMigrationKey)
        }

        self.theme = Self.loadTheme(defaults: defaults)
    }

    func applyPreset(_ preset: ThemePreset) {
        theme = Theme(preset: preset)
        persist()
    }

    func setAccent(_ token: AccentToken, for colorScheme: ColorScheme) {
        customize { draft in
            if colorScheme == .dark {
                draft.dark = ThemeTone(accent: token)
            } else {
                draft.light = ThemeTone(accent: token)
            }
        }
    }

    func setCustomAccent(_ color: Color, for colorScheme: ColorScheme) {
        customize { draft in
            let fallback = colorScheme == .dark ? draft.dark.accent : draft.light.accent
            let tone = ThemeTone(accent: fallback, customAccentHex: color.hexString)
            if colorScheme == .dark {
                draft.dark = tone
            } else {
                draft.light = tone
            }
        }
    }

    func clearCustomAccent(for colorScheme: ColorScheme) {
        customize { draft in
            let tone = colorScheme == .dark ? draft.dark : draft.light
            if colorScheme == .dark {
                draft.dark = ThemeTone(accent: tone.accent)
            } else {
                draft.light = ThemeTone(accent: tone.accent)
            }
        }
    }

    func setTypography(_ token: TypographyToken) {
        customize { $0.typography = token }
    }

    func setDensity(_ token: DensityToken) {
        customize { $0.density = token }
    }

    func setLiquidGlass(_ token: LiquidGlassToken) {
        customize { $0.liquidGlass = token }
    }

    func setReduceTransparency(_ value: Bool) {
        customize { $0.reduceTransparency = value }
    }

    func setReduceMotion(_ value: Bool) {
        customize { $0.reduceMotion = value }
    }

    func setHighContrast(_ value: Bool) {
        customize { $0.highContrast = value }
    }

    private func customize(_ update: (inout Theme) -> Void) {
        var draft = theme
        let base = draft.effectivePreset
        update(&draft)
        theme = Theme(
            preset: .custom,
            basePreset: base,
            light: draft.light,
            dark: draft.dark,
            typography: draft.typography,
            density: draft.density,
            liquidGlass: draft.liquidGlass,
            motion: draft.motion,
            elevation: draft.elevation,
            reduceTransparency: draft.reduceTransparency,
            reduceMotion: draft.reduceMotion,
            highContrast: draft.highContrast
        )
        persist()
    }

    private static func loadTheme(defaults: UserDefaults) -> Theme {
        let storedPreset = ThemePreset(rawValue: defaults.string(forKey: "theme.preset") ?? "")
        let hasLegacyThemeValues = defaults.object(forKey: "theme.accent") != nil
            || defaults.object(forKey: "theme.light.accent") != nil
            || defaults.object(forKey: "theme.dark.accent") != nil
            || defaults.object(forKey: "theme.typography") != nil
            || defaults.object(forKey: "theme.density") != nil
            || defaults.object(forKey: "theme.liquidGlass") != nil
        if storedPreset == nil && !hasLegacyThemeValues {
            return Theme(preset: .porcelain)
        }
        let preset = storedPreset ?? .porcelain
        let recipe = preset.recipe
        let basePreset = ThemePreset(rawValue: defaults.string(forKey: "theme.basePreset") ?? "") ?? preset

        let legacyAccent = AccentToken(rawValue: defaults.string(forKey: "theme.accent") ?? "") ?? recipe.lightAccent
        let lightAccent = AccentToken(rawValue: defaults.string(forKey: "theme.light.accent") ?? "") ?? legacyAccent
        let darkAccent = AccentToken(rawValue: defaults.string(forKey: "theme.dark.accent") ?? "") ?? recipe.darkAccent
        let light = ThemeTone(accent: lightAccent, customAccentHex: defaults.string(forKey: "theme.light.customAccent"))
        let dark = ThemeTone(accent: darkAccent, customAccentHex: defaults.string(forKey: "theme.dark.customAccent"))
        let typography = TypographyToken(rawValue: defaults.string(forKey: "theme.typography") ?? "") ?? recipe.typography
        let density = DensityToken(rawValue: defaults.string(forKey: "theme.density") ?? "") ?? recipe.density
        let liquidGlass = LiquidGlassToken(rawValue: defaults.string(forKey: "theme.liquidGlass") ?? "") ?? recipe.liquidGlass
        let motion = MotionToken(rawValue: defaults.string(forKey: "theme.motion") ?? "") ?? recipe.motion
        let elevation = ElevationToken(rawValue: defaults.string(forKey: "theme.elevation") ?? "") ?? recipe.elevation

        return Theme(
            preset: storedPreset == nil ? .custom : preset,
            basePreset: basePreset,
            light: light,
            dark: dark,
            typography: typography,
            density: density,
            liquidGlass: liquidGlass,
            motion: motion,
            elevation: elevation,
            reduceTransparency: defaults.bool(forKey: "theme.reduceTransparency"),
            reduceMotion: defaults.bool(forKey: "theme.reduceMotion"),
            highContrast: defaults.bool(forKey: "theme.highContrast")
        )
    }

    private func persist() {
        defaults.set(theme.preset.rawValue, forKey: presetKey)
        defaults.set(theme.basePreset.rawValue, forKey: basePresetKey)
        defaults.set(theme.light.accent.rawValue, forKey: accentKey)
        defaults.set(theme.light.accent.rawValue, forKey: lightAccentKey)
        defaults.set(theme.light.customAccentHex, forKey: lightCustomAccentKey)
        defaults.set(theme.dark.accent.rawValue, forKey: darkAccentKey)
        defaults.set(theme.dark.customAccentHex, forKey: darkCustomAccentKey)
        defaults.set(theme.typography.rawValue, forKey: typographyKey)
        defaults.set(theme.density.rawValue, forKey: densityKey)
        defaults.set(theme.liquidGlass.rawValue, forKey: liquidGlassKey)
        defaults.set(theme.motion.rawValue, forKey: motionKey)
        defaults.set(theme.elevation.rawValue, forKey: elevationKey)
        defaults.set(theme.reduceTransparency, forKey: reduceTransparencyKey)
        defaults.set(theme.reduceMotion, forKey: reduceMotionKey)
        defaults.set(theme.highContrast, forKey: highContrastKey)
    }
}
