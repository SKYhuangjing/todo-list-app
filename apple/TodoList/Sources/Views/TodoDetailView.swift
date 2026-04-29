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
                            DetailSection {
                                attachment(at: screenshotPath)
                            }
                        }

                        if !todo.notes.isEmpty {
                            DetailSection {
                                notesSection(for: todo)
                            }
                        }

                        DetailSection {
                            metadataSection(for: todo)
                        }

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

            HStack(spacing: Space.sm) {
                Button {
                    Task { await store.toggleCompletion(for: todo.id) }
                } label: {
                    Label(
                        todo.isCompleted
                            ? LocalizedText.string(.reopen, language: localizationStore.resolvedLanguage)
                            : LocalizedText.string(.complete, language: localizationStore.resolvedLanguage),
                        systemImage: todo.isCompleted ? "arrow.uturn.backward" : "checkmark"
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .buttonBorderShape(.roundedRectangle(radius: Radius.sm))

                Spacer(minLength: 0)
            }
            .padding(.top, Space.xs)
        }
        .padding(.horizontal, 2)
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

    private func notesSection(for todo: TodoItem) -> some View {
        Text(todo.notes)
            .font(theme.type.body)
            .foregroundStyle(Color.primary.opacity(0.88))
            .fixedSize(horizontal: false, vertical: true)
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
        .padding(.horizontal, Space.sm)
        .padding(.top, Space.xs)
    }
}

private struct DetailSection<Content: View>: View {
    var tint: Color?
    @ViewBuilder var content: () -> Content
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = theme.palette(for: colorScheme)
        VStack(alignment: .leading, spacing: Space.md) {
            content()
        }
        .padding(Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(palette.canvasElevated.opacity(0.52))
                .glassSheet(
                    in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous),
                    tint: tint
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(palette.separator, lineWidth: 0.8)
        }
    }
}

private struct DeleteTaskButton: View {
    let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(LocalizationStore.self) private var localizationStore

    var body: some View {
        Button(role: .destructive, action: action) {
            Label(LocalizedText.string(.deleteTask, language: localizationStore.resolvedLanguage), systemImage: "trash")
                .font(theme.type.callout.weight(.medium))
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(.red)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
