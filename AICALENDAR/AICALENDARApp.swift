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

        // Overwrite API key on launch (requested)
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
