import Foundation

class WordChainGameLogic {
    // MARK: - Properties

    private(set) var wordList: Set<String> = []
    private(set) var currentWordLength: Int = 4
    private var distanceCache = LRUCache<String, [String: Int]>(maxSize: 100)
    private var targetDistanceMap: [String: Int] = [:]
    private var currentTarget: String = ""

    // MARK: - Initialization
    init(wordLength: Int) {
        self.currentWordLength = wordLength

        let manager = WordDataManager.shared

        // Filter words by length
        self.wordList = manager.validWords.filter { $0.count == wordLength }
    }

    // MARK: - Chain Generation

    func generateRandomShortestChain(
        minLength: Int,
        forcedStart: String? = nil
    ) -> (chain: [String], start: String, end: String) {
        // Use PuzzleCache for better performance
        if forcedStart == nil {
            if let cached = PuzzleCache.shared.getPuzzle(for: currentWordLength) {
                return cached
            }
        }

        // Fallback to generation if cache miss
        guard !wordList.isEmpty else { return ([], "", "") }

        // For 5-letter words, limit max chain length to 8
        let maxLength = currentWordLength == 5 ? 8 : Int.max

        for _ in 0..<100 {
            let startWord = forcedStart ?? wordList.randomElement()!
            let endWord = wordList.randomElement()!

            guard startWord != endWord else { continue }

            let chain = findShortestChainBidirectional(from: startWord, to: endWord)
            if chain.count >= minLength && chain.count <= maxLength {
                return (chain, startWord, endWord)
            }
        }
        return ([], "", "")
    }

    func generateChainFromWord(_ startWord: String, minLength: Int = 5) -> (chain: [String], start: String, end: String) {
        guard !wordList.isEmpty, wordList.contains(startWord) else { return ([], "", "") }

        // For 5-letter words, limit max chain length to 8
        let maxLength = currentWordLength == 5 ? 8 : Int.max

        for _ in 0..<100 {
            let endWord = wordList.randomElement()!
            guard startWord != endWord else { continue }

            let chain = findShortestChainBidirectional(from: startWord, to: endWord)
            if chain.count >= minLength && chain.count <= maxLength {
                return (chain, startWord, endWord)
            }
        }
        return ([], "", "")
    }

    // MARK: - Chain Finder (Bidirectional BFS - Optimized)

    func findShortestChainBidirectional(from start: String, to end: String) -> [String] {
        guard wordList.contains(start), wordList.contains(end) else { return [] }
        if start == end { return [start] }

        var forwardQueue: [(word: String, path: [String])] = [(start, [start])]
        var backwardQueue: [(word: String, path: [String])] = [(end, [end])]
        var forwardVisited: [String: [String]] = [start: [start]]
        var backwardVisited: [String: [String]] = [end: [end]]

        while !forwardQueue.isEmpty && !backwardQueue.isEmpty {
            // Always expand the smaller frontier for optimal performance
            if forwardQueue.count <= backwardQueue.isEmpty {
                if let result = expandFrontier(&forwardQueue, &forwardVisited, backwardVisited) {
                    return result
                }
            } else {
                if let result = expandFrontier(&backwardQueue, &backwardVisited, forwardVisited, reversed: true) {
                    return result
                }
            }
        }

        return []
    }

    private func expandFrontier(
        _ queue: inout [(word: String, path: [String])],
        _ visited: inout [String: [String]],
        _ otherVisited: [String: [String]],
        reversed: Bool = false
    ) -> [String]? {
        guard !queue.isEmpty else { return nil }

        let (currentWord, path) = queue.removeFirst()

        let neighbors = wordList.filter { areOneLetterApart($0, currentWord) && !visited.keys.contains($0) }

        for neighbor in neighbors {
            let newPath = path + [neighbor]
            visited[neighbor] = newPath

            // Check if we've met the other search
            if let otherPath = otherVisited[neighbor] {
                // Merge paths
                if reversed {
                    // Reverse the backward path and merge
                    var merged = Array(otherPath.dropLast())
                    merged.append(contentsOf: newPath.reversed())
                    return merged
                } else {
                    // Reverse the other path and merge
                    var merged = Array(newPath.dropLast())
                    merged.append(contentsOf: otherPath.reversed())
                    return merged
                }
            }

            queue.append((neighbor, newPath))
        }

        return nil
    }

    // MARK: - Chain Finder (Fallback - Regular BFS)

    func findShortestChain(from start: String, to end: String) -> [String] {
        return findShortestChainBidirectional(from: start, to: end)
    }

    // MARK: - Helper

    func areOneLetterApart(_ w1: String, _ w2: String) -> Bool {
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

    // MARK: - Validation

    func isValidWord(_ word: String) -> Bool {
        wordList.contains(word.uppercased())
    }

    // MARK: - Distance Calculation

    func precomputeDistancesToTarget(_ target: String) {
        guard wordList.contains(target) else { return }
        // If already cached, use it
        if let cached = distanceCache[target] {
            targetDistanceMap = cached
            currentTarget = target
            return
        }
        // Clear previous target distances
        targetDistanceMap.removeAll()
        currentTarget = target
        // Use BFS to compute all distances to target
        var queue: [(word: String, distance: Int)] = [(target, 0)]
        var visited: Set<String> = [target]
        while !queue.isEmpty {
            let (currentWord, distance) = queue.removeFirst()
            targetDistanceMap[currentWord] = distance
            let neighbors = wordList.filter { areOneLetterApart($0, currentWord) && !visited.contains($0) }
            for neighbor in neighbors {
                visited.insert(neighbor)
                queue.append((neighbor, distance + 1))
            }
        }
        // Cache the result
        distanceCache[target] = targetDistanceMap
    }

    func getDistanceToTarget(from word: String) -> Int {
        return targetDistanceMap[word] ?? -1
    }

    func calculateMinimumSteps(from start: String, to end: String) -> Int {
        // If we have precomputed distances for this target, use them
        if end == currentTarget {
            return getDistanceToTarget(from: start)
        }

        // Otherwise use the regular cache
        if let cachedDistances = distanceCache[start],
           let distance = cachedDistances[end] {
            return distance
        }

        // If not in cache, calculate using BFS
        guard wordList.contains(start), wordList.contains(end) else { return -1 }

        var queue: [(word: String, distance: Int)] = [(start, 0)]
        var visited: Set<String> = [start]
        var distances: [String: Int] = [:]

        while !queue.isEmpty {
            let (currentWord, distance) = queue.removeFirst()
            distances[currentWord] = distance

            if currentWord == end {
                // Cache the results
                var cacheEntry = distanceCache[start] ?? [:]
                cacheEntry[end] = distance
                distanceCache[start] = cacheEntry
                return distance
            }

            let neighbors = wordList.filter { areOneLetterApart($0, currentWord) && !visited.contains($0) }
            for neighbor in neighbors {
                visited.insert(neighbor)
                queue.append((neighbor, distance + 1))
            }
        }

        return -1
    }

    // Clear all caches when word length changes
    func clearCache() {
        distanceCache.removeAll()
        targetDistanceMap.removeAll()
        currentTarget = ""
    }
}
