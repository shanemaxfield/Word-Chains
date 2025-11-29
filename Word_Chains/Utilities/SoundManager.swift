import AVFoundation
import UIKit

enum SoundEffect {
    case letterTap
    case validWord
    case invalidWord
    case puzzleComplete
    case achievement
    case streakMilestone
}

class SoundManager {
    static let shared = SoundManager()

    private var audioPlayers: [SoundEffect: AVAudioPlayer] = [:]
    private var isEnabled: Bool = true

    private init() {
        setupAudioSession()
        // Note: Sound files would be added to the project
        // For now, we'll use system sounds
    }

    func playSound(_ effect: SoundEffect) {
        guard isEnabled else { return }

        // Use system sounds for now
        switch effect {
        case .letterTap:
            playSystemSound(1104) // Tock
        case .validWord:
            playSystemSound(1103) // Keyboard tap
        case .invalidWord:
            playSystemSound(1053) // Shake
        case .puzzleComplete:
            playSystemSound(1114) // Anticipate
        case .achievement:
            playSystemSound(1111) // Success
        case .streakMilestone:
            playSystemSound(1113) // Fanfare
        }
    }

    func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isEnabled else { return }

        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    func playNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    func playSuccessPattern() {
        guard isEnabled else { return }

        // Play a series of haptics for puzzle completion
        playHaptic(.light)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playHaptic(.medium)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.playHaptic(.heavy)
        }
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "sound_enabled")
    }

    func isEffectsEnabled() -> Bool {
        return isEnabled
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }

        // Load saved preference
        isEnabled = UserDefaults.standard.object(forKey: "sound_enabled") as? Bool ?? true
    }

    private func playSystemSound(_ soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }
}
