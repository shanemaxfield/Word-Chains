import Foundation

/// Pre-generates and caches puzzles for instant access
class PuzzleCache {
    static let shared = PuzzleCache()

    // MARK: - Properties
    private var cachedPuzzles: [Int: [(chain: [String], start: String, end: String)]] = [:]
    private let cacheSize = 20 // Number of puzzles to pre-generate per length
    private let minLength = 5 // Minimum chain length
    private var generationQueue = DispatchQueue(label: "com.wordchains.puzzlecache", qos: .utility)
    private var isGenerating: [Int: Bool] = [:]

    // MARK: - Initialization
    private init() {
        // Pre-generate puzzles for all lengths
        for length in [3, 4, 5] {
            refillCache(for: length)
        }
    }

    // MARK: - Public Methods
    func getPuzzle(for wordLength: Int) -> (chain: [String], start: String, end: String)? {
        // Get puzzle from cache
        var puzzle: (chain: [String], start: String, end: String)?

        objc_sync_enter(self)
        if var puzzles = cachedPuzzles[wordLength], !puzzles.isEmpty {
            puzzle = puzzles.removeFirst()
            cachedPuzzles[wordLength] = puzzles
        }
        objc_sync_exit(self)

        // Refill cache in background if running low
        if let puzzles = cachedPuzzles[wordLength], puzzles.count < cacheSize / 2 {
            refillCache(for: wordLength)
        }

        return puzzle
    }

    func refillCache(for wordLength: Int) {
        // Prevent multiple simultaneous generations
        guard isGenerating[wordLength] != true else { return }

        isGenerating[wordLength] = true

        generationQueue.async { [weak self] in
            guard let self = self else { return }

            let logic = WordChainGameLogic(wordLength: wordLength)
            var newPuzzles: [(chain: [String], start: String, end: String)] = []

            // Calculate how many puzzles we need
            let currentCount = self.cachedPuzzles[wordLength]?.count ?? 0
            let needed = self.cacheSize - currentCount

            // Generate puzzles using smart algorithm
            for _ in 0..<needed {
                if let puzzle = self.generateSmartPuzzle(logic: logic, wordLength: wordLength) {
                    newPuzzles.append(puzzle)
                }
            }

            // Add to cache
            objc_sync_enter(self)
            if self.cachedPuzzles[wordLength] == nil {
                self.cachedPuzzles[wordLength] = []
            }
            self.cachedPuzzles[wordLength]?.append(contentsOf: newPuzzles)
            objc_sync_exit(self)

            self.isGenerating[wordLength] = false
        }
    }

    // MARK: - Private Methods
    private func generateSmartPuzzle(
        logic: WordChainGameLogic,
        wordLength: Int
    ) -> (chain: [String], start: String, end: String)? {
        let maxLength = wordLength == 5 ? 8 : Int.max

        // Strategy: Use "hub" words (well-connected words) for better chains
        let hubWords = findHubWords(logic: logic, minConnections: wordLength == 5 ? 5 : 6)

        // Try with hub words first (30 attempts)
        for _ in 0..<30 {
            guard let startWord = hubWords.randomElement() else { break }

            // Find words at a good distance
            let potentialEnds = findDistantWords(
                from: startWord,
                logic: logic,
                targetDistance: minLength...min(maxLength, minLength + 3)
            )

            guard let endWord = potentialEnds.randomElement() else { continue }

            let chain = logic.findShortestChain(from: startWord, to: endWord)
            if chain.count >= minLength && chain.count <= maxLength {
                return (chain, startWord, endWord)
            }
        }

        // Fallback to random if hub strategy fails
        for _ in 0..<20 {
            let result = logic.generateRandomShortestChain(minLength: minLength)
            if !result.chain.isEmpty {
                return result
            }
        }

        return nil
    }

    private func findHubWords(logic: WordChainGameLogic, minConnections: Int) -> [String] {
        let wordList = logic.wordList
        var hubWords: [String] = []

        for word in wordList {
            let neighbors = wordList.filter { areOneLetterApart(word, $0) }
            if neighbors.count >= minConnections {
                hubWords.append(word)
            }

            // Limit to avoid excessive computation
            if hubWords.count > 200 {
                break
            }
        }

        return hubWords
    }

    private func findDistantWords(
        from start: String,
        logic: WordChainGameLogic,
        targetDistance: ClosedRange<Int>
    ) -> [String] {
        var candidates: [String] = []
        let wordList = logic.wordList

        // Sample 100 random words and check distance
        let sampleSize = min(100, wordList.count)
        let sampled = Array(wordList.shuffled().prefix(sampleSize))

        for word in sampled {
            guard word != start else { continue }

            let distance = logic.calculateMinimumSteps(from: start, to: word)
            if targetDistance.contains(distance) {
                candidates.append(word)
            }

            // Early exit if we have enough candidates
            if candidates.count >= 20 {
                break
            }
        }

        return candidates
    }

    private func areOneLetterApart(_ w1: String, _ w2: String) -> Bool {
        guard w1.count == w2.count else { return false }
        var diffs = 0
        for (c1, c2) in zip(w1, w2) {
            if c1 != c2 {
                diffs += 1
                if diffs > 1 { return false }
            }
        }
        return diffs == 1
    }

    // MARK: - Debug Methods
    func getCacheStatus() -> [Int: Int] {
        var status: [Int: Int] = [:]
        for length in [3, 4, 5] {
            status[length] = cachedPuzzles[length]?.count ?? 0
        }
        return status
    }

    func clearCache() {
        cachedPuzzles.removeAll()
    }
}
