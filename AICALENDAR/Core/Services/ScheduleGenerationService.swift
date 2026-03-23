import Foundation

enum ScheduleGenerationError: Error, LocalizedError {
    case generationFailed(String)
    case invalidJSON
    case maxRetriesExceeded

    var errorDescription: String? {
        switch self {
        case .generationFailed(let msg): return "Schedule generation failed: \(msg)"
        case .invalidJSON: return "AI returned invalid schedule data."
        case .maxRetriesExceeded: return "Maximum retries exceeded. Please try again."
        }
    }
}

struct GeneratedEvent: Codable {
    let id: String?
    let title: String
    let day: String
    let startTime: String
    let endTime: String
    let type: String
    let isRecurring: Bool?
    let priority: Int?
}

enum ScheduleGenerationService {

    private static let systemPrompt = """
    You are a personal productivity coach. Given the user's profile data, generate a realistic, optimized 7-day weekly schedule. Return ONLY valid JSON — an array of event objects. Schema:
    [{
      "id": "unique-string",
      "title": "Event name",
      "day": "Mon|Tue|Wed|Thu|Fri|Sat|Sun",
      "startTime": "HH:MM",
      "endTime": "HH:MM",
      "type": "workout|work|meal|routine|personal|sleep",
      "isRecurring": true,
      "priority": 1
    }]
    
    Rules:
    - Respect the user's wake/sleep times strictly.
    - Block workout sessions on their specified days/times.
    - Protect deep work windows based on preferences.
    - Include meals if the user follows a meal schedule.
    - Include morning/evening routines if the user has them.
    - Fill remaining time with work/study blocks based on their occupation.
    - Add personal/recovery time between intense blocks.
    - Priority: 1 = highest, 2 = medium, 3 = lowest.
    - Ensure no time overlaps within a day.
    - Return ONLY the JSON array, no markdown, no explanation.
    """

    static func generateSchedule(surveyJSON: String) async throws -> [CalendarEvent] {
        let userPrompt = "Here is the user's profile data:\n\(surveyJSON)\n\nGenerate their optimized weekly schedule."

        let messages = [
            OpenAIMessage.system(systemPrompt),
            OpenAIMessage.user(userPrompt)
        ]

        let response = try await OpenAIService.sendChatCompletion(
            messages: messages,
            temperature: 0.7,
            responseFormat: ["type": "json_object"]
        )

        guard let content = response.firstMessageContent else {
            throw ScheduleGenerationError.generationFailed("Empty response")
        }

        return try parseGeneratedEvents(from: content)
    }

    private static func parseGeneratedEvents(from jsonString: String) throws -> [CalendarEvent] {
        guard let data = jsonString.data(using: .utf8) else {
            throw ScheduleGenerationError.invalidJSON
        }

        // Try to decode directly as array, or look for a "schedule" key
        let decoder = JSONDecoder()

        var generatedEvents: [GeneratedEvent]

        if let events = try? decoder.decode([GeneratedEvent].self, from: data) {
            generatedEvents = events
        } else if let wrapper = try? decoder.decode([String: [GeneratedEvent]].self, from: data),
                  let events = wrapper.values.first {
            generatedEvents = events
        } else {
            throw ScheduleGenerationError.invalidJSON
        }

        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = today.startOfWeek

        let dayMap: [String: Int] = [
            "Mon": 0, "Tue": 1, "Wed": 2, "Thu": 3,
            "Fri": 4, "Sat": 5, "Sun": 6
        ]

        return generatedEvents.compactMap { event in
            guard let dayOffset = dayMap[event.day] else { return nil }

            let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) ?? today

            guard let startDate = parseTime(event.startTime, on: dayDate),
                  let endDate = parseTime(event.endTime, on: dayDate) else {
                return nil
            }

            let eventType = EventType(rawValue: event.type) ?? .personal

            return CalendarEvent(
                title: event.title,
                startDate: startDate,
                endDate: endDate,
                type: eventType,
                isRecurring: event.isRecurring ?? true,
                priority: event.priority ?? 2
            )
        }
    }

    private static func parseTime(_ timeString: String, on date: Date) -> Date? {
        let parts = timeString.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = parts[0]
        components.minute = parts[1]
        return calendar.date(from: components)
    }
}
