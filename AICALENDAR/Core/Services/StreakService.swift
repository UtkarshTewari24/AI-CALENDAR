import Foundation
import SwiftData

enum StreakService {

    /// Call when a task is completed to update streak counters
    static func recordTaskCompletion(profile: UserProfile, modelContext: ModelContext) {
        profile.itemsCompletedInARow += 1
        profile.totalTasksCompleted += 1

        // Check if all of today's tasks are completed
        let todayStart = Date().startOfDay
        let todayEnd = Date().endOfDay
        let descriptor = FetchDescriptor<AxiomTask>(
            predicate: #Predicate {
                $0.deadline >= todayStart && $0.deadline <= todayEnd
            }
        )

        guard let todayTasks = try? modelContext.fetch(descriptor) else { return }
        let allCompleted = todayTasks.allSatisfy { $0.statusRaw == "completed" }

        if allCompleted && !todayTasks.isEmpty {
            updateDayStreak(profile: profile)
        }
    }

    /// Call when a task fails or misses its deadline
    static func recordTaskFailure(profile: UserProfile) {
        profile.itemsCompletedInARow = 0
    }

    private static func updateDayStreak(profile: UserProfile) {
        let today = Date().startOfDay
        if let lastDate = profile.lastStreakDate {
            let daysDiff = Calendar.current.dateComponents([.day], from: lastDate.startOfDay, to: today).day ?? 0
            if daysDiff == 1 {
                profile.currentStreak += 1
            } else if daysDiff > 1 {
                profile.currentStreak = 1
            }
            // daysDiff == 0 means already counted today, no change
        } else {
            profile.currentStreak = 1
        }
        profile.lastStreakDate = today
        profile.longestStreak = max(profile.longestStreak, profile.currentStreak)
    }
}
