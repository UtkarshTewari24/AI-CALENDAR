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
        .tint(theme.accentColor)
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

            Tab("AI", systemImage: "sparkles", value: AppState.AppTab.ai) {
                AIAssistantView()
            }

            Tab("Settings", systemImage: "gearshape", value: AppState.AppTab.settings) {
                SettingsView()
            }
        }
        .onAppear {
            checkForFailedTasks()
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
                punishmentTask = task
                return
            }
        }
    }
}
