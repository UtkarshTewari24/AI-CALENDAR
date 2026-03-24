import Foundation

// MARK: - Event Type

enum EventType: String, Codable, CaseIterable, Identifiable {
    case workout
    case work
    case meal
    case routine
    case personal
    case sleep
    case taskDeadline

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .workout: return "Workout"
        case .work: return "Work / Study"
        case .meal: return "Meal"
        case .routine: return "Routine"
        case .personal: return "Personal"
        case .sleep: return "Sleep"
        case .taskDeadline: return "Task Deadline"
        }
    }

    var defaultIcon: String {
        switch self {
        case .workout: return "figure.run"
        case .work: return "laptopcomputer"
        case .meal: return "fork.knife"
        case .routine: return "arrow.clockwise"
        case .personal: return "person.fill"
        case .sleep: return "moon.fill"
        case .taskDeadline: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Task Status

enum TaskStatus: String, Codable {
    case pending
    case completed
    case failed
}

// MARK: - Verification Method

enum VerificationMethod: String, Codable, CaseIterable, Identifiable {
    case photo
    case text
    case both

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .photo: return "Photo"
        case .text: return "Text"
        case .both: return "Both"
        }
    }
}

// MARK: - Social Platform

enum SocialPlatform: String, Codable, CaseIterable, Identifiable {
    case twitter
    case instagram
    case threads
    case facebook

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .twitter: return "Twitter / X"
        case .instagram: return "Instagram"
        case .threads: return "Threads"
        case .facebook: return "Facebook"
        }
    }

    var iconName: String {
        switch self {
        case .twitter: return "bird"
        case .instagram: return "camera"
        case .threads: return "at"
        case .facebook: return "person.2"
        }
    }
}

// MARK: - Timeline Display Mode

enum TimelineDisplayMode: String, Codable {
    case day
    case week
}

// MARK: - Timeline Density

enum TimelineDensity: String, Codable, CaseIterable, Identifiable {
    case compact
    case comfortable
    case spacious

    var id: String { rawValue }

    var hourHeight: CGFloat {
        switch self {
        case .compact: return 50
        case .comfortable: return 64
        case .spacious: return 80
        }
    }

    var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .comfortable: return "Comfortable"
        case .spacious: return "Spacious"
        }
    }
}

// MARK: - App Color Scheme Preference

enum AppColorSchemePreference: String, Codable, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}

// MARK: - Font Size Preference

enum FontSizePreference: String, Codable, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    var scaleMultiplier: CGFloat {
        switch self {
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.15
        }
    }
}

// MARK: - Recurrence Rule

struct RecurrenceRule: Codable, Equatable, Sendable {
    nonisolated var daysOfWeek: [Int] // 1 = Monday ... 7 = Sunday

    nonisolated init(daysOfWeek: [Int]) {
        self.daysOfWeek = daysOfWeek
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.daysOfWeek = try container.decode([Int].self, forKey: .daysOfWeek)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(daysOfWeek, forKey: .daysOfWeek)
    }

    private enum CodingKeys: String, CodingKey {
        case daysOfWeek
    }
}
