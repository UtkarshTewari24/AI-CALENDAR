import SwiftUI
import SwiftData

struct AccountSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var profiles: [UserProfile]

    @State private var displayName: String = ""
    @State private var showResetConfirmation = false
    @State private var showDeleteConfirmation = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        Form {
            Section("Profile") {
                if let profile {
                    TextField("Display Name", text: $displayName)
                        .onAppear { displayName = profile.displayName }
                        .onSubmit {
                            profile.displayName = displayName
                        }

                    LabeledContent("Email", value: profile.email.isEmpty ? "Not provided" : profile.email)
                }
            }

            Section("Data") {
                Button("Export All Data") {
                    exportData()
                }

                Button("Reset Schedule") {
                    showResetConfirmation = true
                }
                .foregroundStyle(AxiomColors.destructive)
            }

            Section {
                Button("Delete Account & All Data", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }

            Section {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Build", value: "1")
            }
        }
        .navigationTitle("Account")
        .confirmationDialog("Reset Schedule", isPresented: $showResetConfirmation) {
            Button("Reset All Events", role: .destructive) {
                resetSchedule()
            }
        } message: {
            Text("This will delete all calendar events and tasks. This cannot be undone.")
        }
        .confirmationDialog("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Delete Everything", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This cannot be undone.")
        }
    }

    private func exportData() {
        // Build JSON export of all data
        let descriptor = FetchDescriptor<CalendarEvent>()
        let events = (try? modelContext.fetch(descriptor)) ?? []

        let taskDescriptor = FetchDescriptor<AxiomTask>()
        let tasks = (try? modelContext.fetch(taskDescriptor)) ?? []

        let exportDict: [String: Any] = [
            "exportDate": Date().formatted(),
            "eventCount": events.count,
            "taskCount": tasks.count,
            "events": events.map { [
                "title": $0.title,
                "startDate": $0.startDate.formatted(),
                "endDate": $0.endDate.formatted(),
                "type": $0.typeRaw
            ]},
            "tasks": tasks.map { [
                "title": $0.title,
                "deadline": $0.deadline.formatted(),
                "status": $0.statusRaw
            ]}
        ]

        if let data = try? JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("axiom_export.json")
            try? data.write(to: url)

            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }

    private func resetSchedule() {
        let eventDescriptor = FetchDescriptor<CalendarEvent>()
        if let events = try? modelContext.fetch(eventDescriptor) {
            for event in events { modelContext.delete(event) }
        }

        let taskDescriptor = FetchDescriptor<AxiomTask>()
        if let tasks = try? modelContext.fetch(taskDescriptor) {
            for task in tasks { modelContext.delete(task) }
        }

        let sessionDescriptor = FetchDescriptor<PomodoroSession>()
        if let sessions = try? modelContext.fetch(sessionDescriptor) {
            for session in sessions { modelContext.delete(session) }
        }
    }

    private func deleteAccount() {
        resetSchedule()

        let profileDescriptor = FetchDescriptor<UserProfile>()
        if let profiles = try? modelContext.fetch(profileDescriptor) {
            for profile in profiles { modelContext.delete(profile) }
        }

        let socialDescriptor = FetchDescriptor<SocialConnection>()
        if let connections = try? modelContext.fetch(socialDescriptor) {
            for connection in connections { modelContext.delete(connection) }
        }

        KeychainService.delete(key: KeychainService.openAIAPIKeyIdentifier)
        KeychainService.delete(key: KeychainService.appleUserIdIdentifier)
        NotificationService.cancelAll()

        appState.onboardingCompleted = false
    }
}
