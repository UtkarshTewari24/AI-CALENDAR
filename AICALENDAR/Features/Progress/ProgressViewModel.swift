import Foundation

@Observable
final class ProgressViewModel {

    struct DayCompletionData: Identifiable {
        let id = UUID()
        let date: Date
        let totalTasks: Int
        let completedTasks: Int
        let failedTasks: Int

        var status: DayStatus {
            if totalTasks == 0 { return .noTasks }
            if completedTasks == totalTasks { return .allCompleted }
            if failedTasks > 0 { return .hasFailed }
            return .partial
        }

        enum DayStatus {
            case noTasks, allCompleted, hasFailed, partial
        }
    }

    func computeLast30Days(tasks: [AxiomTask]) -> [DayCompletionData] {
        let calendar = Calendar.current
        let today = Date().startOfDay

        return (0..<30).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            let dayStart = date.startOfDay
            let dayEnd = date.endOfDay

            let dayTasks = tasks.filter { $0.deadline >= dayStart && $0.deadline <= dayEnd }

            return DayCompletionData(
                date: date,
                totalTasks: dayTasks.count,
                completedTasks: dayTasks.filter { $0.statusRaw == "completed" }.count,
                failedTasks: dayTasks.filter { $0.statusRaw == "failed" }.count
            )
        }
    }

    func averageTimeBeforeDeadline(tasks: [AxiomTask]) -> TimeInterval? {
        let completed = tasks.compactMap { task -> TimeInterval? in
            task.timeBeforeDeadline
        }
        guard !completed.isEmpty else { return nil }
        return completed.reduce(0, +) / Double(completed.count)
    }

    func completionRate(tasks: [AxiomTask]) -> Double {
        let finished = tasks.filter { $0.statusRaw == "completed" || $0.statusRaw == "failed" }
        guard !finished.isEmpty else { return 0 }
        let completed = finished.filter { $0.statusRaw == "completed" }
        return Double(completed.count) / Double(finished.count)
    }
}
