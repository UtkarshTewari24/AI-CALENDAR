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

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}
