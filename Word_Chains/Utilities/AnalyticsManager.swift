import Foundation

enum AnalyticsEvent {
    case appLaunched
    case tutorialStarted
    case tutorialCompleted
    case tutorialSkipped(step: Int)
    case puzzleStarted(wordLength: Int, mode: String)
    case puzzleCompleted(wordLength: Int, moves: Int, minimumMoves: Int, timeSeconds: Double)
    case puzzleFailed(wordLength: Int, mode: String)
    case hintUsed(wordLength: Int)
    case undoUsed(wordLength: Int)
    case shareAttempted
    case achievementUnlocked(achievement: String)
    case streakMilestone(days: Int)
    case settingsChanged(setting: String, value: String)

    var name: String {
        switch self {
        case .appLaunched: return "app_launched"
        case .tutorialStarted: return "tutorial_started"
        case .tutorialCompleted: return "tutorial_completed"
        case .tutorialSkipped: return "tutorial_skipped"
        case .puzzleStarted: return "puzzle_started"
        case .puzzleCompleted: return "puzzle_completed"
        case .puzzleFailed: return "puzzle_failed"
        case .hintUsed: return "hint_used"
        case .undoUsed: return "undo_used"
        case .shareAttempted: return "share_attempted"
        case .achievementUnlocked: return "achievement_unlocked"
        case .streakMilestone: return "streak_milestone"
        case .settingsChanged: return "settings_changed"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case .tutorialSkipped(let step):
            return ["step": step]
        case .puzzleStarted(let wordLength, let mode):
            return ["word_length": wordLength, "mode": mode]
        case .puzzleCompleted(let wordLength, let moves, let minimumMoves, let timeSeconds):
            let efficiency = minimumMoves > 0 ? Double(minimumMoves) / Double(moves) * 100 : 100
            return [
                "word_length": wordLength,
                "moves": moves,
                "minimum_moves": minimumMoves,
                "efficiency": efficiency,
                "time_seconds": timeSeconds
            ]
        case .puzzleFailed(let wordLength, let mode):
            return ["word_length": wordLength, "mode": mode]
        case .hintUsed(let wordLength):
            return ["word_length": wordLength]
        case .undoUsed(let wordLength):
            return ["word_length": wordLength]
        case .achievementUnlocked(let achievement):
            return ["achievement": achievement]
        case .streakMilestone(let days):
            return ["days": days]
        case .settingsChanged(let setting, let value):
            return ["setting": setting, "value": value]
        default:
            return [:]
        }
    }
}

class AnalyticsManager {
    static let shared = AnalyticsManager()

    private var sessionStartTime: Date?
    private var puzzleStartTimes: [String: Date] = [:] // Track puzzle start times

    private init() {}

    func track(_ event: AnalyticsEvent) {
        // In a production app, you would send this to Firebase, Mixpanel, etc.
        // For now, we'll just log it for debugging
        #if DEBUG
        print("📊 Analytics: \(event.name) - \(event.parameters)")
        #endif

        // Store critical events locally for future analytics integration
        storeEvent(event)
    }

    func startSession() {
        sessionStartTime = Date()
        track(.appLaunched)
    }

    func startPuzzleTimer(for key: String) {
        puzzleStartTimes[key] = Date()
    }

    func getPuzzleDuration(for key: String) -> TimeInterval? {
        guard let startTime = puzzleStartTimes[key] else { return nil }
        return Date().timeIntervalSince(startTime)
    }

    func endPuzzleTimer(for key: String) -> TimeInterval? {
        guard let startTime = puzzleStartTimes[key] else { return nil }
        let duration = Date().timeIntervalSince(startTime)
        puzzleStartTimes.removeValue(forKey: key)
        return duration
    }

    private func storeEvent(_ event: AnalyticsEvent) {
        // Store events locally for batch uploading later
        var events = loadStoredEvents()
        events.append([
            "name": event.name,
            "parameters": event.parameters,
            "timestamp": Date().timeIntervalSince1970
        ])

        // Keep only last 1000 events to avoid unlimited growth
        if events.count > 1000 {
            events = Array(events.suffix(1000))
        }

        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: "analytics_events")
        }
    }

    private func loadStoredEvents() -> [[String: Any]] {
        guard let data = UserDefaults.standard.data(forKey: "analytics_events"),
              let decoded = try? JSONDecoder().decode([[String: AnyCodable]].self, from: data) else {
            return []
        }

        return decoded.map { dict in
            dict.mapValues { $0.value }
        }
    }

    func clearStoredEvents() {
        UserDefaults.standard.removeObject(forKey: "analytics_events")
    }
}

// Helper for encoding Any types
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            value = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        }
    }
}
