import Foundation

enum UserDefaultsService {

    private static let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Keys {
        static let colorScheme = "axiom_color_scheme"
        static let accentColorHex = "axiom_accent_color"
        static let timelineDensity = "axiom_timeline_density"
        static let fontSize = "axiom_font_size"
        static let showNowLine = "axiom_show_now_line"
        static let animateNowLine = "axiom_animate_now_line"
        static let timelineDisplayMode = "axiom_timeline_display_mode"
        static let eventReminderEnabled = "axiom_event_reminder_enabled"
        static let eventReminderMinutes = "axiom_event_reminder_minutes"
        static let taskDeadlineAlertEnabled = "axiom_task_deadline_alert_enabled"
        static let dailyBriefingEnabled = "axiom_daily_briefing_enabled"
        static let dailyBriefingHour = "axiom_daily_briefing_hour"
        static let pomodoroBreakReminder = "axiom_pomodoro_break_reminder"
        static let gracePeriodMinutes = "axiom_grace_period_minutes"
    }

    // MARK: - Appearance

    static var colorScheme: AppColorSchemePreference {
        get {
            guard let raw = defaults.string(forKey: Keys.colorScheme) else { return .system }
            return AppColorSchemePreference(rawValue: raw) ?? .system
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.colorScheme) }
    }

    static var accentColorHex: String {
        get { defaults.string(forKey: Keys.accentColorHex) ?? "#6C63FF" }
        set { defaults.set(newValue, forKey: Keys.accentColorHex) }
    }

    static var timelineDensity: TimelineDensity {
        get {
            guard let raw = defaults.string(forKey: Keys.timelineDensity) else { return .comfortable }
            return TimelineDensity(rawValue: raw) ?? .comfortable
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.timelineDensity) }
    }

    static var fontSize: FontSizePreference {
        get {
            guard let raw = defaults.string(forKey: Keys.fontSize) else { return .medium }
            return FontSizePreference(rawValue: raw) ?? .medium
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.fontSize) }
    }

    static var showNowLine: Bool {
        get { defaults.object(forKey: Keys.showNowLine) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.showNowLine) }
    }

    static var animateNowLine: Bool {
        get { defaults.object(forKey: Keys.animateNowLine) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.animateNowLine) }
    }

    static var timelineDisplayMode: TimelineDisplayMode {
        get {
            guard let raw = defaults.string(forKey: Keys.timelineDisplayMode) else { return .day }
            return TimelineDisplayMode(rawValue: raw) ?? .day
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.timelineDisplayMode) }
    }

    // MARK: - Notifications

    static var eventReminderEnabled: Bool {
        get { defaults.object(forKey: Keys.eventReminderEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.eventReminderEnabled) }
    }

    static var eventReminderMinutes: Int {
        get { defaults.object(forKey: Keys.eventReminderMinutes) as? Int ?? 10 }
        set { defaults.set(newValue, forKey: Keys.eventReminderMinutes) }
    }

    static var taskDeadlineAlertEnabled: Bool {
        get { defaults.object(forKey: Keys.taskDeadlineAlertEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.taskDeadlineAlertEnabled) }
    }

    static var dailyBriefingEnabled: Bool {
        get { defaults.object(forKey: Keys.dailyBriefingEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.dailyBriefingEnabled) }
    }

    static var dailyBriefingHour: Int {
        get { defaults.object(forKey: Keys.dailyBriefingHour) as? Int ?? 7 }
        set { defaults.set(newValue, forKey: Keys.dailyBriefingHour) }
    }

    static var pomodoroBreakReminder: Bool {
        get { defaults.object(forKey: Keys.pomodoroBreakReminder) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.pomodoroBreakReminder) }
    }

    // MARK: - Punishment

    static var gracePeriodMinutes: Int {
        get { defaults.object(forKey: Keys.gracePeriodMinutes) as? Int ?? 0 }
        set { defaults.set(newValue, forKey: Keys.gracePeriodMinutes) }
    }
}
