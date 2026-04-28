import AppKit
import SwiftUI

struct MenuBarDashboardView: View {
    @Bindable var store: TodoStore
    let router: AppRouter

    @Environment(\.theme) private var theme
    @Environment(\.openSettings) private var openSettings
    @Environment(LocalizationStore.self) private var localizationStore

    var body: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            summary

            actions

            if !store.filteredMenuBarTodos().isEmpty {
                Divider().opacity(0.6)

                VStack(spacing: Space.xs) {
                    ForEach(store.filteredMenuBarTodos()) { todo in
                        menuRow(todo: todo)
                    }
                }
            }

            Divider().opacity(0.6)

            footer
        }
        .padding(Space.lg)
        .frame(width: 320)
        .background(.regularMaterial)
    }

    private var summary: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedText.string(.today, language: localizationStore.resolvedLanguage))
                    .font(theme.type.headline)

                Text(LocalizedText.menuBarAttentionSummary(store.count(for: .today), language: localizationStore.resolvedLanguage))
                    .font(theme.type.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                router.showDashboard()
            } label: {
                Label(LocalizedText.string(.open, language: localizationStore.resolvedLanguage), systemImage: "arrow.up.forward.app")
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: Radius.sm))
            .controlSize(.small)
        }
    }

    private var actions: some View {
        HStack(spacing: Space.sm) {
            Button {
                router.showQuickAdd()
            } label: {
                Label(LocalizedText.string(.quickAddTitle, language: localizationStore.resolvedLanguage), systemImage: "plus.circle")
                    .font(theme.type.callout)
            }
            .buttonStyle(.bordered)

            Button {
                openSettings()
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label(LocalizedText.string(.settings, language: localizationStore.resolvedLanguage), systemImage: "gearshape")
                    .font(theme.type.callout)
            }
            .buttonStyle(.bordered)
        }
    }

    private func menuRow(todo: TodoItem) -> some View {
        HStack(spacing: Space.sm) {
            Capsule(style: .continuous)
                .fill(todo.priority.semanticTint)
                .frame(width: 3, height: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(todo.title)
                    .font(theme.type.callout.weight(.medium))
                    .lineLimit(1)

                Text(store.dueLabel(for: todo))
                    .font(theme.type.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, Space.sm)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                .fill(Color.primary.opacity(0.025))
        }
    }

    private var footer: some View {
        HStack(spacing: Space.md) {
            Label("\(store.count(for: .completed))", systemImage: "checkmark.circle")
                .font(theme.type.caption)
                .foregroundStyle(.secondary)

            Label("\(store.count(for: .upcoming))", systemImage: "calendar")
                .font(theme.type.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label(LocalizedText.string(.quit, language: localizationStore.resolvedLanguage), systemImage: "power")
                    .font(theme.type.caption)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help(LocalizedText.format(.quitHelpFormat, language: localizationStore.resolvedLanguage, LocalizedText.string(.appName, language: localizationStore.resolvedLanguage)))
        }
    }
}
