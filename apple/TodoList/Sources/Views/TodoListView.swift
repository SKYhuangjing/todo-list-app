import SwiftUI

struct TodoListView: View {
    @Bindable var store: TodoStore
    let onCreate: () -> Void

    @Environment(\.theme) private var theme
    @Environment(LocalizationStore.self) private var localizationStore

    var body: some View {
        ZStack(alignment: .bottom) {
            listContent
        }
        .safeAreaInset(edge: .bottom) {
            QuickAddDock(action: onCreate)
        }
    }

    @ViewBuilder
    private var listContent: some View {
        if store.visibleTodos.isEmpty {
            EmptyState(
                systemImage: store.hasActiveSearch
                    ? "line.3.horizontal.decrease.circle"
                    : "tray",
                message: store.hasActiveSearch
                    ? LocalizedText.string(.noSearchMatches, language: localizationStore.resolvedLanguage)
                    : LocalizedText.format(.emptySectionFormat, language: localizationStore.resolvedLanguage, store.activeTitle.lowercased()),
                tint: store.activeTint
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Space.sm, pinnedViews: []) {
                    HStack {
                        Text(summaryText)
                            .font(theme.type.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, Space.xl)
                    .padding(.top, Space.xs)
                    .padding(.bottom, Space.sm)

                    ForEach(store.visibleTodos) { todo in
                        TaskRow(
                            todo: todo,
                            isSelected: store.selectedTodoID == todo.id,
                            dueLabel: store.dueLabel(for: todo),
                            isOverdue: store.overdueState(for: todo),
                            onSelect: { store.select(todoID: todo.id) },
                            onToggle: {
                                Task { await store.toggleCompletion(for: todo.id) }
                            }
                        )
                        .padding(.horizontal, Space.lg)
                    }
                }
                .padding(.vertical, Space.sm)
                .padding(.bottom, 108)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var summaryText: String {
        LocalizedText.taskCountSummary(store.visibleTodos.count, language: localizationStore.resolvedLanguage)
    }
}

private struct QuickAddDock: View {
    let action: () -> Void

    var body: some View {
        QuickAddEntryButton(action: action)
            .padding(.horizontal, Space.xl)
            .padding(.top, Space.xs)
            .padding(.bottom, 26)
            .frame(maxWidth: .infinity)
    }
}

private struct QuickAddEntryButton: View {
    let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(LocalizationStore.self) private var localizationStore

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.sm) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 22, height: 22)
                    .foregroundStyle(.white)
                    .background(theme.accentColor, in: Circle())

                Text(LocalizedText.string(.newTask, language: localizationStore.resolvedLanguage))
                    .font(theme.type.callout)
                    .foregroundStyle(.primary)

                Spacer(minLength: Space.md)

                Text("⌘N")
                    .font(theme.type.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Space.md)
            .padding(.vertical, 8)
            .frame(maxWidth: 300)
            .contentShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .glassInteractive(
            in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous),
            tint: theme.accentColor
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        .help(LocalizedText.string(.newTask, language: localizationStore.resolvedLanguage))
    }
}
