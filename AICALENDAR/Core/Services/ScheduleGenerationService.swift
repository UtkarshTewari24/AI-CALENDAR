import Foundation

enum ScheduleGenerationError: Error, LocalizedError {
    case generationFailed(String)
    case invalidJSON(String)
    case maxRetriesExceeded

    var errorDescription: String? {
        switch self {
        case .generationFailed(let msg): return "Schedule generation failed: \(msg)"
        case .invalidJSON(let detail): return "AI returned invalid schedule data: \(detail)"
        case .maxRetriesExceeded: return "Maximum retries exceeded. Please try again."
        }
    }
}

struct GeneratedEvent: Codable {
    let title: String
    let day: String
    let startTime: String
    let endTime: String
    let type: String?
    let isRecurring: Bool?
    let priority: Int?

    // Accept alternate key names from various models
    enum CodingKeys: String, CodingKey {
        case title, day, type, isRecurring, priority
        case startTime = "startTime"
        case endTime = "endTime"
    }

    // Custom init to handle flexible field names
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: FlexibleCodingKeys.self)

        title = try container.decodeIfPresent(String.self, forKey: .init("title")) ?? "Untitled"

        day = try container.decodeIfPresent(String.self, forKey: .init("day")) ?? "Mon"

        // Try startTime, start_time, start
        if let v = try? container.decode(String.self, forKey: .init("startTime")) {
            startTime = v
        } else if let v = try? container.decode(String.self, forKey: .init("start_time")) {
            startTime = v
        } else if let v = try? container.decode(String.self, forKey: .init("start")) {
            startTime = v
        } else {
            startTime = "09:00"
        }

        // Try endTime, end_time, end
        if let v = try? container.decode(String.self, forKey: .init("endTime")) {
            endTime = v
        } else if let v = try? container.decode(String.self, forKey: .init("end_time")) {
            endTime = v
        } else if let v = try? container.decode(String.self, forKey: .init("end")) {
            endTime = v
        } else {
            endTime = "10:00"
        }

        type = try? container.decode(String.self, forKey: .init("type"))
        if let v = try? container.decode(Bool.self, forKey: .init("isRecurring")) {
            isRecurring = v
        } else {
            isRecurring = try? container.decode(Bool.self, forKey: .init("is_recurring"))
        }
        priority = try? container.decode(Int.self, forKey: .init("priority"))
    }
}

// Flexible coding keys that accept any string
private struct FlexibleCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(_ string: String) {
        self.stringValue = string
        self.intValue = nil
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

enum ScheduleGenerationService {

    private static let systemPrompt = """
    You are an expert personal productivity coach. Given the user's profile data, generate a realistic 7-day weekly schedule.

    You MUST return a JSON object with a "schedule" key containing an array of event objects. Example:
    {"schedule": [{"title": "Morning Run", "day": "Mon", "startTime": "07:00", "endTime": "07:45", "type": "workout", "isRecurring": true, "priority": 1}]}

    Event schema:
    - title: string (specific, actionable name)
    - day: "Mon"|"Tue"|"Wed"|"Thu"|"Fri"|"Sat"|"Sun"
    - startTime: "HH:MM" (24-hour)
    - endTime: "HH:MM" (24-hour)
    - type: "workout"|"work"|"meal"|"routine"|"personal"|"sleep"
    - isRecurring: boolean
    - priority: 1 (critical), 2 (medium), 3 (flexible)

    Requirements:
    1. Sleep block every night
    2. Morning routine after waking (30 min)
    3. Breakfast, lunch, dinner (30-45 min each)
    4. Work/study sessions (1.5-2 hr blocks with breaks)
    5. Workouts on their exercise days
    6. Evening wind-down before sleep
    7. Personal/hobby time (1-2 blocks per day)
    8. Weekends should differ from weekdays

    Generate 8-12 events per day, ~50-60 total. No time overlaps.
    Make titles specific (e.g., "Morning Gym — Upper Body" not "Workout").
    Return ONLY the JSON object, nothing else.
    """

    static func generateSchedule(surveyJSON: String) async throws -> [CalendarEvent] {
        let userPrompt = "Here is the user's profile data:\n\(surveyJSON)\n\nGenerate their optimized weekly schedule. Return ONLY a JSON object with a \"schedule\" key."

        let messages = [
            OpenAIMessage.system(systemPrompt),
            OpenAIMessage.user(userPrompt)
        ]

        let response = try await OpenAIService.sendChatCompletion(
            messages: messages,
            temperature: 0.5,
            responseFormat: ["type": "json_object"]
        )

        guard let content = response.firstMessageContent, !content.isEmpty else {
            throw ScheduleGenerationError.generationFailed("Empty response from AI")
        }

        // Log for debugging
        print("[ScheduleGen] Response length: \(content.count) chars")
        print("[ScheduleGen] First 200 chars: \(String(content.prefix(200)))")

        if let finishReason = response.finishReason, finishReason != "stop" {
            print("[ScheduleGen] Warning: finish_reason = \(finishReason)")
        }

        return try parseGeneratedEvents(from: content)
    }

    private static func parseGeneratedEvents(from jsonString: String) throws -> [CalendarEvent] {
        // Step 1: Clean the string — strip markdown fences and surrounding text
        let cleaned = extractJSON(from: jsonString)

        guard let data = cleaned.data(using: .utf8) else {
            throw ScheduleGenerationError.invalidJSON("Could not convert to data")
        }

        let decoder = JSONDecoder()
        var generatedEvents: [GeneratedEvent] = []

        // Strategy 1: Decode as {"schedule": [...]} wrapper
        if let wrapper = try? decoder.decode(ScheduleWrapper.self, from: data) {
            generatedEvents = wrapper.schedule
            print("[ScheduleGen] Decoded via schedule wrapper: \(generatedEvents.count) events")
        }
        // Strategy 2: Decode as generic dict with any key containing an array
        else if let dictWrapper = try? decoder.decode([String: [GeneratedEvent]].self, from: data),
                let events = dictWrapper.values.first {
            generatedEvents = events
            print("[ScheduleGen] Decoded via dict wrapper: \(generatedEvents.count) events")
        }
        // Strategy 3: Decode as direct array
        else if let events = try? decoder.decode([GeneratedEvent].self, from: data) {
            generatedEvents = events
            print("[ScheduleGen] Decoded as direct array: \(generatedEvents.count) events")
        }
        // Strategy 4: Try to find and extract a JSON array from the text
        else if let arrayData = extractJSONArray(from: cleaned)?.data(using: .utf8),
                let events = try? decoder.decode([GeneratedEvent].self, from: arrayData) {
            generatedEvents = events
            print("[ScheduleGen] Decoded from extracted array: \(generatedEvents.count) events")
        }
        // Strategy 5: Try lenient line-by-line parsing for truncated JSON
        else {
            let events = parseLenient(from: cleaned)
            if !events.isEmpty {
                generatedEvents = events
                print("[ScheduleGen] Lenient parse recovered: \(events.count) events")
            } else {
                // Log the actual content for debugging
                let preview = String(cleaned.prefix(500))
                print("[ScheduleGen] FAILED to parse. Preview: \(preview)")
                throw ScheduleGenerationError.invalidJSON("Could not parse AI response. Preview: \(String(cleaned.prefix(100)))")
            }
        }

        guard !generatedEvents.isEmpty else {
            throw ScheduleGenerationError.invalidJSON("AI returned empty schedule")
        }

        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = today.startOfWeek

        let dayMap: [String: Int] = [
            "Mon": 0, "Monday": 0,
            "Tue": 1, "Tuesday": 1,
            "Wed": 2, "Wednesday": 2,
            "Thu": 3, "Thursday": 3,
            "Fri": 4, "Friday": 4,
            "Sat": 5, "Saturday": 5,
            "Sun": 6, "Sunday": 6
        ]

        let calendarEvents = generatedEvents.compactMap { event -> CalendarEvent? in
            // Try exact match first, then prefix match
            let dayKey = dayMap.keys.first(where: { event.day.hasPrefix($0) || $0.hasPrefix(event.day) })
            guard let key = dayKey, let dayOffset = dayMap[key] else {
                print("[ScheduleGen] Skipping event with unrecognized day: \(event.day)")
                return nil
            }

            let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) ?? today

            guard let startDate = parseTime(event.startTime, on: dayDate),
                  let endDate = parseTime(event.endTime, on: dayDate) else {
                print("[ScheduleGen] Skipping event with bad time: \(event.startTime)-\(event.endTime)")
                return nil
            }

            let eventType = EventType(rawValue: event.type ?? "personal") ?? .personal

            return CalendarEvent(
                title: event.title,
                startDate: startDate,
                endDate: endDate,
                type: eventType,
                isRecurring: event.isRecurring ?? true,
                priority: event.priority ?? 2
            )
        }

        print("[ScheduleGen] Final calendar events: \(calendarEvents.count)")
        return calendarEvents
    }

    // MARK: - JSON Extraction Helpers

    /// Strip markdown fences, find the outermost JSON structure
    private static func extractJSON(from raw: String) -> String {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code fences
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        // If it starts with { or [, it's already JSON
        if cleaned.hasPrefix("{") || cleaned.hasPrefix("[") {
            return cleaned
        }

        // Try to find the first { or [ and extract from there
        if let braceIdx = cleaned.firstIndex(of: "{") {
            cleaned = String(cleaned[braceIdx...])
        } else if let bracketIdx = cleaned.firstIndex(of: "[") {
            cleaned = String(cleaned[bracketIdx...])
        }

        return cleaned
    }

    /// Try to extract a JSON array from within text that might contain a JSON object
    private static func extractJSONArray(from text: String) -> String? {
        guard let start = text.firstIndex(of: "[") else { return nil }

        // Find matching closing bracket
        var depth = 0
        var end: String.Index?
        for idx in text.indices[start...] {
            if text[idx] == "[" { depth += 1 }
            else if text[idx] == "]" {
                depth -= 1
                if depth == 0 {
                    end = idx
                    break
                }
            }
        }

        if let end {
            return String(text[start...end])
        }

        // If no matching bracket found (truncated), return what we have + close it
        return String(text[start...]) + "]"
    }

    /// Last-resort: parse individual JSON objects from truncated JSON
    private static func parseLenient(from text: String) -> [GeneratedEvent] {
        let decoder = JSONDecoder()
        var events: [GeneratedEvent] = []

        // Find all {...} blocks
        var searchStart = text.startIndex
        while searchStart < text.endIndex {
            guard let braceStart = text[searchStart...].firstIndex(of: "{") else { break }

            var depth = 0
            var braceEnd: String.Index?
            for idx in text.indices[braceStart...] {
                if text[idx] == "{" { depth += 1 }
                else if text[idx] == "}" {
                    depth -= 1
                    if depth == 0 {
                        braceEnd = idx
                        break
                    }
                }
            }

            if let braceEnd {
                let objectStr = String(text[braceStart...braceEnd])
                if let objData = objectStr.data(using: .utf8),
                   let event = try? decoder.decode(GeneratedEvent.self, from: objData) {
                    events.append(event)
                }
                searchStart = text.index(after: braceEnd)
            } else {
                break
            }
        }

        return events
    }

    private static func parseTime(_ timeString: String, on date: Date) -> Date? {
        // Handle various time formats: "HH:MM", "H:MM", "HH:MM:SS"
        let cleaned = timeString.trimmingCharacters(in: .whitespaces)
        let parts = cleaned.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return nil }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = min(parts[0], 23)
        components.minute = min(parts[1], 59)
        return calendar.date(from: components)
    }
}

// Typed wrapper for {"schedule": [...]} format
private struct ScheduleWrapper: Codable {
    let schedule: [GeneratedEvent]
}
