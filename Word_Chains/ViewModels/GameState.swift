import SwiftUI

// MARK: - Game State Models
struct WordChainState: Equatable {
    var chain: [String]
    var userWord: String
    var isCompleted: Bool
    var gameLogic: WordChainGameLogic
    var changesMade: Int
    static func == (lhs: WordChainState, rhs: WordChainState) -> Bool {
        lhs.chain == rhs.chain &&
        lhs.userWord == rhs.userWord &&
        lhs.isCompleted == rhs.isCompleted &&
        lhs.changesMade == rhs.changesMade
        // Note: gameLogic is not compared for equality
    }
}

// MARK: - Puzzle Queue Item
struct PuzzleQueueItem: Codable {
    let chain: [String]
    let start: String
    let end: String
    // Note: gameLogic is not stored as it can be recreated
}

// MARK: - Persisted Queue Item (for storage)
struct PersistedPuzzleQueueItem: Codable {
    let chain: [String]
    let start: String
    let end: String
}

// MARK: - Persisted State for Free Roam
struct PersistedWordChainState: Codable {
    var chain: [String]
    var userWord: String
    var isCompleted: Bool
    var changesMade: Int
}

// MARK: - Game State Manager
class GameState: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var currentWordLength: Int = 4
    @Published private(set) var statesByLength: [Int: WordChainState] = [:]
    @Published private(set) var gridResetTrigger: Bool = false
    @Published private(set) var currentDistanceToTargetByLength: [Int: Int?] = [:]
    @Published private(set) var isHintActiveByLength: [Int: Bool] = [:]
    @Published private(set) var isSearchingForChain: [Int: Bool] = [:]
    @Published var showOnboarding: Bool = false
    
    // MARK: - Constants
    let availableLengths = [3, 4, 5]
    let lengthLabels = [3: "3-Letter", 4: "4-Letter", 5: "5-Letter"]
    let queueSize = 20 // Number of puzzles to keep in queue
    
    // MARK: - Private Properties
    private var puzzleGenerationTasks: [Int: Task<Void, Never>] = [:]
    private var puzzleQueues: [Int: [PuzzleQueueItem]] = [:] // Queue of pre-generated puzzles
    private var queueGenerationTasks: [Int: Task<Void, Never>] = [:] // Tasks for filling the queue
    
    // MARK: - Initialization
    init() {
        loadOnboardingState()
        loadPuzzleQueues()
        
        // Start queue generation for 5-letter words immediately on app launch
        DispatchQueue.main.async {
            self.startInitialQueueGeneration()
        }
    }
    
    // MARK: - Initial Queue Generation
    private func startInitialQueueGeneration() {
        // First, ensure we have at least one puzzle for each word length
        ensureOnePuzzlePerLength()
        
        // Set up initial puzzle after a short delay to allow initial generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setupInitialPuzzle()
        }
        
        // Then fill the queues sequentially, starting with 5-letter
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.fillQueuesSequentially()
        }
    }
    
    private func ensureOnePuzzlePerLength() {
        let priorityOrder = [5, 4, 3]
        
        for wordLength in priorityOrder {
            let currentQueueSize = puzzleQueues[wordLength]?.count ?? 0
            if currentQueueSize == 0 {
                print("Generating initial puzzle for \(wordLength)-letter words")
                generateSinglePuzzle(for: wordLength)
            } else {
                print("Already have \(currentQueueSize) puzzles for \(wordLength)-letter words")
            }
        }
    }
    
    private func generateSinglePuzzle(for wordLength: Int) {
        Task {
            let logic = WordChainGameLogic(wordLength: wordLength)
            
            let result = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let chainResult = logic.generateRandomShortestChain(minLength: 5)
                    let validChain = chainResult.chain.allSatisfy { $0.count == wordLength }
                    if validChain {
                        continuation.resume(returning: chainResult)
                    } else {
                        continuation.resume(returning: ([], "", ""))
                    }
                }
            }
            
            if !result.chain.isEmpty {
                await MainActor.run {
                    let puzzleItem = PuzzleQueueItem(
                        chain: result.chain,
                        start: result.start,
                        end: result.end
                    )
                    
                    var existingQueue = self.puzzleQueues[wordLength] ?? []
                    existingQueue.append(puzzleItem)
                    self.puzzleQueues[wordLength] = existingQueue
                    self.savePuzzleQueues()
                    
                    print("Generated initial puzzle for \(wordLength)-letter words. Queue size: \(existingQueue.count)")
                }
            }
        }
    }
    
    private func fillQueuesSequentially() {
        let priorityOrder = [5, 4, 3]
        fillNextQueue(priorityOrder: priorityOrder, currentIndex: 0)
    }
    
    private func fillNextQueue(priorityOrder: [Int], currentIndex: Int) {
        guard currentIndex < priorityOrder.count else {
            print("Completed filling all queues sequentially")
            return
        }
        
        let wordLength = priorityOrder[currentIndex]
        let currentQueueSize = puzzleQueues[wordLength]?.count ?? 0
        
        if currentQueueSize < queueSize {
            print("Starting sequential queue fill for \(wordLength)-letter words (current: \(currentQueueSize)/\(queueSize))")
            
            // Fill this queue, then move to the next
            fillQueueSequentially(for: wordLength) {
                // When this queue is done, move to the next
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.fillNextQueue(priorityOrder: priorityOrder, currentIndex: currentIndex + 1)
                }
            }
        } else {
            print("Queue already full for \(wordLength)-letter words (\(currentQueueSize)/\(queueSize)), moving to next")
            // Move to next queue immediately
            fillNextQueue(priorityOrder: priorityOrder, currentIndex: currentIndex + 1)
        }
    }
    
    private func setupInitialPuzzle() {
        // Try to get a puzzle from the current word length's queue
        if let nextPuzzle = getNextPuzzleFromQueue(for: currentWordLength) {
            print("Setting up initial puzzle from queue for \(currentWordLength)-letter")
            let gameLogic = WordChainGameLogic(wordLength: currentWordLength)
            setCurrentChain(nextPuzzle.chain, start: nextPuzzle.start, end: nextPuzzle.end, gameLogic: gameLogic, for: currentWordLength)
        } else {
            print("No puzzle available in queue for \(currentWordLength)-letter, will generate when needed")
        }
    }
    
    private func fillQueueSequentially(for wordLength: Int, completion: @escaping () -> Void) {
        // Only cancel if there's already a task running
        if let existingTask = queueGenerationTasks[wordLength] {
            print("Cancelling existing fillQueue task for \(wordLength)-letter")
            existingTask.cancel()
        }
        
        print("Starting sequential fillQueue for \(wordLength)-letter puzzles")
        
        queueGenerationTasks[wordLength] = Task {
            let logic = WordChainGameLogic(wordLength: wordLength)
            
            // Get current queue size to know how many more we need
            let currentQueueSize = await MainActor.run { self.puzzleQueues[wordLength]?.count ?? 0 }
            let puzzlesNeeded = max(0, queueSize - currentQueueSize)
            
            print("Need to generate \(puzzlesNeeded) puzzles for \(wordLength)-letter queue")
            
            // Generate puzzles and add them to the queue incrementally
            var generatedCount = 0
            while generatedCount < puzzlesNeeded && !Task.isCancelled {
                let result = await withCheckedContinuation { continuation in
                    DispatchQueue.global(qos: .utility).async {
                        let chainResult = logic.generateRandomShortestChain(minLength: 5)
                        let validChain = chainResult.chain.allSatisfy { $0.count == wordLength }
                        if validChain {
                            continuation.resume(returning: chainResult)
                        } else {
                            continuation.resume(returning: ([], "", ""))
                        }
                    }
                }
                
                if !Task.isCancelled && !result.chain.isEmpty {
                    let puzzleItem = PuzzleQueueItem(
                        chain: result.chain,
                        start: result.start,
                        end: result.end
                    )
                    
                    // Add puzzle to queue immediately
                    await MainActor.run {
                        var existingQueue = self.puzzleQueues[wordLength] ?? []
                        existingQueue.append(puzzleItem)
                        self.puzzleQueues[wordLength] = existingQueue
                        generatedCount += 1
                        print("Added puzzle \(generatedCount)/\(puzzlesNeeded) to queue for \(wordLength)-letter. Queue size now: \(existingQueue.count)")
                        
                        // Save queue after each addition
                        self.savePuzzleQueues()
                    }
                }
                
                // Small delay between generations to avoid overwhelming the system
                if generatedCount < puzzlesNeeded && !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                }
            }
            
            // Clean up the task and call completion
            await MainActor.run {
                self.queueGenerationTasks[wordLength] = nil
                let finalQueueSize = self.puzzleQueues[wordLength]?.count ?? 0
                
                if Task.isCancelled {
                    print("Sequential fillQueue cancelled for \(wordLength)-letter, but added \(generatedCount) puzzles. Total queue size: \(finalQueueSize)")
                } else {
                    print("Completed sequential fillQueue for \(wordLength)-letter. Total queue size: \(finalQueueSize)")
                }
                
                // Call completion to move to next queue
                completion()
            }
        }
    }
    
    // MARK: - Onboarding Methods
    func checkAndShowOnboarding() {
        if !hasSeenOnboarding {
            showOnboarding = true
        }
    }
    
    func completeOnboarding() {
        hasSeenOnboarding = true
        showOnboarding = false
        saveOnboardingState()
    }
    
    // For testing purposes - reset onboarding state
    func resetOnboarding() {
        hasSeenOnboarding = false
        showOnboarding = false
        saveOnboardingState()
    }
    
    private var hasSeenOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hasSeenOnboarding")
        }
    }
    
    private func loadOnboardingState() {
        // Load onboarding state from UserDefaults
        hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }
    
    private func saveOnboardingState() {
        UserDefaults.standard.set(hasSeenOnboarding, forKey: "hasSeenOnboarding")
    }
    
    // MARK: - Queue Persistence Methods
    private func savePuzzleQueues() {
        var persistedQueues: [Int: [PersistedPuzzleQueueItem]] = [:]
        
        for (wordLength, queue) in puzzleQueues {
            let persistedQueue = queue.map { puzzleItem in
                PersistedPuzzleQueueItem(
                    chain: puzzleItem.chain,
                    start: puzzleItem.start,
                    end: puzzleItem.end
                )
            }
            persistedQueues[wordLength] = persistedQueue
        }
        
        if let data = try? JSONEncoder().encode(persistedQueues) {
            UserDefaults.standard.set(data, forKey: "puzzle_queues")
            print("Saved puzzle queues: \(persistedQueues.keys.map { "\($0)-letter: \(persistedQueues[$0]?.count ?? 0)" }.joined(separator: ", "))")
        }
    }
    
    private func loadPuzzleQueues() {
        guard let data = UserDefaults.standard.data(forKey: "puzzle_queues"),
              let persistedQueues = try? JSONDecoder().decode([Int: [PersistedPuzzleQueueItem]].self, from: data) else {
            print("No saved puzzle queues found")
            return
        }
        
        for (wordLength, persistedQueue) in persistedQueues {
            let logic = WordChainGameLogic(wordLength: wordLength)
            let queue = persistedQueue.map { persistedItem in
                PuzzleQueueItem(
                    chain: persistedItem.chain,
                    start: persistedItem.start,
                    end: persistedItem.end
                )
            }
            puzzleQueues[wordLength] = queue
            print("Loaded \(queue.count) puzzles for \(wordLength)-letter queue")
        }
    }
    
    // MARK: - Public Methods
    func setWordLength(_ length: Int) {
        guard availableLengths.contains(length) else { return }
        currentWordLength = length
        if statesByLength[length] == nil {
            setupGameLogic(for: length)
        }
        
        // Initialize queue for this word length if needed
        if puzzleQueues[length] == nil {
            print("Initializing queue for \(length)-letter puzzles")
            fillQueue(for: length)
        } else {
            // Check if queue needs refilling
            let currentQueueSize = puzzleQueues[length]?.count ?? 0
            print("Queue for \(length)-letter has \(currentQueueSize) puzzles")
            if currentQueueSize < 5 {
                print("Refilling queue for \(length)-letter puzzles")
                fillQueue(for: length)
            }
        }
        
        // If we're showing loading state and there's no ongoing task, start a new search
        if isSearchingForChain[length] == true && puzzleGenerationTasks[length] == nil {
            generateNewPuzzle()
        }
        
        gridResetTrigger.toggle()
        clearHintSteps(for: length)
        persistStatesByLength()
    }
    
    func resetCurrentPuzzle() {
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
            statesByLength[currentWordLength] = state
        }
        gridResetTrigger.toggle()
        clearHintSteps(for: currentWordLength)
        persistStatesByLength()
    }
    
    func generateNewPuzzle() {
        let wordLength = currentWordLength
        
        print("generateNewPuzzle called for \(wordLength)-letter")
        
        // First, try to get a puzzle from the queue
        if let nextPuzzle = getNextPuzzleFromQueue(for: wordLength) {
            print("Using puzzle from queue for \(wordLength)-letter")
            // Recreate gameLogic for the puzzle
            let gameLogic = WordChainGameLogic(wordLength: wordLength)
            setCurrentChain(nextPuzzle.chain, start: nextPuzzle.start, end: nextPuzzle.end, gameLogic: gameLogic, for: wordLength)
            // Check and refill the queue immediately
            checkAndRefillQueue(for: wordLength)
            return
        }
        
        print("Queue empty, generating new puzzle for \(wordLength)-letter")
        
        // If queue is empty, generate immediately
        guard let logic = statesByLength[wordLength]?.gameLogic else { return }
        isSearchingForChain[wordLength] = true
        
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
                // Always update the chain, regardless of current word length
                setCurrentChain(result.chain, start: result.start, end: result.end, gameLogic: logic, for: wordLength)
                self.isSearchingForChain[wordLength] = false
                self.puzzleGenerationTasks[wordLength] = nil
                // Check and refill the queue after generating a puzzle
                self.checkAndRefillQueue(for: wordLength)
            }
        }
    }
    
    func updateUserWord(_ word: String) {
        guard var state = statesByLength[currentWordLength] else { return }
        if state.userWord != word {
            state.changesMade += 1
        }
        state.userWord = word
        validateWord(&state)
        statesByLength[currentWordLength] = state
        // Update distance if hint is active
        if isHintActive {
            let distance = state.gameLogic.getDistanceToTarget(from: word)
            setHintState(distance: distance, active: true, for: currentWordLength)
        }
        persistStatesByLength()
    }
    
    func calculateHintSteps() {
        guard let state = statesByLength[currentWordLength] else { return }
        // Precompute distances to target if not already done
        if let target = state.chain.last {
            state.gameLogic.precomputeDistancesToTarget(target)
            let distance = state.gameLogic.getDistanceToTarget(from: state.userWord)
            setHintState(distance: distance, active: true, for: currentWordLength)
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
        // Remove the guard that checks currentWordLength
        guard var state = statesByLength[wordLength] else { return }
        state.chain = chain
        state.userWord = start
        state.isCompleted = false
        state.changesMade = 0
        state.gameLogic = gameLogic
        statesByLength[wordLength] = state
        persistStatesByLength()
    }
    
    func setupGameLogic(for length: Int) {
        let logic = WordChainGameLogic(wordLength: length)
        if statesByLength[length] == nil {
            // Try to get a puzzle from the queue first
            if let nextPuzzle = getNextPuzzleFromQueue(for: length) {
                print("Setting up initial state from queue for \(length)-letter")
                statesByLength[length] = WordChainState(
                    chain: nextPuzzle.chain,
                    userWord: nextPuzzle.start,
                    isCompleted: false,
                    gameLogic: logic,
                    changesMade: 0
                )
            } else {
                // If no queue available, generate a temporary puzzle
                print("No queue available for \(length)-letter, generating temporary puzzle")
            let result = logic.generateRandomShortestChain(minLength: 5)
            statesByLength[length] = WordChainState(
                chain: result.chain,
                userWord: result.start,
                isCompleted: false,
                gameLogic: logic,
                changesMade: 0
            )
            }
            // Initialize queue for this word length
            fillQueue(for: length)
        } else {
            // Update existing state with new game logic
            var state = statesByLength[length]!
            state.gameLogic = logic
            statesByLength[length] = state
            // Ensure queue is filled for this word length
            ensureQueueHasPuzzles(for: length)
        }
    }
    
    // Add a public method to check queue status
    func checkQueueStatus() {
        checkAndRefillQueue(for: currentWordLength)
    }
    
    // MARK: - Private Methods
    private func validateWord(_ state: inout WordChainState) {
        let guess = state.userWord.uppercased()
        let target = state.chain.last ?? ""
        if state.gameLogic.isValidWord(guess) && guess == target {
            state.isCompleted = true
        }
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
                    changesMade: persisted.changesMade
                )
            }
        }
    }

    private func persistStatesByLength() {
        let export = exportPersistedStates()
        UserDefaults.standard.set(try? JSONEncoder().encode(export), forKey: "freeroam_statesByLength")
    }
    
    // MARK: - Queue Management Methods
    private func fillQueue(for wordLength: Int) {
        // Only cancel if there's already a task running
        if let existingTask = queueGenerationTasks[wordLength] {
            print("Cancelling existing fillQueue task for \(wordLength)-letter")
            existingTask.cancel()
        }
        
        print("Starting fillQueue for \(wordLength)-letter puzzles")
        
        queueGenerationTasks[wordLength] = Task {
            let logic = WordChainGameLogic(wordLength: wordLength)
            
            // Get current queue size to know how many more we need
            let currentQueueSize = await MainActor.run { self.puzzleQueues[wordLength]?.count ?? 0 }
            let puzzlesNeeded = max(0, queueSize - currentQueueSize)
            
            print("Need to generate \(puzzlesNeeded) puzzles for \(wordLength)-letter queue")
            
            // Generate puzzles and add them to the queue incrementally
            var generatedCount = 0
            while generatedCount < puzzlesNeeded && !Task.isCancelled {
                let result = await withCheckedContinuation { continuation in
                    DispatchQueue.global(qos: .utility).async {
                        let chainResult = logic.generateRandomShortestChain(minLength: 5)
                        // Verify that all words in the chain match the current word length
                        let validChain = chainResult.chain.allSatisfy { $0.count == wordLength }
                        if validChain {
                            continuation.resume(returning: chainResult)
                        } else {
                            continuation.resume(returning: ([], "", ""))
                        }
                    }
                }
                
                if !Task.isCancelled && !result.chain.isEmpty {
                    let puzzleItem = PuzzleQueueItem(
                        chain: result.chain,
                        start: result.start,
                        end: result.end
                    )
                    
                    // Add puzzle to queue immediately
                    await MainActor.run {
                        var existingQueue = self.puzzleQueues[wordLength] ?? []
                        existingQueue.append(puzzleItem)
                        self.puzzleQueues[wordLength] = existingQueue
                        generatedCount += 1
                        print("Added puzzle \(generatedCount)/\(puzzlesNeeded) to queue for \(wordLength)-letter. Queue size now: \(existingQueue.count)")
                        
                        // Save queue after each addition
                        self.savePuzzleQueues()
                    }
                }
                
                // Small delay between generations to avoid overwhelming the system
                if generatedCount < puzzlesNeeded && !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                }
            }
            
            // Clean up the task
            await MainActor.run {
                self.queueGenerationTasks[wordLength] = nil
                let finalQueueSize = self.puzzleQueues[wordLength]?.count ?? 0
                
                if Task.isCancelled {
                    print("fillQueue cancelled for \(wordLength)-letter, but added \(generatedCount) puzzles. Total queue size: \(finalQueueSize)")
                } else {
                    print("Completed fillQueue for \(wordLength)-letter. Total queue size: \(finalQueueSize)")
                }
            }
        }
    }
    
    private func getNextPuzzleFromQueue(for wordLength: Int) -> PuzzleQueueItem? {
        guard var queue = puzzleQueues[wordLength], !queue.isEmpty else { 
            print("Queue empty for \(wordLength)-letter puzzles")
            return nil 
        }
        let nextPuzzle = queue.removeFirst()
        puzzleQueues[wordLength] = queue
        
        print("Using puzzle from queue for \(wordLength)-letter. Queue size now: \(queue.count)")
        
        // Save queue after removing a puzzle
        savePuzzleQueues()
        
        // Start refilling immediately to maintain queue size
        if queue.count < queueSize {
            fillQueue(for: wordLength)
        }
        
        return nextPuzzle
    }
    
    private func ensureQueueHasPuzzles(for wordLength: Int) {
        let currentQueueSize = puzzleQueues[wordLength]?.count ?? 0
        print("Ensuring queue has puzzles for \(wordLength)-letter. Current size: \(currentQueueSize)")
        if currentQueueSize < queueSize { // Refill whenever we have less than full queue
            fillQueue(for: wordLength)
        }
    }
    
    // Add a method to check and refill queue status
    private func checkAndRefillQueue(for wordLength: Int) {
        let currentQueueSize = puzzleQueues[wordLength]?.count ?? 0
        let isGenerating = queueGenerationTasks[wordLength] != nil
        
        print("Checking queue for \(wordLength)-letter. Size: \(currentQueueSize), Generating: \(isGenerating)")
        
        // Only start generation if queue is very low and we're not currently generating
        if currentQueueSize < 3 && !isGenerating {
            print("Starting queue fill for \(wordLength)-letter puzzles (queue size: \(currentQueueSize))")
            fillQueue(for: wordLength)
        } else if currentQueueSize < queueSize && !isGenerating {
            print("Queue size acceptable (\(currentQueueSize)), not starting new generation")
        } else if isGenerating {
            print("Queue generation already in progress for \(wordLength)-letter")
        }
    }
} 
