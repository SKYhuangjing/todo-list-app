import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

enum Space {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 28
    static let xxxl: CGFloat = 40
}

enum Radius {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    static let capsule: CGFloat = 999
}

struct Elevation {
    let yOffset: CGFloat
    let blur: CGFloat
    let lightOpacity: Double
    let darkOpacity: Double

    func shadowColor(for colorScheme: ColorScheme) -> Color {
        Color.black.opacity(colorScheme == .dark ? darkOpacity : lightOpacity)
    }

    static let hover = Elevation(yOffset: 1, blur: 6, lightOpacity: 0.04, darkOpacity: 0.24)
    static let chrome = Elevation(yOffset: 6, blur: 24, lightOpacity: 0.08, darkOpacity: 0.28)
    static let modal = Elevation(yOffset: 20, blur: 48, lightOpacity: 0.16, darkOpacity: 0.40)
}

enum SurfaceColor {
    static var canvas: Color {
        #if canImport(AppKit)
        Color(nsColor: .textBackgroundColor)
        #else
        Color(.systemBackground)
        #endif
    }

    static var canvasElevated: Color {
        #if canImport(AppKit)
        Color(nsColor: .underPageBackgroundColor)
        #else
        Color(.secondarySystemBackground)
        #endif
    }

    static var sidebar: Color {
        #if canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(.systemBackground)
        #endif
    }

    static var separatorSoft: Color {
        #if canImport(AppKit)
        Color(nsColor: .separatorColor).opacity(0.35)
        #else
        Color.gray.opacity(0.2)
        #endif
    }

    static var separator: Color {
        #if canImport(AppKit)
        Color(nsColor: .separatorColor).opacity(0.65)
        #else
        Color.gray.opacity(0.3)
        #endif
    }
}

enum SemanticColor {
    static let priorityP1: Color = .red
    static let priorityP2: Color = .orange
    static let priorityP3: Color = .blue
    static let priorityP4: Color = .secondary

    static let statusDone: Color = .green
    static let statusOverdue: Color = .orange
    static let statusInfo: Color = .blue
}

extension TodoPriority {
    var semanticTint: Color {
        switch self {
        case .p1: SemanticColor.priorityP1
        case .p2: SemanticColor.priorityP2
        case .p3: SemanticColor.priorityP3
        case .p4: SemanticColor.priorityP4
        }
    }
}
