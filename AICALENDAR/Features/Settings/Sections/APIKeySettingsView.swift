import SwiftUI

struct APIKeySettingsView: View {
    @State private var apiKey = ""
    @State private var isTesting = false
    @State private var testResult: Bool?
    @State private var hasExistingKey = KeychainService.openAIAPIKey != nil

    var body: some View {
        Form {
            Section("OpenAI API Key") {
                if hasExistingKey && apiKey.isEmpty {
                    HStack {
                        Text("sk-...••••••••")
                            .font(AxiomTypography.mono)
                            .foregroundStyle(AxiomColors.textSecondary)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AxiomColors.success)
                    }
                }

                SecureField("Enter API Key", text: $apiKey)
                    .font(AxiomTypography.mono)

                if !apiKey.isEmpty {
                    Button("Save Key") {
                        KeychainService.openAIAPIKey = apiKey
                        hasExistingKey = true
                        apiKey = ""
                    }
                }
            }

            Section("Test Connection") {
                Button {
                    testConnection()
                } label: {
                    HStack {
                        Text("Test Connection")
                        Spacer()
                        if isTesting {
                            ProgressView()
                        } else if let result = testResult {
                            Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result ? AxiomColors.success : AxiomColors.destructive)
                        }
                    }
                }
                .disabled(isTesting || !hasExistingKey)
            }

            if hasExistingKey {
                Section {
                    Button("Remove API Key", role: .destructive) {
                        KeychainService.openAIAPIKey = nil
                        hasExistingKey = false
                        testResult = nil
                    }
                }
            }

            Section {
                Text("Your API key is stored securely in the iOS Keychain. It is never sent anywhere except to OpenAI's servers.")
                    .font(AxiomTypography.micro)
                    .foregroundStyle(AxiomColors.textSecondary)
            }
        }
        .navigationTitle("AI Integration")
    }

    private func testConnection() {
        isTesting = true
        testResult = nil
        Task {
            let result = await OpenAIService.testConnection()
            testResult = result
            isTesting = false
        }
    }
}
