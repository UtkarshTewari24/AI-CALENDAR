import Foundation
import SwiftData

@Model
final class CalendarEvent {
    var id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var typeRaw: String
    var notes: String
    var isRecurring: Bool
    var recurRuleData: Data?
    var linkedTaskId: UUID?
    var priority: Int
    var createdAt: Date

    @Transient
    var type: EventType {
        get { EventType(rawValue: typeRaw) ?? .personal }
        set { typeRaw = newValue.rawValue }
    }

    @Transient
    var recurRule: RecurrenceRule? {
        get {
            guard let data = recurRuleData else { return nil }
            return try? JSONDecoder().decode(RecurrenceRule.self, from: data)
        }
        set {
            recurRuleData = try? JSONEncoder().encode(newValue)
        }
    }

    @Transient
    var durationMinutes: Int {
        Int(endDate.timeIntervalSince(startDate) / 60)
    }

    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        endDate: Date,
        type: EventType = .personal,
        notes: String = "",
        isRecurring: Bool = false,
        recurRule: RecurrenceRule? = nil,
        linkedTaskId: UUID? = nil,
        priority: Int = 2,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.typeRaw = type.rawValue
        self.notes = notes
        self.isRecurring = isRecurring
        self.recurRuleData = try? JSONEncoder().encode(recurRule)
        self.linkedTaskId = linkedTaskId
        self.priority = priority
        self.createdAt = createdAt
    }
}
