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
        // Get your actual Groq API key from: https://console.groq.com/keys
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
