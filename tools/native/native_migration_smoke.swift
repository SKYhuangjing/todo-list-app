import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

@MainActor
func verifyQuickAddDraftPersistence() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let database = TodoDatabase(databaseURL: root.appendingPathComponent("todo.db"))
    let store = TodoStore(database: database)

    _ = await store.createTag(named: "Research", colorHex: "#8B5CF6")
    try await Task.sleep(for: .milliseconds(80))
    guard let tagID = store.availableTags.first?.id else {
        throw NSError(domain: "NativeMigrationSmoke", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Quick Add tag creation did not persist."
        ])
    }

    var draft = TodoDraft()
    draft.title = "Capture migration QA"
    draft.notes = "Quick Add should persist selected tags."
    draft.hasDueDate = true
    draft.dueDate = ISO8601DateFormatter().date(from: "2026-04-24T00:00:00Z") ?? .now
    draft.priority = .p2
    draft.selectedTagIDs = [tagID]
    draft.screenshotPath = "/tmp/quick-add-shot.png"

    let created = await store.createTodo(from: draft)
    let snapshot = try await database.loadSnapshot()

    expect(created?.title == "Capture migration QA", "Quick Add did not create the expected task title.")
    expect(snapshot.todos.count == 1, "Quick Add did not persist exactly one task.")
    expect(snapshot.todos.first?.tags.map(\.name) == ["Research"], "Quick Add tag selection was not persisted.")
    expect(snapshot.todos.first?.screenshotPath == "/tmp/quick-add-shot.png", "Quick Add screenshot path was not persisted.")
}

func verifyTransferRoundTrip() async throws {
    let sourceRoot = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: sourceRoot, withIntermediateDirectories: true)
    let sourceDatabase = TodoDatabase(databaseURL: sourceRoot.appendingPathComponent("todo.db"))
    let opsTag = try await sourceDatabase.createTag(name: "Ops", colorHex: "#10B981")
    try await sourceDatabase.insertTodo(
        id: UUID(),
        title: "Export backup",
        notes: "Ensure native import stays compatible.",
        screenshotPath: "/tmp/export-shot.png",
        dueDate: ISO8601DateFormatter().date(from: "2026-04-23T00:00:00Z"),
        status: .completed,
        priority: .p2,
        createdAt: ISO8601DateFormatter().date(from: "2026-04-21T00:00:00Z") ?? .now,
        completedAt: ISO8601DateFormatter().date(from: "2026-04-21T06:00:00Z"),
        tagIDs: [opsTag.id]
    )

    let exportURL = sourceRoot.appendingPathComponent("backup.json")
    try await DataTransferService.exportData(using: sourceDatabase, to: exportURL)

    let targetRoot = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: targetRoot, withIntermediateDirectories: true)
    let targetDatabase = TodoDatabase(databaseURL: targetRoot.appendingPathComponent("todo.db"))
    let summary = try await DataTransferService.importData(using: targetDatabase, from: exportURL)
    let importedSnapshot = try await targetDatabase.loadSnapshot()

    expect(summary.importedTags == 1, "Import should create exactly one tag.")
    expect(summary.importedTodos == 1, "Import should create exactly one todo.")
    expect(importedSnapshot.todos.first?.status == .completed, "Imported todo status did not round-trip.")
    expect(importedSnapshot.todos.first?.priority == .p2, "Imported todo priority did not round-trip.")
    expect(importedSnapshot.todos.first?.tags.map(\.name) == ["Ops"], "Imported todo tags did not round-trip.")
}

@main
struct NativeMigrationSmoke {
    static func main() async {
        do {
            let settingsRoot = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: settingsRoot, withIntermediateDirectories: true)
            let settingsDatabase = TodoDatabase(databaseURL: settingsRoot.appendingPathComponent("todo.db"))
            let settings = try await settingsDatabase.loadSettingsSnapshot()

            expect(settings.shortcuts.quickInput == "F2", "Default quick input shortcut should remain F2.")
            expect(settings.shortcuts.showList == "F3", "Default show dashboard shortcut should remain F3.")
            expect(settings.hideDockIcon == false, "Hide Dock icon should default to off.")

            try await verifyQuickAddDraftPersistence()
            try await verifyTransferRoundTrip()
            print("native migration smoke passed")
        } catch {
            fputs("FAIL: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
