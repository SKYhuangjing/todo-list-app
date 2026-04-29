import AppKit
import CoreGraphics
import Foundation

@MainActor
final class ScreenRecordingPermissionGuide {
    static let shared = ScreenRecordingPermissionGuide()

    private var overlay: PermissionOverlayWindowController?
    private var trackingTimer: Timer?
    private var activationObserver: NSObjectProtocol?
    private var onPermissionGranted: (() -> Void)?

    private init() {}

    func present(
        appDisplayName: String,
        language: ResolvedLanguage,
        onPermissionGranted: @escaping () -> Void
    ) {
        self.onPermissionGranted = onPermissionGranted

        if ScreenshotService.hasPermission() {
            finishGranted()
            return
        }

        let hostApp = PermissionHostApp(
            displayName: appDisplayName,
            bundleURL: Bundle.main.bundleURL,
            icon: NSWorkspace.shared.icon(forFile: Bundle.main.bundleURL.path)
        )
        overlay = PermissionOverlayWindowController(
            hostApp: hostApp,
            language: language,
            onBack: { [weak self] in
                self?.dismiss()
            },
            onDragAccepted: { [weak self] in
                self?.hideAfterDragAccepted()
            }
        )

        ScreenshotService.openSystemSettings()
        startTracking()
    }

    func dismiss() {
        trackingTimer?.invalidate()
        trackingTimer = nil
        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
            self.activationObserver = nil
        }
        overlay?.close()
        overlay = nil
        onPermissionGranted = nil
    }

    private func startTracking() {
        trackingTimer?.invalidate()
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }

        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
        }
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }

        refresh()
    }

    private func refresh() {
        if ScreenshotService.hasPermission() {
            finishGranted()
            return
        }

        guard let snapshot = SystemSettingsWindowLocator.frontmostWindow() else {
            overlay?.hide()
            return
        }
        overlay?.show(anchoredTo: snapshot.frame, visibleFrame: snapshot.visibleFrame)
    }

    private func finishGranted() {
        let callback = onPermissionGranted
        dismiss()
        callback?()
    }

    private func hideAfterDragAccepted() {
        trackingTimer?.invalidate()
        trackingTimer = nil
        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
            self.activationObserver = nil
        }
        overlay?.close()
        overlay = nil
    }
}

private struct PermissionHostApp {
    let displayName: String
    let bundleURL: URL
    let icon: NSImage
}

private struct SystemSettingsWindowSnapshot {
    let frame: CGRect
    let visibleFrame: CGRect
}

private enum SystemSettingsWindowLocator {
    static let bundleIdentifier = "com.apple.systempreferences"

    static func frontmostWindow() -> SystemSettingsWindowSnapshot? {
        guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == bundleIdentifier else {
            return nil
        }
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first else {
            return nil
        }
        guard let windowInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], .zero) as? [[String: Any]] else {
            return nil
        }

        let windows = windowInfo.compactMap { info -> SystemSettingsWindowSnapshot? in
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t, ownerPID == app.processIdentifier else {
                return nil
            }
            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0 else {
                return nil
            }
            guard let bounds = info[kCGWindowBounds as String] as? [String: CGFloat] else {
                return nil
            }

            let cgFrame = CGRect(
                x: bounds["X"] ?? 0,
                y: bounds["Y"] ?? 0,
                width: bounds["Width"] ?? 0,
                height: bounds["Height"] ?? 0
            )
            let converted = appKitGeometry(from: cgFrame)
            guard converted.frame.width > 320, converted.frame.height > 240 else {
                return nil
            }
            return SystemSettingsWindowSnapshot(frame: converted.frame, visibleFrame: converted.visibleFrame)
        }

        return windows.max { lhs, rhs in
            lhs.frame.width * lhs.frame.height < rhs.frame.width * rhs.frame.height
        }
    }

    private static func appKitGeometry(from cgFrame: CGRect) -> (frame: CGRect, visibleFrame: CGRect) {
        let screens = NSScreen.screens.compactMap { screen -> (frame: CGRect, visibleFrame: CGRect, cgBounds: CGRect)? in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return nil
            }
            let displayID = CGDirectDisplayID(number.uint32Value)
            return (screen.frame, screen.visibleFrame, CGDisplayBounds(displayID))
        }

        guard let matchedScreen = screens
            .filter({ $0.cgBounds.intersects(cgFrame) })
            .max(by: { lhs, rhs in
                lhs.cgBounds.intersection(cgFrame).width * lhs.cgBounds.intersection(cgFrame).height
                    < rhs.cgBounds.intersection(cgFrame).width * rhs.cgBounds.intersection(cgFrame).height
            })
        else {
            return (cgFrame, NSScreen.main?.visibleFrame ?? cgFrame)
        }

        let localX = cgFrame.minX - matchedScreen.cgBounds.minX
        let localY = cgFrame.minY - matchedScreen.cgBounds.minY
        let frame = CGRect(
            x: matchedScreen.frame.minX + localX,
            y: matchedScreen.frame.maxY - localY - cgFrame.height,
            width: cgFrame.width,
            height: cgFrame.height
        )
        return (frame, matchedScreen.visibleFrame)
    }
}

private final class PermissionOverlayWindowController: NSWindowController {
    private let windowSize = NSSize(width: 530, height: 109)

    init(
        hostApp: PermissionHostApp,
        language: ResolvedLanguage,
        onBack: @escaping () -> Void,
        onDragAccepted: @escaping () -> Void
    ) {
        let panel = PassiveOverlayPanel(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init(window: panel)
        configure(panel)
        panel.contentView = PermissionOverlayContentView(
            hostApp: hostApp,
            language: language,
            onBack: onBack,
            onDragAccepted: onDragAccepted
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(anchoredTo settingsFrame: CGRect, visibleFrame: CGRect) {
        guard let window else { return }
        window.setFrame(NSRect(origin: origin(for: settingsFrame, visibleFrame: visibleFrame), size: windowSize), display: true)
        window.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }

    private func configure(_ window: NSWindow) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.hasShadow = true
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.animationBehavior = .none
    }

    private func origin(for settingsFrame: CGRect, visibleFrame: CGRect) -> NSPoint {
        let sidebarWidth: CGFloat = 170
        let contentMinX = settingsFrame.minX + sidebarWidth
        let contentWidth = max(settingsFrame.width - sidebarWidth, windowSize.width)
        let preferredX = contentMinX + ((contentWidth - windowSize.width) / 2) - 8
        let preferredY = settingsFrame.minY + 14
        let minX = visibleFrame.minX + 8
        let maxX = visibleFrame.maxX - windowSize.width - 8
        let minY = visibleFrame.minY + 8
        let maxY = visibleFrame.maxY - windowSize.height - 8

        return NSPoint(
            x: min(max(preferredX, minX), maxX),
            y: min(max(preferredY, minY), maxY)
        )
    }
}

private final class PassiveOverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private final class PermissionOverlayContentView: NSView {
    private let hostApp: PermissionHostApp
    private let language: ResolvedLanguage
    private let onBack: () -> Void
    private let onDragAccepted: () -> Void

    init(
        hostApp: PermissionHostApp,
        language: ResolvedLanguage,
        onBack: @escaping () -> Void,
        onDragAccepted: @escaping () -> Void
    ) {
        self.hostApp = hostApp
        self.language = language
        self.onBack = onBack
        self.onDragAccepted = onDragAccepted
        super.init(frame: NSRect(x: 0, y: 0, width: 530, height: 109))
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        let materialView = NSVisualEffectView()
        materialView.translatesAutoresizingMaskIntoConstraints = false
        materialView.material = .popover
        materialView.blendingMode = .behindWindow
        materialView.state = .active
        materialView.wantsLayer = true
        materialView.layer?.cornerRadius = 18
        materialView.layer?.masksToBounds = true
        materialView.layer?.borderWidth = 0.5
        materialView.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.18).cgColor
        addSubview(materialView)

        let tintView = NSView()
        tintView.translatesAutoresizingMaskIntoConstraints = false
        tintView.wantsLayer = true
        tintView.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.78).cgColor
        materialView.addSubview(tintView)

        let backChrome = NSView()
        backChrome.translatesAutoresizingMaskIntoConstraints = false
        backChrome.wantsLayer = true
        backChrome.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95).cgColor
        backChrome.layer?.cornerRadius = 16
        materialView.addSubview(backChrome)

        let backButton = NSButton()
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.isBordered = false
        backButton.image = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: LocalizedText.string(.close, language: language))
        backButton.contentTintColor = NSColor.labelColor.withAlphaComponent(0.72)
        backButton.target = self
        backButton.action = #selector(backPressed)
        if let cell = backButton.cell as? NSButtonCell {
            cell.imagePosition = .imageOnly
        }
        backChrome.addSubview(backButton)

        let arrowView = NSImageView()
        arrowView.translatesAutoresizingMaskIntoConstraints = false
        arrowView.image = NSImage(systemSymbolName: "arrow.up", accessibilityDescription: nil)
        arrowView.symbolConfiguration = .init(pointSize: 28, weight: .bold)
        arrowView.contentTintColor = NSColor(calibratedRed: 0.15, green: 0.54, blue: 0.98, alpha: 1)
        materialView.addSubview(arrowView)

        let titleLabel = NSTextField(labelWithString: titleText)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = NSColor.labelColor.withAlphaComponent(0.82)
        titleLabel.maximumNumberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        materialView.addSubview(titleLabel)

        let dragSource = PermissionAppDragSourceView(hostApp: hostApp, onDragAccepted: onDragAccepted)
        materialView.addSubview(dragSource)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 530),
            heightAnchor.constraint(equalToConstant: 109),

            materialView.leadingAnchor.constraint(equalTo: leadingAnchor),
            materialView.trailingAnchor.constraint(equalTo: trailingAnchor),
            materialView.topAnchor.constraint(equalTo: topAnchor),
            materialView.bottomAnchor.constraint(equalTo: bottomAnchor),

            tintView.leadingAnchor.constraint(equalTo: materialView.leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: materialView.trailingAnchor),
            tintView.topAnchor.constraint(equalTo: materialView.topAnchor),
            tintView.bottomAnchor.constraint(equalTo: materialView.bottomAnchor),

            backChrome.leadingAnchor.constraint(equalTo: materialView.leadingAnchor, constant: 18),
            backChrome.topAnchor.constraint(equalTo: materialView.topAnchor, constant: 52),
            backChrome.widthAnchor.constraint(equalToConstant: 32),
            backChrome.heightAnchor.constraint(equalToConstant: 32),

            backButton.centerXAnchor.constraint(equalTo: backChrome.centerXAnchor),
            backButton.centerYAnchor.constraint(equalTo: backChrome.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 14),
            backButton.heightAnchor.constraint(equalToConstant: 14),

            arrowView.leadingAnchor.constraint(equalTo: materialView.leadingAnchor, constant: 35),
            arrowView.topAnchor.constraint(equalTo: materialView.topAnchor, constant: 10),
            arrowView.widthAnchor.constraint(equalToConstant: 28),
            arrowView.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.leadingAnchor.constraint(equalTo: arrowView.trailingAnchor, constant: 10),
            titleLabel.centerYAnchor.constraint(equalTo: arrowView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: materialView.trailingAnchor, constant: -22),

            dragSource.leadingAnchor.constraint(equalTo: materialView.leadingAnchor, constant: 64),
            dragSource.trailingAnchor.constraint(equalTo: materialView.trailingAnchor, constant: -21),
            dragSource.topAnchor.constraint(equalTo: materialView.topAnchor, constant: 47),
            dragSource.heightAnchor.constraint(equalToConstant: 43)
        ])
    }

    private var titleText: String {
        switch language {
        case .english:
            return "Drag \(hostApp.displayName) to the list above to allow Screen Recording"
        case .simplifiedChinese:
            return "把 \(hostApp.displayName) 拖到上方列表以允许屏幕录制"
        }
    }

    @objc
    private func backPressed() {
        onBack()
    }
}

private final class PermissionAppDragSourceView: NSView, NSPasteboardItemDataProvider, NSDraggingSource {
    private let hostApp: PermissionHostApp
    private let onDragAccepted: () -> Void
    private let rowView = NSView()
    private let iconChrome = NSView()
    private let iconView: NSImageView
    private let label = NSTextField(labelWithString: "")

    init(hostApp: PermissionHostApp, onDragAccepted: @escaping () -> Void) {
        self.hostApp = hostApp
        self.onDragAccepted = onDragAccepted
        self.iconView = NSImageView(image: hostApp.icon)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setup()
        updateAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setDataProvider(self, forTypes: [.fileURL])

        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        draggingItem.setDraggingFrame(convert(rowView.bounds, from: rowView), contents: draggingImage())

        let session = beginDraggingSession(with: [draggingItem], event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = true
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateAppearance()
    }

    func pasteboard(_ pasteboard: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: NSPasteboard.PasteboardType) {
        guard type == .fileURL else { return }
        item.setData(hostApp.bundleURL.dataRepresentation, forType: .fileURL)
    }

    func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        rowView.isHidden = true
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        .copy
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        rowView.isHidden = false
        guard operation != [] else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            onDragAccepted()
        }
    }

    private func setup() {
        wantsLayer = true

        rowView.wantsLayer = true
        rowView.layer?.cornerRadius = 7
        rowView.layer?.borderWidth = 1
        rowView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowView)

        iconChrome.wantsLayer = true
        iconChrome.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.9).cgColor
        iconChrome.layer?.cornerRadius = 6
        iconChrome.translatesAutoresizingMaskIntoConstraints = false
        rowView.addSubview(iconChrome)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconChrome.addSubview(iconView)

        label.stringValue = hostApp.displayName
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = NSColor.labelColor.withAlphaComponent(0.82)
        label.translatesAutoresizingMaskIntoConstraints = false
        rowView.addSubview(label)

        NSLayoutConstraint.activate([
            rowView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowView.topAnchor.constraint(equalTo: topAnchor),
            rowView.bottomAnchor.constraint(equalTo: bottomAnchor),
            rowView.heightAnchor.constraint(equalToConstant: 43),

            iconChrome.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 10),
            iconChrome.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            iconChrome.widthAnchor.constraint(equalToConstant: 26),
            iconChrome.heightAnchor.constraint(equalToConstant: 26),

            iconView.centerXAnchor.constraint(equalTo: iconChrome.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconChrome.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            label.leadingAnchor.constraint(equalTo: iconChrome.trailingAnchor, constant: 11),
            label.trailingAnchor.constraint(lessThanOrEqualTo: rowView.trailingAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: rowView.centerYAnchor)
        ])
    }

    private func updateAppearance() {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        if isDark {
            rowView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.06).cgColor
            rowView.layer?.borderColor = NSColor.white.withAlphaComponent(0.08).cgColor
        } else {
            rowView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.65).cgColor
            rowView.layer?.borderColor = NSColor(
                red: 0.87451,
                green: 0.866667,
                blue: 0.862745,
                alpha: 1
            ).cgColor
        }
    }

    private func draggingImage() -> NSImage {
        let image = NSImage(size: rowView.bounds.size)
        image.lockFocus()
        rowView.displayIgnoringOpacity(rowView.bounds, in: NSGraphicsContext.current!)
        image.unlockFocus()
        return image
    }
}
