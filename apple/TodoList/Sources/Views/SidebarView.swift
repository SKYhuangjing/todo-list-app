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

enum SidebarLayoutMetrics {
    static let collapsedWidth: CGFloat = 76
    static let expandedWidth: CGFloat = 236
}

struct SidebarView: View {
    @Bindable var store: TodoStore
    let isExpanded: Bool
    let onToggleExpansion: () -> Void

    @Environment(\.theme) private var theme
    @Environment(LocalizationStore.self) private var localizationStore
    @Namespace private var selectionNamespace

    var body: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            brand
                .padding(.horizontal, isExpanded ? Space.md : Space.sm)
                .padding(.top, Space.lg)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: isExpanded ? Space.xl : Space.md) {
                    itemGroup {
                        ForEach(SidebarSection.allCases) { section in
                            SidebarItem(
                                title: section.title,
                                systemImage: section.systemImage,
                                count: store.count(for: section),
                                tint: section.semanticTint,
                                isSelected: store.selectedTagID == nil && store.selectedSection == section,
                                namespace: selectionNamespace
                            ) {
                                store.select(section)
                            }
                        }
                    }

                    if !store.availableTags.isEmpty {
                        itemGroup(header: isExpanded ? LocalizedText.string(.sidebarTags, language: localizationStore.resolvedLanguage) : nil) {
                            ForEach(store.availableTags) { tag in
                                SidebarItem(
                                    title: tag.name,
                                    systemImage: "number",
                                    collapsedSymbol: tagCollapsedSymbol(for: tag.name),
                                    count: store.count(forTagID: tag.id),
                                    tint: tag.tint,
                                    isSelected: store.selectedTagID == tag.id,
                                    namespace: selectionNamespace
                                ) {
                                    store.select(tagID: tag.id)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, isExpanded ? Space.sm : 4)
                .padding(.bottom, Space.md)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.sidebarExpanded, isExpanded)
    }

    @ViewBuilder
    private var brand: some View {
        VStack(alignment: isExpanded ? .leading : .center, spacing: Space.sm) {
            HStack(spacing: Space.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.accentColor.opacity(0.95),
                                    theme.accentColor.opacity(0.72)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 26, height: 26)

                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }

                if isExpanded {
                    Text(LocalizedText.string(.appName, language: localizationStore.resolvedLanguage))
                        .font(theme.type.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }

                if isExpanded {
                    Spacer(minLength: 0)
                }

                Button(action: onToggleExpansion) {
                    Image(systemName: isExpanded ? "chevron.left" : "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.primary.opacity(0.72))
                        .frame(width: 24, height: 24)
                        .background {
                            Circle()
                                .fill(Color.primary.opacity(0.045))
                        }
                }
                .buttonStyle(.plain)
                .help(
                    isExpanded
                        ? LocalizedText.string(.collapseSidebar, language: localizationStore.resolvedLanguage)
                        : LocalizedText.string(.expandSidebar, language: localizationStore.resolvedLanguage)
                )
            }
            .frame(maxWidth: .infinity, alignment: isExpanded ? .leading : .center)

            if !isExpanded {
                Divider()
                    .padding(.horizontal, Space.sm)
            }
        }
        .animation(Motion.hover, value: isExpanded)
    }

    @ViewBuilder
    private func itemGroup<Content: View>(
        header: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            if let header {
                SectionLabel(text: header)
                    .padding(.horizontal, 10)
                    .padding(.top, Space.xs)
            }

            VStack(spacing: isExpanded ? theme.metrics.sidebarRowSpacing : 2) {
                content()
            }
        }
    }

    private func tagCollapsedSymbol(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstCharacter = trimmed.first else { return "#" }
        return String(firstCharacter).uppercased()
    }
}
