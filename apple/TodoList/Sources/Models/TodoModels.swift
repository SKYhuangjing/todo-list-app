import Foundation
import SwiftUI

enum TodoStatus: String, CaseIterable, Hashable, Sendable {
    case pending
    case completed
    case overdue

    var isOpen: Bool {
        self != .completed
    }
}

enum TodoPriority: Int, CaseIterable, Identifiable, Comparable, Hashable, Sendable {
    case p1 = 1
    case p2 = 2
    case p3 = 3
    case p4 = 4

    var id: Int { rawValue }

    var title: String { "P\(rawValue)" }

    var description: String {
        switch self {
        case .p1: LocalizedText.string(.priorityCritical)
        case .p2: LocalizedText.string(.priorityToday)
        case .p3: LocalizedText.string(.priorityPlanned)
        case .p4: LocalizedText.string(.prioritySomeday)
        }
    }

    var tint: Color {
        switch self {
        case .p1: .red
        case .p2: .orange
        case .p3: .blue
        case .p4: .secondary
        }
    }

    static func < (lhs: TodoPriority, rhs: TodoPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct TodoTag: Identifiable, Hashable {
    let id: UUID
    var name: String
    var tint: Color

    init(id: UUID = UUID(), name: String, tint: Color) {
        self.id = id
        self.name = name
        self.tint = tint
    }
}

struct TodoItem: Identifiable, Hashable {
    let id: UUID
    var title: String
    var notes: String
    var screenshotPath: String?
    var status: TodoStatus
    var dueDate: Date?
    var priority: TodoPriority
    var tags: [TodoTag]
    var createdAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        screenshotPath: String? = nil,
        status: TodoStatus = .pending,
        dueDate: Date? = nil,
        priority: TodoPriority = .p3,
        tags: [TodoTag] = [],
        createdAt: Date = .now,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.screenshotPath = screenshotPath
        self.status = status
        self.dueDate = dueDate
        self.priority = priority
        self.tags = tags
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    var isCompleted: Bool {
        status == .completed
    }

    var isOpen: Bool {
        status.isOpen
    }
}

enum SidebarSection: String, CaseIterable, Identifiable {
    case inbox
    case today
    case upcoming
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inbox: LocalizedText.string(.sectionInboxTitle)
        case .today: LocalizedText.string(.sectionTodayTitle)
        case .upcoming: LocalizedText.string(.sectionUpcomingTitle)
        case .completed: LocalizedText.string(.sectionCompletedTitle)
        }
    }

    var subtitle: String {
        switch self {
        case .inbox: LocalizedText.string(.sectionInboxSubtitle)
        case .today: LocalizedText.string(.sectionTodaySubtitle)
        case .upcoming: LocalizedText.string(.sectionUpcomingSubtitle)
        case .completed: LocalizedText.string(.sectionCompletedSubtitle)
        }
    }

    var systemImage: String {
        switch self {
        case .inbox: "tray.full"
        case .today: "sun.max"
        case .upcoming: "calendar"
        case .completed: "checkmark.circle"
        }
    }

    var semanticTint: Color {
        switch self {
        case .inbox: .blue
        case .today: .orange
        case .upcoming: .cyan
        case .completed: .green
        }
    }

    func matches(_ todo: TodoItem, referenceDate: Date, calendar: Calendar = .current) -> Bool {
        let today = calendar.startOfDay(for: referenceDate)

        switch self {
        case .inbox:
            return todo.isOpen
        case .today:
            guard todo.isOpen else { return false }
            guard let dueDate = todo.dueDate else { return true }
            return calendar.startOfDay(for: dueDate) <= today
        case .upcoming:
            guard todo.isOpen, let dueDate = todo.dueDate else { return false }
            return calendar.startOfDay(for: dueDate) > today
        case .completed:
            return todo.status == .completed
        }
    }
}

struct TodoDraft {
    var title = ""
    var notes = ""
    var dueDate: Date = .now
    var hasDueDate = false
    var priority: TodoPriority = .p3
    var selectedTagIDs: Set<UUID> = []
    var screenshotPath: String?
}

struct DashboardMetric: Identifiable {
    let id: String
    let title: String
    let value: Int
    let icon: String
    let tint: Color
}

enum AppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: LocalizedText.string(.appearanceModeSystem)
        case .light: LocalizedText.string(.appearanceModeLight)
        case .dark: LocalizedText.string(.appearanceModeDark)
        }
    }
}

struct ShortcutConfiguration: Equatable, Sendable {
    var quickInput: String
    var showList: String

    static let `default` = ShortcutConfiguration(quickInput: "F2", showList: "F3")
}

struct AppSettingsSnapshot: Sendable {
    var appearanceMode: AppearanceMode
    var appLanguage: AppLanguage
    var shortcuts: ShortcutConfiguration
    var hideDockIcon: Bool
}

struct ImportSummary: Sendable {
    let importedTodos: Int
    let importedTags: Int
}
