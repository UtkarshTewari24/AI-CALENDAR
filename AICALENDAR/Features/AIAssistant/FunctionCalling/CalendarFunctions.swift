import Foundation

enum CalendarFunctions {
    static let allTools: [OpenAITool] = [
        getEventsTool,
        addEventTool,
        updateEventTool,
        deleteEventTool,
        swapEventsTool,
        findFreeSlotTool,
        getTasksTool,
        createTaskTool
    ]

    static let getEventsTool = OpenAITool.function(
        name: "get_events",
        description: "Get all events for a specific date",
        parameters: .object(properties: [
            "date": .string(description: "Date in YYYY-MM-DD format")
        ], required: ["date"])
    )

    static let addEventTool = OpenAITool.function(
        name: "add_event",
        description: "Create a new calendar event",
        parameters: .object(properties: [
            "title": .string(description: "Event title"),
            "day": .string(description: "Date in YYYY-MM-DD format"),
            "startTime": .string(description: "Start time in HH:MM format (24h)"),
            "endTime": .string(description: "End time in HH:MM format (24h)"),
            "type": .string(description: "Event type", enumValues: ["workout", "work", "meal", "routine", "personal", "sleep"]),
            "isRecurring": .boolean(description: "Whether this is a recurring event"),
            "recurDays": .array(items: .string(description: "Day of week"), description: "Days of week for recurrence (Mon, Tue, etc.)")
        ], required: ["title", "day", "startTime", "endTime", "type"])
    )

    static let updateEventTool = OpenAITool.function(
        name: "update_event",
        description: "Update an existing event's fields",
        parameters: .object(properties: [
            "eventId": .string(description: "UUID of the event to update"),
            "title": .string(description: "New title"),
            "startTime": .string(description: "New start time HH:MM"),
            "endTime": .string(description: "New end time HH:MM"),
            "type": .string(description: "New event type")
        ], required: ["eventId"])
    )

    static let deleteEventTool = OpenAITool.function(
        name: "delete_event",
        description: "Remove an event from the calendar",
        parameters: .object(properties: [
            "eventId": .string(description: "UUID of the event to delete")
        ], required: ["eventId"])
    )

    static let swapEventsTool = OpenAITool.function(
        name: "swap_events",
        description: "Swap the times of two events",
        parameters: .object(properties: [
            "eventId1": .string(description: "UUID of the first event"),
            "eventId2": .string(description: "UUID of the second event")
        ], required: ["eventId1", "eventId2"])
    )

    static let findFreeSlotTool = OpenAITool.function(
        name: "find_free_slot",
        description: "Find available time windows on a given date",
        parameters: .object(properties: [
            "date": .string(description: "Date in YYYY-MM-DD format"),
            "durationMinutes": .integer(description: "Required duration in minutes")
        ], required: ["date", "durationMinutes"])
    )

    static let getTasksTool = OpenAITool.function(
        name: "get_tasks",
        description: "Get all active tasks with their deadlines",
        parameters: .object(properties: [:])
    )

    static let createTaskTool = OpenAITool.function(
        name: "create_task",
        description: "Create a new task with deadline and verification",
        parameters: .object(properties: [
            "title": .string(description: "Task title"),
            "deadline": .string(description: "Deadline in YYYY-MM-DD HH:MM format"),
            "description": .string(description: "Task description"),
            "verificationMethod": .string(description: "How to verify completion", enumValues: ["photo", "text", "both"])
        ], required: ["title", "deadline"])
    )
}
