import SwiftUI

struct NotificationSettingsView: View {
    @State private var eventReminder = UserDefaultsService.eventReminderEnabled
    @State private var eventReminderMinutes = UserDefaultsService.eventReminderMinutes
    @State private var taskDeadlineAlert = UserDefaultsService.taskDeadlineAlertEnabled
    @State private var dailyBriefing = UserDefaultsService.dailyBriefingEnabled
    @State private var dailyBriefingHour = UserDefaultsService.dailyBriefingHour
    @State private var pomodoroBreak = UserDefaultsService.pomodoroBreakReminder
    @State private var gracePeriod = UserDefaultsService.gracePeriodMinutes

    private let gracePeriodOptions = [0, 5, 10, 15, 20, 30]

    var body: some View {
        Form {
            Section("Event Reminders") {
                Toggle("Event Reminders", isOn: $eventReminder)
                    .onChange(of: eventReminder) { _, val in
                        UserDefaultsService.eventReminderEnabled = val
                    }

                if eventReminder {
                    Picker("Remind Before", selection: $eventReminderMinutes) {
                        Text("5 min").tag(5)
                        Text("10 min").tag(10)
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                    }
                    .onChange(of: eventReminderMinutes) { _, val in
                        UserDefaultsService.eventReminderMinutes = val
                    }
                }
            }

            Section("Task Alerts") {
                Toggle("Deadline Alerts", isOn: $taskDeadlineAlert)
                    .onChange(of: taskDeadlineAlert) { _, val in
                        UserDefaultsService.taskDeadlineAlertEnabled = val
                    }
            }

            Section("Daily Briefing") {
                Toggle("Daily Schedule Briefing", isOn: $dailyBriefing)
                    .onChange(of: dailyBriefing) { _, val in
                        UserDefaultsService.dailyBriefingEnabled = val
                    }

                if dailyBriefing {
                    Picker("Delivery Time", selection: $dailyBriefingHour) {
                        ForEach(5...11, id: \.self) { hour in
                            Text("\(hour):00 AM").tag(hour)
                        }
                    }
                    .onChange(of: dailyBriefingHour) { _, val in
                        UserDefaultsService.dailyBriefingHour = val
                    }
                }
            }

            Section("Pomodoro") {
                Toggle("Break Reminders", isOn: $pomodoroBreak)
                    .onChange(of: pomodoroBreak) { _, val in
                        UserDefaultsService.pomodoroBreakReminder = val
                    }
            }

            Section("Accountability") {
                Picker("Grace Period After Deadline", selection: $gracePeriod) {
                    Text("None").tag(0)
                    ForEach(gracePeriodOptions.dropFirst(), id: \.self) { minutes in
                        Text("\(minutes) minutes").tag(minutes)
                    }
                }
                .onChange(of: gracePeriod) { _, val in
                    UserDefaultsService.gracePeriodMinutes = val
                }

                Text("Grace period delays the punishment flow after a task deadline passes.")
                    .font(AxiomTypography.micro)
                    .foregroundStyle(AxiomColors.textSecondary)
            }
        }
        .navigationTitle("Notifications")
    }
}
