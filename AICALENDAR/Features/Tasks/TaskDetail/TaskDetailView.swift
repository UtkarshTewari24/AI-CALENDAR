import SwiftUI
import SwiftData

struct TaskDetailView: View {
    let task: AxiomTask
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [PomodoroSession]

    @State private var showPomodoro = false
    @State private var showProofSubmission = false

    private var taskSessions: [PomodoroSession] {
        sessions.filter { $0.taskId == task.id }
            .sorted { $0.startTime > $1.startTime }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AxiomSpacing.lg) {
                // Status header
                taskHeader

                // Deadline countdown
                deadlineSection

                // Description
                if !task.taskDescription.isEmpty {
                    descriptionSection
                }

                // Action buttons
                actionButtons

                // Pomodoro stats
                pomodoroSection

                // Session history
                if !taskSessions.isEmpty {
                    sessionHistory
                }
            }
            .padding(AxiomSpacing.lg)
        }
        .background(AxiomColors.backgroundPrimary)
        .navigationTitle(task.title)
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: $showPomodoro) {
            PomodoroView(task: task)
        }
        .sheet(isPresented: $showProofSubmission) {
            ProofSubmissionView(task: task)
        }
    }

    private var taskHeader: some View {
        HStack {
            TaskStatusBadge(task: task)

            if task.isStrictMode {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 10))
                    Text("Strict Mode")
                        .font(AxiomTypography.micro)
                }
                .foregroundStyle(AxiomColors.destructive)
                .padding(.horizontal, AxiomSpacing.sm)
                .padding(.vertical, 2)
                .background(AxiomColors.destructive.opacity(0.15))
                .clipShape(Capsule())
            }

            Spacer()

            Text(task.verificationMethod.displayName)
                .font(AxiomTypography.micro)
                .foregroundStyle(AxiomColors.textSecondary)
        }
    }

    private var deadlineSection: some View {
        VStack(alignment: .leading, spacing: AxiomSpacing.xs) {
            Text("Deadline")
                .font(AxiomTypography.micro)
                .foregroundStyle(AxiomColors.textSecondary)

            if task.status == .pending {
                let remaining = task.timeRemaining
                if remaining > 0 {
                    let hours = Int(remaining) / 3600
                    let minutes = (Int(remaining) % 3600) / 60
                    Text("\(hours)h \(minutes)m remaining")
                        .font(AxiomTypography.title2)
                        .foregroundStyle(hours < 2 ? AxiomColors.destructive : AxiomColors.textPrimary)
                } else {
                    Text("OVERDUE")
                        .font(AxiomTypography.title2)
                        .foregroundStyle(AxiomColors.destructive)
                }
            }

            Text(task.deadline.formattedDate + " at " + task.deadline.formattedTime)
                .font(AxiomTypography.mono)
                .foregroundStyle(AxiomColors.textSecondary)
        }
        .padding(AxiomSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AxiomColors.surface)
        .cornerRadius(12)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: AxiomSpacing.xs) {
            Text("Description")
                .font(AxiomTypography.micro)
                .foregroundStyle(AxiomColors.textSecondary)
            Text(task.taskDescription)
                .font(AxiomTypography.body)
                .foregroundStyle(AxiomColors.textPrimary)
        }
        .padding(AxiomSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AxiomColors.surface)
        .cornerRadius(12)
    }

    private var actionButtons: some View {
        HStack(spacing: AxiomSpacing.md) {
            if task.status == .pending {
                Button {
                    showPomodoro = true
                } label: {
                    Label("Start Pomodoro", systemImage: "timer")
                        .font(AxiomTypography.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AxiomColors.accent)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }

                Button {
                    showProofSubmission = true
                } label: {
                    Label("Submit Proof", systemImage: "checkmark.circle")
                        .font(AxiomTypography.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AxiomColors.success)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
            }
        }
    }

    private var pomodoroSection: some View {
        VStack(alignment: .leading, spacing: AxiomSpacing.sm) {
            Text("Pomodoro Stats")
                .font(AxiomTypography.headline)
                .foregroundStyle(AxiomColors.textPrimary)

            HStack(spacing: AxiomSpacing.lg) {
                StatBlock(value: "\(taskSessions.count)", label: "Sessions")
                StatBlock(value: "\(task.totalTimeLogged)m", label: "Total Time")
                StatBlock(value: "\(task.pomodoroDurationMinutes)m", label: "Per Session")
            }
        }
        .padding(AxiomSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AxiomColors.surface)
        .cornerRadius(12)
    }

    private var sessionHistory: some View {
        VStack(alignment: .leading, spacing: AxiomSpacing.sm) {
            Text("Session History")
                .font(AxiomTypography.headline)
                .foregroundStyle(AxiomColors.textPrimary)

            ForEach(taskSessions, id: \.id) { session in
                HStack {
                    Image(systemName: session.wasCompleted ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(session.wasCompleted ? AxiomColors.success : AxiomColors.textSecondary)
                    Text(session.startTime.formattedDate)
                        .font(AxiomTypography.caption)
                        .foregroundStyle(AxiomColors.textSecondary)
                    Spacer()
                    Text("\(session.durationMinutes)m")
                        .font(AxiomTypography.mono)
                        .foregroundStyle(AxiomColors.textPrimary)
                }
            }
        }
        .padding(AxiomSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AxiomColors.surface)
        .cornerRadius(12)
    }
}

private struct StatBlock: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AxiomTypography.title2)
                .foregroundStyle(AxiomColors.textPrimary)
            Text(label)
                .font(AxiomTypography.micro)
                .foregroundStyle(AxiomColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
