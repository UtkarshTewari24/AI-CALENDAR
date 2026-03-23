import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var description = ""
    @State private var deadline = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var verificationMethod: VerificationMethod = .photo
    @State private var whatCountsAsDone = ""
    @State private var isStrictMode = false
    @State private var pomodoroDuration = 25
    @State private var assignToTimeline = false
    @State private var workBlockStart = Date()
    @State private var workBlockEnd = Date().addingTimeInterval(3600)

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Task Title", text: $title)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    DatePicker("Deadline", selection: $deadline)
                }

                Section("Verification") {
                    Picker("Proof Type", selection: $verificationMethod) {
                        ForEach(VerificationMethod.allCases) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("What counts as done?", text: $whatCountsAsDone)
                        .textContentType(nil)
                }

                Section("Pomodoro") {
                    Stepper("Session length: \(pomodoroDuration) min", value: $pomodoroDuration, in: 5...60, step: 5)
                }

                Section("Accountability") {
                    Toggle("Strict Mode", isOn: $isStrictMode)
                    if isStrictMode {
                        Text("If you miss this task, you'll be required to make a public accountability post.")
                            .font(AxiomTypography.micro)
                            .foregroundStyle(AxiomColors.textSecondary)
                    }
                }

                Section("Timeline") {
                    Toggle("Assign work block on timeline", isOn: $assignToTimeline)
                    if assignToTimeline {
                        DatePicker("Work block start", selection: $workBlockStart)
                        DatePicker("Work block end", selection: $workBlockEnd)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveTask() {
        let task = AxiomTask(
            title: title.trimmingCharacters(in: .whitespaces),
            taskDescription: description,
            deadline: deadline,
            verificationMethod: verificationMethod,
            whatCountsAsDone: whatCountsAsDone,
            isStrictMode: isStrictMode,
            pomodoroDurationMinutes: pomodoroDuration
        )

        if assignToTimeline {
            let event = CalendarEvent(
                title: "Work on: \(task.title)",
                startDate: workBlockStart,
                endDate: workBlockEnd,
                type: .taskDeadline,
                linkedTaskId: task.id
            )
            modelContext.insert(event)
            task.linkedEventId = event.id
        }

        modelContext.insert(task)

        if UserDefaultsService.taskDeadlineAlertEnabled {
            NotificationService.scheduleTaskDeadlineWarning(
                taskId: task.id,
                title: task.title,
                deadline: task.deadline
            )
            NotificationService.scheduleTaskOverdueAlert(
                taskId: task.id,
                title: task.title,
                deadline: task.deadline
            )
        }
    }
}
