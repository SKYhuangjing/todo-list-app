import AppKit
import SwiftUI

@MainActor
final class QuickAddPanelController: NSObject, NSWindowDelegate {
    private let window: NSWindow
    private let store: TodoStore
    private let themeStore: ThemeStore
    private let localizationStore: LocalizationStore

    init(store: TodoStore, themeStore: ThemeStore, localizationStore: LocalizationStore) {
        self.store = store
        self.themeStore = themeStore
        self.localizationStore = localizationStore
        self.window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 720),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        super.init()

        window.title = LocalizedText.string(.quickAddTitle, language: localizationStore.resolvedLanguage)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.contentViewController = NSHostingController(rootView: makeRootView())
    }

    func showPanel(preserveDraft: Bool = false) {
        window.title = LocalizedText.string(.quickAddTitle, language: localizationStore.resolvedLanguage)

        if !preserveDraft, let contentViewController = window.contentViewController as? NSHostingController<AnyView> {
            contentViewController.rootView = makeRootView()
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    func hidePanel() {
        window.orderOut(nil)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    private func makeRootView() -> AnyView {
        AnyView(
            QuickAddPanelView(store: store, onClose: { [weak self] in
                self?.hidePanel()
            })
            .environment(themeStore)
            .theme(themeStore.theme)
            .environment(localizationStore)
            .environment(\.locale, localizationStore.locale)
            .id(localizationStore.language)
        )
    }
}
