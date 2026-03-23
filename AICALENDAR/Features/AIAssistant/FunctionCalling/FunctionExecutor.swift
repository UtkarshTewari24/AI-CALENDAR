import Foundation
import SwiftData

enum FunctionExecutor {

    static func execute(
        functionName: String,
        arguments: String,
        modelContext: ModelContext
    ) -> String {
        guard let data = arguments.data(using: .utf8),
              let args = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return #"{"error": "Invalid arguments"}"#
        }

        switch functionName {
        case "get_events":
            return getEvents(args: args, context: modelContext)
        case "add_event":
            return addEvent(args: args, context: modelContext)
        case "update_event":
            return updateEvent(args: args, context: modelContext)
        case "delete_event":
            return deleteEvent(args: args, context: modelContext)
        case "swap_events":
            return swapEvents(args: args, context: modelContext)
        case "find_free_slot":
            return findFreeSlot(args: args, context: modelContext)
        case "get_tasks":
            return getTasks(context: modelContext)
        case "create_task":
            return createTask(args: args, context: modelContext)
        default:
            return #"{"error": "Unknown function: \#(functionName)"}"#
        }
    }

    // MARK: - Get Events

    private static func getEvents(args: [String: Any], context: ModelContext) -> String {
        guard let dateStr = args["date"] as? String,
              let date = parseDate(dateStr) else {
            return #"{"error": "Invalid date format"}"#
        }

        let start = date.startOfDay
        let end = date.endOfDay

        let descriptor = FetchDescriptor<CalendarEvent>(
            predicate: #Predicate { $0.startDate >= start && $0.startDate <= end },
            sortBy: [SortDescriptor(\.startDate)]
        )

        guard let events = try? context.fetch(descriptor) else {
            return #"{"events": []}"#
        }

        let eventDicts = events.map { event -> [String: Any] in
            [
                "id": event.id.uuidString,
                "title": event.title,
                "startTime": formatTime(event.startDate),
                "endTime": formatTime(event.endDate),
                "type": event.typeRaw,
                "priority": event.priority
            ]
        }

        if let data = try? JSONSerialization.data(withJSONObject: ["events": eventDicts]),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return #"{"events": []}"#
    }

    // MARK: - Add Event

    private static func addEvent(args: [String: Any], context: ModelContext) -> String {
        guard let title = args["title"] as? String,
              let dayStr = args["day"] as? String,
              let startStr = args["startTime"] as? String,
              let endStr = args["endTime"] as? String,
              let typeStr = args["type"] as? String,
              let date = parseDate(dayStr),
              let startDate = parseTime(startStr, on: date),
              let endDate = parseTime(endStr, on: date) else {
            return #"{"error": "Missing or invalid fields"}"#
        }

        let eventType = EventType(rawValue: typeStr) ?? .personal
        let isRecurring = args["isRecurring"] as? Bool ?? false

        let event = CalendarEvent(
            title: title,
            startDate: startDate,
            endDate: endDate,
            type: eventType,
            isRecurring: isRecurring
        )
        context.insert(event)

        return #"{"success": true, "eventId": "\#(event.id.uuidString)", "title": "\#(title)", "startTime": "\#(startStr)", "endTime": "\#(endStr)"}"#
    }

    // MARK: - Update Event

    private static func updateEvent(args: [String: Any], context: ModelContext) -> String {
        guard let idStr = args["eventId"] as? String,
              let eventId = UUID(uuidString: idStr) else {
            return #"{"error": "Invalid event ID"}"#
        }

        let descriptor = FetchDescriptor<CalendarEvent>(
            predicate: #Predicate { $0.id == eventId }
        )

        guard let event = try? context.fetch(descriptor).first else {
            return #"{"error": "Event not found"}"#
        }

        if let title = args["title"] as? String { event.title = title }
        if let typeStr = args["type"] as? String { event.typeRaw = typeStr }

        if let startStr = args["startTime"] as? String,
           let start = parseTime(startStr, on: event.startDate) {
            event.startDate = start
        }
        if let endStr = args["endTime"] as? String,
           let end = parseTime(endStr, on: event.endDate) {
            event.endDate = end
        }

        return #"{"success": true, "eventId": "\#(event.id.uuidString)"}"#
    }

    // MARK: - Delete Event

    private static func deleteEvent(args: [String: Any], context: ModelContext) -> String {
        guard let idStr = args["eventId"] as? String,
              let eventId = UUID(uuidString: idStr) else {
            return #"{"error": "Invalid event ID"}"#
        }

        let descriptor = FetchDescriptor<CalendarEvent>(
            predicate: #Predicate { $0.id == eventId }
        )

        guard let event = try? context.fetch(descriptor).first else {
            return #"{"error": "Event not found"}"#
        }

        let title = event.title
        context.delete(event)
        return #"{"success": true, "deleted": "\#(title)"}"#
    }

    // MARK: - Swap Events

    private static func swapEvents(args: [String: Any], context: ModelContext) -> String {
        guard let id1Str = args["eventId1"] as? String,
              let id2Str = args["eventId2"] as? String,
              let id1 = UUID(uuidString: id1Str),
              let id2 = UUID(uuidString: id2Str) else {
            return #"{"error": "Invalid event IDs"}"#
        }

        let desc1 = FetchDescriptor<CalendarEvent>(predicate: #Predicate { $0.id == id1 })
        let desc2 = FetchDescriptor<CalendarEvent>(predicate: #Predicate { $0.id == id2 })

        guard let event1 = try? context.fetch(desc1).first,
              let event2 = try? context.fetch(desc2).first else {
            return #"{"error": "One or both events not found"}"#
        }

        let tempStart = event1.startDate
        let tempEnd = event1.endDate
        event1.startDate = event2.startDate
        event1.endDate = event2.endDate
        event2.startDate = tempStart
        event2.endDate = tempEnd

        return #"{"success": true, "swapped": ["\#(event1.title)", "\#(event2.title)"]}"#
    }

    // MARK: - Find Free Slot

    private static func findFreeSlot(args: [String: Any], context: ModelContext) -> String {
        guard let dateStr = args["date"] as? String,
              let duration = args["durationMinutes"] as? Int,
              let date = parseDate(dateStr) else {
            return #"{"error": "Invalid parameters"}"#
        }

        let start = date.startOfDay
        let end = date.endOfDay

        let descriptor = FetchDescriptor<CalendarEvent>(
            predicate: #Predicate { $0.startDate >= start && $0.startDate <= end },
            sortBy: [SortDescriptor(\.startDate)]
        )

        guard let events = try? context.fetch(descriptor) else {
            return #"{"slots": [{"startTime": "08:00", "endTime": "22:00"}]}"#
        }

        // Find gaps between events
        var slots: [[String: String]] = []
        var currentTime = Date.timeFromComponents(hour: 7, minute: 0, relativeTo: date)
        let dayEnd = Date.timeFromComponents(hour: 22, minute: 0, relativeTo: date)

        for event in events {
            if event.startDate > currentTime {
                let gap = event.startDate.timeIntervalSince(currentTime) / 60
                if Int(gap) >= duration {
                    slots.append([
                        "startTime": formatTime(currentTime),
                        "endTime": formatTime(event.startDate)
                    ])
                }
            }
            if event.endDate > currentTime {
                currentTime = event.endDate
            }
        }

        // Check gap after last event
        if currentTime < dayEnd {
            let gap = dayEnd.timeIntervalSince(currentTime) / 60
            if Int(gap) >= duration {
                slots.append([
                    "startTime": formatTime(currentTime),
                    "endTime": formatTime(dayEnd)
                ])
            }
        }

        if let data = try? JSONSerialization.data(withJSONObject: ["slots": slots]),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return #"{"slots": []}"#
    }

    // MARK: - Get Tasks

    private static func getTasks(context: ModelContext) -> String {
        let descriptor = FetchDescriptor<AxiomTask>(
            predicate: #Predicate { $0.statusRaw == "pending" },
            sortBy: [SortDescriptor(\.deadline)]
        )

        guard let tasks = try? context.fetch(descriptor) else {
            return #"{"tasks": []}"#
        }

        let taskDicts = tasks.map { task -> [String: Any] in
            [
                "id": task.id.uuidString,
                "title": task.title,
                "deadline": formatDateTime(task.deadline),
                "status": task.statusRaw,
                "isOverdue": task.isOverdue
            ]
        }

        if let data = try? JSONSerialization.data(withJSONObject: ["tasks": taskDicts]),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return #"{"tasks": []}"#
    }

    // MARK: - Create Task

    private static func createTask(args: [String: Any], context: ModelContext) -> String {
        guard let title = args["title"] as? String,
              let deadlineStr = args["deadline"] as? String,
              let deadline = parseDateTime(deadlineStr) else {
            return #"{"error": "Missing title or deadline"}"#
        }

        let description = args["description"] as? String ?? ""
        let methodStr = args["verificationMethod"] as? String ?? "photo"
        let method = VerificationMethod(rawValue: methodStr) ?? .photo

        let task = AxiomTask(
            title: title,
            taskDescription: description,
            deadline: deadline,
            verificationMethod: method
        )
        context.insert(task)

        return #"{"success": true, "taskId": "\#(task.id.uuidString)", "title": "\#(title)"}"#
    }

    // MARK: - Helpers

    private static func parseDate(_ str: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: str)
    }

    private static func parseTime(_ timeStr: String, on date: Date) -> Date? {
        let parts = timeStr.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = parts[0]
        components.minute = parts[1]
        return calendar.date(from: components)
    }

    private static func parseDateTime(_ str: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: str)
    }

    private static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private static func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
