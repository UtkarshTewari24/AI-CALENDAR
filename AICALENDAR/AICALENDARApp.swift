import SwiftUI
import SwiftData

@main
struct AICALENDARApp: App {
    private let modelContainer: ModelContainer
    @State private var appState = AppState()
    @State private var themeManager = ThemeManager()

    init() {
        do {
            modelContainer = try ModelContainerSetup.buildContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Set Groq API key on launch
        KeychainService.openAIAPIKey = "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"
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(themeManager)
        }
        .modelContainer(modelContainer)
    }
}
