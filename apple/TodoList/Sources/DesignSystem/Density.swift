import SwiftUI

enum DensityToken: String, CaseIterable, Identifiable, Codable, Sendable {
    case compact
    case balanced
    case comfortable

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .compact: LocalizedText.string(.densityCompact)
        case .balanced: LocalizedText.string(.densityBalanced)
        case .comfortable: LocalizedText.string(.densityComfortable)
        }
    }

    var tagline: String {
        switch self {
        case .compact: LocalizedText.string(.densityCompactTagline)
        case .balanced: LocalizedText.string(.densityBalancedTagline)
        case .comfortable: LocalizedText.string(.densityComfortableTagline)
        }
    }
}

struct DensityMetrics: Sendable {
    let taskRowMinHeight: CGFloat
    let taskRowHorizontalPadding: CGFloat
    let taskRowVerticalPadding: CGFloat
    let taskRowSpacing: CGFloat

    let sidebarRowHeight: CGFloat
    let sidebarRowHorizontalPadding: CGFloat
    let sidebarRowSpacing: CGFloat

    let sectionVerticalPadding: CGFloat
    let sectionHorizontalPadding: CGFloat

    let showsNotesPreview: Bool
    let showsMetaChipsInRow: Bool

    static func resolve(for token: DensityToken) -> DensityMetrics {
        switch token {
        case .compact:
            return DensityMetrics(
                taskRowMinHeight: 36,
                taskRowHorizontalPadding: Space.md,
                taskRowVerticalPadding: 6,
                taskRowSpacing: 2,
                sidebarRowHeight: 32,
                sidebarRowHorizontalPadding: Space.sm,
                sidebarRowSpacing: 2,
                sectionVerticalPadding: 10,
                sectionHorizontalPadding: Space.lg,
                showsNotesPreview: false,
                showsMetaChipsInRow: false
            )
        case .balanced:
            return DensityMetrics(
                taskRowMinHeight: 48,
                taskRowHorizontalPadding: Space.md,
                taskRowVerticalPadding: 10,
                taskRowSpacing: 3,
                sidebarRowHeight: 36,
                sidebarRowHorizontalPadding: Space.sm,
                sidebarRowSpacing: 3,
                sectionVerticalPadding: 14,
                sectionHorizontalPadding: Space.lg,
                showsNotesPreview: true,
                showsMetaChipsInRow: true
            )
        case .comfortable:
            return DensityMetrics(
                taskRowMinHeight: 62,
                taskRowHorizontalPadding: Space.lg,
                taskRowVerticalPadding: 14,
                taskRowSpacing: 5,
                sidebarRowHeight: 42,
                sidebarRowHorizontalPadding: Space.md,
                sidebarRowSpacing: 4,
                sectionVerticalPadding: 18,
                sectionHorizontalPadding: Space.xl,
                showsNotesPreview: true,
                showsMetaChipsInRow: true
            )
        }
    }
}
