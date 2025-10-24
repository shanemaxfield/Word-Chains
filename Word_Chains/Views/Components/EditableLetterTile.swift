import SwiftUI
import UIKit

// MARK: - EditableLetterTile View
struct EditableLetterTile: View {
    // MARK: - Properties
    let index: Int
    let wordLength: Int
    @Binding var userWord: String
    @Binding var focusedIndex: Int?
    var gameLogic: WordChainGameLogic
    var onInvalidEntry: (() -> Void)?
    var externalInvalidTrigger: Binding<Bool>
    @Binding var externalInvalidLetter: String?
    
    // MARK: - State
    @State private var localText: String = ""
    @State private var isInvalid: Bool = false
    @State private var pendingInvalidLetter: String? = nil
    @State private var isAnimatingInvalid: Bool = false
    @State private var previousValidLetter: String = ""
    @State private var invalidLetterBounce: Bool = false
    
    // MARK: - Computed Properties
    private var isFocused: Bool { focusedIndex == index }
    
    private var tileSize: CGFloat {
        ResponsiveSizing.tileSize(for: wordLength)
    }
    
    private var tilePadding: CGFloat {
        ResponsiveSizing.adaptiveTilePadding(for: wordLength)
    }
    
    private var cornerRadius: CGFloat {
        ResponsiveSizing.cornerRadius(baseRadius: 20)
    }
    
    private var fontSize: CGFloat {
        ResponsiveSizing.fontSize(baseSize: 36)
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            tileBackground
            letterDisplay
        }
        .frame(width: tileSize, height: tileSize)
        .contentShape(Rectangle()) // defines hitbox
        .overlay(
            Rectangle()
                .fill(Color.clear)
                .frame(width: 10, height: 10)
                .allowsHitTesting(true)
        )
        .padding(tilePadding) // dynamic spacing between tiles based on word length
        .onTapGesture {
            focusedIndex = index
            Haptics.soft()
        }
        .animation(.easeInOut(duration: 0.18), value: isFocused)
        .onAppear { updateLocalText() }
        .onChange(of: externalInvalidLetter) { handleExternalInvalidLetter($0) }
        .onChange(of: userWord) { _ in handleUserWordChange() }
    }
    
    // MARK: - View Components
    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(SemanticColors.backgroundMain)
            .shadow(
                color: isFocused ? SemanticColors.accentPrimary.opacity(0.2) : SemanticColors.textPrimary.opacity(0.05),
                radius: isFocused ? ResponsiveSizing.spacing(baseSpacing: 12) : ResponsiveSizing.spacing(baseSpacing: 6),
                x: 0,
                y: isFocused ? ResponsiveSizing.spacing(baseSpacing: 4) : ResponsiveSizing.spacing(baseSpacing: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        isFocused ? SemanticColors.accentPrimary : SemanticColors.textSecondary,
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }
    
    private var letterDisplay: some View {
        Text(localText.isEmpty ? " " : localText)
            .responsiveFont(size: 36, weight: .bold, design: .rounded)
            .foregroundColor(isInvalid ? SemanticColors.error : SemanticColors.textTile)
            .scaleEffect(isInvalid && invalidLetterBounce ? 0.82 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.45), value: isInvalid && invalidLetterBounce)
            .frame(width: tileSize, height: tileSize)
            .multilineTextAlignment(.center)
            .scaleEffect(isFocused ? 1.08 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isFocused)
    }
    
    // MARK: - Private Methods
    private func updateLocalText() {
        let letters = Array(userWord)
        if index < letters.count {
            localText = String(letters[index])
            previousValidLetter = String(letters[index])
        } else {
            localText = ""
            previousValidLetter = ""
        }
    }
    
    private func handleExternalInvalidLetter(_ newValue: String?) {
        guard let invalidLetter = newValue else { return }
        handleInvalidEntry(invalidLetter)
    }
    
    private func handleUserWordChange() {
        if !isAnimatingInvalid {
            updateLocalText()
            let letters = Array(userWord)
            if index < letters.count {
                previousValidLetter = String(letters[index])
            } else {
                previousValidLetter = ""
            }
        }
    }
    
    private func handleInvalidEntry(_ invalidLetter: String) {
        onInvalidEntry?()
        isAnimatingInvalid = true
        localText = invalidLetter
        pendingInvalidLetter = invalidLetter
        isInvalid = true
        invalidLetterBounce = true
        
        withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) {
            invalidLetterBounce = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isInvalid = false
                pendingInvalidLetter = nil
                isAnimatingInvalid = false
                localText = previousValidLetter
                invalidLetterBounce = false
            }
        }
    }
}

// MARK: - Haptics Helper
struct Haptics {
    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
}
