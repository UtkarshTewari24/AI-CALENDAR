import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Customization") {
                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        Label("Appearance", systemImage: "paintbrush")
                    }
                }

                Section("Notifications") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                }

                Section("AI Integration") {
                    NavigationLink {
                        APIKeySettingsView()
                    } label: {
                        Label("OpenAI API Key", systemImage: "key")
                    }
                }

                Section("Account") {
                    NavigationLink {
                        AccountSettingsView()
                    } label: {
                        Label("Account & Data", systemImage: "person.circle")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
