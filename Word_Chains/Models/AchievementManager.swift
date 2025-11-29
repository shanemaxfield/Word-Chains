import Foundation
import SwiftUI

enum Achievement: String, CaseIterable, Codable {
    case firstPuzzle = "first_puzzle"
    case streak3 = "streak_3"
    case streak7 = "streak_7"
    case streak30 = "streak_30"
    case perfectSolve = "perfect_solve"
    case perfect10 = "perfect_10"
    case puzzle50 = "puzzle_50"
    case puzzle100 = "puzzle_100"
    case allLengths = "all_lengths"
    case speedDemon = "speed_demon"

    var title: String {
        switch self {
        case .firstPuzzle: return "Getting Started"
        case .streak3: return "On Fire"
        case .streak7: return "Week Warrior"
        case .streak30: return "Monthly Master"
        case .perfectSolve: return "Perfectionist"
        case .perfect10: return "Expert"
        case .puzzle50: return "Dedicated"
        case .puzzle100: return "Centurion"
        case .allLengths: return "Well Rounded"
        case .speedDemon: return "Speed Demon"
        }
    }

    var description: String {
        switch self {
        case .firstPuzzle: return "Complete your first puzzle"
        case .streak3: return "Maintain a 3-day streak"
        case .streak7: return "Maintain a 7-day streak"
        case .streak30: return "Maintain a 30-day streak"
        case .perfectSolve: return "Solve a puzzle with minimum moves"
        case .perfect10: return "Solve 10 puzzles perfectly"
        case .puzzle50: return "Complete 50 puzzles"
        case .puzzle100: return "Complete 100 puzzles"
        case .allLengths: return "Solve puzzles of all lengths"
        case .speedDemon: return "Complete a puzzle in under 60 seconds"
        }
    }

    var icon: String {
        switch self {
        case .firstPuzzle: return "star.fill"
        case .streak3: return "flame.fill"
        case .streak7: return "bolt.fill"
        case .streak30: return "crown.fill"
        case .perfectSolve: return "checkmark.seal.fill"
        case .perfect10: return "rosette"
        case .puzzle50: return "medal.fill"
        case .puzzle100: return "trophy.fill"
        case .allLengths: return "square.grid.3x3.fill"
        case .speedDemon: return "hare.fill"
        }
    }

    var color: Color {
        switch self {
        case .firstPuzzle: return Color("C_WarmTeal")
        case .streak3: return .orange
        case .streak7: return .red
        case .streak30: return .purple
        case .perfectSolve: return .green
        case .perfect10: return Color("BlueGreenDeep")
        case .puzzle50: return .blue
        case .puzzle100: return .yellow
        case .allLengths: return Color("C_SoftCoral")
        case .speedDemon: return .cyan
        }
    }
}

class AchievementManager: ObservableObject {
    @Published private(set) var unlockedAchievements: Set<Achievement> = []
    @Published var newlyUnlockedAchievement: Achievement?
    @Published var showAchievementAlert: Bool = false

    private let achievementsKey = "unlocked_achievements"
    private let solvedLengthsKey = "solved_lengths"
    @Published private(set) var solvedLengths: Set<Int> = []

    init() {
        loadAchievements()
    }

    func checkAchievements(
        totalPuzzles: Int,
        perfectSolves: Int,
        currentStreak: Int,
        isPerfectSolve: Bool,
        solveTime: TimeInterval?,
        wordLength: Int
    ) {
        var newAchievements: [Achievement] = []

        // Track solved lengths
        if !solvedLengths.contains(wordLength) {
            solvedLengths.insert(wordLength)
            saveSolvedLengths()
        }

        // First puzzle
        if totalPuzzles == 1 && !unlockedAchievements.contains(.firstPuzzle) {
            newAchievements.append(.firstPuzzle)
        }

        // Streak achievements
        if currentStreak >= 3 && !unlockedAchievements.contains(.streak3) {
            newAchievements.append(.streak3)
        }
        if currentStreak >= 7 && !unlockedAchievements.contains(.streak7) {
            newAchievements.append(.streak7)
        }
        if currentStreak >= 30 && !unlockedAchievements.contains(.streak30) {
            newAchievements.append(.streak30)
        }

        // Perfect solve achievements
        if isPerfectSolve && !unlockedAchievements.contains(.perfectSolve) {
            newAchievements.append(.perfectSolve)
        }
        if perfectSolves >= 10 && !unlockedAchievements.contains(.perfect10) {
            newAchievements.append(.perfect10)
        }

        // Total puzzle achievements
        if totalPuzzles >= 50 && !unlockedAchievements.contains(.puzzle50) {
            newAchievements.append(.puzzle50)
        }
        if totalPuzzles >= 100 && !unlockedAchievements.contains(.puzzle100) {
            newAchievements.append(.puzzle100)
        }

        // All lengths achievement
        if solvedLengths.count >= 3 && !unlockedAchievements.contains(.allLengths) {
            newAchievements.append(.allLengths)
        }

        // Speed achievement
        if let time = solveTime, time < 60 && !unlockedAchievements.contains(.speedDemon) {
            newAchievements.append(.speedDemon)
        }

        // Unlock new achievements
        for achievement in newAchievements {
            unlockAchievement(achievement)
        }
    }

    private func unlockAchievement(_ achievement: Achievement) {
        guard !unlockedAchievements.contains(achievement) else { return }

        unlockedAchievements.insert(achievement)
        newlyUnlockedAchievement = achievement
        showAchievementAlert = true
        saveAchievements()

        // Generate haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func dismissAchievementAlert() {
        showAchievementAlert = false
        newlyUnlockedAchievement = nil
    }

    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode(Set<Achievement>.self, from: data) {
            unlockedAchievements = decoded
        }

        if let data = UserDefaults.standard.data(forKey: solvedLengthsKey),
           let decoded = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            solvedLengths = decoded
        }
    }

    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(unlockedAchievements) {
            UserDefaults.standard.set(encoded, forKey: achievementsKey)
        }
    }

    private func saveSolvedLengths() {
        if let encoded = try? JSONEncoder().encode(solvedLengths) {
            UserDefaults.standard.set(encoded, forKey: solvedLengthsKey)
        }
    }
}
