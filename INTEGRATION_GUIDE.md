# Integration Guide - New Features

This guide shows you how to integrate the new features into your existing Word Chains app.

## Quick Start - 5 Minute Integration

### Step 1: Update App Entry Point

Replace the existing GameState with EnhancedGameState in `Word_ChainsApp.swift` or your main app file:

```swift
import SwiftUI

@main
struct Word_ChainsApp: App {
    @StateObject private var gameState = EnhancedGameState() // Changed from GameState

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
        }
    }
}
```

### Step 2: Add Achievement Banner to Main View

In your main view (e.g., `ContentView.swift`), add the achievement banner overlay:

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameState: EnhancedGameState

    var body: some View {
        ZStack {
            // Your existing content
            NavigationView {
                PuzzleOfTheDayView()
                    .environmentObject(gameState)
            }

            // NEW: Achievement banner
            if gameState.achievementManager.showAchievementAlert,
               let achievement = gameState.achievementManager.newlyUnlockedAchievement {
                AchievementBanner(
                    achievement: achievement,
                    isShowing: $gameState.achievementManager.showAchievementAlert
                )
            }
        }
        .onAppear {
            // Initialize word data
            WordDataManager.shared.loadData()

            // NEW: Puzzle cache initializes automatically in background
        }
    }
}
```

### Step 3: Update Game Card Usage

Replace GameCardView with EnhancedGameCardView in your game views:

```swift
// BEFORE:
GameCardView(
    tilesCount: tilesCount,
    makeTile: makeTile,
    targetWord: targetWord,
    showReset: true,
    onReset: { /* ... */ },
    // ... other params
)

// AFTER:
EnhancedGameCardView(
    tilesCount: tilesCount,
    makeTile: makeTile,
    targetWord: targetWord,
    showReset: true,
    onReset: { /* ... */ },
    // ... existing params ...

    // NEW: Undo functionality
    onUndo: { gameState.undoLastMove() },
    canUndo: gameState.canUndo
)
```

### Step 4: Add Streak Display to Celebration Card

In `CelebrationCardView.swift`, add the streak display:

```swift
struct CelebrationCardView: View {
    @EnvironmentObject var gameState: EnhancedGameState

    var body: some View {
        VStack(spacing: 20) {
            // Existing celebration content...

            // NEW: Streak display
            StreakDisplay(streakManager: gameState.streakManager)
                .padding(.horizontal, 16)

            // NEW: Share button
            if let shareText = gameState.generateShareableResult() {
                ShareButton(shareText: shareText)
            }

            // Existing buttons...
        }
    }
}
```

## Feature-by-Feature Integration

### Streak System

The streak system automatically tracks completions when you use EnhancedGameState. No additional code needed!

```swift
// Streaks are automatically recorded when puzzles complete
// Access streak data:
gameState.streakManager.currentStreak
gameState.streakManager.longestStreak
gameState.streakManager.totalPuzzlesCompleted
```

### Achievements

Achievements are automatically checked on puzzle completion. Display them:

```swift
// In your main view stack:
if gameState.achievementManager.showAchievementAlert,
   let achievement = gameState.achievementManager.newlyUnlockedAchievement {
    AchievementBanner(
        achievement: achievement,
        isShowing: $gameState.achievementManager.showAchievementAlert
    )
}
```

### Sound & Haptics

Sounds and haptics are automatically played via EnhancedGameState. To manually trigger:

```swift
SoundManager.shared.playSound(.validWord)
SoundManager.shared.playHaptic(.medium)
SoundManager.shared.playSuccessPattern() // For celebrations
```

Disable sounds:
```swift
SoundManager.shared.setEnabled(false)
```

### Undo

Undo is built into EnhancedGameState:

```swift
// In your game card or controls:
Button("Undo") {
    gameState.undoLastMove()
}
.disabled(!gameState.canUndo)
```

### Sharing

Simple one-line integration:

```swift
// Use the ShareButton component:
ShareButton(shareText: gameState.generateShareableResult())

// Or call directly:
ShareManager.shared.shareResults(text: gameState.generateShareableResult())
```

### Enhanced Hints

The improved hint display is built into EnhancedGameCardView. No changes needed!

The hint system now shows:
- 🎯 "Very Close!" for 0-2 steps (green)
- 🟠 "Getting Closer" for 3-5 steps (orange)
- 🔴 "X steps away" for 6+ steps (red)

### Analytics

Analytics events are automatically tracked. To add custom events:

```swift
AnalyticsManager.shared.track(.puzzleStarted(wordLength: 4, mode: "custom"))
```

Available events:
- `appLaunched`, `tutorialStarted`, `tutorialCompleted`
- `puzzleStarted`, `puzzleCompleted`, `puzzleFailed`
- `hintUsed`, `undoUsed`, `shareAttempted`
- `achievementUnlocked`, `streakMilestone`

## Performance Optimizations

### Puzzle Pre-Caching

Automatically active when using EnhancedGameState. The system:
1. Pre-generates 20 puzzles per word length on app launch
2. Refills cache in background when it gets low
3. Uses smart hub-word algorithm for better chains

**No code changes needed!** Just use the existing `gameState.generateNewPuzzle()`.

### Bidirectional BFS

Automatically used in WordChainLogic. **No code changes needed!**

### LRU Cache

Automatically manages memory in WordChainLogic. **No code changes needed!**

### Debounced Persistence

Automatically debounces saves in EnhancedGameState. **No code changes needed!**

To force immediate save (e.g., on app backgrounding):
```swift
.onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
    gameState.forcePersist()
}
```

## Testing Your Integration

### 1. Test Streaks
```swift
// In debug mode, manually test streaks:
#if DEBUG
gameState.streakManager.recordPuzzleCompletion(isPerfect: true)
#endif
```

### 2. Test Achievements
```swift
// Unlock a test achievement:
#if DEBUG
gameState.achievementManager.unlockAchievement(.firstPuzzle)
#endif
```

### 3. Test Undo
1. Make several moves in a puzzle
2. Tap the undo button
3. Verify the word reverts and move counter decrements

### 4. Test Sharing
1. Complete a puzzle
2. Tap the share button
3. Verify the share sheet appears with formatted text

### 5. Test Sounds
1. Tap letters (should hear soft taps)
2. Make a valid word (success sound)
3. Try invalid word (error sound)
4. Complete puzzle (celebration sound + haptic pattern)

## Troubleshooting

### "Cannot find type 'EnhancedGameState'"
Make sure you've added all the new files to your Xcode project target.

### Achievements not appearing
Check that:
1. Achievement banner is in the ZStack of your main view
2. It's checking `gameState.achievementManager.showAchievementAlert`

### Undo button not working
Verify:
1. You're passing `onUndo` and `canUndo` to EnhancedGameCardView
2. The callback is: `onUndo: { gameState.undoLastMove() }`

### Sounds not playing
Check:
1. Device is not in silent mode
2. `SoundManager.shared.isEffectsEnabled()` returns true

### Slow puzzle generation
This should be fixed with pre-caching. If still slow:
1. Check that PuzzleCache is initializing on app launch
2. Verify you're using `EnhancedGameState` (not old `GameState`)

## Migration Checklist

- [ ] Replace GameState with EnhancedGameState
- [ ] Add AchievementBanner to main view ZStack
- [ ] Update GameCardView to EnhancedGameCardView
- [ ] Add undo button parameters (onUndo, canUndo)
- [ ] Add StreakDisplay to celebration card
- [ ] Add ShareButton to celebration card
- [ ] Test all features end-to-end
- [ ] Verify no compilation errors
- [ ] Test on physical device (for haptics)

## Next Steps

After integration:

1. **Test thoroughly** on multiple devices
2. **Monitor analytics** (once connected to backend)
3. **Gather user feedback** on new features
4. **Iterate based on data** and feedback
5. **Consider implementing**:
   - Interactive onboarding
   - Dark mode
   - Accessibility improvements
   - Leaderboards

## Need Help?

- Check RELEASE_NOTES.md for detailed feature documentation
- Review example code in new component files
- All managers have self-contained examples in their comments

---

**Quick Reference**:
- EnhancedGameState: Core game state with all new features
- StreakManager: Streak tracking
- AchievementManager: Achievement system
- SoundManager: Sound effects and haptics
- AnalyticsManager: Event tracking
- ShareManager: Social sharing
- PuzzleCache: Puzzle pre-generation
