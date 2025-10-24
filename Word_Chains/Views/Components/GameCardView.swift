import SwiftUI

struct GameCardView: View {
    let tilesCount: Int
    let makeTile: (Int) -> AnyView
    let targetWord: String
    let showReset: Bool
    let onReset: (() -> Void)?
    let showFreeRoam: Bool
    let onFreeRoam: (() -> Void)?
    let cardColor: Color
    let puzzleCompleted: Bool
    let invalidMessage: String?
    let showInvalidMessage: Bool
    let showSuccess: Bool
    let successMessage: String?
    let onSuccessAction: (() -> Void)?
    let successActionLabel: String?
    let minimumChanges: Int
    let onHint: (() -> Void)?
    let currentDistance: Int?
    let isHintActive: Bool
    let bottomRightButton: (() -> AnyView)?
    let shouldAnimateTarget: Bool

    // Responsive constants
    private var buttonFontSize: CGFloat { 16 }
    private var buttonWidth: CGFloat { 70 }
    private var buttonHeight: CGFloat { 40 }
    private var cardCornerRadius: CGFloat { 24 }
    private var cardShadowRadius: CGFloat { 16 }
    private var cardPaddingV: CGFloat { 24 }
    private var cardPaddingH: CGFloat { tilesCount == 5 ? 8 : 24 }
    private var cardOverlayCornerRadius: CGFloat { 24 }
    private var cardOverlayLineWidth: CGFloat { 1 }
    private var cardOverlayOpacity: Double { 0.08 }
    private var cardShadowOpacity: Double { 0.07 }
    private var cardShadowY: CGFloat { 6 }
    private var cardFrameHeight: CGFloat { 270 }
    private var cardInnerSpacing: CGFloat { 8 }
    private var tileRowSpacing: CGFloat { tilesCount == 5 ? 8 : 12 }
    private var tileRowHeight: CGFloat { 64 }
    private var minChangesFontSize: CGFloat { 16 }
    private var targetFontSize: CGFloat { 22 }
    private var invalidFontSize: CGFloat { 14 }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: ResponsiveSizing.spacing(baseSpacing: cardInnerSpacing)) {
                Spacer().frame(height: ResponsiveSizing.spacing(baseSpacing: 26))
                HStack(spacing: ResponsiveSizing.spacing(baseSpacing: tileRowSpacing)) {
                    ForEach(0..<tilesCount, id: \.self) { index in
                        makeTile(index)
                    }
                }
                .responsivePadding(.vertical, 8)
                .responsivePadding(.bottom, 10)
                .frame(height: ResponsiveSizing.tileSize(for: 4))

                Spacer().frame(height: ResponsiveSizing.spacing(baseSpacing: 8))

                Text(showInvalidMessage && invalidMessage != nil ? invalidMessage! : " ")
                    .responsiveFont(size: invalidFontSize, weight: .medium, design: .rounded)
                    .foregroundColor(SemanticColors.error)
                    .multilineTextAlignment(.center)
                    .opacity(showInvalidMessage && invalidMessage != nil ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: showInvalidMessage)

                Spacer().frame(height: ResponsiveSizing.spacing(baseSpacing: 4))

                HStack(spacing: ResponsiveSizing.spacing(baseSpacing: 16)) {
                    Text("Minimum Changes: \(minimumChanges)")
                        .responsiveFont(size: minChangesFontSize, weight: .medium, design: .rounded)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.textPrimary.opacity(0.5))
                    
                    if isHintActive, let distance = currentDistance {
                        Text("Steps to Target: \(distance)")
                            .responsiveFont(size: minChangesFontSize, weight: .medium, design: .rounded)
                            .foregroundColor(SemanticColors.accentPrimary)
                    }
                }
                .responsivePadding(.vertical, 4)
                .frame(height: ResponsiveSizing.spacing(baseSpacing: 24))

                HStack(spacing: ResponsiveSizing.spacing(baseSpacing: 12)) {
                    if showReset, let onReset = onReset, !puzzleCompleted {
                        Button(action: onReset) {
                            Image(systemName: "arrow.counterclockwise")
                                .responsiveFont(size: buttonFontSize, weight: .bold, design: .rounded)
                                .foregroundColor(SemanticColors.backgroundMain)
                                .responsiveFrame(width: buttonWidth, height: buttonHeight)
                                .background(Capsule().fill(SemanticColors.error))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .clipShape(Capsule())
                        .shadow(color: SemanticColors.error.opacity(0.10), radius: ResponsiveSizing.spacing(baseSpacing: 4), x: 0, y: ResponsiveSizing.spacing(baseSpacing: 2))
                    }
                    
                    if let onHint = onHint, !puzzleCompleted {
                        Button(action: onHint) {
                            Image(systemName: "lightbulb.fill")
                                .responsiveFont(size: buttonFontSize, weight: .bold, design: .rounded)
                                .foregroundColor(SemanticColors.backgroundMain)
                                .responsiveFrame(width: buttonWidth, height: buttonHeight)
                                .background(Capsule().fill(SemanticColors.accentPrimary))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .clipShape(Capsule())
                        .shadow(color: SemanticColors.accentPrimary.opacity(0.10), radius: ResponsiveSizing.spacing(baseSpacing: 4), x: 0, y: ResponsiveSizing.spacing(baseSpacing: 2))
                    }
                    
                    if let bottomRightButton = bottomRightButton {
                        bottomRightButton()
                            .responsiveFrame(width: buttonWidth, height: buttonHeight)
                            .background(Capsule().fill(SemanticColors.accentTertiary))
                            .clipShape(Capsule())
                            .shadow(color: SemanticColors.accentTertiary.opacity(0.10), radius: ResponsiveSizing.spacing(baseSpacing: 4), x: 0, y: ResponsiveSizing.spacing(baseSpacing: 2))
                    }
                }
                .frame(height: ResponsiveSizing.spacing(baseSpacing: 40))
                .responsivePadding(.top, 5)
                .responsivePadding(.bottom, -8)

                // Target word display
                HStack(spacing: ResponsiveSizing.spacing(baseSpacing: 8)) {
                    Text("Target:")
                        .responsiveFont(size: targetFontSize, weight: .semibold, design: .rounded)
                        .foregroundColor(SemanticColors.textPrimary)
                    AnyView(
                        Text(targetWord)
                            .responsiveFont(size: targetFontSize, weight: .semibold, design: .rounded)
                            .foregroundColor(SemanticColors.textPrimary)
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.4).combined(with: .opacity),
                        removal: .scale(scale: 1.8).combined(with: .opacity)
                    ))
                    .id(targetWord) // Force view recreation when target word changes
                }
                .responsivePadding(.vertical, 12)
                .responsivePadding(.horizontal, 24)
                .animation(shouldAnimateTarget ? .spring(response: 0.6, dampingFraction: 0.4) : nil, value: targetWord)

                Spacer(minLength: 0)
            }
            .responsiveFrame(height: cardFrameHeight)
            .responsivePadding(.vertical, cardPaddingV)
            .responsivePadding(.horizontal, cardPaddingH)
            .background(cardColor.opacity(0.98))
            .cornerRadius(cardCornerRadius)
            .shadow(color: SemanticColors.textPrimary.opacity(cardShadowOpacity), radius: ResponsiveSizing.spacing(baseSpacing: cardShadowRadius), x: 0, y: cardShadowY)
            .overlay(
                RoundedRectangle(cornerRadius: cardOverlayCornerRadius)
                    .stroke(SemanticColors.textPrimary.opacity(cardOverlayOpacity), lineWidth: cardOverlayLineWidth)
            )
            .responsivePadding(.horizontal, 8)
        }
    }
} 
 
