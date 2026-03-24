import Foundation

struct SurveyResponse: Codable {
    // SECTION A: Daily Rhythm
    var wakeUpHour: Int = 6
    var wakeUpMinute: Int = 0
    var sleepHour: Int = 22
    var sleepMinute: Int = 0
    var chronotype: Chronotype = .inBetween
    var workStudyHours: Double = 8

    // SECTION B: Fitness & Health
    var doesExercise: ExerciseFrequency = .sometimes
    var exerciseTypes: [ExerciseType] = []
    var exerciseSchedule: [ExerciseScheduleEntry] = []
    var dietaryStructure: [DietaryOption] = []
    var mealTimes: MealTimes = MealTimes()

    // SECTION C: Work / Study
    var occupation: String = ""
    var workStartHour: Int = 9
    var workStartMinute: Int = 0
    var workEndHour: Int = 17
    var workEndMinute: Int = 0
    var workDays: [Int] = [1, 2, 3, 4, 5] // 1=Mon..7=Sun, default Mon-Fri
    var hasFixedCommitments: Bool = false
    var fixedCommitments: [FixedCommitment] = []
    var deepWorkPreference: TimeOfDayPreference = .morning
    var deepWorkHoursTarget: Int = 4

    // SECTION D: Personal Routines
    var hasMorningRoutine: Bool = false
    var morningRoutineItems: [RoutineItem] = []
    var morningRoutineMinutes: Int = 30
    var hasEveningRoutine: Bool = false
    var eveningRoutineItems: [RoutineItem] = []
    var eveningRoutineMinutes: Int = 30

    // SECTION E: Priorities & Values
    var topPriorities: [LifeArea] = [.health, .career, .relationships]
    var socialAccountabilityFeel: AccountabilityFeel = .fineWithIt
    var dailyNonNegotiable: String = ""
}

// MARK: - Enums

enum Chronotype: String, Codable, CaseIterable, Identifiable {
    case morning = "Morning Person"
    case night = "Night Person"
    case inBetween = "In Between"
    var id: String { rawValue }
}

enum ExerciseFrequency: String, Codable, CaseIterable, Identifiable {
    case yes = "Yes"
    case no = "No"
    case sometimes = "Sometimes"
    var id: String { rawValue }
}

enum ExerciseType: String, Codable, CaseIterable, Identifiable {
    case running = "Running"
    case gym = "Gym / Weights"
    case martialArts = "Martial Arts / Combat Sports"
    case yoga = "Yoga / Stretching"
    case teamSports = "Team Sports"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case other = "Other"
    var id: String { rawValue }
}

struct ExerciseScheduleEntry: Codable, Identifiable {
    var id = UUID()
    var activity: ExerciseType
    var days: [Int] = [] // 1 = Monday ... 7 = Sunday
    var hour: Int = 8
    var minute: Int = 0
}

enum DietaryOption: String, Codable, CaseIterable, Identifiable {
    case intermittentFasting = "Intermittent Fasting"
    case specificMealTimes = "Specific Meal Times"
    case noStructure = "No Structure"
    case other = "Other"
    var id: String { rawValue }
}

struct MealTimes: Codable {
    var breakfastHour: Int = 8
    var breakfastMinute: Int = 0
    var lunchHour: Int = 12
    var lunchMinute: Int = 30
    var dinnerHour: Int = 19
    var dinnerMinute: Int = 0
}

struct FixedCommitment: Codable, Identifiable {
    var id = UUID()
    var name: String = ""
    var days: [Int] = []
    var startHour: Int = 9
    var startMinute: Int = 0
    var endHour: Int = 10
    var endMinute: Int = 0
}

enum TimeOfDayPreference: String, Codable, CaseIterable, Identifiable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case noPreference = "No Preference"
    var id: String { rawValue }
}

enum RoutineItem: String, Codable, CaseIterable, Identifiable {
    case meditation = "Meditation"
    case journaling = "Journaling"
    case coldShower = "Cold Shower"
    case reading = "Reading"
    case stretching = "Stretching"
    case prayer = "Prayer"
    case skincare = "Skincare"
    case other = "Other"
    var id: String { rawValue }
}

enum LifeArea: String, Codable, CaseIterable, Identifiable {
    case health = "Health"
    case career = "Career / Studies"
    case relationships = "Relationships"
    case creativity = "Creativity"
    case finance = "Finance"
    case spiritual = "Spiritual / Mental"
    case hobbies = "Hobbies"
    var id: String { rawValue }
}

enum AccountabilityFeel: String, Codable, CaseIterable, Identifiable {
    case loveIt = "Love it"
    case fineWithIt = "Fine with it"
    case nervousButOpen = "Nervous but open"
    case tellMeMore = "Tell me more"
    var id: String { rawValue }
}
