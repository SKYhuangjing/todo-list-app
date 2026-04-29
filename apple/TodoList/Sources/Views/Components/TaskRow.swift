import SwiftUI

struct TaskRow: View {
    let todo: TodoItem
    let isSelected: Bool
    let dueLabel: String
    let isOverdue: Bool
    let onSelect: () -> Void
    let onToggle: () -> Void

    @Environment(\.theme) private var theme
    @Environment(LocalizationStore.self) private var localizationStore
    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: Space.md) {
            checkbox
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: theme.metrics.taskRowSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(todo.title)
                        .font(theme.type.headline)
                        .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                        .strikethrough(todo.isCompleted)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer(minLength: 8)

                    Text(todo.priority.title)
                        .font(theme.type.microLabel)
                        .tracking(0.4)
                        .foregroundStyle(todo.priority.semanticTint.opacity(todo.isCompleted ? 0.58 : 0.94))
                }

                if theme.metrics.showsNotesPreview, !todo.notes.isEmpty {
                    Text(todo.notes)
                        .font(theme.type.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                if theme.metrics.showsMetaChipsInRow {
                    metaRow
                        .padding(.top, 1)
                }
            }
        }
        .padding(.horizontal, theme.metrics.taskRowHorizontalPadding)
        .padding(.vertical, theme.metrics.taskRowVerticalPadding)
        .frame(minHeight: theme.metrics.taskRowMinHeight, alignment: .center)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground)
        .overlay(alignment: .leading) {
            Capsule(style: .continuous)
                .fill(todo.priority.semanticTint.opacity(todo.isCompleted ? 0.18 : 0.82))
                .frame(width: isSelected ? 3 : 2)
                .padding(.vertical, 12)
                .opacity(isSelected || isHovering ? 1 : 0.55)
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { isHovering = $0 }
        .animation(Motion.hover, value: isHovering)
        .animation(Motion.selection, value: isSelected)
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(theme.accentColor.opacity(0.13))
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .strokeBorder(theme.accentColor.opacity(0.34), lineWidth: 1)
                }
        } else if isHovering {
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(SurfaceColor.recessedControl)
        }
    }

    private var checkbox: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    todo.isCompleted ? Color.green.opacity(0.0) : Color.secondary.opacity(0.42),
                    lineWidth: 1.4
                )
                .background(
                    Circle().fill(todo.isCompleted ? Color.green : Color.clear)
                )
                .frame(width: 18, height: 18)

            if todo.isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .contentShape(Circle())
        .onTapGesture { onToggle() }
        .help(
            todo.isCompleted
                ? LocalizedText.string(.markOpen, language: localizationStore.resolvedLanguage)
                : LocalizedText.string(.markComplete, language: localizationStore.resolvedLanguage)
        )
    }

    @ViewBuilder
    private var metaRow: some View {
        if todo.dueDate != nil || isOverdue || !todo.tags.isEmpty {
            HStack(spacing: 10) {
                if todo.dueDate != nil || isOverdue {
                    HStack(spacing: 4) {
                        Image(systemName: isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                            .font(.system(size: 9.5, weight: .semibold))
                        Text(dueLabel)
                            .font(theme.type.caption)
                    }
                    .foregroundStyle(isOverdue ? Color.orange : Color.secondary)
                }

                ForEach(todo.tags.prefix(2)) { tag in
                    HStack(spacing: 4) {
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
    }
}
