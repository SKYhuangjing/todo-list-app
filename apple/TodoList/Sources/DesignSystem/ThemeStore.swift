import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class ThemeStore {
    private(set) var theme: Theme

    private let defaults: UserDefaults
    private let accentKey = "theme.accent"
    private let lightAccentKey = "theme.light.accent"
    private let lightCustomAccentKey = "theme.light.customAccent"
    private let darkAccentKey = "theme.dark.accent"
    private let darkCustomAccentKey = "theme.dark.customAccent"
    private let typographyKey = "theme.typography"
    private let densityKey = "theme.density"
    private let liquidGlassKey = "theme.liquidGlass"
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

        let legacyAccent = AccentToken(rawValue: defaults.string(forKey: accentKey) ?? "") ?? .inkNavy
        let lightAccent = AccentToken(rawValue: defaults.string(forKey: lightAccentKey) ?? "") ?? legacyAccent
        let darkAccent = AccentToken(rawValue: defaults.string(forKey: darkAccentKey) ?? "") ?? .porcelainBlue
        let light = ThemeTone(accent: lightAccent, customAccentHex: defaults.string(forKey: lightCustomAccentKey))
        let dark = ThemeTone(accent: darkAccent, customAccentHex: defaults.string(forKey: darkCustomAccentKey))
        let typography = TypographyToken(rawValue: defaults.string(forKey: typographyKey) ?? "") ?? .sfPro
        let density = DensityToken(rawValue: defaults.string(forKey: densityKey) ?? "") ?? .comfortable
        let liquidGlass = LiquidGlassToken(rawValue: defaults.string(forKey: liquidGlassKey) ?? "") ?? .clear
        self.theme = Theme(light: light, dark: dark, typography: typography, density: density, liquidGlass: liquidGlass)
    }

    func applyPreset(_ preset: ThemePreset) {
        var next = Theme(preset: preset)
        next.liquidGlass = theme.liquidGlass
        theme = next
        persist()
    }

    func setAccent(_ token: AccentToken, for colorScheme: ColorScheme) {
        setTone(ThemeTone(accent: token), for: colorScheme)
    }

    func setCustomAccent(_ color: Color, for colorScheme: ColorScheme) {
        let fallback = colorScheme == .dark ? theme.dark.accent : theme.light.accent
        setTone(
            ThemeTone(accent: fallback, customAccentHex: color.hexString),
            for: colorScheme
        )
    }

    func clearCustomAccent(for colorScheme: ColorScheme) {
        let tone = colorScheme == .dark ? theme.dark : theme.light
        setTone(ThemeTone(accent: tone.accent), for: colorScheme)
    }

    private func setTone(_ tone: ThemeTone, for colorScheme: ColorScheme) {
        if colorScheme == .dark {
            theme = Theme(light: theme.light, dark: tone, typography: theme.typography, density: theme.density, liquidGlass: theme.liquidGlass)
        } else {
            theme = Theme(light: tone, dark: theme.dark, typography: theme.typography, density: theme.density, liquidGlass: theme.liquidGlass)
        }
        persist()
    }

    func setTypography(_ token: TypographyToken) {
        theme = Theme(light: theme.light, dark: theme.dark, typography: token, density: theme.density, liquidGlass: theme.liquidGlass)
        persist()
    }

    func setDensity(_ token: DensityToken) {
        theme = Theme(light: theme.light, dark: theme.dark, typography: theme.typography, density: token, liquidGlass: theme.liquidGlass)
        persist()
    }

    func setLiquidGlass(_ token: LiquidGlassToken) {
        theme = Theme(light: theme.light, dark: theme.dark, typography: theme.typography, density: theme.density, liquidGlass: token)
        persist()
    }

    private func persist() {
        defaults.set(theme.light.accent.rawValue, forKey: accentKey)
        defaults.set(theme.light.accent.rawValue, forKey: lightAccentKey)
        defaults.set(theme.light.customAccentHex, forKey: lightCustomAccentKey)
        defaults.set(theme.dark.accent.rawValue, forKey: darkAccentKey)
        defaults.set(theme.dark.customAccentHex, forKey: darkCustomAccentKey)
        defaults.set(theme.typography.rawValue, forKey: typographyKey)
        defaults.set(theme.density.rawValue, forKey: densityKey)
        defaults.set(theme.liquidGlass.rawValue, forKey: liquidGlassKey)
    }
}
