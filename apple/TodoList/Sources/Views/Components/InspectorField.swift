import SwiftUI

struct InspectorField: View {
    let label: String
    let value: String
    var valueColor: Color? = nil

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(theme.type.caption)
                .foregroundStyle(.tertiary)

            Text(value)
                .font(theme.type.body)
                .foregroundStyle(valueColor ?? .primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct InspectorFieldGrid<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), alignment: .topLeading),
                GridItem(.flexible(), alignment: .topLeading)
            ],
            alignment: .leading,
            spacing: Space.md
        ) {
            content()
        }
    }
}
