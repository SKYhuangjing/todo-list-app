import Carbon.HIToolbox
import Foundation
import OSLog

enum ShortcutRole: UInt32, CaseIterable {
    case quickInput = 1
    case showList = 2
}

enum ShortcutParseError: LocalizedError {
    case empty
    case unsupportedKey(String)

    var errorDescription: String? {
        switch self {
        case .empty:
            return LocalizedText.string(.shortcutEmpty)
        case let .unsupportedKey(key):
            return LocalizedText.format(.shortcutUnsupportedFormat, key)
        }
    }
}

struct ParsedShortcut {
    let keyCode: UInt32
    let modifiers: UInt32
}

enum ShortcutParser {
    static func parse(_ shortcut: String) throws -> ParsedShortcut {
        let trimmed = shortcut.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ShortcutParseError.empty }

        let parts = trimmed.split(separator: "+").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard let keyPart = parts.last, !keyPart.isEmpty else { throw ShortcutParseError.empty }

        var modifiers: UInt32 = 0
        for modifier in parts.dropLast() {
            switch modifier.lowercased() {
            case "cmd", "command": modifiers |= UInt32(cmdKey)
            case "ctrl", "control": modifiers |= UInt32(controlKey)
            case "alt", "option": modifiers |= UInt32(optionKey)
            case "shift": modifiers |= UInt32(shiftKey)
            default: break
            }
        }

        let normalizedKey = keyPart.uppercased()
        guard let keyCode = keyCode(for: normalizedKey) else {
            throw ShortcutParseError.unsupportedKey(normalizedKey)
        }

        return ParsedShortcut(keyCode: keyCode, modifiers: modifiers)
    }

    private static func keyCode(for key: String) -> UInt32? {
        let map: [String: UInt32] = [
            "A": 0, "S": 1, "D": 2, "F": 3, "H": 4, "G": 5, "Z": 6, "X": 7, "C": 8, "V": 9,
            "B": 11, "Q": 12, "W": 13, "E": 14, "R": 15, "Y": 16, "T": 17,
            "1": 18, "2": 19, "3": 20, "4": 21, "6": 22, "5": 23, "=": 24, "9": 25, "7": 26,
            "-": 27, "8": 28, "0": 29, "]": 30, "O": 31, "U": 32, "[": 33, "I": 34, "P": 35,
            "L": 37, "J": 38, "'": 39, "K": 40, ";": 41, "\\": 42, ",": 43, "/": 44, "N": 45,
            "M": 46, ".": 47, "SPACE": 49
        ]
        if let mapped = map[key] { return mapped }
        if key.hasPrefix("F"), let functionNumber = Int(key.dropFirst()) {
            let functionMap: [Int: UInt32] = [1: 122, 2: 120, 3: 99, 4: 118, 5: 96, 6: 97, 7: 98, 8: 100, 9: 101, 10: 109, 11: 103, 12: 111]
            return functionMap[functionNumber]
        }
        return nil
    }
}

@MainActor
final class GlobalShortcutManager {
    static let shared = GlobalShortcutManager()

    private let signature: OSType = 1414745415 // 'TDGL'
    private let logger = Logger(subsystem: "com.sky.todolistapp", category: "shortcuts")
    private weak var router: AppRouter?
    private var hotKeyRefs: [ShortcutRole: EventHotKeyRef?] = [:]
    private var eventHandlerInstalled = false

    private init() {
        installEventHandlerIfNeeded()
    }

    func update(shortcuts: ShortcutConfiguration, router: AppRouter) throws {
        self.router = router
        unregisterAll()
        try register(shortcut: shortcuts.quickInput, role: .quickInput)
        try register(shortcut: shortcuts.showList, role: .showList)
        logger.info("registered shortcuts quick_input=\(shortcuts.quickInput, privacy: .public) show_list=\(shortcuts.showList, privacy: .public)")
    }

    private func register(shortcut: String, role: ShortcutRole) throws {
        let parsed = try ShortcutParser.parse(shortcut)
        let hotKeyID = EventHotKeyID(signature: signature, id: role.rawValue)
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            parsed.keyCode,
            parsed.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard status == noErr else {
            throw TodoDatabaseError.statementFailed(LocalizedText.format(.shortcutRegisterFailedFormat, shortcut))
        }
        hotKeyRefs[role] = hotKeyRef
    }

    private func unregisterAll() {
        for role in ShortcutRole.allCases {
            if let ref = hotKeyRefs[role] ?? nil {
                UnregisterEventHotKey(ref)
            }
            hotKeyRefs[role] = nil
        }
    }

    private func installEventHandlerIfNeeded() {
        guard !eventHandlerInstalled else { return }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ in
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard status == noErr else { return OSStatus(eventNotHandledErr) }
                Task { @MainActor in
                    GlobalShortcutManager.shared.handleHotKey(id: hotKeyID)
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )
        eventHandlerInstalled = true
    }

    private func handleHotKey(id: EventHotKeyID) {
        guard id.signature == signature, let role = ShortcutRole(rawValue: id.id) else { return }
        logger.info("shortcut_triggered role=\(String(describing: role), privacy: .public)")
        switch role {
        case .quickInput:
            router?.showQuickAdd()
        case .showList:
            router?.showDashboard()
        }
    }
}
