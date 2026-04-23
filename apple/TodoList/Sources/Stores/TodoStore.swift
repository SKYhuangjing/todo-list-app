import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class TodoStore {
    var todos: [TodoItem]
    var availableTags: [TodoTag]
    var selectedSection: SidebarSection = .today {
        didSet {
            if selectedTagID != nil {
                selectedTagID = nil
            }
            reconcileSelection()
        }
    }
    var selectedTagID: UUID? {
        didSet { reconcileSelection() }
    }
    var selectedTodoID: TodoItem.ID?
    var searchText = "" {
        didSet { reconcileSelection() }
    }

    let database: TodoDatabase
    private let calendar = Calendar.current

    init(database: TodoDatabase = TodoDatabase()) {
        self.database = database
        self.todos = []
        self.availableTags = []
        self.selectedTodoID = nil
        self.selectedTagID = nil
        reconcileSelection()
        Task { [weak self] in
            await self?.reloadFromDatabase()
        }
    }

    var activeTitle: String {
        selectedTag?.name ?? selectedSection.title
    }

    var activeSubtitle: String {
        if let selectedTag {
            return LocalizedText.format(.taggedOpenWorkFormat, selectedTag.name)
        }
        return selectedSection.subtitle
    }

    var activeTint: Color {
        selectedTag?.tint ?? selectedSection.semanticTint
    }

    var selectedTag: TodoTag? {
        guard let selectedTagID else { return nil }
        return availableTags.first(where: { $0.id == selectedTagID })
    }

    var visibleTodos: [TodoItem] {
        todos
            .filter(matchesCurrentScope)
            .sorted(by: sort(lhs:rhs:))
    }

    var selectedTodo: TodoItem? {
        if let selectedTodoID {
            return visibleTodos.first(where: { $0.id == selectedTodoID })
                ?? todos.first(where: { $0.id == selectedTodoID })
        }
        return visibleTodos.first
    }

    var metrics: [DashboardMetric] {
        [
            DashboardMetric(id: "today", title: LocalizedText.string(.metricDueToday), value: count(for: .today), icon: "sun.max", tint: .orange),
            DashboardMetric(id: "upcoming", title: LocalizedText.string(.metricUpcoming), value: count(for: .upcoming), icon: "calendar", tint: .cyan),
            DashboardMetric(id: "completed", title: LocalizedText.string(.metricClosed), value: count(for: .completed), icon: "checkmark.circle", tint: .green),
        ]
    }

    var hasActiveSearch: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func reloadFromDatabase() async {
        do {
            let snapshot = try await database.loadSnapshot()
            availableTags = snapshot.tags.map(\.appTag)
            todos = snapshot.todos.map(\.appTodo)
            if selectedTodoID == nil {
                selectedTodoID = visibleTodos.first?.id ?? todos.first?.id
            }
            reconcileSelection()
        } catch {
            print("Failed to load todos from shared database: \(error.localizedDescription)")
        }
    }

    func count(for section: SidebarSection) -> Int {
        todos.filter { section.matches($0, referenceDate: .now, calendar: calendar) }.count
    }

    func count(forTagID tagID: UUID) -> Int {
        todos.filter { todo in
            todo.isOpen && todo.tags.contains(where: { $0.id == tagID })
        }.count
    }

    func select(_ section: SidebarSection) {
        selectedTagID = nil
        selectedSection = section
    }

    func select(tagID: UUID) {
        selectedTagID = tagID
    }

    func isTagSelected(_ tagID: UUID) -> Bool {
        selectedTagID == tagID
    }

    func select(todoID: TodoItem.ID) {
        withAnimation(StoreMotion.detail) {
            selectedTodoID = todoID
        }
    }

    func toggleCompletion(for todoID: TodoItem.ID) async {
        guard let index = todos.firstIndex(where: { $0.id == todoID }) else { return }
        let isClosing = todos[index].status.isOpen
        let nextStatus: TodoStatus = isClosing ? .completed : .pending
        let completedAt = isClosing ? Date.now : nil

        do {
            try await database.updateTodoStatus(id: todoID, status: nextStatus, completedAt: completedAt)
        } catch {
            print("Failed to update todo status: \(error.localizedDescription)")
            return
        }

        withAnimation(StoreMotion.list) {
            todos[index].status = nextStatus
            todos[index].completedAt = completedAt
            reconcileSelection(preferredTodoID: isClosing ? nil : todoID)
        }
    }

    func createTodo(from draft: TodoDraft) async -> TodoItem? {
        let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }

        let dueDate = draft.hasDueDate ? draft.dueDate : nil
        let tags = availableTags.filter { draft.selectedTagIDs.contains($0.id) }

        let newTodo = TodoItem(
            title: trimmedTitle,
            notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines),
            screenshotPath: draft.screenshotPath,
            status: .pending,
            dueDate: dueDate,
            priority: draft.priority,
            tags: tags
        )

        do {
            try await database.insertTodo(
                id: newTodo.id,
                title: newTodo.title,
                notes: newTodo.notes,
                screenshotPath: newTodo.screenshotPath,
                dueDate: newTodo.dueDate,
                status: newTodo.status,
                priority: newTodo.priority,
                createdAt: newTodo.createdAt,
                completedAt: newTodo.completedAt,
                tagIDs: newTodo.tags.map(\.id)
            )
        } catch {
            print("Failed to create todo: \(error.localizedDescription)")
            return nil
        }

        withAnimation(StoreMotion.list) {
            todos.insert(newTodo, at: 0)
            if selectedTagID == nil {
                selectedSection = dueDate == nil ? .inbox : .today
            }
            selectedTodoID = newTodo.id
            reconcileSelection(preferredTodoID: newTodo.id)
        }
        return newTodo
    }

    func deleteTodo(id: UUID) async -> Bool {
        do {
            try await database.deleteTodo(id: id)
        } catch {
            print("Failed to delete todo: \(error.localizedDescription)")
            return false
        }

        withAnimation(StoreMotion.list) {
            todos.removeAll { $0.id == id }
            reconcileSelection()
        }
        return true
    }

    func createTag(named name: String, colorHex: String? = nil) async -> TodoTag? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }

        do {
            let persistedTag = try await database.createTag(name: trimmedName, colorHex: colorHex)
            let tag = persistedTag.appTag
            withAnimation(StoreMotion.list) {
                availableTags.removeAll { $0.id == tag.id }
                availableTags.append(tag)
                availableTags.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }
            return tag
        } catch {
            print("Failed to create tag: \(error.localizedDescription)")
            return nil
        }
    }

    func deleteTag(id: UUID) async -> Bool {
        do {
            try await database.deleteTag(id: id)
        } catch {
            print("Failed to delete tag: \(error.localizedDescription)")
            return false
        }

        withAnimation(StoreMotion.list) {
            availableTags.removeAll { $0.id == id }
            todos = todos.map { todo in
                var mutable = todo
                mutable.tags.removeAll { $0.id == id }
                return mutable
            }
            if selectedTagID == id {
                selectedTagID = nil
                selectedSection = .inbox
            }
            reconcileSelection()
        }
        return true
    }

    func dueLabel(for todo: TodoItem) -> String {
        guard let dueDate = todo.dueDate else { return LocalizedText.string(.noDeadline) }
        if calendar.isDateInToday(dueDate) { return LocalizedText.string(.today) }
        if calendar.isDateInTomorrow(dueDate) { return LocalizedText.string(.tomorrow) }
        return LocalizedText.dueLabelDate(dueDate)
    }

    func overdueState(for todo: TodoItem) -> Bool {
        guard todo.isOpen, let dueDate = todo.dueDate else { return false }
        return calendar.startOfDay(for: dueDate) < calendar.startOfDay(for: .now)
    }

    func detailDateLabel(for todo: TodoItem) -> String {
        guard let dueDate = todo.dueDate else { return LocalizedText.string(.noDeadline) }
        return LocalizedText.detailDate(dueDate)
    }

    func filteredMenuBarTodos(limit: Int = 4) -> [TodoItem] {
        todos
            .filter(\.isOpen)
            .sorted(by: sort(lhs:rhs:))
            .prefix(limit)
            .map(\.self)
    }

    func reconcileSelection(preferredTodoID: TodoItem.ID? = nil) {
        let visibleIDs = Set(visibleTodos.map(\.id))

        if let preferredTodoID, visibleIDs.contains(preferredTodoID) {
            selectedTodoID = preferredTodoID
            return
        }

        if let selectedTodoID, visibleIDs.contains(selectedTodoID) {
            return
        }

        selectedTodoID = visibleTodos.first?.id
    }

    private func matchesCurrentScope(_ todo: TodoItem) -> Bool {
        if let selectedTagID {
            guard todo.isOpen else { return false }
            guard todo.tags.contains(where: { $0.id == selectedTagID }) else { return false }
        } else if !selectedSection.matches(todo, referenceDate: .now, calendar: calendar) {
            return false
        }

        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return true }

        let loweredQuery = trimmedQuery.lowercased()
        let searchableText = [
            todo.title,
            todo.notes,
            todo.tags.map(\.name).joined(separator: " "),
            todo.screenshotPath ?? ""
        ]
        .joined(separator: " ")
        .lowercased()

        return searchableText.contains(loweredQuery)
    }

    private func sort(lhs: TodoItem, rhs: TodoItem) -> Bool {
        switch (lhs.isCompleted, rhs.isCompleted) {
        case (true, true):
            return (lhs.completedAt ?? lhs.createdAt) > (rhs.completedAt ?? rhs.createdAt)
        case (true, false):
            return false
        case (false, true):
            return true
        case (false, false):
            if lhs.priority != rhs.priority {
                return lhs.priority < rhs.priority
            }

            switch (lhs.dueDate, rhs.dueDate) {
            case let (lhsDue?, rhsDue?):
                if lhsDue != rhsDue {
                    return lhsDue < rhsDue
                }
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                break
            }

            return lhs.createdAt > rhs.createdAt
        }
    }
}

private enum StoreMotion {
    static let section = Animation.snappy(duration: 0.24, extraBounce: 0.02)
    static let list = Animation.snappy(duration: 0.28, extraBounce: 0.04)
    static let detail = Animation.snappy(duration: 0.30, extraBounce: 0.03)
}
