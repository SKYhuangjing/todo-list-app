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
        case .ember: .forestGreen
        case .sumi: .violet
        case .custom: .porcelainBlue
        }
    }

    var typography: TypographyToken {
        switch self {
        case .porcelain: .sfPro
        case .ember: .sfProRounded
        case .sumi: .newYork
        case .custom: .sfPro
        }
    }

    var density: DensityToken {
        switch self {
        case .porcelain: .comfortable
        case .ember: .balanced
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

    func palette(for colorScheme: ColorScheme) -> ThemePalette {
        ThemePalette.resolve(preset: preset, colorScheme: colorScheme)
    }

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

struct ThemePalette {
    let canvas: Color
    let canvasElevated: Color
    let sidebar: Color
    let recessedControl: Color
    let selectedControl: Color
    let separator: Color

    static func resolve(preset: ThemePreset, colorScheme: ColorScheme) -> ThemePalette {
        switch (preset, colorScheme) {
        case (.porcelain, .light):
            return ThemePalette(
                canvas: Color(red: 0.968, green: 0.956, blue: 0.928),
                canvasElevated: Color(red: 1.000, green: 0.990, blue: 0.968),
                sidebar: Color(red: 0.914, green: 0.900, blue: 0.866),
                recessedControl: Color(red: 0.930, green: 0.916, blue: 0.886),
                selectedControl: Color(red: 1.000, green: 0.972, blue: 0.920),
                separator: Color.black.opacity(0.09)
            )
        case (.ember, .light):
            return ThemePalette(
                canvas: Color(red: 1.000, green: 0.936, blue: 0.888),
                canvasElevated: Color(red: 1.000, green: 0.978, blue: 0.936),
                sidebar: Color(red: 0.944, green: 0.828, blue: 0.750),
                recessedControl: Color(red: 0.972, green: 0.890, blue: 0.828),
                selectedControl: Color(red: 1.000, green: 0.910, blue: 0.800),
                separator: Color(red: 0.420, green: 0.190, blue: 0.080).opacity(0.16)
            )
        case (.sumi, .light):
            return ThemePalette(
                canvas: Color(red: 0.936, green: 0.944, blue: 0.952),
                canvasElevated: Color(red: 0.988, green: 0.990, blue: 0.992),
                sidebar: Color(red: 0.870, green: 0.884, blue: 0.900),
                recessedControl: Color(red: 0.902, green: 0.912, blue: 0.928),
                selectedControl: Color(red: 0.948, green: 0.960, blue: 0.976),
                separator: Color.black.opacity(0.12)
            )
        case (.custom, .light):
            return ThemePalette(
                canvas: Color(red: 0.958, green: 0.960, blue: 0.954),
                canvasElevated: Color(red: 0.996, green: 0.996, blue: 0.990),
                sidebar: Color(red: 0.914, green: 0.916, blue: 0.910),
                recessedControl: Color(red: 0.928, green: 0.930, blue: 0.924),
                selectedControl: Color(red: 0.982, green: 0.984, blue: 0.976),
                separator: Color.black.opacity(0.10)
            )
        case (.porcelain, .dark):
            return ThemePalette(
                canvas: Color(red: 0.074, green: 0.074, blue: 0.062),
                canvasElevated: Color(red: 0.122, green: 0.118, blue: 0.098),
                sidebar: Color(red: 0.100, green: 0.098, blue: 0.082),
                recessedControl: Color(red: 0.172, green: 0.166, blue: 0.138),
                selectedControl: Color(red: 0.220, green: 0.202, blue: 0.158),
                separator: Color.white.opacity(0.10)
            )
        case (.ember, .dark):
            return ThemePalette(
                canvas: Color(red: 0.118, green: 0.064, blue: 0.040),
                canvasElevated: Color(red: 0.180, green: 0.092, blue: 0.052),
                sidebar: Color(red: 0.142, green: 0.074, blue: 0.046),
                recessedControl: Color(red: 0.228, green: 0.124, blue: 0.074),
                selectedControl: Color(red: 0.298, green: 0.156, blue: 0.082),
                separator: Color(red: 1.000, green: 0.620, blue: 0.320).opacity(0.14)
            )
        case (.sumi, .dark):
            return ThemePalette(
                canvas: Color(red: 0.040, green: 0.046, blue: 0.056),
                canvasElevated: Color(red: 0.080, green: 0.088, blue: 0.104),
                sidebar: Color(red: 0.060, green: 0.066, blue: 0.078),
                recessedControl: Color(red: 0.122, green: 0.132, blue: 0.150),
                selectedControl: Color(red: 0.168, green: 0.180, blue: 0.204),
                separator: Color.white.opacity(0.12)
            )
        case (.custom, .dark):
            return ThemePalette(
                canvas: Color(red: 0.068, green: 0.070, blue: 0.066),
                canvasElevated: Color(red: 0.116, green: 0.118, blue: 0.112),
                sidebar: Color(red: 0.094, green: 0.096, blue: 0.090),
                recessedControl: Color(red: 0.170, green: 0.172, blue: 0.162),
                selectedControl: Color(red: 0.206, green: 0.208, blue: 0.196),
                separator: Color.white.opacity(0.10)
            )
        @unknown default:
            return ThemePalette.resolve(preset: .porcelain, colorScheme: .light)
        }
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
