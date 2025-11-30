import SwiftUI

struct FreeRoamView: View {
    @EnvironmentObject var state: EnhancedGameState
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var focusedIndex: Int?
    @State private var showSuccess: Bool = false
    @State private var showInvalidMessage: Bool = false
    @State private var externalInvalidTriggers: [Int: Bool] = [:]
    @State private var externalInvalidLetters: [Int: String?] = [:]
    @State private var isCelebrating: Bool = false
    @State private var celebrationStartTime: Date = Date()
    @State private var showCelebrationCard: Bool = false
    @State private var showMinimumChain: Bool = false
    @AppStorage("freeroam_hintActiveByLength") private var hintActiveByLengthData: Data = Data()
    @AppStorage("freeroam_hintDistanceByLength") private var hintDistanceByLengthData: Data = Data()
    @AppStorage("freeroam_userWordByLength") private var userWordByLengthData: Data = Data()
    @AppStorage("freeroam_currentWordLength") private var currentWordLengthStorage: Int = 4
    @State private var hintActiveByLength: [Int: Bool] = [:]
    @State private var hintDistanceByLength: [Int: Int] = [:]
    @State private var userWordByLength: [Int: String] = [:]
    @AppStorage("freeroam_chainsByLength") private var chainsByLengthData: Data = Data()
    @AppStorage("freeroam_targetWordsByLength") private var targetWordsByLengthData: Data = Data()
    @AppStorage("freeroam_statesByLength") private var statesByLengthData: Data = Data()
    @State private var pulseScale: CGFloat = 1.0
    @State private var showDelayedLoadingMessage: Bool = false
    @State private var loadingMessageTimer: DispatchWorkItem? = nil
    @State private var nextButtonTriggeredSearch: Bool = false

    let lengthOptions = [3, 4, 5]
    let lengthLabels = [3: "3-Letter", 4: "4-Letter", 5: "5-Letter"]

    var body: some View {
        ZStack {
            Color("SandstoneBeige").ignoresSafeArea()
            backgroundOverlay
            CelebrationPulseOverlay(isActive: isCelebrating)
            mainContent
            if isCelebrating {
                CelebrationConfettiView().transition(.opacity)
            }
            // Loading message overlay for 5-letter words
            if showDelayedLoadingMessage && state.currentWordLength == 5 {
                VStack {
                    Spacer()
                    Text("Finding a new chain...")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black)
                                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                        )
                        .scaleEffect(pulseScale)
                        .animation(
                            Animation.easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true),
                            value: pulseScale
                        )
                    Spacer()
                }
                .zIndex(100)
                .onAppear {
                    // Reset animation state
                    pulseScale = 1.0
                    // Force a layout update
                    DispatchQueue.main.async {
                        // Start animation after a brief delay
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            pulseScale = 1.15
                        }
                    }
                }
                .onDisappear {
                    // Reset scale when view disappears
                    pulseScale = 1.0
                }
            }
            // Celebration card overlay (single instance)
            if showCelebrationCard || showMinimumChain {
                CelebrationCardView(
                    onRetry: {
                        state.resetCurrentPuzzle()
                        showCelebrationCard = false
                        showMinimumChain = false
                    },
                    onShowMinimum: {
                        if showMinimumChain {
                            showMinimumChain = false
                            showCelebrationCard = true
                        } else {
                            showMinimumChain = true
                            showCelebrationCard = false
                        }
                    },
                    onNext: {
                        nextButtonTriggeredSearch = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            state.generateNewPuzzle()
                            showCelebrationCard = false
                            showMinimumChain = false
                        }
                    },
                    onFreeRoam: nil,
                    onContinueChain: handleContinueChain,
                    changesMade: state.currentChangesMade,
                    minimumChanges: state.minimumChangesNeeded,
                    showFreeRoamButton: !showMinimumChain,
                    showMinimumChain: showMinimumChain,
                    minimumChain: state.minimumPossibleChain,
                    minimumChainGroups: showMinimumChain ? [state.minimumPossibleChain] : nil,
                    streakManager: state.streakManager,
                    shareText: state.generateShareableResult()
                )
                .zIndex(101)
            }
        }
        .navigationBarHidden(true)
        .animation(.spring(response: 1.2, dampingFraction: 0.85), value: showCelebrationCard)
        .onAppear {
            // Restore all states for all lengths
            let savedStates = (try? JSONDecoder().decode([Int: PersistedWordChainState].self, from: statesByLengthData)) ?? [:]
            state.importPersistedStates(savedStates)
            // Restore user progress and hint state
            userWordByLength = (try? JSONDecoder().decode([Int: String].self, from: userWordByLengthData)) ?? [:]
            if let storedLength = [3,4,5].first(where: { $0 == currentWordLengthStorage }) {
                state.setWordLength(storedLength)
            }
            hintActiveByLength = (try? JSONDecoder().decode([Int: Bool].self, from: hintActiveByLengthData)) ?? [:]
            hintDistanceByLength = (try? JSONDecoder().decode([Int: Int].self, from: hintDistanceByLengthData)) ?? [:]
            // Recompute hint distances for all active hints
            for length in [3, 4, 5] {
                if hintActiveByLength[length] == true {
                    let logic = WordChainGameLogic(wordLength: length)
                    let chain = state.statesByLength[length]?.chain ?? []
                    let target = chain.last ?? ""
                    logic.precomputeDistancesToTarget(target)
                    let word = userWordByLength[length] ?? state.statesByLength[length]?.userWord ?? ""
                    let distance = logic.getDistanceToTarget(from: word)
                    hintDistanceByLength[length] = distance
                }
            }
            if state.isCurrentPuzzleCompleted {
                showCelebrationCard = true
            }
            // Check if we're still searching for a chain
            if state.isSearchingForChain[state.currentWordLength] == true {
                showDelayedLoadingMessage = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedIndex = 0
            }
        }
        .onChange(of: state.currentWordLength) { newValue in
            currentWordLengthStorage = newValue
        }
        .onChange(of: state.currentUserWord) { newValue in
            userWordByLength[state.currentWordLength] = newValue
            userWordByLengthData = (try? JSONEncoder().encode(userWordByLength)) ?? Data()
        }
        .onChange(of: state.isCurrentPuzzleCompleted) { completed in
            if !completed {
                showSuccess = false
                isCelebrating = false
                showCelebrationCard = false
                showMinimumChain = false
            } else {
                isCelebrating = true
                celebrationStartTime = Date()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    showCelebrationCard = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    isCelebrating = false
                }
                hintActiveByLength[state.currentWordLength] = false
                hintDistanceByLength[state.currentWordLength] = nil
            }
        }
        .onChange(of: hintActiveByLength) { newValue in
            hintActiveByLengthData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
        .onChange(of: hintDistanceByLength) { newValue in
            hintDistanceByLengthData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
        .onChange(of: state.currentChain) { newChain in
            var chains = (try? JSONDecoder().decode([Int: [String]].self, from: chainsByLengthData)) ?? [:]
            chains[state.currentWordLength] = newChain
            chainsByLengthData = (try? JSONEncoder().encode(chains)) ?? Data()
        }
        .onChange(of: state.currentChain.last) { newTarget in
            var targets = (try? JSONDecoder().decode([Int: String].self, from: targetWordsByLengthData)) ?? [:]
            targets[state.currentWordLength] = newTarget ?? ""
            targetWordsByLengthData = (try? JSONEncoder().encode(targets)) ?? Data()
        }
        .onChange(of: state.statesByLength) { _ in
            let export = state.exportPersistedStates()
            statesByLengthData = (try? JSONEncoder().encode(export)) ?? Data()
        }
        .onChange(of: state.isSearchingForChain[state.currentWordLength]) { isSearching in
            loadingMessageTimer?.cancel()
            if isSearching == true {
                if nextButtonTriggeredSearch {
                    let workItem = DispatchWorkItem {
                        if state.isSearchingForChain[state.currentWordLength] == true {
                            showDelayedLoadingMessage = true
                        }
                    }
                    loadingMessageTimer = workItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)
                } else {
                    showDelayedLoadingMessage = true
                }
                nextButtonTriggeredSearch = false
            } else {
                showDelayedLoadingMessage = false
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 6) {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color("C_Charcoal"))
                        .frame(width: 54, height: 54)
                        .contentShape(Rectangle())
                }
                Spacer()
            }
            .padding(.bottom, 12)
            Text("Free Roam")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(Color("C_Charcoal"))
                .padding(.top, -8)
                .padding(.bottom, 24)
            // Capsule Length Selector
            HStack(spacing: 8) {
                ForEach(lengthOptions, id: \.self) { option in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            state.setWordLength(option)
                        }
                    }) {
                        Text(lengthLabels[option] ?? "")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(state.currentWordLength == option ? Color("C_PureWhite") : Color("C_Charcoal"))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 22)
                            .background(
                                Capsule()
                                    .fill(state.currentWordLength == option ? Color("C_WarmTeal") : Color("C_PureWhite"))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(state.currentWordLength == option ? Color("C_WarmTeal") : Color("C_Charcoal").opacity(0.12), lineWidth: 1.2)
                            )
                            .shadow(color: state.currentWordLength == option ? Color("C_WarmTeal").opacity(0.10) : .clear, radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)

            let chain = state.currentChain
            let puzzleCompleted = state.isCurrentPuzzleCompleted
            let gameLogic = state.currentGameLogic ?? WordChainGameLogic(wordLength: state.currentWordLength)

            if !chain.isEmpty {
                EnhancedGameCardView(
                    tilesCount: state.currentWordLength,
                    makeTile: { index in
                        AnyView(
                            EditableLetterTile(
                                index: index,
                                wordLength: state.currentWordLength,
                                userWord: Binding(
                                    get: { state.currentUserWord },
                                    set: { newWord in
                                        state.updateUserWord(newWord)
                                        userWordByLength[state.currentWordLength] = newWord
                                        userWordByLengthData = (try? JSONEncoder().encode(userWordByLength)) ?? Data()
                                        if hintActiveByLength[state.currentWordLength] == true {
                                            let logic = state.currentGameLogic ?? WordChainGameLogic(wordLength: state.currentWordLength)
                                            let distance = logic.getDistanceToTarget(from: newWord)
                                            hintDistanceByLength[state.currentWordLength] = distance
                                        }
                                    }
                                ),
                                focusedIndex: $focusedIndex,
                                gameLogic: gameLogic,
                                onInvalidEntry: {
                                    showInvalidMessage = true
                                },
                                externalInvalidTrigger: Binding(
                                    get: { externalInvalidTriggers[index] ?? false },
                                    set: { externalInvalidTriggers[index] = $0 }
                                ),
                                externalInvalidLetter: Binding(
                                    get: { externalInvalidLetters[index] ?? nil },
                                    set: { externalInvalidLetters[index] = $0 }
                                )
                            )
                            .modifier(CelebrationTileEffect(
                                isActive: isCelebrating,
                                index: index,
                                startTime: celebrationStartTime
                            ))
                        )
                    },
                    targetWord: chain.last ?? "----",
                    showReset: true,
                    onReset: {
                        state.resetCurrentPuzzle()
                        focusedIndex = 0
                        // Do NOT clear hint state on reset
                    },
                    showFreeRoam: false,
                    onFreeRoam: nil,
                    cardColor: Color("C_PureWhite"),
                    puzzleCompleted: state.isCurrentPuzzleCompleted,
                    invalidMessage: showInvalidMessage ? "Not in word list" : nil,
                    showInvalidMessage: showInvalidMessage,
                    showSuccess: state.isCurrentPuzzleCompleted,
                    successMessage: "Puzzle Solved!",
                    onSuccessAction: nil,
                    successActionLabel: nil,
                    minimumChanges: state.minimumChangesNeeded,
                    onHint: {
                        let logic = state.currentGameLogic ?? WordChainGameLogic(wordLength: state.currentWordLength)
                        let target = chain.last ?? ""
                        logic.precomputeDistancesToTarget(target)
                        let word = state.currentUserWord
                        let distance = logic.getDistanceToTarget(from: word)
                        hintActiveByLength[state.currentWordLength] = true
                        hintDistanceByLength[state.currentWordLength] = distance
                    },
                    currentDistance: (hintDistanceByLength[state.currentWordLength] ?? -1) == -1 ? nil : hintDistanceByLength[state.currentWordLength],
                    isHintActive: hintActiveByLength[state.currentWordLength] ?? false,
                    bottomRightButton: {
                        AnyView(
                            Button(action: {
                                nextButtonTriggeredSearch = true
                                hintActiveByLength[state.currentWordLength] = false
                                hintDistanceByLength[state.currentWordLength] = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                    state.generateNewPuzzle()
                                }
                            }) {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 28)
                                    .background(Capsule().fill(Color("SlateBlueGrey")))
                                    .overlay(
                                        Capsule().stroke(Color("AshGray"), lineWidth: 1.2)
                                    )
                                    .shadow(color: Color("SlateBlueGrey").opacity(0.10), radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        )
                    },
                    onUndo: { state.undoLastMove() },
                    canUndo: state.canUndo
                )
                .frame(height: 270)
                .padding(.top, 32)
                if !chain.isEmpty {
                    LetterKeyboard(
                        onLetterTap: { letter in
                            if let currentIndex = focusedIndex {
                                var wordArray = Array(state.currentUserWord)
                                if currentIndex < wordArray.count {
                                    wordArray[currentIndex] = letter.first!
                                    let newWord = String(wordArray)
                                    if gameLogic.isValidWord(newWord) {
                                        withAnimation {
                                            state.updateUserWord(newWord)
                                        }
                                    } else {
                                        externalInvalidTriggers[currentIndex] = true
                                        showInvalidMessage = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            withAnimation {
                                                showInvalidMessage = false
                                            }
                                        }
                                        externalInvalidLetters[currentIndex] = letter
                                        Task {
                                            try? await Task.sleep(nanoseconds: 2_500_000_000)
                                            await MainActor.run {
                                                externalInvalidLetters[currentIndex] = nil
                                            }
                                        }
                                    }
                                }
                            }
                        },
                        onDelete: {
                            if let currentIndex = focusedIndex {
                                var wordArray = Array(state.currentUserWord)
                                if currentIndex < wordArray.count {
                                    wordArray[currentIndex] = " "
                                    withAnimation {
                                        state.updateUserWord(String(wordArray))
                                    }
                                }
                            }
                        }
                    )
                    .padding(.top, 48)
                    .padding(.horizontal, 8)
                    .opacity(focusedIndex != nil ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: focusedIndex)
                }
            } else {
                // If the chain is empty, show nothing (or a fallback UI if desired), but do NOT generate a new puzzle automatically
                Color.clear
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 16)
    }

    private var backgroundOverlay: some View {
        Group {
            if let paper = UIImage(named: "PaperTexture") {
                Image(uiImage: paper)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.12)
                    .ignoresSafeArea()
            } else {
                LinearGradient(gradient: Gradient(colors: [Color("SandstoneBeige"), Color("SoftSand").opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
        }
    }

    private func validateWord() {
        let guess = state.currentUserWord.uppercased()
        let target = state.currentChain.last ?? ""
        if state.currentGameLogic?.isValidWord(guess) == true,
           guess == target {
            state.updateUserWord(guess)
        }
    }

    private func makeTile(index: Int, gameLogic: WordChainGameLogic) -> some View {
        EditableLetterTile(
            index: index,
            wordLength: state.currentWordLength,
            userWord: Binding(
                get: { state.currentUserWord },
                set: { state.updateUserWord($0) }
            ),
            focusedIndex: $focusedIndex,
            gameLogic: gameLogic,
            onInvalidEntry: {
                showInvalidMessage = true
            },
            externalInvalidTrigger: Binding(
                get: { externalInvalidTriggers[index] ?? false },
                set: { externalInvalidTriggers[index] = $0 }
            ),
            externalInvalidLetter: Binding(
                get: { externalInvalidLetters[index] ?? nil },
                set: { externalInvalidLetters[index] = $0 }
            )
        )
    }

    private func handleContinueChain() {
        guard let lastWord = state.currentChain.last,
              let gameLogic = state.currentGameLogic else { return }
        let (chain, start, end) = gameLogic.generateChainFromWord(lastWord)
        guard !chain.isEmpty else { return }

        withAnimation {
            state.setCurrentChain(chain, start: start, end: end, gameLogic: gameLogic)
            showCelebrationCard = false
            showMinimumChain = false
        }
    }
} 
