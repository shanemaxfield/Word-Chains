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

                HStack(spacing: 16) {
                    Text("Minimum Changes: \(minimumChanges)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color("C_Charcoal").opacity(0.7))
                    
                    if isHintActive, let distance = currentDistance {
                        Text("Steps to Target: \(distance)")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color("C_WarmTeal"))
                    }
                }
                .padding(.vertical, 4)

                HStack(spacing: 12) {
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
                    
                    if let onHint = onHint, !puzzleCompleted {
                        Button(action: onHint) {
                            Image(systemName: "lightbulb.fill")
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

                HStack(spacing: 2) {
                    Text("Target:")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(Color("C_Charcoal"))
                        .padding(.top, 2)
                    ForEach(Array(targetWord), id: \ .self) { char in
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
} 
 
