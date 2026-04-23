import SwiftUI

struct SectionLabel: View {
    let text: String

    @Environment(\.theme) private var theme

    var body: some View {
        Text(text.uppercased())
            .font(theme.type.microLabel)
            .tracking(theme.type.microLabelTracking)
            .foregroundStyle(.tertiary)
    }
}
