import SwiftUI
import SwiftData

@Observable
final class OnboardingCoordinator {
    enum Step: Int, CaseIterable {
        case signIn
        case survey
        case generating
        case preview
    }

    var currentStep: Step = .signIn
    var surveyResponse = SurveyResponse()
    var generatedEvents: [CalendarEvent] = []
    var generationError: String?
    var regenerationCount: Int = 0
    var isGenerating: Bool = false

    let maxRegenerations = 3

    var canRegenerate: Bool {
        regenerationCount < maxRegenerations
    }

    func advanceToSurvey() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            currentStep = .survey
        }
    }

    func advanceToGeneration() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            currentStep = .generating
        }
    }

    func advanceToPreview() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            currentStep = .preview
        }
    }

    func generateSchedule() async {
        isGenerating = true
        generationError = nil

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let surveyData = try encoder.encode(surveyResponse)
            let surveyJSON = String(data: surveyData, encoding: .utf8) ?? "{}"

            let events = try await ScheduleGenerationService.generateSchedule(surveyJSON: surveyJSON)
            generatedEvents = events
            regenerationCount += 1
            advanceToPreview()
        } catch {
            generationError = error.localizedDescription
        }

        isGenerating = false
    }

    func regenerateSchedule() async {
        guard canRegenerate else { return }
        isGenerating = true
        generationError = nil

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            currentStep = .generating
        }

        await generateSchedule()
    }

    func confirmSchedule(modelContext: ModelContext, appState: AppState) {
        for event in generatedEvents {
            modelContext.insert(event)
        }

        // Save survey data to user profile
        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = try? modelContext.fetch(descriptor).first {
            if let data = try? JSONEncoder().encode(surveyResponse) {
                profile.surveyDataJSON = String(data: data, encoding: .utf8) ?? "{}"
            }
            profile.onboardingCompleted = true
        }

        appState.onboardingCompleted = true
    }
}
