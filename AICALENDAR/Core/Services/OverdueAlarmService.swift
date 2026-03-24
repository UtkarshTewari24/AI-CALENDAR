import Foundation
import UserNotifications

enum OverdueAlarmService {

    /// Schedule repeating alarm-style notifications every 30 min from 5-10 PM
    static func scheduleOverdueAlarms(taskId: UUID, title: String) {
        guard UserDefaultsService.overdueAlarmEnabled else { return }

        let center = UNUserNotificationCenter.current()

        // Times: 17:00, 17:30, 18:00, ..., 21:30, 22:00
        let times: [(hour: Int, minute: Int)] = [
            (17, 0), (17, 30), (18, 0), (18, 30),
            (19, 0), (19, 30), (20, 0), (20, 30),
            (21, 0), (21, 30), (22, 0)
        ]

        for (hour, minute) in times {
            let content = UNMutableNotificationContent()
            content.title = "Overdue Task Reminder"
            content.body = "\(title) is overdue! Complete it now."
            content.sound = UNNotificationSound.defaultCritical
            content.interruptionLevel = .timeSensitive

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let identifier = "overdue_alarm_\(taskId.uuidString)_\(hour)_\(minute)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request)
        }
    }

    /// Cancel all alarms for a specific task (e.g., when completed)
    static func cancelOverdueAlarms(taskId: UUID) {
        let identifiers = [
            (17, 0), (17, 30), (18, 0), (18, 30),
            (19, 0), (19, 30), (20, 0), (20, 30),
            (21, 0), (21, 30), (22, 0)
        ].map { "overdue_alarm_\(taskId.uuidString)_\($0.0)_\($0.1)" }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Cancel all overdue alarms across all tasks
    static func cancelAllOverdueAlarms() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let overdueIds = requests
                .filter { $0.identifier.hasPrefix("overdue_alarm_") }
                .map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: overdueIds)
        }
    }
}
