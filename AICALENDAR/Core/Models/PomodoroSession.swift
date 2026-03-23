import Foundation
import SwiftData

@Model
final class PomodoroSession {
    var id: UUID
    var taskId: UUID
    var startTime: Date
    var endTime: Date?
    var durationMinutes: Int
    var wasCompleted: Bool

    init(
        id: UUID = UUID(),
        taskId: UUID,
        startTime: Date = Date(),
        durationMinutes: Int = 25,
        wasCompleted: Bool = false
    ) {
        self.id = id
        self.taskId = taskId
        self.startTime = startTime
        self.endTime = nil
        self.durationMinutes = durationMinutes
        self.wasCompleted = wasCompleted
    }
}
