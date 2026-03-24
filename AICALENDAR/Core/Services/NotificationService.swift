import Foundation
import UserNotifications

enum NotificationService {

    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    static func requestTimeSensitivePermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound, .timeSensitive])
        } catch {
            return false
        }
    }

    static func scheduleEventReminder(eventId: UUID, title: String, date: Date, minutesBefore: Int = 10) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "\(title) starts in \(minutesBefore) minutes."
        content.sound = .default

        let triggerDate = date.addingTimeInterval(-Double(minutesBefore * 60))
        guard triggerDate > Date() else { return }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "event_\(eventId.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    static func scheduleTaskDeadlineWarning(taskId: UUID, title: String, deadline: Date, hoursBefore: Int = 1) {
        let content = UNMutableNotificationContent()
        content.title = "Task Deadline Approaching"
        content.body = "\(title) is due in \(hoursBefore) hour\(hoursBefore == 1 ? "" : "s"). Don't forget to submit proof."
        content.sound = .default

        let triggerDate = deadline.addingTimeInterval(-Double(hoursBefore * 3600))
        guard triggerDate > Date() else { return }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "task_deadline_\(taskId.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    static func scheduleTaskOverdueAlert(taskId: UUID, title: String, deadline: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Task Overdue"
        content.body = "⚠️ \(title) is now overdue. Accountability begins."
        content.sound = .default

        guard deadline > Date() else { return }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: deadline
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "task_overdue_\(taskId.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    static func scheduleDailyBriefing(eventCount: Int, firstEventTitle: String?, firstEventTime: String?, deliveryHour: Int = 7) {
        let content = UNMutableNotificationContent()
        content.title = "Daily Schedule"
        if let title = firstEventTitle, let time = firstEventTime {
            content.body = "You have \(eventCount) events today. First up: \(title) at \(time)."
        } else {
            content.body = "You have \(eventCount) events today."
        }
        content.sound = .default

        var components = DateComponents()
        components.hour = deliveryHour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily_briefing",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    static func schedulePomodoroBreakEnd() {
        let content = UNMutableNotificationContent()
        content.title = "Break Over"
        content.body = "Break over. Ready for your next session?"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false)

        let request = UNNotificationRequest(
            identifier: "pomodoro_break",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    static func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
