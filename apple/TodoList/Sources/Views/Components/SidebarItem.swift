import SwiftUI

struct SidebarItem: View {
    let title: String
    let systemImage: String
    var collapsedSymbol: String? = nil
    let count: Int?
    let tint: Color
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.sidebarExpanded) private var isExpanded
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Group {
                if isExpanded {
                    expandedContent
                } else {
                    collapsedContent
                }
            }
            .background(alignment: .center) {
                if isSelected {
                    Color.clear
                        .glassChrome(
                            in: RoundedRectangle(
                                cornerRadius: isExpanded ? 10 : 12,
                                style: .continuous
                            ),
                            tint: tint
                        )
                        .matchedGeometryEffect(id: MatchedGeometryID.sidebarSelection, in: namespace)
                } else if isHovering {
                    RoundedRectangle(
                        cornerRadius: isExpanded ? 10 : 12,
                        style: .continuous
                    )
                    .fill(Color.primary.opacity(0.04))
                }
            }
            .contentShape(
                RoundedRectangle(
                    cornerRadius: isExpanded ? 10 : 12,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(Motion.selection, value: isSelected)
        .animation(Motion.hover, value: isHovering)
        .help(helpText)
    }

    private var expandedContent: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 12.5, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(iconColor)
                .frame(width: 18)

            Text(title)
                .font(theme.type.body.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(Color.primary.opacity(isSelected ? 1 : 0.82))
                .lineLimit(1)

            Spacer(minLength: 4)

            if let count, count > 0 {
                Text("\(count)")
                    .font(theme.type.number(size: 11, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? tint : Color.secondary.opacity(0.7))
            }
        }
        .padding(.horizontal, 10)
        .frame(height: theme.metrics.sidebarRowHeight)
    }

    private var collapsedContent: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let collapsedSymbol, !collapsedSymbol.isEmpty {
                    Text(collapsedSymbol)
                        .font(.system(size: 15, weight: isSelected ? .bold : .semibold, design: .rounded))
                        .foregroundStyle(iconColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(iconColor)
                }
            }
            .frame(width: 38, height: 38)

            if let count, count > 0 {
                Text(count > 99 ? "99+" : "\(count)")
                    .font(.system(size: 9, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .frame(minWidth: 14, minHeight: 14)
                    .background {
                        Capsule(style: .continuous)
                            .fill(tint)
                    }
                    .offset(x: 6, y: -4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }

    private var iconColor: Color {
        if isSelected { return tint }
        if isHovering { return Color.primary.opacity(0.9) }
        return Color.secondary
    }

    private var helpText: String {
        if let count, count > 0 {
            return "\(title) · \(count)"
        }
        return title
    }
}
