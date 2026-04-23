import SwiftUI

struct EmptyState: View {
    let systemImage: String
    let message: String
    var tint: Color? = nil

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: Space.md) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle((tint ?? theme.accentColor).opacity(0.72))
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill((tint ?? theme.accentColor).opacity(0.08))
                }

            Text(message)
                .font(theme.type.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(Space.xl)
    }
}
