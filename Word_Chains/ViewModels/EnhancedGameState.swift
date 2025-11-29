import SwiftUI

// MARK: - Game State Models
struct WordChainState: Equatable {
    var chain: [String]
    var userWord: String
    var isCompleted: Bool
    var gameLogic: WordChainGameLogic
    var changesMade: Int
    var undoStack: [String] = [] // Track undo history

    static func == (lhs: WordChainState, rhs: WordChainState) -> Bool {
        lhs.chain == rhs.chain &&
        lhs.userWord == rhs.userWord &&
        lhs.isCompleted == rhs.isCompleted &&
        lhs.changesMade == rhs.changesMade
        // Note: gameLogic and undoStack are not compared for equality
    }
}

// MARK: - Persisted State for Free Roam
struct PersistedWordChainState: Codable {
    var chain: [String]
    var userWord: String
    var isCompleted: Bool
    var changesMade: Int
}

// MARK: - Enhanced Game State Manager
class EnhancedGameState: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var currentWordLength: Int = 4
    @Published private(set) var statesByLength: [Int: WordChainState] = [:]
    @Published private(set) var gridResetTrigger: Bool = false
    @Published private(set) var currentDistanceToTargetByLength: [Int: Int?] = [:]
    @Published private(set) var isHintActiveByLength: [Int: Bool] = [:]
    @Published private(set) var isSearchingForChain: [Int: Bool] = [:]

    // MARK: - Managers
    @Published var streakManager = StreakManager()
    @Published var achievementManager = AchievementManager()
    private let soundManager = SoundManager.shared
    private let analyticsManager = AnalyticsManager.shared

    // MARK: - Puzzle Start Times (for analytics)
    private var puzzleStartTimes: [Int: Date] = [:]

    // MARK: - Constants
    let availableLengths = [3, 4, 5]
    let lengthLabels = [3: "3-Letter", 4: "4-Letter", 5: "5-Letter"]
    let maxUndoSteps = 10

    // MARK: - Private Properties
    private var puzzleGenerationTasks: [Int: Task<Void, Never>] = [:]
    private var persistenceWorkItem: DispatchWorkItem?

    // MARK: - Initialization
    init() {
        analyticsManager.startSession()
        // Initialize puzzle cache in background
        DispatchQueue.global(qos: .utility).async {
            _ = PuzzleCache.shared
        }
    }

    // MARK: - Public Methods
    func setWordLength(_ length: Int) {
        guard availableLengths.contains(length) else { return }
        currentWordLength = length

        if statesByLength[length] == nil {
            setupGameLogic(for: length)
        }

        // If we're showing loading state and there's no ongoing task, start a new search
        if isSearchingForChain[length] == true && puzzleGenerationTasks[length] == nil {
            generateNewPuzzle()
        }

        gridResetTrigger.toggle()
        clearHintSteps(for: length)
        debouncedPersist()
    }

    func resetCurrentPuzzle() {
        soundManager.playHaptic(.medium)

        // If there's no chain or it's empty, generate a new puzzle
        if statesByLength[currentWordLength]?.chain.isEmpty ?? true {
            generateNewPuzzle()
            return
        }

        guard let start = statesByLength[currentWordLength]?.chain.first else { return }
        if var state = statesByLength[currentWordLength] {
            state.userWord = start
            state.isCompleted = false
            state.changesMade = 0
            state.undoStack = []
            statesByLength[currentWordLength] = state
        }
        gridResetTrigger.toggle()
        clearHintSteps(for: currentWordLength)
        debouncedPersist()
    }

    func generateNewPuzzle() {
        let wordLength = currentWordLength
        guard let logic = statesByLength[wordLength]?.gameLogic else { return }
        isSearchingForChain[wordLength] = true

        analyticsManager.track(.puzzleStarted(wordLength: wordLength, mode: "free_roam"))
        puzzleStartTimes[wordLength] = Date()

        puzzleGenerationTasks[wordLength] = Task {
            let minLength = 5
            let result = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let chainResult = logic.generateRandomShortestChain(minLength: minLength)
                    // Verify that all words in the chain match the current word length
                    let validChain = chainResult.chain.allSatisfy { $0.count == wordLength }
                    if validChain {
                        continuation.resume(returning: chainResult)
                    } else {
                        continuation.resume(returning: ([], "", ""))
                    }
                }
            }

            // If cancelled, do not update state
            if Task.isCancelled {
                await MainActor.run { self.isSearchingForChain[wordLength] = false }
                return
            }

            // If no chain found, retry automatically
            if result.chain.isEmpty {
                await MainActor.run { self.isSearchingForChain[wordLength] = false }
                // Small delay before retrying
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                if !Task.isCancelled {
                    generateNewPuzzle()
                }
                return
            }

            await MainActor.run {
                setCurrentChain(result.chain, start: result.start, end: result.end, gameLogic: logic, for: wordLength)
                self.isSearchingForChain[wordLength] = false
                self.puzzleGenerationTasks[wordLength] = nil
            }
        }
    }

    func updateUserWord(_ word: String) {
        guard var state = statesByLength[currentWordLength] else { return }

        // Track undo history
        if state.userWord != word {
            state.undoStack.append(state.userWord)
            if state.undoStack.count > maxUndoSteps {
                state.undoStack.removeFirst()
            }
            state.changesMade += 1

            // Play sound for valid word change
            soundManager.playSound(.validWord)
            soundManager.playHaptic(.light)
        }

        state.userWord = word
        validateWord(&state)
        statesByLength[currentWordLength] = state

        // Update distance if hint is active
        if isHintActive {
            let distance = state.gameLogic.getDistanceToTarget(from: word)
            setHintState(distance: distance, active: true, for: currentWordLength)
        }

        debouncedPersist()
    }

    func undoLastMove() {
        guard var state = statesByLength[currentWordLength] else { return }
        guard let previousWord = state.undoStack.popLast() else { return }

        state.userWord = previousWord
        state.changesMade = max(0, state.changesMade - 1)
        statesByLength[currentWordLength] = state

        soundManager.playHaptic(.medium)
        analyticsManager.track(.undoUsed(wordLength: currentWordLength))

        debouncedPersist()
    }

    var canUndo: Bool {
        guard let state = statesByLength[currentWordLength] else { return false }
        return !state.undoStack.isEmpty
    }

    func calculateHintSteps() {
        guard let state = statesByLength[currentWordLength] else { return }

        // Precompute distances to target if not already done
        if let target = state.chain.last {
            state.gameLogic.precomputeDistancesToTarget(target)
            let distance = state.gameLogic.getDistanceToTarget(from: state.userWord)
            setHintState(distance: distance, active: true, for: currentWordLength)

            analyticsManager.track(.hintUsed(wordLength: currentWordLength))
            soundManager.playHaptic(.medium)
        }
    }

    func clearHintSteps(for length: Int) {
        currentDistanceToTargetByLength[length] = nil
        isHintActiveByLength[length] = false
    }

    func setHintState(distance: Int?, active: Bool, for length: Int) {
        currentDistanceToTargetByLength[length] = distance
        isHintActiveByLength[length] = active
    }

    func setCurrentChain(_ chain: [String], start: String, end: String, gameLogic: WordChainGameLogic, for length: Int? = nil) {
        let wordLength = length ?? currentWordLength
        guard var state = statesByLength[wordLength] else { return }

        state.chain = chain
        state.userWord = start
        state.isCompleted = false
        state.changesMade = 0
        state.gameLogic = gameLogic
        state.undoStack = []
        statesByLength[wordLength] = state

        debouncedPersist()
    }

    // MARK: - Private Methods
    private func setupGameLogic(for length: Int) {
        let logic = WordChainGameLogic(wordLength: length)
        if statesByLength[length] == nil {
            let result = logic.generateRandomShortestChain(minLength: 5)
            statesByLength[length] = WordChainState(
                chain: result.chain,
                userWord: result.start,
                isCompleted: false,
                gameLogic: logic,
                changesMade: 0,
                undoStack: []
            )
        }
    }

    private func validateWord(_ state: inout WordChainState) {
        let guess = state.userWord.uppercased()
        let target = state.chain.last ?? ""

        if state.gameLogic.isValidWord(guess) && guess == target {
            state.isCompleted = true
            handlePuzzleCompletion()
        }
    }

    private func handlePuzzleCompletion() {
        // Calculate solve time
        var solveTime: TimeInterval? = nil
        if let startTime = puzzleStartTimes[currentWordLength] {
            solveTime = Date().timeIntervalSince(startTime)
            puzzleStartTimes.removeValue(forKey: currentWordLength)
        }

        let isPerfect = currentChangesMade == minimumChangesNeeded

        // Track analytics
        analyticsManager.track(.puzzleCompleted(
            wordLength: currentWordLength,
            moves: currentChangesMade,
            minimumMoves: minimumChangesNeeded,
            timeSeconds: solveTime ?? 0
        ))

        // Record streak
        streakManager.recordPuzzleCompletion(isPerfect: isPerfect)

        // Check achievements
        achievementManager.checkAchievements(
            totalPuzzles: streakManager.totalPuzzlesCompleted,
            perfectSolves: streakManager.perfectSolves,
            currentStreak: streakManager.currentStreak,
            isPerfectSolve: isPerfect,
            solveTime: solveTime,
            wordLength: currentWordLength
        )

        // Play success sounds and haptics
        soundManager.playSound(.puzzleComplete)
        soundManager.playSuccessPattern()
    }

    // MARK: - Computed Properties
    var currentChain: [String] {
        statesByLength[currentWordLength]?.chain ?? []
    }

    var currentUserWord: String {
        statesByLength[currentWordLength]?.userWord ?? ""
    }

    var isCurrentPuzzleCompleted: Bool {
        statesByLength[currentWordLength]?.isCompleted ?? false
    }

    var currentGameLogic: WordChainGameLogic? {
        statesByLength[currentWordLength]?.gameLogic
    }

    var minimumChangesNeeded: Int {
        guard let chain = statesByLength[currentWordLength]?.chain,
              chain.count >= 2 else { return 0 }
        return chain.count - 1
    }

    var currentChangesMade: Int {
        statesByLength[currentWordLength]?.changesMade ?? 0
    }

    var minimumPossibleChain: [String] {
        guard let chain = statesByLength[currentWordLength]?.chain else { return [] }
        return chain
    }

    var currentDistanceToTarget: Int? {
        currentDistanceToTargetByLength[currentWordLength] ?? nil
    }

    var isHintActive: Bool {
        isHintActiveByLength[currentWordLength] ?? false
    }

    // MARK: - Persistence Helpers
    func exportPersistedStates() -> [Int: PersistedWordChainState] {
        var dict: [Int: PersistedWordChainState] = [:]
        for (length, state) in statesByLength {
            dict[length] = PersistedWordChainState(
                chain: state.chain,
                userWord: state.userWord,
                isCompleted: state.isCompleted,
                changesMade: state.changesMade
            )
        }
        return dict
    }

    func importPersistedStates(_ dict: [Int: PersistedWordChainState]) {
        for (length, persisted) in dict {
            if var state = statesByLength[length] {
                state.chain = persisted.chain
                state.userWord = persisted.userWord
                state.isCompleted = persisted.isCompleted
                state.changesMade = persisted.changesMade
                statesByLength[length] = state
            } else {
                // If not present, create a new state with a default gameLogic
                let logic = WordChainGameLogic(wordLength: length)
                statesByLength[length] = WordChainState(
                    chain: persisted.chain,
                    userWord: persisted.userWord,
                    isCompleted: persisted.isCompleted,
                    gameLogic: logic,
                    changesMade: persisted.changesMade,
                    undoStack: []
                )
            }
        }
    }

    // MARK: - Debounced Persistence
    private func debouncedPersist() {
        persistenceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.persistStatesByLength()
        }

        persistenceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    func forcePersist() {
        persistenceWorkItem?.cancel()
        persistStatesByLength()
    }

    private func persistStatesByLength() {
        let export = exportPersistedStates()
        UserDefaults.standard.set(try? JSONEncoder().encode(export), forKey: "freeroam_statesByLength")
    }

    // MARK: - Share Functionality
    func generateShareableResult() -> String {
        let efficiency = minimumChangesNeeded == 0 ? 100 :
            min(100, Int(Double(minimumChangesNeeded) / Double(currentChangesMade) * 100))

        let stars = efficiency >= 90 ? "⭐⭐⭐" : efficiency >= 75 ? "⭐⭐" : "⭐"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let dateString = dateFormatter.string(from: Date())

        return """
        Word Chains - \(dateString)
        \(stars) \(currentChangesMade)/\(minimumChangesNeeded) moves
        \(currentWordLength)-letter puzzle
        Efficiency: \(efficiency)%

        Can you beat my score?
        """
    }
}
