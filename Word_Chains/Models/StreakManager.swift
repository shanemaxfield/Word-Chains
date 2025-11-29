import Foundation
import SwiftUI

class StreakManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var longestStreak: Int = 0
    @Published private(set) var lastCompletedDate: Date?
    @Published private(set) var totalPuzzlesCompleted: Int = 0
    @Published private(set) var perfectSolves: Int = 0 // Solved with minimum moves

    // MARK: - Private Properties
    private let calendar = Calendar.current
    private let streakKey = "user_current_streak"
    private let longestStreakKey = "user_longest_streak"
    private let lastCompletedKey = "user_last_completed_date"
    private let totalPuzzlesKey = "user_total_puzzles"
    private let perfectSolvesKey = "user_perfect_solves"

    // MARK: - Initialization
    init() {
        loadStreakData()
    }

    // MARK: - Public Methods
    func recordPuzzleCompletion(isPerfect: Bool = false) {
        let today = calendar.startOfDay(for: Date())

        // Increment total puzzles
        totalPuzzlesCompleted += 1
        if isPerfect {
            perfectSolves += 1
        }

        guard let lastDate = lastCompletedDate else {
            // First completion ever
            currentStreak = 1
            longestStreak = 1
            lastCompletedDate = today
            save()
            return
        }

        let lastDateStart = calendar.startOfDay(for: lastDate)
        let daysSinceLastCompletion = calendar.dateComponents([.day], from: lastDateStart, to: today).day ?? 0

        if daysSinceLastCompletion == 0 {
            // Already completed today - no streak change, but count puzzle
            save()
            return
        } else if daysSinceLastCompletion == 1 {
            // Consecutive day - increment streak
            currentStreak += 1
            longestStreak = max(currentStreak, longestStreak)
        } else {
            // Streak broken - reset to 1
            currentStreak = 1
        }

        lastCompletedDate = today
        save()
    }

    func isStreakAtRisk() -> Bool {
        guard let lastDate = lastCompletedDate else { return false }
        let today = calendar.startOfDay(for: Date())
        let lastDateStart = calendar.startOfDay(for: lastDate)
        let daysSince = calendar.dateComponents([.day], from: lastDateStart, to: today).day ?? 0
        return daysSince >= 1 && currentStreak > 0
    }

    func hasCompletedToday() -> Bool {
        guard let lastDate = lastCompletedDate else { return false }
        return calendar.isDateInToday(lastDate)
    }

    func getStreakEmoji() -> String {
        switch currentStreak {
        case 0...2: return "🔥"
        case 3...6: return "🔥🔥"
        case 7...13: return "🔥🔥🔥"
        case 14...29: return "🔥🔥🔥🔥"
        default: return "🔥🔥🔥🔥🔥"
        }
    }

    func getStreakMessage() -> String {
        if currentStreak == 0 {
            return "Start your streak today!"
        } else if currentStreak == 1 {
            return "Keep it going tomorrow!"
        } else if currentStreak < 7 {
            return "You're on a roll!"
        } else if currentStreak < 30 {
            return "Amazing streak!"
        } else {
            return "Legendary streak!"
        }
    }

    // MARK: - Private Methods
    private func loadStreakData() {
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
        longestStreak = UserDefaults.standard.integer(forKey: longestStreakKey)
        totalPuzzlesCompleted = UserDefaults.standard.integer(forKey: totalPuzzlesKey)
        perfectSolves = UserDefaults.standard.integer(forKey: perfectSolvesKey)

        if let timestamp = UserDefaults.standard.object(forKey: lastCompletedKey) as? Double {
            lastCompletedDate = Date(timeIntervalSince1970: timestamp)
        }

        // Check if streak should be broken
        checkStreakStatus()
    }

    private func checkStreakStatus() {
        guard let lastDate = lastCompletedDate else { return }
        let today = calendar.startOfDay(for: Date())
        let lastDateStart = calendar.startOfDay(for: lastDate)
        let daysSince = calendar.dateComponents([.day], from: lastDateStart, to: today).day ?? 0

        // If more than 1 day has passed, break the streak
        if daysSince > 1 && currentStreak > 0 {
            currentStreak = 0
            save()
        }
    }

    private func save() {
        UserDefaults.standard.set(currentStreak, forKey: streakKey)
        UserDefaults.standard.set(longestStreak, forKey: longestStreakKey)
        UserDefaults.standard.set(totalPuzzlesCompleted, forKey: totalPuzzlesKey)
        UserDefaults.standard.set(perfectSolves, forKey: perfectSolvesKey)

        if let date = lastCompletedDate {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: lastCompletedKey)
        }
    }

    // MARK: - Debug Methods
    func resetStreak() {
        currentStreak = 0
        longestStreak = 0
        lastCompletedDate = nil
        totalPuzzlesCompleted = 0
        perfectSolves = 0
        save()
    }
}
