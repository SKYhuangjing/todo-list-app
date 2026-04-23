import SwiftUI

struct ChromeBar<Accessory: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var accessory: () -> Accessory

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.lg) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(theme.type.display)
                    .tracking(theme.type.displayTracking)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let subtitle {
                    Text(subtitle)
                        .font(theme.type.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: Space.md)

            accessory()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct GlassIconButton: View {
    let systemImage: String
    var help: String? = nil
    let action: () -> Void

    @Environment(\.theme) private var theme
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 32, height: 32)
                .foregroundStyle(Color.primary.opacity(isHovering ? 1 : 0.82))
                .contentShape(Circle())
                .background {
                    Circle()
                        .fill(Color.clear)
                        .glassChrome(in: Circle(), interactive: true)
                }
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(Motion.hover, value: isHovering)
        .ifLet(help) { view, help in view.help(help) }
    }
}

struct GlassSettingsLink: View {
    var systemImage: String = "gearshape"
    var help: String? = LocalizedText.string(.settings)

    @Environment(\.openSettings) private var openSettings
    @State private var isHovering = false

    var body: some View {
        Button {
            openSettings()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 34, height: 34)
                .foregroundStyle(
                    Color.primary.opacity(isHovering ? 0.95 : 0.72)
                )
                .contentShape(Circle())
                .background {
                    Circle()
                        .fill(
                            Color.primary.opacity(isHovering ? 0.085 : 0.045)
                        )
                }
                .overlay {
                    Circle()
                        .strokeBorder(
                            Color.primary.opacity(isHovering ? 0.12 : 0.06),
                            lineWidth: 0.6
                        )
                }
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(Motion.hover, value: isHovering)
        .ifLet(help) { view, help in view.help(help) }
    }
}

struct GlassPrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    @Environment(\.theme) private var theme
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 11.5, weight: .bold))
                }
                Text(title)
                    .font(theme.type.callout.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(minHeight: 32)
            .background {
                Capsule(style: .continuous)
                    .fill(theme.accentColor)
                    .shadow(
                        color: theme.accentColor.opacity(isHovering ? 0.32 : 0.18),
                        radius: isHovering ? 10 : 6,
                        x: 0,
                        y: 3
                    )
            }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(Motion.hover, value: isHovering)
    }
}

private extension View {
    @ViewBuilder
    func ifLet<Value, Content: View>(_ value: Value?, transform: (Self, Value) -> Content) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }
}
