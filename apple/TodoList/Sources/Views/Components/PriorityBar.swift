import SwiftUI

struct PriorityBar: View {
    let priority: TodoPriority
    var isActive: Bool = true

    var body: some View {
        Capsule(style: .continuous)
            .fill(priority.semanticTint.opacity(isActive ? 0.95 : 0.30))
            .frame(width: 3)
            .accessibilityHidden(true)
    }
}
