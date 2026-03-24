import Foundation
import SwiftData

@Model
final class AxiomTask {
    var id: UUID
    var title: String
    var taskDescription: String
    var deadline: Date
    var statusRaw: String
    var verificationMethodRaw: String
    var whatCountsAsDone: String
    var proofImagePath: String?
    var proofText: String?
    var verificationResponse: String?
    var verifiedAt: Date?
    var isPunished: Bool
    var isStrictMode: Bool
    var linkedEventId: UUID?
    var pomodoroDurationMinutes: Int
    var totalTimeLogged: Int
    var completedAt: Date?
    var createdAt: Date

    var status: TaskStatus {
        get { TaskStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    var verificationMethod: VerificationMethod {
        get { VerificationMethod(rawValue: verificationMethodRaw) ?? .photo }
        set { verificationMethodRaw = newValue.rawValue }
    }

    var isOverdue: Bool {
        status == .pending && deadline < Date()
    }

    var timeRemaining: TimeInterval {
        deadline.timeIntervalSince(Date())
    }

    var timeBeforeDeadline: TimeInterval? {
        guard let completed = completedAt ?? verifiedAt else { return nil }
        return deadline.timeIntervalSince(completed)
    }

    init(
        id: UUID = UUID(),
        title: String,
        taskDescription: String = "",
        deadline: Date,
        status: TaskStatus = .pending,
        verificationMethod: VerificationMethod = .photo,
        whatCountsAsDone: String = "",
        isStrictMode: Bool = false,
        linkedEventId: UUID? = nil,
        pomodoroDurationMinutes: Int = 25,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.deadline = deadline
        self.statusRaw = status.rawValue
        self.verificationMethodRaw = verificationMethod.rawValue
        self.whatCountsAsDone = whatCountsAsDone
        self.proofImagePath = nil
        self.proofText = nil
        self.verificationResponse = nil
        self.verifiedAt = nil
        self.isPunished = false
        self.isStrictMode = isStrictMode
        self.linkedEventId = linkedEventId
        self.pomodoroDurationMinutes = pomodoroDurationMinutes
        self.totalTimeLogged = 0
        self.completedAt = nil
        self.createdAt = createdAt
    }
}
