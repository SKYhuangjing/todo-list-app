import SwiftUI

private struct SidebarExpandedKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    var sidebarExpanded: Bool {
        get { self[SidebarExpandedKey.self] }
        set { self[SidebarExpandedKey.self] = newValue }
    }
}

private enum SidebarSelection: Hashable {
    case section(SidebarSection)
    case tag(UUID)
}

struct SidebarView: View {
    @Bindable var store: TodoStore

    @Environment(\.theme) private var theme
    @Environment(LocalizationStore.self) private var localizationStore

    var body: some View {
        List(selection: sidebarSelection) {
            Section {
                ForEach(SidebarSection.allCases) { section in
                    SidebarSourceRow(
                        title: section.title,
                        systemImage: section.systemImage,
                        count: store.count(for: section),
                        tint: section.semanticTint,
                        isSelected: store.selectedTagID == nil && store.selectedSection == section
                    )
                    .tag(SidebarSelection.section(section))
                }
            }

            Section(LocalizedText.string(.sidebarTags, language: localizationStore.resolvedLanguage)) {
                if store.availableTags.isEmpty {
                    Text(LocalizedText.string(.none, language: localizationStore.resolvedLanguage))
                        .font(theme.type.caption)
                        .foregroundStyle(.tertiary)
                        .frame(minHeight: 28, alignment: .center)
                } else {
                    ForEach(store.availableTags) { tag in
                        SidebarSourceRow(
                            title: tag.name,
                            systemImage: "number",
                            count: store.count(forTagID: tag.id),
                            tint: tag.tint,
                            isSelected: store.selectedTagID == tag.id
                        )
                        .tag(SidebarSelection.tag(tag.id))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(LocalizedText.string(.appName, language: localizationStore.resolvedLanguage))
        .environment(\.sidebarExpanded, true)
    }

    private var sidebarSelection: Binding<SidebarSelection?> {
        Binding {
            if let selectedTagID = store.selectedTagID {
                return .tag(selectedTagID)
            }
            return .section(store.selectedSection)
        } set: { selection in
            guard let selection else { return }
            switch selection {
            case let .section(section):
                store.select(section)
            case let .tag(tagID):
                store.select(tagID: tagID)
            }
        }
    }
}

private struct SidebarSourceRow: View {
    let title: String
    let systemImage: String
    let count: Int
    let tint: Color
    let isSelected: Bool

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? theme.accentColor : tint.opacity(0.82))
                .symbolRenderingMode(.hierarchical)
                .frame(width: 17)

            Text(title)
                .font(theme.type.callout.weight(isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)

            Spacer(minLength: Space.sm)

            if count > 0 {
                Text(count, format: .number)
                    .font(theme.type.caption)
                    .foregroundStyle(isSelected ? theme.accentColor : Color.secondary.opacity(0.62))
                    .monospacedDigit()
            }
        }
        .frame(minHeight: min(theme.metrics.sidebarRowHeight, 36))
    }
}
