import SwiftUI
import SwiftData

@Observable
final class AppState {
    var onboardingCompleted: Bool = false
    var activeTab: AppTab = .timeline
    var showConfetti: Bool = false
    var pendingPunishmentTaskId: UUID?

    enum AppTab: Int, CaseIterable {
        case timeline = 0
        case tasks = 1
        case progress = 2
        case ai = 3
        case settings = 4

        var title: String {
            switch self {
            case .timeline: return "Timeline"
            case .tasks: return "Tasks"
            case .progress: return "Progress"
            case .ai: return "AI"
            case .settings: return "Settings"
            }
        }

        var iconName: String {
            switch self {
            case .timeline: return "calendar"
            case .tasks: return "checkmark.circle"
            case .progress: return "chart.bar.fill"
            case .ai: return "sparkles"
            case .settings: return "gearshape"
            }
        }
    }

    func checkOnboardingStatus(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = try? modelContext.fetch(descriptor).first {
            onboardingCompleted = profile.onboardingCompleted
        }
    }

    func completeOnboarding(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = try? modelContext.fetch(descriptor).first {
            profile.onboardingCompleted = true
            onboardingCompleted = true
        }
    }
}
