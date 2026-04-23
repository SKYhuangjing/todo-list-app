import SwiftUI

struct RootView: View {
    @Bindable var store: TodoStore
    let router: AppRouter

    @SceneStorage("dashboard.sidebar.expanded") private var isSidebarExpanded = true
    @Environment(LocalizationStore.self) private var localizationStore

    var body: some View {
        HSplitView {
            SidebarView(
                store: store,
                isExpanded: isSidebarExpanded,
                onToggleExpansion: toggleSidebar
            )
            .frame(
                minWidth: isSidebarExpanded ? SidebarLayoutMetrics.expandedWidth : SidebarLayoutMetrics.collapsedWidth,
                idealWidth: isSidebarExpanded ? SidebarLayoutMetrics.expandedWidth : SidebarLayoutMetrics.collapsedWidth,
                maxWidth: isSidebarExpanded ? SidebarLayoutMetrics.expandedWidth : SidebarLayoutMetrics.collapsedWidth
            )

            TodoListView(
                store: store,
                isSidebarExpanded: isSidebarExpanded,
                onToggleSidebar: toggleSidebar,
                onCreate: { router.showQuickAdd() }
            )
            .frame(minWidth: 640, idealWidth: 780, maxWidth: .infinity)

            TodoDetailView(store: store)
                .frame(minWidth: 320, idealWidth: 360, maxWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(SurfaceColor.canvas.ignoresSafeArea())
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
            isSidebarExpanded.toggle()
        }
    }
}
