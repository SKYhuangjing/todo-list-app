import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

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

    var lightAccent: AccentToken {
        switch self {
        case .porcelain: .inkNavy
        case .ember: .warmOrange
        case .sumi: .graphite
        case .custom: .inkNavy
        }
    }

    var darkAccent: AccentToken {
        switch self {
        case .porcelain: .porcelainBlue
        case .ember: .warmOrange
        case .sumi: .graphite
        case .custom: .porcelainBlue
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

enum LiquidGlassToken: String, CaseIterable, Identifiable, Codable, Sendable {
    case clear
    case tinted

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .clear: LocalizedText.string(.liquidGlassClear)
        case .tinted: LocalizedText.string(.liquidGlassTinted)
        }
    }

    var tagline: String {
        switch self {
        case .clear: LocalizedText.string(.liquidGlassClearTagline)
        case .tinted: LocalizedText.string(.liquidGlassTintedTagline)
        }
    }
}

struct ThemeTone: Equatable, Codable, Sendable {
    var accent: AccentToken
    var customAccentHex: String?

    var usesCustomAccent: Bool { customAccentHex != nil }

    func accentColor(for colorScheme: ColorScheme) -> Color {
        if let customAccentHex, let color = Color(hex: customAccentHex) {
            return color
        }
        return accent.color(for: colorScheme)
    }
}

struct Theme: Equatable, Sendable {
    var preset: ThemePreset
    var light: ThemeTone
    var dark: ThemeTone
    var typography: TypographyToken
    var density: DensityToken
    var liquidGlass: LiquidGlassToken

    var accentColor: Color {
        Self.adaptive(light: light.accentColor(for: .light), dark: dark.accentColor(for: .dark))
    }

    var type: TypeScale { TypeScale.resolve(for: typography) }

    var metrics: DensityMetrics { DensityMetrics.resolve(for: density) }

    static let porcelain: Theme = Theme(preset: .porcelain)
    static let ember: Theme = Theme(preset: .ember)
    static let sumi: Theme = Theme(preset: .sumi)

    init(preset: ThemePreset) {
        self.preset = preset
        self.light = ThemeTone(accent: preset.lightAccent)
        self.dark = ThemeTone(accent: preset.darkAccent)
        self.typography = preset.typography
        self.density = preset.density
        self.liquidGlass = .clear
    }

    init(
        light: ThemeTone,
        dark: ThemeTone,
        typography: TypographyToken,
        density: DensityToken,
        liquidGlass: LiquidGlassToken = .clear
    ) {
        if let matched = Self.matchingPreset(light: light, dark: dark, typography: typography, density: density) {
            self.preset = matched
        } else {
            self.preset = .custom
        }
        self.light = light
        self.dark = dark
        self.typography = typography
        self.density = density
        self.liquidGlass = liquidGlass
    }

    static func matchingPreset(light: ThemeTone, dark: ThemeTone, typography: TypographyToken, density: DensityToken) -> ThemePreset? {
        for preset in [ThemePreset.porcelain, .ember, .sumi] {
            if !light.usesCustomAccent
                && !dark.usesCustomAccent
                && preset.lightAccent == light.accent
                && preset.darkAccent == dark.accent
                && preset.typography == typography
                && preset.density == density {
                return preset
            }
        }
        return nil
    }

    private static func adaptive(light: Color, dark: Color) -> Color {
        #if canImport(AppKit)
        return Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
            return NSColor(isDark ? dark : light)
        })
        #else
        return light
        #endif
    }
}

extension Color {
    init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else {
            return nil
        }

        self.init(
            red: Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8) & 0xFF) / 255.0,
            blue: Double(value & 0xFF) / 255.0
        )
    }

    var hexString: String? {
        #if canImport(AppKit)
        guard let color = NSColor(self).usingColorSpace(.sRGB) else {
            return nil
        }
        let red = Int(round(color.redComponent * 255.0))
        let green = Int(round(color.greenComponent * 255.0))
        let blue = Int(round(color.blueComponent * 255.0))
        return String(format: "#%02X%02X%02X", red, green, blue)
        #else
        return nil
        #endif
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
