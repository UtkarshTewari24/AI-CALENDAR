import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            if appState.onboardingCompleted {
                MainTabView()
            } else {
                OnboardingView()
            }

            // Confetti overlay
            if appState.showConfetti {
                ConfettiView(isActive: Binding(
                    get: { appState.showConfetti },
                    set: { appState.showConfetti = $0 }
                ))
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(theme.resolvedColorScheme)
        .tint(theme.effectiveAccentColor)
        .onAppear {
            appState.checkOnboardingStatus(modelContext: modelContext)
        }
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<AxiomTask> { $0.statusRaw == "pending" }) private var pendingTasks: [AxiomTask]
    @Query private var profiles: [UserProfile]

    @State private var punishmentTask: AxiomTask?

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.activeTab) {
            Tab("Timeline", systemImage: "calendar", value: AppState.AppTab.timeline) {
                TimelineView()
            }

            Tab("Tasks", systemImage: "checkmark.circle", value: AppState.AppTab.tasks) {
                TasksView()
            }

            Tab("Progress", systemImage: "chart.bar.fill", value: AppState.AppTab.progress) {
                ProgressView()
            }

            Tab("AI", systemImage: "sparkles", value: AppState.AppTab.ai) {
                AIAssistantView()
            }

            Tab("Settings", systemImage: "gearshape", value: AppState.AppTab.settings) {
                SettingsView()
            }
        }
        .onAppear {
            checkForFailedTasks()
            monitorOverdueTasks()
        }
        .onChange(of: pendingTasks.count) { _, _ in
            monitorOverdueTasks()
        }
        .fullScreenCover(item: $punishmentTask) { task in
            PunishmentView(task: task) {
                punishmentTask = nil
            }
        }
    }

    private func checkForFailedTasks() {
        let gracePeriod = TimeInterval(UserDefaultsService.gracePeriodMinutes * 60)
        let now = Date()

        for task in pendingTasks {
            if task.isStrictMode && task.deadline.addingTimeInterval(gracePeriod) < now && !task.isPunished {
                task.status = .failed
                // Record streak failure
                if let profile = profiles.first {
                    StreakService.recordTaskFailure(profile: profile)
                }
                punishmentTask = task
                return
            }
        }
    }

    private func monitorOverdueTasks() {
        let hasOverdue = pendingTasks.contains { $0.isOverdue }
        if hasOverdue {
            theme.startPunishmentBlink()
            for task in pendingTasks where task.isOverdue {
                OverdueAlarmService.scheduleOverdueAlarms(taskId: task.id, title: task.title)
            }
        } else {
            theme.stopPunishmentBlink()
            OverdueAlarmService.cancelAllOverdueAlarms()
        }
    }
}
