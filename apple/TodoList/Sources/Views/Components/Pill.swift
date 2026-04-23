import SwiftUI

struct Pill: View {
    let title: String
    var systemImage: String? = nil
    var count: Int? = nil
    var tint: Color? = nil
    var isActive: Bool = false
    var action: (() -> Void)? = nil

    @Environment(\.theme) private var theme
    @State private var isHovering = false

    private var effectiveTint: Color { tint ?? theme.accentColor }

    var body: some View {
        Group {
            if let action {
                Button(action: action) { content }
                    .buttonStyle(.plain)
            } else {
                content
            }
        }
        .onHover { isHovering = $0 }
        .animation(Motion.hover, value: isActive)
        .animation(Motion.hover, value: isHovering)
    }

    @ViewBuilder
    private var content: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10.5, weight: isActive ? .bold : .semibold))
            }

            Text(title)
                .font(theme.type.callout.weight(isActive ? .semibold : .medium))
                .fixedSize()

            if let count {
                Text("\(count)")
                    .font(theme.type.number(size: 11, weight: isActive ? .semibold : .medium))
                    .monospacedDigit()
                    .opacity(isActive ? 0.9 : 0.65)
            }
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .frame(minHeight: 28)
        .background {
            Capsule(style: .continuous)
                .fill(backgroundFill)
        }
        .overlay {
            if isActive {
                Capsule(style: .continuous)
                    .strokeBorder(effectiveTint.opacity(0.42), lineWidth: 1)
            }
        }
        .contentShape(Capsule(style: .continuous))
    }

    private var foregroundColor: Color {
        if isActive { return .primary }
        if isHovering { return .primary }
        return .secondary
    }

    private var backgroundFill: Color {
        if isActive { return effectiveTint.opacity(0.14) }
        if isHovering { return Color.primary.opacity(0.06) }
        return Color.primary.opacity(0.035)
    }
}
