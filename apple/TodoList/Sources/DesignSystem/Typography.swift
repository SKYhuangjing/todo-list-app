import SwiftUI

enum TypographyToken: String, CaseIterable, Identifiable, Codable, Sendable {
    case sfPro
    case sfProRounded
    case newYork

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sfPro: "SF Pro"
        case .sfProRounded: "SF Pro Rounded"
        case .newYork: "New York"
        }
    }

    var tagline: String {
        switch self {
        case .sfPro: LocalizedText.string(.typographySFProTagline)
        case .sfProRounded: LocalizedText.string(.typographyRoundedTagline)
        case .newYork: LocalizedText.string(.typographyNewYorkTagline)
        }
    }

    fileprivate var displayDesign: Font.Design {
        switch self {
        case .sfPro: .default
        case .sfProRounded: .rounded
        case .newYork: .serif
        }
    }
}

struct TypeScale: Sendable {
    let display: Font
    let title: Font
    let headline: Font
    let body: Font
    let callout: Font
    let caption: Font
    let microLabel: Font
    let keycap: Font

    let displayTracking: CGFloat
    let titleTracking: CGFloat
    let microLabelTracking: CGFloat

    static func resolve(for token: TypographyToken) -> TypeScale {
        let displayDesign = token.displayDesign
        return TypeScale(
            display: .system(size: 30, weight: .semibold, design: displayDesign),
            title: .system(size: 22, weight: .semibold, design: displayDesign),
            headline: .system(size: 16, weight: .semibold, design: displayDesign),
            body: .system(size: 13.5, weight: .regular, design: .default),
            callout: .system(size: 12, weight: .medium, design: .default),
            caption: .system(size: 11, weight: .medium, design: .default),
            microLabel: .system(size: 10.5, weight: .bold, design: .default),
            keycap: .system(size: 11, weight: .semibold, design: .monospaced),
            displayTracking: -0.4,
            titleTracking: -0.2,
            microLabelTracking: 0.8
        )
    }

    func number(size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
