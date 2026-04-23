import SwiftUI

struct TodoListView: View {
    @Bindable var store: TodoStore
    let isSidebarExpanded: Bool
    let onToggleSidebar: () -> Void
    let onCreate: () -> Void

    @Environment(\.theme) private var theme
    @Environment(LocalizationStore.self) private var localizationStore
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            ChromeBar(title: store.activeTitle, subtitle: store.activeSubtitle) {
                HStack(spacing: Space.sm) {
                    GlassIconButton(
                        systemImage: isSidebarExpanded ? "chevron.left" : "chevron.right",
                        help: isSidebarExpanded
                            ? LocalizedText.string(.collapseSidebar, language: localizationStore.resolvedLanguage)
                            : LocalizedText.string(.expandSidebar, language: localizationStore.resolvedLanguage),
                        action: onToggleSidebar
                    )

                    GlassPrimaryButton(
                        title: LocalizedText.string(.newTask, language: localizationStore.resolvedLanguage),
                        systemImage: "plus",
                        action: onCreate
                    )
                        .keyboardShortcut("n", modifiers: [.command])

                    GlassSettingsLink()
                }
            }
            .padding(.horizontal, Space.xl)
            .padding(.top, Space.lg)

            filterRow
                .padding(.horizontal, Space.xl)

            searchField
                .padding(.horizontal, Space.xl)

            listContent
                .padding(.horizontal, Space.lg)
        }
        .padding(.bottom, Space.md)
        .canvasPage()
    }

    private var filterRow: some View {
        HStack(spacing: Space.sm) {
            ForEach(SidebarSection.allCases) { section in
                Pill(
                    title: section.title,
                    systemImage: section.systemImage,
                    count: store.count(for: section),
                    tint: section.semanticTint,
                    isActive: store.selectedTagID == nil && store.selectedSection == section,
                    action: { store.select(section) }
                )
            }

            Spacer(minLength: Space.md)
        }
    }

    private var searchField: some View {
        HStack(spacing: Space.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.tertiary)

            TextField(LocalizedText.string(.searchPlaceholder, language: localizationStore.resolvedLanguage), text: $store.searchText)
                .textFieldStyle(.plain)
                .font(theme.type.body)
                .focused($searchFocused)

            if !store.searchText.isEmpty {
                Button {
                    store.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }

            Text(summaryText)
                .font(theme.type.caption)
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
        .padding(.horizontal, Space.md)
        .padding(.vertical, 9)
        .background {
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.primary.opacity(searchFocused ? 0.05 : 0.035))
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(
                    searchFocused ? theme.accentColor.opacity(0.38) : Color.clear,
                    lineWidth: 1
                )
        }
        .animation(Motion.hover, value: searchFocused)
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
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(store.visibleTodos.enumerated()), id: \.element.id) { index, todo in
                        if index > 0 {
                            Divider()
                                .padding(.leading, theme.metrics.taskRowHorizontalPadding + 3 + Space.md)
                                .opacity(0.55)
                        }

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
                    }
                }
                .padding(.vertical, Space.sm)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var summaryText: String {
        LocalizedText.taskCountSummary(store.visibleTodos.count, language: localizationStore.resolvedLanguage)
    }
}
