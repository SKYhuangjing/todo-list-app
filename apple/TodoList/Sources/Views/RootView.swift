import SwiftUI

struct RootView: View {
    @Bindable var store: TodoStore
    let router: AppRouter

    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @Environment(\.theme) private var theme
    @Environment(\.openSettings) private var openSettings
    @Environment(LocalizationStore.self) private var localizationStore

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(store: store)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
        } content: {
            TodoListView(
                store: store,
                onCreate: { router.showQuickAdd() }
            )
            .navigationTitle(store.activeTitle)
            .navigationSubtitle(store.activeSubtitle)
            .navigationSplitViewColumnWidth(min: 360, ideal: 430, max: 520)
        } detail: {
            TodoDetailView(store: store)
                .navigationSplitViewColumnWidth(min: 340, ideal: 420, max: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .searchable(
            text: $store.searchText,
            placement: .toolbar,
            prompt: LocalizedText.string(.searchPlaceholder, language: localizationStore.resolvedLanguage)
        )
        .toolbar {
            ToolbarItemGroup {
                Button(action: toggleSidebar) {
                    Label(
                        sidebarToggleTitle,
                        systemImage: columnVisibility == .all ? "sidebar.left" : "sidebar.left"
                    )
                }
                .help(sidebarToggleTitle)

                Button {
                    router.showQuickAdd()
                } label: {
                    Label(LocalizedText.string(.newTask, language: localizationStore.resolvedLanguage), systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])
                .help(LocalizedText.string(.newTask, language: localizationStore.resolvedLanguage))

                Button {
                    openSettings()
                } label: {
                    Label(LocalizedText.string(.settings, language: localizationStore.resolvedLanguage), systemImage: "gearshape")
                }
                .help(LocalizedText.string(.settings, language: localizationStore.resolvedLanguage))
            }
        }
        .tint(theme.accentColor)
        .background {
            WindowBridge(
                role: .dashboard,
                title: LocalizedText.string(.appName, language: localizationStore.resolvedLanguage)
            )
                .frame(width: 0, height: 0)
        }
        .adaptiveWindowBackground()
    }

    private func toggleSidebar() {
        withAnimation(Motion.reveal) {
            columnVisibility = columnVisibility == .all ? .doubleColumn : .all
        }
    }

    private var sidebarToggleTitle: String {
        columnVisibility == .all
            ? LocalizedText.string(.collapseSidebar, language: localizationStore.resolvedLanguage)
            : LocalizedText.string(.expandSidebar, language: localizationStore.resolvedLanguage)
    }
}
