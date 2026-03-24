import Foundation
import SwiftData

enum ModelContainerSetup {
    static func buildContainer() throws -> ModelContainer {
        let schema = Schema([
            CalendarEvent.self,
            AxiomTask.self,
            PomodoroSession.self,
            UserProfile.self,
            SocialConnection.self
        ])

        let configuration = ModelConfiguration(
            "Axiom",
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            // Migration failed — delete the old store and retry
            // This handles schema changes that can't be auto-migrated
            let storeURL = configuration.url
            let fileManager = FileManager.default
            let storePath = storeURL.path()

            // Remove all SQLite-related files
            for suffix in ["", "-shm", "-wal"] {
                let filePath = storePath + suffix
                if fileManager.fileExists(atPath: filePath) {
                    try? fileManager.removeItem(atPath: filePath)
                }
            }

            // Retry with a fresh store
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        }
    }
}
