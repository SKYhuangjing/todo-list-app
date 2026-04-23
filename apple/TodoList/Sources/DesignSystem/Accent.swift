import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

enum AccentToken: String, CaseIterable, Identifiable, Codable, Sendable {
    case inkNavy
    case graphite
    case cypress
    case porcelainBlue
    case warmOrange
    case forestGreen
    case violet
    case systemAccent

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .inkNavy: LocalizedText.string(.accentInkNavy)
        case .graphite: LocalizedText.string(.accentGraphite)
        case .cypress: LocalizedText.string(.accentCypress)
        case .porcelainBlue: LocalizedText.string(.accentPorcelainBlue)
        case .warmOrange: LocalizedText.string(.accentWarmOrange)
        case .forestGreen: LocalizedText.string(.accentForestGreen)
        case .violet: LocalizedText.string(.accentViolet)
        case .systemAccent: LocalizedText.string(.accentSystem)
        }
    }

    var tagline: String {
        switch self {
        case .inkNavy: LocalizedText.string(.accentInkNavyTagline)
        case .graphite: LocalizedText.string(.accentGraphiteTagline)
        case .cypress: LocalizedText.string(.accentCypressTagline)
        case .porcelainBlue: LocalizedText.string(.accentPorcelainBlueTagline)
        case .warmOrange: LocalizedText.string(.accentWarmOrangeTagline)
        case .forestGreen: LocalizedText.string(.accentForestGreenTagline)
        case .violet: LocalizedText.string(.accentVioletTagline)
        case .systemAccent: LocalizedText.string(.accentSystemTagline)
        }
    }

    var color: Color {
        switch self {
        case .inkNavy: return Self.adaptive(
            light: Color(red: 30.0/255.0, green: 58.0/255.0, blue: 95.0/255.0),
            dark: Color(red: 143.0/255.0, green: 174.0/255.0, blue: 212.0/255.0)
        )
        case .graphite: return Self.adaptive(
            light: Color(red: 62.0/255.0, green: 70.0/255.0, blue: 84.0/255.0),
            dark: Color(red: 178.0/255.0, green: 188.0/255.0, blue: 206.0/255.0)
        )
        case .cypress: return Self.adaptive(
            light: Color(red: 43.0/255.0, green: 87.0/255.0, blue: 80.0/255.0),
            dark: Color(red: 127.0/255.0, green: 179.0/255.0, blue: 169.0/255.0)
        )
        case .porcelainBlue: return Self.adaptive(
            light: Color(red: 58.0/255.0, green: 111.0/255.0, blue: 224.0/255.0),
            dark: Color(red: 108.0/255.0, green: 147.0/255.0, blue: 242.0/255.0)
        )
        case .warmOrange: return Self.adaptive(
            light: Color(red: 240.0/255.0, green: 138.0/255.0, blue: 44.0/255.0),
            dark: Color(red: 255.0/255.0, green: 163.0/255.0, blue: 71.0/255.0)
        )
        case .forestGreen: return Self.adaptive(
            light: Color(red: 47.0/255.0, green: 158.0/255.0, blue: 101.0/255.0),
            dark: Color(red: 69.0/255.0, green: 194.0/255.0, blue: 129.0/255.0)
        )
        case .violet: return Self.adaptive(
            light: Color(red: 124.0/255.0, green: 90.0/255.0, blue: 232.0/255.0),
            dark: Color(red: 164.0/255.0, green: 140.0/255.0, blue: 255.0/255.0)
        )
        case .systemAccent:
            #if canImport(AppKit)
            return Color(nsColor: .controlAccentColor)
            #else
            return .accentColor
            #endif
        }
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
