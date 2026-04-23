import Foundation
import SQLite3
import SwiftUI

struct TodoSnapshot: Sendable {
    let todos: [PersistedTodo]
    let tags: [PersistedTag]
}

struct PersistedTag: Sendable {
    let id: UUID
    let name: String
    let colorHex: String

    var appTag: TodoTag {
        TodoTag(id: id, name: name, tint: Color(databaseHex: colorHex))
    }
}

struct PersistedTodo: Sendable {
    let id: UUID
    let title: String
    let notes: String
    let screenshotPath: String?
    let status: TodoStatus
    let dueDate: Date?
    let priority: TodoPriority
    let tags: [PersistedTag]
    let createdAt: Date
    let completedAt: Date?

    var appTodo: TodoItem {
        TodoItem(
            id: id,
            title: title,
            notes: notes,
            screenshotPath: screenshotPath,
            status: status,
            dueDate: dueDate,
            priority: priority,
            tags: tags.map(\.appTag),
            createdAt: createdAt,
            completedAt: completedAt
        )
    }
}

enum SettingKey: String, Sendable {
    case quickInputShortcut = "shortcut_quick_input"
    case showListShortcut = "shortcut_show_list"
    case appearanceMode = "appearance_mode"
    case hideDockIcon = "hide_dock_icon"
    case appLanguage = "app_language"
}

struct TodoTransferBundle: Codable, Sendable {
    let version: String
    let exportedAt: String
    let todos: [TodoTransferRecord]
    let tags: [TagTransferRecord]

    enum CodingKeys: String, CodingKey {
        case version
        case exportedAt = "exported_at"
        case todos
        case tags
    }
}

struct TodoTransferRecord: Codable, Sendable {
    let title: String
    let content: String?
    let screenshotPath: String?
    let dueDate: String?
    let status: String
    let priority: Int?
    let tags: [String]
    let createdAt: String
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case title
        case content
        case screenshotPath = "screenshot_path"
        case dueDate = "due_date"
        case status
        case priority
        case tags
        case createdAt = "created_at"
        case completedAt = "completed_at"
    }
}

struct TagTransferRecord: Codable, Sendable {
    let name: String
    let color: String
}

enum SharedDatabaseLocation {
    static let todoDatabaseURL: URL = {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return baseURL
            .appendingPathComponent("com.todolist.app", isDirectory: true)
            .appendingPathComponent("todo.db", isDirectory: false)
    }()

    static let screenshotsDirectoryURL: URL = todoDatabaseURL
        .deletingLastPathComponent()
        .appendingPathComponent("screenshots", isDirectory: true)
}

enum TodoDatabaseError: LocalizedError {
    case openDatabaseFailed(String)
    case statementFailed(String)
    case invalidIdentifier(String)
    case duplicateTagName(String)
    case tagNotFound(String)

    var errorDescription: String? {
        switch self {
        case let .openDatabaseFailed(message): message
        case let .statementFailed(message): message
        case let .invalidIdentifier(identifier): "Invalid UUID in database: \(identifier)"
        case let .duplicateTagName(name): LocalizedText.format(.duplicateTagNameFormat, name)
        case let .tagNotFound(identifier): "Tag not found for deletion: \(identifier)"
        }
    }
}

actor TodoDatabase {
    private let databaseURL: URL

    init(databaseURL: URL = SharedDatabaseLocation.todoDatabaseURL) {
        self.databaseURL = databaseURL
    }

    func loadSnapshot() throws -> TodoSnapshot {
        try withConnection { db in
            try Self.ensureSchema(in: db)
            let tags = try Self.fetchTags(in: db)
            let tagsByID = Dictionary(uniqueKeysWithValues: tags.map { ($0.id, $0) })
            let todos = try Self.fetchTodos(in: db, tagsByID: tagsByID)
            return TodoSnapshot(todos: todos, tags: tags)
        }
    }

    func loadSettingsSnapshot() throws -> AppSettingsSnapshot {
        try withConnection { db in
            try Self.ensureSchema(in: db)
            let values = try Self.fetchSettings(in: db)
            let appearance = AppearanceMode(rawValue: values[.appearanceMode] ?? "") ?? .system
            let appLanguage = AppLanguage(rawValue: values[.appLanguage] ?? "") ?? .system
            let quickInput = values[.quickInputShortcut] ?? ShortcutConfiguration.default.quickInput
            let showList = values[.showListShortcut] ?? ShortcutConfiguration.default.showList
            let hideDockIcon = (values[.hideDockIcon] ?? "false") == "true"
            return AppSettingsSnapshot(
                appearanceMode: appearance,
                appLanguage: appLanguage,
                shortcuts: ShortcutConfiguration(quickInput: quickInput, showList: showList),
                hideDockIcon: hideDockIcon
            )
        }
    }

    func upsertSetting(key: SettingKey, value: String) throws {
        try withConnection { db in
            try Self.ensureSchema(in: db)
            let sql = """
            INSERT INTO settings (key, value, updated_at)
            VALUES (?, ?, ?)
            ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at
            """
            let statement = try Self.prepare(in: db, sql: sql)
            defer { sqlite3_finalize(statement) }
            try Self.bind(key.rawValue, at: 1, in: statement)
            try Self.bind(value, at: 2, in: statement)
            try Self.bind(Self.formatTimestamp(.now), at: 3, in: statement)
            try Self.step(statement, in: db)
        }
    }

    func createTag(name: String, colorHex: String? = nil) throws -> PersistedTag {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let color = colorHex ?? Self.defaultTagPalette.randomElement() ?? "#3B82F6"
        let tag = PersistedTag(id: UUID(), name: normalized, colorHex: color)

        try withConnection { db in
            try Self.ensureSchema(in: db)
            let sql = "INSERT INTO tags (id, name, color, created_at) VALUES (?, ?, ?, ?)"
            let statement = try Self.prepare(in: db, sql: sql)
            defer { sqlite3_finalize(statement) }
            try Self.bind(tag.id.uuidString, at: 1, in: statement)
            try Self.bind(tag.name, at: 2, in: statement)
            try Self.bind(tag.colorHex, at: 3, in: statement)
            try Self.bind(Self.formatTimestamp(.now), at: 4, in: statement)
            do {
                try Self.step(statement, in: db)
            } catch {
                if Self.lastErrorMessage(in: db).localizedCaseInsensitiveContains("UNIQUE") {
                    throw TodoDatabaseError.duplicateTagName(normalized)
                }
                throw error
            }
        }

        return tag
    }

    func deleteTag(id: UUID) throws {
        try withConnection { db in
            try Self.ensureSchema(in: db)
            let statement = try Self.prepare(in: db, sql: "DELETE FROM tags WHERE id = ?")
            defer { sqlite3_finalize(statement) }
            try Self.bind(id.uuidString, at: 1, in: statement)
            try Self.step(statement, in: db)
            guard sqlite3_changes(db) > 0 else {
                throw TodoDatabaseError.tagNotFound(id.uuidString)
            }
        }
    }

    func insertTodo(
        id: UUID,
        title: String,
        notes: String,
        screenshotPath: String?,
        dueDate: Date?,
        status: TodoStatus,
        priority: TodoPriority,
        createdAt: Date,
        completedAt: Date?,
        tagIDs: [UUID]
    ) throws {
        try withConnection { db in
            try Self.ensureSchema(in: db)
            try Self.execute(in: db, sql: "BEGIN IMMEDIATE TRANSACTION")
            do {
                let todoSQL = """
                INSERT INTO todos (
                    id, title, content, screenshot_path, due_date, status, created_at, updated_at, completed_at, priority
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """
                let statement = try Self.prepare(in: db, sql: todoSQL)
                defer { sqlite3_finalize(statement) }
                try Self.bind(id.uuidString, at: 1, in: statement)
                try Self.bind(title, at: 2, in: statement)
                try Self.bind(notes.isEmpty ? nil : notes, at: 3, in: statement)
                try Self.bind(screenshotPath, at: 4, in: statement)
                try Self.bind(Self.formatDueDate(dueDate), at: 5, in: statement)
                try Self.bind(status.rawValue, at: 6, in: statement)
                try Self.bind(Self.formatTimestamp(createdAt), at: 7, in: statement)
                try Self.bind(Self.formatTimestamp(createdAt), at: 8, in: statement)
                try Self.bind(Self.formatTimestamp(completedAt), at: 9, in: statement)
                try Self.bind(Int32(priority.rawValue), at: 10, in: statement)
                try Self.step(statement, in: db)

                if !tagIDs.isEmpty {
                    let relationStatement = try Self.prepare(in: db, sql: "INSERT OR IGNORE INTO todo_tags (todo_id, tag_id) VALUES (?, ?)")
                    defer { sqlite3_finalize(relationStatement) }
                    for tagID in tagIDs {
                        sqlite3_reset(relationStatement)
                        sqlite3_clear_bindings(relationStatement)
                        try Self.bind(id.uuidString, at: 1, in: relationStatement)
                        try Self.bind(tagID.uuidString, at: 2, in: relationStatement)
                        try Self.step(relationStatement, in: db)
                    }
                }

                try Self.execute(in: db, sql: "COMMIT")
            } catch {
                try? Self.execute(in: db, sql: "ROLLBACK")
                throw error
            }
        }
    }

    func updateTodoStatus(id: UUID, status: TodoStatus, completedAt: Date?) throws {
        try withConnection { db in
            try Self.ensureSchema(in: db)
            let statement = try Self.prepare(
                in: db,
                sql: "UPDATE todos SET status = ?, completed_at = ?, updated_at = ? WHERE id = ?"
            )
            defer { sqlite3_finalize(statement) }
            try Self.bind(status.rawValue, at: 1, in: statement)
            try Self.bind(Self.formatTimestamp(completedAt), at: 2, in: statement)
            try Self.bind(Self.formatTimestamp(.now), at: 3, in: statement)
            try Self.bind(id.uuidString, at: 4, in: statement)
            try Self.step(statement, in: db)
        }
    }

    func deleteTodo(id: UUID) throws {
        try withConnection { db in
            try Self.ensureSchema(in: db)
            let statement = try Self.prepare(in: db, sql: "DELETE FROM todos WHERE id = ?")
            defer { sqlite3_finalize(statement) }
            try Self.bind(id.uuidString, at: 1, in: statement)
            try Self.step(statement, in: db)
        }
    }

    func exportBundle() throws -> TodoTransferBundle {
        try withConnection { db in
            try Self.ensureSchema(in: db)
            let tags = try Self.fetchTags(in: db)
            let tagsByID = Dictionary(uniqueKeysWithValues: tags.map { ($0.id, $0) })
            let todos = try Self.fetchTodos(in: db, tagsByID: tagsByID)

            return TodoTransferBundle(
                version: "2.0",
                exportedAt: ISO8601DateFormatter().string(from: .now),
                todos: todos.map {
                    TodoTransferRecord(
                        title: $0.title,
                        content: $0.notes.isEmpty ? nil : $0.notes,
                        screenshotPath: $0.screenshotPath,
                        dueDate: Self.formatDueDate($0.dueDate),
                        status: $0.status.rawValue,
                        priority: $0.priority.rawValue,
                        tags: $0.tags.map(\.name),
                        createdAt: Self.formatTimestamp($0.createdAt) ?? Self.formatTimestamp(.now)!,
                        completedAt: Self.formatTimestamp($0.completedAt)
                    )
                },
                tags: tags.map { TagTransferRecord(name: $0.name, color: $0.colorHex) }
            )
        }
    }

    func importBundle(_ bundle: TodoTransferBundle) throws -> ImportSummary {
        try withConnection { db in
            try Self.ensureSchema(in: db)
            try Self.execute(in: db, sql: "BEGIN IMMEDIATE TRANSACTION")
            do {
                let timestamp = Self.formatTimestamp(.now) ?? ""
                var tagIDsByName: [String: UUID] = [:]
                var importedTags = 0
                var importedTodos = 0

                for tag in bundle.tags {
                    if let existing = try Self.findTagID(named: tag.name, in: db) {
                        tagIDsByName[tag.name] = existing
                        continue
                    }

                    let tagID = UUID()
                    let statement = try Self.prepare(in: db, sql: "INSERT INTO tags (id, name, color, created_at) VALUES (?, ?, ?, ?)")
                    try Self.bind(tagID.uuidString, at: 1, in: statement)
                    try Self.bind(tag.name, at: 2, in: statement)
                    try Self.bind(tag.color, at: 3, in: statement)
                    try Self.bind(timestamp, at: 4, in: statement)
                    try Self.step(statement, in: db)
                    sqlite3_finalize(statement)
                    tagIDsByName[tag.name] = tagID
                    importedTags += 1
                }

                for record in bundle.todos {
                    let todoID = UUID()
                    let priority = TodoPriority(rawValue: record.priority ?? 4) ?? .p4
                    let statement = try Self.prepare(
                        in: db,
                        sql: """
                        INSERT INTO todos (id, title, content, screenshot_path, due_date, status, created_at, updated_at, completed_at, priority)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """
                    )
                    try Self.bind(todoID.uuidString, at: 1, in: statement)
                    try Self.bind(record.title, at: 2, in: statement)
                    try Self.bind(record.content, at: 3, in: statement)
                    try Self.bind(record.screenshotPath, at: 4, in: statement)
                    try Self.bind(record.dueDate, at: 5, in: statement)
                    try Self.bind(record.status, at: 6, in: statement)
                    try Self.bind(record.createdAt, at: 7, in: statement)
                    try Self.bind(timestamp, at: 8, in: statement)
                    try Self.bind(record.completedAt, at: 9, in: statement)
                    try Self.bind(Int32(priority.rawValue), at: 10, in: statement)
                    try Self.step(statement, in: db)
                    sqlite3_finalize(statement)
                    importedTodos += 1

                    if !record.tags.isEmpty {
                        let relationStatement = try Self.prepare(in: db, sql: "INSERT OR IGNORE INTO todo_tags (todo_id, tag_id) VALUES (?, ?)")
                        defer { sqlite3_finalize(relationStatement) }
                        for tagName in record.tags {
                            let resolvedTagID: UUID?
                            if let existingTagID = tagIDsByName[tagName] {
                                resolvedTagID = existingTagID
                            } else {
                                resolvedTagID = try Self.findTagID(named: tagName, in: db)
                            }
                            if let tagID = resolvedTagID {
                                sqlite3_reset(relationStatement)
                                sqlite3_clear_bindings(relationStatement)
                                try Self.bind(todoID.uuidString, at: 1, in: relationStatement)
                                try Self.bind(tagID.uuidString, at: 2, in: relationStatement)
                                try Self.step(relationStatement, in: db)
                            }
                        }
                    }
                }

                try Self.execute(in: db, sql: "COMMIT")
                return ImportSummary(importedTodos: importedTodos, importedTags: importedTags)
            } catch {
                try? Self.execute(in: db, sql: "ROLLBACK")
                throw error
            }
        }
    }

    private func withConnection<T>(_ body: (OpaquePointer) throws -> T) throws -> T {
        let parentDirectory = databaseURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parentDirectory, withIntermediateDirectories: true)

        var database: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(databaseURL.path, &database, flags, nil) == SQLITE_OK, let database else {
            let message = database.flatMap(Self.lastErrorMessage(in:)) ?? "Unable to open SQLite database."
            sqlite3_close(database)
            throw TodoDatabaseError.openDatabaseFailed(message)
        }
        defer { sqlite3_close(database) }

        try Self.execute(in: database, sql: "PRAGMA foreign_keys = ON;")
        return try body(database)
    }

    private static func ensureSchema(in db: OpaquePointer) throws {
        try execute(in: db, sql: """
        CREATE TABLE IF NOT EXISTS todos (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT,
            screenshot_path TEXT,
            due_date TEXT,
            status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'completed', 'overdue')),
            created_at TEXT DEFAULT (datetime('now')),
            updated_at TEXT DEFAULT (datetime('now')),
            completed_at TEXT
        );

        CREATE TABLE IF NOT EXISTS tags (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            color TEXT DEFAULT '#3B82F6',
            created_at TEXT DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS todo_tags (
            todo_id TEXT NOT NULL,
            tag_id TEXT NOT NULL,
            PRIMARY KEY (todo_id, tag_id),
            FOREIGN KEY (todo_id) REFERENCES todos(id) ON DELETE CASCADE,
            FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at TEXT DEFAULT (datetime('now'))
        );

        INSERT OR IGNORE INTO settings (key, value) VALUES
            ('shortcut_quick_input', 'F2'),
            ('shortcut_show_list', 'F3'),
            ('appearance_mode', 'system'),
            ('hide_dock_icon', 'false'),
            ('app_language', 'system');

        CREATE INDEX IF NOT EXISTS idx_todos_status ON todos(status);
        CREATE INDEX IF NOT EXISTS idx_todos_due_date ON todos(due_date);
        CREATE INDEX IF NOT EXISTS idx_todo_tags_todo ON todo_tags(todo_id);
        CREATE INDEX IF NOT EXISTS idx_todo_tags_tag ON todo_tags(tag_id);
        """)

        if try !columnExists(in: db, table: "todos", column: "priority") {
            try execute(in: db, sql: "ALTER TABLE todos ADD COLUMN priority INTEGER DEFAULT 1;")
        }
    }

    private static func fetchSettings(in db: OpaquePointer) throws -> [SettingKey: String] {
        let statement = try prepare(
            in: db,
            sql: "SELECT key, value FROM settings WHERE key IN (?, ?, ?, ?, ?)"
        )
        defer { sqlite3_finalize(statement) }
        try bind(SettingKey.quickInputShortcut.rawValue, at: 1, in: statement)
        try bind(SettingKey.showListShortcut.rawValue, at: 2, in: statement)
        try bind(SettingKey.appearanceMode.rawValue, at: 3, in: statement)
        try bind(SettingKey.hideDockIcon.rawValue, at: 4, in: statement)
        try bind(SettingKey.appLanguage.rawValue, at: 5, in: statement)

        var values: [SettingKey: String] = [:]
        while sqlite3_step(statement) == SQLITE_ROW {
            if let keyString = text(at: 0, in: statement), let key = SettingKey(rawValue: keyString) {
                values[key] = text(at: 1, in: statement)
            }
        }
        return values
    }

    private static func fetchTags(in db: OpaquePointer) throws -> [PersistedTag] {
        let statement = try prepare(in: db, sql: "SELECT id, name, color FROM tags ORDER BY name COLLATE NOCASE ASC")
        defer { sqlite3_finalize(statement) }

        var tags: [PersistedTag] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let rawID = text(at: 0, in: statement) ?? ""
            guard let id = UUID(uuidString: rawID) else {
                throw TodoDatabaseError.invalidIdentifier(rawID)
            }
            tags.append(
                PersistedTag(
                    id: id,
                    name: text(at: 1, in: statement) ?? "",
                    colorHex: text(at: 2, in: statement) ?? "#3B82F6"
                )
            )
        }
        return tags
    }

    private static func fetchTodos(in db: OpaquePointer, tagsByID: [UUID: PersistedTag]) throws -> [PersistedTodo] {
        let statement = try prepare(
            in: db,
            sql: """
            SELECT
                t.id,
                t.title,
                t.content,
                t.screenshot_path,
                t.due_date,
                t.status,
                t.created_at,
                t.completed_at,
                t.priority,
                tg.id AS tag_id
            FROM todos t
            LEFT JOIN todo_tags tt ON tt.todo_id = t.id
            LEFT JOIN tags tg ON tg.id = tt.tag_id
            ORDER BY t.updated_at DESC, t.created_at DESC, tg.name COLLATE NOCASE ASC
            """
        )
        defer { sqlite3_finalize(statement) }

        struct Accumulator {
            var id: UUID
            var title: String
            var notes: String
            var screenshotPath: String?
            var status: TodoStatus
            var dueDate: Date?
            var priority: TodoPriority
            var createdAt: Date
            var completedAt: Date?
            var tags: [PersistedTag]
        }

        var orderedIDs: [UUID] = []
        var todosByID: [UUID: Accumulator] = [:]

        while sqlite3_step(statement) == SQLITE_ROW {
            let rawID = text(at: 0, in: statement) ?? ""
            guard let todoID = UUID(uuidString: rawID) else {
                throw TodoDatabaseError.invalidIdentifier(rawID)
            }

            if todosByID[todoID] == nil {
                orderedIDs.append(todoID)
                todosByID[todoID] = Accumulator(
                    id: todoID,
                    title: text(at: 1, in: statement) ?? "",
                    notes: text(at: 2, in: statement) ?? "",
                    screenshotPath: text(at: 3, in: statement),
                    status: TodoStatus(rawValue: text(at: 5, in: statement) ?? "") ?? .pending,
                    dueDate: parseDatabaseDate(text(at: 4, in: statement)),
                    priority: TodoPriority(rawValue: Int(int(at: 8, in: statement))) ?? .p1,
                    createdAt: parseDatabaseTimestamp(text(at: 6, in: statement)) ?? .now,
                    completedAt: parseDatabaseTimestamp(text(at: 7, in: statement)),
                    tags: []
                )
            }

            if
                let rawTagID = text(at: 9, in: statement),
                let tagID = UUID(uuidString: rawTagID),
                let tag = tagsByID[tagID]
            {
                todosByID[todoID]?.tags.append(tag)
            }
        }

        return orderedIDs.compactMap { id in
            guard let todo = todosByID[id] else { return nil }
            return PersistedTodo(
                id: todo.id,
                title: todo.title,
                notes: todo.notes,
                screenshotPath: todo.screenshotPath,
                status: todo.status,
                dueDate: todo.dueDate,
                priority: todo.priority,
                tags: todo.tags,
                createdAt: todo.createdAt,
                completedAt: todo.completedAt
            )
        }
    }

    private static func findTagID(named name: String, in db: OpaquePointer) throws -> UUID? {
        let statement = try prepare(in: db, sql: "SELECT id FROM tags WHERE name = ?")
        defer { sqlite3_finalize(statement) }
        try bind(name, at: 1, in: statement)
        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
        guard let rawID = text(at: 0, in: statement), let id = UUID(uuidString: rawID) else {
            throw TodoDatabaseError.invalidIdentifier(text(at: 0, in: statement) ?? "")
        }
        return id
    }

    private static func columnExists(in db: OpaquePointer, table: String, column: String) throws -> Bool {
        let statement = try prepare(in: db, sql: "PRAGMA table_info(\(table))")
        defer { sqlite3_finalize(statement) }

        while sqlite3_step(statement) == SQLITE_ROW {
            if text(at: 1, in: statement) == column {
                return true
            }
        }
        return false
    }

    private static func prepare(in db: OpaquePointer, sql: String) throws -> OpaquePointer {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw TodoDatabaseError.statementFailed(lastErrorMessage(in: db))
        }
        return statement
    }

    private static func execute(in db: OpaquePointer, sql: String) throws {
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            throw TodoDatabaseError.statementFailed(lastErrorMessage(in: db))
        }
    }

    private static func bind(_ value: String?, at index: Int32, in statement: OpaquePointer) throws {
        if let value {
            guard sqlite3_bind_text(statement, index, value, -1, SQLITE_TRANSIENT) == SQLITE_OK else {
                throw TodoDatabaseError.statementFailed("Failed to bind text value.")
            }
        } else {
            guard sqlite3_bind_null(statement, index) == SQLITE_OK else {
                throw TodoDatabaseError.statementFailed("Failed to bind null value.")
            }
        }
    }

    private static func bind(_ value: Int32, at index: Int32, in statement: OpaquePointer) throws {
        guard sqlite3_bind_int(statement, index, value) == SQLITE_OK else {
            throw TodoDatabaseError.statementFailed("Failed to bind integer value.")
        }
    }

    private static func step(_ statement: OpaquePointer, in db: OpaquePointer) throws {
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw TodoDatabaseError.statementFailed(lastErrorMessage(in: db))
        }
    }

    private static func text(at index: Int32, in statement: OpaquePointer) -> String? {
        guard let rawValue = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: rawValue)
    }

    private static func int(at index: Int32, in statement: OpaquePointer) -> Int32 {
        sqlite3_column_int(statement, index)
    }

    private static func lastErrorMessage(in db: OpaquePointer) -> String {
        String(cString: sqlite3_errmsg(db))
    }

    private static func parseDatabaseTimestamp(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        return databaseTimestampFormatter.date(from: value)
            ?? databaseDateFormatter.date(from: value)
            ?? iso8601WithFractional.date(from: value)
            ?? ISO8601DateFormatter().date(from: value)
    }

    private static func parseDatabaseDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        return databaseDateFormatter.date(from: value)
            ?? databaseTimestampFormatter.date(from: value)
            ?? iso8601WithFractional.date(from: value)
            ?? ISO8601DateFormatter().date(from: value)
    }

    private static func formatTimestamp(_ date: Date?) -> String? {
        guard let date else { return nil }
        return databaseTimestampFormatter.string(from: date)
    }

    private static func formatDueDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        return databaseDateFormatter.string(from: date)
    }

    private static let defaultTagPalette = ["#3B82F6", "#10B981", "#F59E0B", "#EF4444", "#8B5CF6", "#EC4899"]
}

private let databaseTimestampFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
}()

private let databaseDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

private let iso8601WithFractional: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

private extension Color {
    init(databaseHex hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let red, green, blue: Double
        switch sanitized.count {
        case 6:
            red = Double((value & 0xFF0000) >> 16) / 255
            green = Double((value & 0x00FF00) >> 8) / 255
            blue = Double(value & 0x0000FF) / 255
        default:
            red = 0.231
            green = 0.510
            blue = 0.965
        }

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}
