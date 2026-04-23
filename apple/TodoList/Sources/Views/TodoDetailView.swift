import SwiftUI

struct TodoDetailView: View {
    @Bindable var store: TodoStore

    @Environment(\.theme) private var theme
    @Environment(LocalizationStore.self) private var localizationStore

    var body: some View {
        Group {
            if let todo = store.selectedTodo {
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.xl) {
                        header(for: todo)

                        if let screenshotPath = todo.screenshotPath {
                            attachment(at: screenshotPath)
                        }

                        notesSection(for: todo)

                        metadataSection(for: todo)

                        deleteAction(for: todo)
                    }
                    .padding(Space.xl)
                }
                .id(todo.id)
                .scrollIndicators(.hidden)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                EmptyState(
                    systemImage: "sidebar.right",
                    message: LocalizedText.string(.selectTaskForDetails, language: localizationStore.resolvedLanguage),
                    tint: store.activeTint
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .canvasPage()
        .animation(Motion.reveal, value: store.selectedTodo?.id)
    }

    private func header(for todo: TodoItem) -> some View {
        VStack(alignment: .leading, spacing: Space.md) {
            HStack(spacing: Space.sm) {
                statusPill(for: todo)

                Spacer(minLength: Space.xs)

                if todo.dueDate != nil || store.overdueState(for: todo) {
                    dueChip(for: todo)
                }
            }

            Text(todo.title)
                .font(theme.type.title)
                .tracking(theme.type.titleTracking)
                .fixedSize(horizontal: false, vertical: true)

            if !todo.tags.isEmpty {
                HStack(spacing: Space.sm) {
                    ForEach(todo.tags.prefix(4)) { tag in
                        HStack(spacing: 5) {
                            Circle()
                                .fill(tag.tint)
                                .frame(width: 5, height: 5)
                            Text(tag.name)
                                .font(theme.type.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            GlassChromeCluster {
                HStack(spacing: Space.sm) {
                    GlassPrimaryButton(
                        title: todo.isCompleted
                            ? LocalizedText.string(.reopen, language: localizationStore.resolvedLanguage)
                            : LocalizedText.string(.complete, language: localizationStore.resolvedLanguage),
                        systemImage: todo.isCompleted ? "arrow.uturn.backward" : "checkmark"
                    ) {
                        Task { await store.toggleCompletion(for: todo.id) }
                    }

                    Spacer(minLength: 0)
                }
            }
            .padding(.top, Space.xs)
        }
        .padding(Space.lg)
        .glassChrome(
            in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous),
            tint: theme.accentColor.opacity(0.72)
        )
    }

    private func statusPill(for todo: TodoItem) -> some View {
        HStack(spacing: 5) {
            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle.dotted")
                .font(.system(size: 10.5, weight: .semibold))
            Text(
                todo.isCompleted
                    ? LocalizedText.string(.statusCompleted, language: localizationStore.resolvedLanguage)
                    : LocalizedText.string(.statusOpen, language: localizationStore.resolvedLanguage)
            )
                .font(theme.type.microLabel)
                .tracking(theme.type.microLabelTracking)
        }
        .foregroundStyle(todo.isCompleted ? Color.green : Color.secondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background {
            Capsule(style: .continuous)
                .fill(
                    (todo.isCompleted ? Color.green : Color.secondary).opacity(0.12)
                )
        }
    }

    private func dueChip(for todo: TodoItem) -> some View {
        let overdue = store.overdueState(for: todo)
        let color: Color = overdue ? .orange : .secondary
        return HStack(spacing: 5) {
            Image(systemName: overdue ? "exclamationmark.triangle.fill" : "calendar")
                .font(.system(size: 10, weight: .semibold))
            Text(store.detailDateLabel(for: todo))
                .font(theme.type.caption)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background {
            Capsule(style: .continuous)
                .fill(color.opacity(0.12))
        }
    }

    private func attachment(at path: String) -> some View {
        AsyncImage(url: URL(fileURLWithPath: path)) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.primary.opacity(0.05))
                .frame(height: 180)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }

    @ViewBuilder
    private func notesSection(for todo: TodoItem) -> some View {
        if todo.notes.isEmpty {
            EmptyView()
        } else {
            Text(todo.notes)
                .font(theme.type.body)
                .foregroundStyle(Color.primary.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func metadataSection(for todo: TodoItem) -> some View {
        VStack(alignment: .leading, spacing: Space.md) {
            InspectorFieldGrid {
                InspectorField(
                    label: LocalizedText.string(.priority, language: localizationStore.resolvedLanguage),
                    value: "\(todo.priority.title) · \(todo.priority.description)",
                    valueColor: todo.priority.semanticTint
                )
                InspectorField(
                    label: LocalizedText.string(.deadline, language: localizationStore.resolvedLanguage),
                    value: store.detailDateLabel(for: todo)
                )
                InspectorField(
                    label: LocalizedText.string(.created, language: localizationStore.resolvedLanguage),
                    value: LocalizedText.dateTime(todo.createdAt, language: localizationStore.resolvedLanguage)
                )
                InspectorField(
                    label: LocalizedText.string(.tags, language: localizationStore.resolvedLanguage),
                    value: todo.tags.isEmpty
                        ? LocalizedText.string(.none, language: localizationStore.resolvedLanguage)
                        : todo.tags.map(\.name).joined(separator: ", ")
                )
            }
        }
    }

    private func deleteAction(for todo: TodoItem) -> some View {
        DeleteTaskButton {
            Task { _ = await store.deleteTodo(id: todo.id) }
        }
        .padding(.top, Space.sm)
    }
}

private struct DeleteTaskButton: View {
    let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(LocalizationStore.self) private var localizationStore
    @State private var isHovering = false

    var body: some View {
        Button(role: .destructive, action: action) {
            Label(LocalizedText.string(.deleteTask, language: localizationStore.resolvedLanguage), systemImage: "trash")
                .font(theme.type.callout.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isHovering ? Color.red.opacity(0.95) : Color.secondary)
        .background {
            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                .fill(isHovering ? Color.red.opacity(0.08) : Color.primary.opacity(0.03))
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                .strokeBorder(
                    isHovering ? Color.red.opacity(0.28) : Color.primary.opacity(0.06),
                    lineWidth: 1
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
        .onHover { isHovering = $0 }
        .animation(Motion.hover, value: isHovering)
    }
}
