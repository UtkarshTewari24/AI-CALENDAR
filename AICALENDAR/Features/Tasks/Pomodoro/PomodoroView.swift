import SwiftUI
import SwiftData

struct PomodoroView: View {
    let task: AxiomTask
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: PomodoroViewModel

    init(task: AxiomTask) {
        self.task = task
        self._viewModel = State(initialValue: PomodoroViewModel(
            taskId: task.id,
            durationMinutes: task.pomodoroDurationMinutes
        ))
    }

    var body: some View {
        ZStack {
            AxiomColors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: AxiomSpacing.xxl) {
                // Task title
                Text(task.title)
                    .font(AxiomTypography.title1)
                    .foregroundStyle(AxiomColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, AxiomSpacing.xxl)

                Spacer()

                // Analog clock
                AxiomClock(
                    progress: viewModel.progress,
                    isBreak: viewModel.state == .onBreak,
                    isPaused: viewModel.state == .paused
                )
                .frame(width: 280, height: 280)
                .onTapGesture {
                    viewModel.togglePause()
                }

                // State label
                Text(viewModel.stateLabel)
                    .font(AxiomTypography.caption)
                    .foregroundStyle(AxiomColors.textSecondary)

                Spacer()

                // Bottom controls
                bottomControls
            }
            .padding(AxiomSpacing.lg)
        }
        .task {
            await viewModel.run()
        }
        .onChange(of: viewModel.sessionCompleted) { _, completed in
            if completed {
                saveSession()
                viewModel.sessionCompleted = false
            }
        }
    }

    @ViewBuilder
    private var bottomControls: some View {
        switch viewModel.state {
        case .idle:
            Button("Start") {
                viewModel.start()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AxiomColors.accent)
            .foregroundStyle(.white)
            .font(AxiomTypography.headline)
            .cornerRadius(12)

        case .running, .paused:
            EmptyView()

        case .sessionComplete:
            VStack(spacing: AxiomSpacing.md) {
                Text("Session complete!")
                    .font(AxiomTypography.title2)
                    .foregroundStyle(AxiomColors.success)

                Text("Take a 5-minute break?")
                    .font(AxiomTypography.body)
                    .foregroundStyle(AxiomColors.textSecondary)

                HStack(spacing: AxiomSpacing.md) {
                    Button("Start Break") {
                        viewModel.startBreak()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AxiomColors.success)
                    .foregroundStyle(.white)
                    .font(AxiomTypography.headline)
                    .cornerRadius(12)

                    Button("Another Session") {
                        viewModel.startNewSession()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AxiomColors.accent)
                    .foregroundStyle(.white)
                    .font(AxiomTypography.headline)
                    .cornerRadius(12)
                }
            }

        case .onBreak:
            EmptyView()

        case .breakComplete:
            Button("Start Next Session") {
                viewModel.startNewSession()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AxiomColors.accent)
            .foregroundStyle(.white)
            .font(AxiomTypography.headline)
            .cornerRadius(12)
        }

        Button("Done") {
            dismiss()
        }
        .font(AxiomTypography.caption)
        .foregroundStyle(AxiomColors.textSecondary)
        .padding(.bottom, AxiomSpacing.lg)
    }

    private func saveSession() {
        let session = PomodoroSession(
            taskId: task.id,
            startTime: viewModel.sessionStartTime ?? Date().addingTimeInterval(-Double(task.pomodoroDurationMinutes * 60)),
            durationMinutes: task.pomodoroDurationMinutes,
            wasCompleted: true
        )
        session.endTime = Date()
        modelContext.insert(session)

        task.totalTimeLogged += task.pomodoroDurationMinutes

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
