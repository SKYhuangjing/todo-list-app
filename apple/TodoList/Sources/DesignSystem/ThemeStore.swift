import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class ThemeStore {
    private(set) var theme: Theme

    private let defaults: UserDefaults
    private let accentKey = "theme.accent"
    private let typographyKey = "theme.typography"
    private let densityKey = "theme.density"
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

        let accent = AccentToken(rawValue: defaults.string(forKey: accentKey) ?? "") ?? .inkNavy
        let typography = TypographyToken(rawValue: defaults.string(forKey: typographyKey) ?? "") ?? .sfPro
        let density = DensityToken(rawValue: defaults.string(forKey: densityKey) ?? "") ?? .comfortable
        self.theme = Theme(accent: accent, typography: typography, density: density)
    }

    func applyPreset(_ preset: ThemePreset) {
        theme = Theme(preset: preset)
        persist()
    }

    func setAccent(_ token: AccentToken) {
        theme = Theme(accent: token, typography: theme.typography, density: theme.density)
        persist()
    }

    func setTypography(_ token: TypographyToken) {
        theme = Theme(accent: theme.accent, typography: token, density: theme.density)
        persist()
    }

    func setDensity(_ token: DensityToken) {
        theme = Theme(accent: theme.accent, typography: theme.typography, density: token)
        persist()
    }

    private func persist() {
        defaults.set(theme.accent.rawValue, forKey: accentKey)
        defaults.set(theme.typography.rawValue, forKey: typographyKey)
        defaults.set(theme.density.rawValue, forKey: densityKey)
    }
}
