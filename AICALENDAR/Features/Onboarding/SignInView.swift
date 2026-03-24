import SwiftUI
import AuthenticationServices
import SwiftData

struct SignInView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var modelContext
    let onComplete: () -> Void

    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AxiomColors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: AxiomSpacing.lg) {
                Spacer()

                Text("AXIOM")
                    .font(.system(size: 48, weight: .bold, design: .default))
                    .foregroundStyle(theme.effectiveAccentColor)
                    .tracking(8)

                Text("Your day, held accountable.")
                    .font(AxiomTypography.caption)
                    .foregroundStyle(AxiomColors.textSecondary)

                Spacer()

                if let errorMessage {
                    Text(errorMessage)
                        .font(AxiomTypography.caption)
                        .foregroundStyle(AxiomColors.destructive)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AxiomSpacing.lg)
                }

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleSignInResult(result)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 52)
                .cornerRadius(12)
                .padding(.horizontal, AxiomSpacing.xl)

                Button {
                    createGuestProfile()
                    onComplete()
                } label: {
                    Text("Continue without Sign In")
                        .font(AxiomTypography.body)
                        .foregroundStyle(AxiomColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AxiomColors.surface)
                        .cornerRadius(12)
                }
                .padding(.horizontal, AxiomSpacing.xl)

                Spacer()
                    .frame(height: AxiomSpacing.xxl)

                Button("Terms of Service & Privacy Policy") {
                    // Opens in SFSafariViewController in a future iteration
                }
                .font(AxiomTypography.micro)
                .foregroundStyle(AxiomColors.textSecondary)
                .padding(.bottom, AxiomSpacing.lg)
            }
        }
    }

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Unexpected credential type."
                return
            }

            let userId = credential.user
            let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            let email = credential.email ?? ""

            // Store in Keychain
            try? KeychainService.save(key: KeychainService.appleUserIdIdentifier, value: userId)

            // Create user profile
            let profile = UserProfile(
                appleUserId: userId,
                displayName: fullName.isEmpty ? "User" : fullName,
                email: email
            )
            modelContext.insert(profile)

            onComplete()

        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                errorMessage = nil
            } else {
                errorMessage = "Sign in failed. Please try again."
            }
        }
    }

    private func createGuestProfile() {
        let profile = UserProfile(
            appleUserId: "guest-\(UUID().uuidString)",
            displayName: "User",
            email: ""
        )
        modelContext.insert(profile)
    }
}
