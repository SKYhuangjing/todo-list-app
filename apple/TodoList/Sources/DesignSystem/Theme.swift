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
        case .ember: .sage
        case .sumi: .graphite
        case .custom: .inkNavy
        }
    }

    var darkAccent: AccentToken {
        switch self {
        case .porcelain: .porcelainBlue
        case .ember: .sage
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

    var recipe: ThemeRecipe {
        switch self {
        case .porcelain:
            ThemeRecipe(
                preset: self,
                lightAccent: lightAccent,
                darkAccent: darkAccent,
                typography: typography,
                density: density,
                liquidGlass: .clear,
                motion: .calm,
                elevation: .soft
            )
        case .ember:
            ThemeRecipe(
                preset: self,
                lightAccent: lightAccent,
                darkAccent: darkAccent,
                typography: typography,
                density: density,
                liquidGlass: .tinted,
                motion: .warm,
                elevation: .warm
            )
        case .sumi:
            ThemeRecipe(
                preset: self,
                lightAccent: lightAccent,
                darkAccent: darkAccent,
                typography: typography,
                density: density,
                liquidGlass: .reduced,
                motion: .minimal,
                elevation: .crisp
            )
        case .custom:
            ThemePreset.porcelain.recipe
        }
    }
}

enum LiquidGlassToken: String, CaseIterable, Identifiable, Codable, Sendable {
    case reduced
    case clear
    case tinted
    case vivid

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .reduced: LocalizedText.string(.liquidGlassReduced)
        case .clear: LocalizedText.string(.liquidGlassClear)
        case .tinted: LocalizedText.string(.liquidGlassTinted)
        case .vivid: LocalizedText.string(.liquidGlassVivid)
        }
    }

    var tagline: String {
        switch self {
        case .reduced: LocalizedText.string(.liquidGlassReducedTagline)
        case .clear: LocalizedText.string(.liquidGlassClearTagline)
        case .tinted: LocalizedText.string(.liquidGlassTintedTagline)
        case .vivid: LocalizedText.string(.liquidGlassVividTagline)
        }
    }
}

enum MotionToken: String, Codable, Equatable, Sendable {
    case calm
    case warm
    case minimal
}

enum ElevationToken: String, Codable, Equatable, Sendable {
    case soft
    case warm
    case crisp
}

struct ThemeRecipe: Codable, Sendable {
    let preset: ThemePreset
    let lightAccent: AccentToken
    let darkAccent: AccentToken
    let typography: TypographyToken
    let density: DensityToken
    let liquidGlass: LiquidGlassToken
    let motion: MotionToken
    let elevation: ElevationToken
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
    var basePreset: ThemePreset
    var light: ThemeTone
    var dark: ThemeTone
    var typography: TypographyToken
    var density: DensityToken
    var liquidGlass: LiquidGlassToken
    var motion: MotionToken
    var elevation: ElevationToken
    var reduceTransparency: Bool
    var reduceMotion: Bool
    var highContrast: Bool

    var accentColor: Color {
        Self.adaptive(light: light.accentColor(for: .light), dark: dark.accentColor(for: .dark))
    }

    var type: TypeScale { TypeScale.resolve(for: typography) }

    var metrics: DensityMetrics { DensityMetrics.resolve(for: density) }

    var effectivePreset: ThemePreset {
        preset == .custom ? basePreset : preset
    }

    var effectiveLiquidGlass: LiquidGlassToken {
        reduceTransparency ? .reduced : liquidGlass
    }

    func palette(for colorScheme: ColorScheme) -> ThemePalette {
        ThemePalette.resolve(preset: effectivePreset, colorScheme: colorScheme, highContrast: highContrast)
    }

    static let porcelain: Theme = Theme(preset: .porcelain)
    static let ember: Theme = Theme(preset: .ember)
    static let sumi: Theme = Theme(preset: .sumi)

    init(preset: ThemePreset) {
        let recipe = preset.recipe
        self.preset = recipe.preset
        self.basePreset = recipe.preset
        self.light = ThemeTone(accent: recipe.lightAccent)
        self.dark = ThemeTone(accent: recipe.darkAccent)
        self.typography = recipe.typography
        self.density = recipe.density
        self.liquidGlass = recipe.liquidGlass
        self.motion = recipe.motion
        self.elevation = recipe.elevation
        self.reduceTransparency = false
        self.reduceMotion = false
        self.highContrast = false
    }

    init(
        preset: ThemePreset = .custom,
        basePreset: ThemePreset = .porcelain,
        light: ThemeTone,
        dark: ThemeTone,
        typography: TypographyToken,
        density: DensityToken,
        liquidGlass: LiquidGlassToken = .clear,
        motion: MotionToken = .calm,
        elevation: ElevationToken = .soft,
        reduceTransparency: Bool = false,
        reduceMotion: Bool = false,
        highContrast: Bool = false
    ) {
        if let matched = Self.matchingPreset(
            light: light,
            dark: dark,
            typography: typography,
            density: density,
            liquidGlass: liquidGlass,
            motion: motion,
            elevation: elevation,
            reduceTransparency: reduceTransparency,
            reduceMotion: reduceMotion,
            highContrast: highContrast
        ) {
            self.preset = matched
            self.basePreset = matched
        } else {
            self.preset = preset
            self.basePreset = basePreset == .custom ? .porcelain : basePreset
        }
        self.light = light
        self.dark = dark
        self.typography = typography
        self.density = density
        self.liquidGlass = liquidGlass
        self.motion = motion
        self.elevation = elevation
        self.reduceTransparency = reduceTransparency
        self.reduceMotion = reduceMotion
        self.highContrast = highContrast
    }

    static func matchingPreset(
        light: ThemeTone,
        dark: ThemeTone,
        typography: TypographyToken,
        density: DensityToken,
        liquidGlass: LiquidGlassToken,
        motion: MotionToken,
        elevation: ElevationToken,
        reduceTransparency: Bool,
        reduceMotion: Bool,
        highContrast: Bool
    ) -> ThemePreset? {
        guard !reduceTransparency, !reduceMotion, !highContrast else { return nil }
        for preset in [ThemePreset.porcelain, .ember, .sumi] {
            let recipe = preset.recipe
            if !light.usesCustomAccent
                && !dark.usesCustomAccent
                && recipe.lightAccent == light.accent
                && recipe.darkAccent == dark.accent
                && recipe.typography == typography
                && recipe.density == density
                && recipe.liquidGlass == liquidGlass
                && recipe.motion == motion
                && recipe.elevation == elevation {
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

    static func resolve(preset: ThemePreset, colorScheme: ColorScheme, highContrast: Bool = false) -> ThemePalette {
        let palette: ThemePalette
        switch (preset, colorScheme) {
        case (.porcelain, .light):
            palette = ThemePalette(
                canvas: Color(red: 0.968, green: 0.956, blue: 0.928),
                canvasElevated: Color(red: 1.000, green: 0.990, blue: 0.968),
                sidebar: Color(red: 0.914, green: 0.900, blue: 0.866),
                recessedControl: Color(red: 0.930, green: 0.916, blue: 0.886),
                selectedControl: Color(red: 1.000, green: 0.972, blue: 0.920),
                separator: Color.black.opacity(0.09)
            )
        case (.ember, .light):
            palette = ThemePalette(
                canvas: Color(red: 0.953, green: 0.961, blue: 0.937),
                canvasElevated: Color(red: 0.984, green: 0.988, blue: 0.969),
                sidebar: Color(red: 0.894, green: 0.914, blue: 0.867),
                recessedControl: Color(red: 0.922, green: 0.937, blue: 0.902),
                selectedControl: Color(red: 0.965, green: 0.945, blue: 0.867),
                separator: Color(red: 0.220, green: 0.310, blue: 0.240).opacity(0.12)
            )
        case (.sumi, .light):
            palette = ThemePalette(
                canvas: Color(red: 0.936, green: 0.944, blue: 0.952),
                canvasElevated: Color(red: 0.988, green: 0.990, blue: 0.992),
                sidebar: Color(red: 0.870, green: 0.884, blue: 0.900),
                recessedControl: Color(red: 0.902, green: 0.912, blue: 0.928),
                selectedControl: Color(red: 0.948, green: 0.960, blue: 0.976),
                separator: Color.black.opacity(0.12)
            )
        case (.custom, .light):
            palette = ThemePalette(
                canvas: Color(red: 0.958, green: 0.960, blue: 0.954),
                canvasElevated: Color(red: 0.996, green: 0.996, blue: 0.990),
                sidebar: Color(red: 0.914, green: 0.916, blue: 0.910),
                recessedControl: Color(red: 0.928, green: 0.930, blue: 0.924),
                selectedControl: Color(red: 0.982, green: 0.984, blue: 0.976),
                separator: Color.black.opacity(0.10)
            )
        case (.porcelain, .dark):
            palette = ThemePalette(
                canvas: Color(red: 0.074, green: 0.074, blue: 0.062),
                canvasElevated: Color(red: 0.122, green: 0.118, blue: 0.098),
                sidebar: Color(red: 0.100, green: 0.098, blue: 0.082),
                recessedControl: Color(red: 0.172, green: 0.166, blue: 0.138),
                selectedControl: Color(red: 0.220, green: 0.202, blue: 0.158),
                separator: Color.white.opacity(0.10)
            )
        case (.ember, .dark):
            palette = ThemePalette(
                canvas: Color(red: 0.059, green: 0.082, blue: 0.067),
                canvasElevated: Color(red: 0.090, green: 0.125, blue: 0.098),
                sidebar: Color(red: 0.071, green: 0.102, blue: 0.078),
                recessedControl: Color(red: 0.114, green: 0.165, blue: 0.129),
                selectedControl: Color(red: 0.149, green: 0.212, blue: 0.157),
                separator: Color(red: 0.600, green: 0.720, blue: 0.620).opacity(0.14)
            )
        case (.sumi, .dark):
            palette = ThemePalette(
                canvas: Color(red: 0.040, green: 0.046, blue: 0.056),
                canvasElevated: Color(red: 0.080, green: 0.088, blue: 0.104),
                sidebar: Color(red: 0.060, green: 0.066, blue: 0.078),
                recessedControl: Color(red: 0.122, green: 0.132, blue: 0.150),
                selectedControl: Color(red: 0.168, green: 0.180, blue: 0.204),
                separator: Color.white.opacity(0.12)
            )
        case (.custom, .dark):
            palette = ThemePalette(
                canvas: Color(red: 0.068, green: 0.070, blue: 0.066),
                canvasElevated: Color(red: 0.116, green: 0.118, blue: 0.112),
                sidebar: Color(red: 0.094, green: 0.096, blue: 0.090),
                recessedControl: Color(red: 0.170, green: 0.172, blue: 0.162),
                selectedControl: Color(red: 0.206, green: 0.208, blue: 0.196),
                separator: Color.white.opacity(0.10)
            )
        @unknown default:
            palette = ThemePalette.resolve(preset: .porcelain, colorScheme: .light)
        }
        guard highContrast else { return palette }
        return palette.highContrastAdjusted(for: colorScheme)
    }

    private func highContrastAdjusted(for colorScheme: ColorScheme) -> ThemePalette {
        ThemePalette(
            canvas: canvas,
            canvasElevated: canvasElevated,
            sidebar: sidebar,
            recessedControl: recessedControl,
            selectedControl: selectedControl,
            separator: colorScheme == .dark ? Color.white.opacity(0.24) : Color.black.opacity(0.24)
        )
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
