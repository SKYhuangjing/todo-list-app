import Foundation
import SwiftUI

enum SampleData {
    static let design = TodoTag(name: "Design", tint: .mint)
    static let product = TodoTag(name: "Product", tint: .blue)
    static let focus = TodoTag(name: "Focus", tint: .orange)
    static let ops = TodoTag(name: "Ops", tint: .green)
    static let writing = TodoTag(name: "Writing", tint: .pink)

    static let tags: [TodoTag] = [design, product, focus, ops, writing]

    static let todos: [TodoItem] = [
        TodoItem(
            title: "Ship the Liquid Glass review build",
            notes: "Freeze visual polish at noon, then verify search, selection, and keyboard flows before sending the build.",
            status: .pending,
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: .now),
            priority: .p1,
            tags: [design, focus]
        ),
        TodoItem(
            title: "Refine task detail copy",
            notes: "Tighten the summary paragraph so the detail pane reads like a command center instead of a note dump.",
            status: .pending,
            dueDate: .now,
            priority: .p2,
            tags: [writing, product]
        ),
        TodoItem(
            title: "Audit menu bar quick actions",
            notes: "Make sure the menu bar view exposes the same next actions users see in the main window.",
            status: .pending,
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: .now),
            priority: .p2,
            tags: [ops]
        ),
        TodoItem(
            title: "Capture onboarding screenshots",
            notes: "Need a clean set for docs after the dashboard layout is stable.",
            status: .pending,
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: .now),
            priority: .p3,
            tags: [design]
        ),
        TodoItem(
            title: "Backfill app launch notes",
            notes: "Summarize what changed in build_and_run.sh and which window opens by default.",
            status: .completed,
            dueDate: Calendar.current.date(byAdding: .day, value: -2, to: .now),
            priority: .p4,
            tags: [writing, ops],
            completedAt: Calendar.current.date(byAdding: .hour, value: -8, to: .now)
        ),
    ]
}
