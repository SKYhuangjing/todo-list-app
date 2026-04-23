import SwiftUI

enum ThemePreset: String, CaseIterable, Identifiable, Codable, Sendable {
    case porcelain
    case ember
    case sumi
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .porcelain: LocalizedText.string(.themePorcelain)
        case .ember: LocalizedText.string(.themeEmber)
        case .sumi: LocalizedText.string(.themeSumi)
        case .custom: LocalizedText.string(.themeCustom)
        }
    }

    var tagline: String {
        switch self {
        case .porcelain: LocalizedText.string(.themePorcelainTagline)
        case .ember: LocalizedText.string(.themeEmberTagline)
        case .sumi: LocalizedText.string(.themeSumiTagline)
        case .custom: LocalizedText.string(.themeCustomTagline)
        }
    }

    var accent: AccentToken {
        switch self {
        case .porcelain: .inkNavy
        case .ember: .warmOrange
        case .sumi: .graphite
        case .custom: .inkNavy
        }
    }

    var typography: TypographyToken {
        switch self {
        case .porcelain: .sfPro
        case .ember: .sfPro
        case .sumi: .sfPro
        case .custom: .sfPro
        }
    }

    var density: DensityToken {
        switch self {
        case .porcelain: .comfortable
        case .ember: .comfortable
        case .sumi: .compact
        case .custom: .comfortable
        }
    }
}

struct Theme: Equatable, Sendable {
    var preset: ThemePreset
    var accent: AccentToken
    var typography: TypographyToken
    var density: DensityToken

    var accentColor: Color { accent.color }

    var type: TypeScale { TypeScale.resolve(for: typography) }

    var metrics: DensityMetrics { DensityMetrics.resolve(for: density) }

    static let porcelain: Theme = Theme(preset: .porcelain)
    static let ember: Theme = Theme(preset: .ember)
    static let sumi: Theme = Theme(preset: .sumi)

    init(preset: ThemePreset) {
        self.preset = preset
        self.accent = preset.accent
        self.typography = preset.typography
        self.density = preset.density
    }

    init(accent: AccentToken, typography: TypographyToken, density: DensityToken) {
        if let matched = Self.matchingPreset(accent: accent, typography: typography, density: density) {
            self.preset = matched
        } else {
            self.preset = .custom
        }
        self.accent = accent
        self.typography = typography
        self.density = density
    }

    static func matchingPreset(accent: AccentToken, typography: TypographyToken, density: DensityToken) -> ThemePreset? {
        for preset in [ThemePreset.porcelain, .ember, .sumi] {
            if preset.accent == accent && preset.typography == typography && preset.density == density {
                return preset
            }
        }
        return nil
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .porcelain
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    func theme(_ theme: Theme) -> some View {
        environment(\.theme, theme)
    }
}
