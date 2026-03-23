import SwiftUI
import SwiftData

struct OnboardingView: View {
    @State private var coordinator = OnboardingCoordinator()
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            AxiomColors.backgroundPrimary.ignoresSafeArea()

            switch coordinator.currentStep {
            case .signIn:
                SignInView {
                    coordinator.advanceToSurvey()
                }
                .transition(.move(edge: .trailing))

            case .survey:
                SurveyView(coordinator: coordinator)
                    .transition(.move(edge: .trailing))

            case .generating:
                ScheduleGenerationView(coordinator: coordinator)
                    .transition(.opacity)

            case .preview:
                SchedulePreviewView(coordinator: coordinator)
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: coordinator.currentStep)
        .overlay(alignment: .topTrailing) {
            Button {
                skipOnboarding()
            } label: {
                Text("Skip AI Setup")
                    .font(AxiomTypography.micro)
                    .foregroundStyle(AxiomColors.textSecondary)
                    .padding(.horizontal, AxiomSpacing.md)
                    .padding(.vertical, AxiomSpacing.sm)
                    .background(AxiomColors.surface.opacity(0.9))
                    .cornerRadius(10)
            }
            .padding(.top, AxiomSpacing.lg)
            .padding(.trailing, AxiomSpacing.lg)
        }
    }

    private func skipOnboarding() {
        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = try? modelContext.fetch(descriptor).first {
            profile.onboardingCompleted = true
        } else {
            let profile = UserProfile(
                appleUserId: "guest-\(UUID().uuidString)",
                displayName: "User",
                email: "",
                onboardingCompleted: true
            )
            modelContext.insert(profile)
        }
        appState.onboardingCompleted = true
    }
}
