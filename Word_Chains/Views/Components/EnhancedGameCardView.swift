import SwiftUI

struct EnhancedGameCardView: View {
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
    let onUndo: (() -> Void)?
    let canUndo: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 8) {
                HStack(spacing: tilesCount == 5 ? 8 : 12) {
                    ForEach(0..<tilesCount, id: \.self) { index in
                        makeTile(index)
                    }
                }
                .padding(.vertical, 8)
                .padding(.bottom, 10)

                Text(showInvalidMessage && invalidMessage != nil ? invalidMessage! : " ")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color("C_SoftCoral"))
                    .multilineTextAlignment(.center)
                    .opacity(showInvalidMessage && invalidMessage != nil ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: showInvalidMessage)
                    .padding(.top, 2)

                // Enhanced hint display
                HStack(spacing: 16) {
                    Text("Minimum Changes: \(minimumChanges)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color("C_Charcoal").opacity(0.7))

                    if isHintActive, let distance = currentDistance {
                        HStack(spacing: 4) {
                            Text(distanceText(distance))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(distanceColor(distance))

                            Image(systemName: distanceIcon(distance))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(distanceColor(distance))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(distanceColor(distance).opacity(0.15))
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.vertical, 4)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHintActive)

                // Control buttons
                HStack(spacing: 12) {
                    // Undo button
                    if let onUndo = onUndo, !puzzleCompleted {
                        Button(action: onUndo) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(canUndo ? Color("C_PureWhite") : Color("C_Charcoal").opacity(0.3))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 28)
                                .background(Capsule().fill(canUndo ? Color("SlateBlueGrey") : Color("DustyGray")))
                                .overlay(
                                    Capsule().stroke(canUndo ? Color("SlateBlueGrey").opacity(0.7) : Color("DustyGray").opacity(0.5), lineWidth: 1.2)
                                )
                                .shadow(color: canUndo ? Color("SlateBlueGrey").opacity(0.10) : Color.clear, radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!canUndo)
                    }

                    // Reset button
                    if showReset, let onReset = onReset, !puzzleCompleted {
                        Button(action: onReset) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Color("C_PureWhite"))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 28)
                                .background(Capsule().fill(Color("C_SoftCoral")))
                                .overlay(
                                    Capsule().stroke(Color("C_SoftCoral").opacity(0.7), lineWidth: 1.2)
                                )
                                .shadow(color: Color("C_SoftCoral").opacity(0.10), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // Hint button
                    if let onHint = onHint, !puzzleCompleted {
                        Button(action: onHint) {
                            Image(systemName: isHintActive ? "lightbulb.fill" : "lightbulb")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Color("C_PureWhite"))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 28)
                                .background(Capsule().fill(Color("C_WarmTeal")))
                                .overlay(
                                    Capsule().stroke(Color("C_WarmTeal").opacity(0.7), lineWidth: 1.2)
                                )
                                .shadow(color: Color("C_WarmTeal").opacity(0.10), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // Target display
                HStack(spacing: 2) {
                    Text("Target:")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(Color("C_Charcoal"))
                        .padding(.top, 2)
                    ForEach(Array(targetWord), id: \.self) { char in
                        Text(String(char))
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("C_Charcoal"))
                    }
                }

                if showSuccess {
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color.green)
                            .transition(.scale)
                        Text(successMessage ?? "Puzzle Solved!")
                            .font(.headline)
                            .foregroundColor(Color.green)
                        if let onSuccessAction = onSuccessAction, let label = successActionLabel {
                            Button(label, action: onSuccessAction)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 24)
                                .background(Capsule().fill(Color("SlateBlueGrey")))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity)
                }

                Spacer(minLength: 0)
            }
            .frame(height:270)
            .padding(.vertical, 24)
            .padding(.horizontal, tilesCount == 5 ? 8 : 24)
            .background(cardColor.opacity(0.98))
            .cornerRadius(24)
            .shadow(color: Color("C_Charcoal").opacity(0.07), radius: 16, x: 0, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color("C_Charcoal").opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 8)

            if let bottomRightButton = bottomRightButton {
                bottomRightButton()
                    .padding(.trailing, 16)
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Hint Display Helpers
    private func distanceText(_ distance: Int) -> String {
        switch distance {
        case 0: return "🎯 Solved!"
        case 1: return "🔥 1 Step Away!"
        case 2...3: return "🎯 Very Close!"
        case 4...6: return "📍 Getting Closer"
        default: return "🧭 \(distance) steps away"
        }
    }

    private func distanceColor(_ distance: Int) -> Color {
        switch distance {
        case 0...2: return .green
        case 3...5: return .orange
        default: return Color("C_SoftCoral")
        }
    }

    private func distanceIcon(_ distance: Int) -> String {
        switch distance {
        case 0: return "checkmark.circle.fill"
        case 1...3: return "flame.fill"
        case 4...6: return "target"
        default: return "location.fill"
        }
    }
}
