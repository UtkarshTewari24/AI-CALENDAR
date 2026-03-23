import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var appleUserId: String
    var displayName: String
    var email: String
    var onboardingCompleted: Bool
    var surveyDataJSON: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        appleUserId: String = "",
        displayName: String = "",
        email: String = "",
        onboardingCompleted: Bool = false,
        surveyDataJSON: String = "{}",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.appleUserId = appleUserId
        self.displayName = displayName
        self.email = email
        self.onboardingCompleted = onboardingCompleted
        self.surveyDataJSON = surveyDataJSON
        self.createdAt = createdAt
    }
}
