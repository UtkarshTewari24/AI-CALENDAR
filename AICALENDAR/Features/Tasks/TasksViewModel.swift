import SwiftUI
import SwiftData

enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case today = "Today"
    case thisWeek = "This Week"
    case overdue = "Overdue"
    var id: String { rawValue }
}

@Observable
final class TasksViewModel {
    var selectedFilter: TaskFilter = .all
    var showingAddTask = false
    var selectedTask: AxiomTask?

    func filteredTasks(from tasks: [AxiomTask]) -> (upcoming: [AxiomTask], completed: [AxiomTask]) {
        let filtered: [AxiomTask]
        switch selectedFilter {
        case .all:
            filtered = tasks
        case .today:
            filtered = tasks.filter { $0.deadline.isToday }
        case .thisWeek:
            let weekStart = Date().startOfWeek
            let weekEnd = weekStart.endOfWeek
            filtered = tasks.filter { $0.deadline >= weekStart && $0.deadline <= weekEnd.endOfDay }
        case .overdue:
            filtered = tasks.filter { $0.isOverdue }
        }

        let upcoming = filtered
            .filter { $0.status == .pending }
            .sorted { first, second in
                // Overdue first, then by deadline
                if first.isOverdue && !second.isOverdue { return true }
                if !first.isOverdue && second.isOverdue { return false }
                return first.deadline < second.deadline
            }

        let completed = filtered
            .filter { $0.status == .completed }
            .sorted { $0.verifiedAt ?? $0.deadline > $1.verifiedAt ?? $1.deadline }

        return (upcoming, completed)
    }

    var overdueCount: Int {
        0 // Will be computed from query results in the view
    }
}
