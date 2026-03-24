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

    // Streak tracking
    var currentStreak: Int
    var longestStreak: Int
    var itemsCompletedInARow: Int
    var lastStreakDate: Date?
    var totalTasksCompleted: Int

    init(
        id: UUID = UUID(),
        appleUserId: String = "",
        displayName: String = "",
        email: String = "",
        onboardingCompleted: Bool = false,
        surveyDataJSON: String = "{}",
        createdAt: Date = Date(),
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        itemsCompletedInARow: Int = 0,
        lastStreakDate: Date? = nil,
        totalTasksCompleted: Int = 0
    ) {
        self.id = id
        self.appleUserId = appleUserId
        self.displayName = displayName
        self.email = email
        self.onboardingCompleted = onboardingCompleted
        self.surveyDataJSON = surveyDataJSON
        self.createdAt = createdAt
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.itemsCompletedInARow = itemsCompletedInARow
        self.lastStreakDate = lastStreakDate
        self.totalTasksCompleted = totalTasksCompleted
    }
}
