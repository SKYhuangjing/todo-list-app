import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
enum DataTransferService {
    static func exportData(using database: TodoDatabase) async throws -> URL {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "todo-backup-\(Self.fileDateFormatter.string(from: .now)).json"

        guard panel.runModal() == .OK, let url = panel.url else {
            throw CancellationError()
        }

        try await exportData(using: database, to: url)
        return url
    }

    static func importData(using database: TodoDatabase) async throws -> ImportSummary {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else {
            throw CancellationError()
        }

        return try await importData(using: database, from: url)
    }

    static func exportData(using database: TodoDatabase, to url: URL) async throws {
        let bundle = try await database.exportBundle()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(bundle)
        try data.write(to: url, options: .atomic)
    }

    static func importData(using database: TodoDatabase, from url: URL) async throws -> ImportSummary {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let bundle = try decoder.decode(TodoTransferBundle.self, from: data)
        return try await database.importBundle(bundle)
    }

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
