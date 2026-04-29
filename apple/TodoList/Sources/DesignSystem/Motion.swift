import SwiftUI

enum Motion {
    static let selection: Animation = .spring(response: 0.32, dampingFraction: 0.86)

    static let reveal: Animation = .spring(response: 0.42, dampingFraction: 0.82)

    static let hover: Animation = .easeOut(duration: 0.12)

    static let glassMorph: Animation = .spring(response: 0.38, dampingFraction: 0.80)

    static let cardPress: Animation = .spring(response: 0.22, dampingFraction: 0.72)

    static let settingsSection: Animation = .spring(response: 0.34, dampingFraction: 0.88)
}

enum MatchedGeometryID {
    static let sidebarSelection = "sidebar.selection.indicator"
}
