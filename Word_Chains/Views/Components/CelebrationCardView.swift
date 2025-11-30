import SwiftUI

struct FixedWidthContainer<Content: View>: View {
    let content: Content
    let width: CGFloat
    let showCardBackground: Bool
    let showBorder: Bool
    let backgroundColor: Color
    let horizontalPadding: CGFloat

    init(width: CGFloat = 280,
         showCardBackground: Bool = true,
         showBorder: Bool = false,
         backgroundColor: Color = Color("C_PureWhite"),
         horizontalPadding: CGFloat = 12,
         @ViewBuilder content: () -> Content) {
        self.width = width
        self.showCardBackground = showCardBackground
        self.showBorder = showBorder
        self.backgroundColor = backgroundColor
        self.horizontalPadding = horizontalPadding
        self.content = content()
    }

    var body: some View {
        content
            .padding(.vertical, 6)
            .padding(.horizontal, horizontalPadding)
            .background(
                showCardBackground ?
                    RoundedRectangle(cornerRadius: 16)
                        .fill(backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(showBorder ? Color("C_Charcoal") : Color.clear, lineWidth: 5.2)
                        )
                        .shadow(color: Color("C_Charcoal").opacity(0.05), radius: 8, x: 0, y: 4)
                : nil
            )
            .frame(width: width)
    }
}

struct CelebrationCardView: View {
    var onRetry: () -> Void
    var onShowMinimum: () -> Void
    var onNext: (() -> Void)?
    var onFreeRoam: (() -> Void)?
    var onContinueChain: (() -> Void)?
    var changesMade: Int
    var minimumChanges: Int
    var showFreeRoamButton: Bool
    var showMinimumChain: Bool
    var minimumChain: [String]
    var minimumChainGroups: [[String]]? = nil
    var onWordLengthChange: ((Int) -> Void)? = nil
    var currentWordLength: Int = 4
    var streakManager: StreakManager? = nil
    var shareText: String? = nil
    @State private var selectedChainIndex: Int = 0
    @Namespace private var morphNamespace
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack(alignment: .topLeading) {
                if showMinimumChain {
                    Button(action: onShowMinimum) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color("C_Charcoal"))
                            .padding(16)
                            .contentShape(Rectangle())
                    }
                    .zIndex(2)
                }
                VStack(spacing: 20) {
            if !(showMinimumChain && minimumChainGroups != nil && !(minimumChainGroups?.isEmpty ?? true)) {
                VStack(spacing: 8) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(Color("C_WarmTeal"))
                    Text("🎉 Puzzle Complete!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color("C_Charcoal"))
                }
                .padding(.top, 16)
                .padding(.vertical, 4)
            }
            if !(showMinimumChain && minimumChainGroups != nil && !(minimumChainGroups?.isEmpty ?? true)) {
                FixedWidthContainer {
                    VStack(spacing: 12) {
                        Text("Changes Made: \(changesMade)")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(Color("C_Charcoal"))
                        Text("Minimum Possible: \(minimumChanges)")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(Color("C_Charcoal"))
                    }
                }

                // Streak display (if provided)
                if let streak = streakManager {
                    HStack(spacing: 8) {
                        Text(streak.getStreakEmoji())
                            .font(.system(size: 20))
                        Text("\(streak.currentStreak) Day Streak!")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color("C_WarmTeal"))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        Capsule()
                            .fill(Color("C_WarmTeal").opacity(0.1))
                    )
                }

                // Share button (if provided)
                if let text = shareText {
                    ShareButton(shareText: text, label: "Share Result", icon: "square.and.arrow.up")
                        .padding(.horizontal, 16)
                }
            }
                    // Morphing Button <-> Minimum Chain Display
                    Group {
                        if !showMinimumChain {
                            HStack(spacing: 12) {
                                Button(action: onRetry) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 28)
                                        .background(Capsule().fill(Color("C_WarmTeal")))
                    .overlay(
                                            Capsule().stroke(Color("C_WarmTeal"), lineWidth: 1.2)
                                        )
                                        .shadow(color: Color("C_WarmTeal").opacity(0.10), radius: 4, x: 0, y: 2)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                        onShowMinimum()
                                    }
                                }) {
                            HStack(spacing: 8) {
                                        Image(systemName: "list.bullet")
                                    .font(.system(size: 16, weight: .medium))
                                        Text("Show Minimum")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(Color("C_PureWhite"))
                            .padding(.vertical, 12)
                                    .frame(width: 196)
                                        .background(
                                            Capsule()
                                                .fill(Color("BlueGreenDeep"))
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(Color("BlueGreenDeep"), lineWidth: 1.2)
                                        )
                                        .shadow(color: Color("BlueGreenDeep").opacity(0.15), radius: 8, x: 0, y: 4)
                                    .matchedGeometryEffect(id: "showMinimumMorph", in: morphNamespace)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        } else if let groups = minimumChainGroups, !groups.isEmpty {
                            HStack {
                                Spacer()
                                TabView(selection: $selectedChainIndex) {
                                    ForEach(groups.indices, id: \.self) { idx in
                                        FixedWidthContainer(
                                            width: 406.4,
                                            showCardBackground: true,
                                            showBorder: true,
                                            backgroundColor: Color("BlueGreenDeep"),
                                            horizontalPadding: 0
                                        ) {
                                            let chain = groups[idx]
                                            Group {
                                                if chain.count > 7 {
                                                    ScrollView {
                                                        VStack(spacing: 8) {
                                                            Text("Chain #\(idx + 1)")
                                                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                                                .foregroundColor(Color("C_PureWhite").opacity(0.9))
                                                            ForEach(chain.indices, id: \.self) { i in
                                                                Text(chain[i])
                                                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                                                    .foregroundColor(Color("C_PureWhite"))
                                                                if i < chain.count - 1 {
                                                                    Image(systemName: "arrow.down")
                                                                        .font(.system(size: 10, weight: .medium))
                                                                        .foregroundColor(Color("C_PureWhite").opacity(0.6))
                                                                }
                                                            }
                                                        }
                                                        .padding(.vertical, 12)
                                                        .padding(.horizontal, 12)
                                                    }
                                                } else {
                                                    VStack(spacing: 8) {
                                                        Text("Chain #\(idx + 1)")
                                                            .font(.system(size: 32, weight: .bold, design: .rounded))
                                                            .foregroundColor(Color("C_PureWhite").opacity(0.9))
                                                        VStack(spacing: 6) {
                                                            ForEach(chain.indices, id: \.self) { i in
                                                                Text(chain[i])
                                                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                                                    .foregroundColor(Color("C_PureWhite"))
                                                                if i < chain.count - 1 {
                                                                    Image(systemName: "arrow.down")
                                                                        .font(.system(size: 10, weight: .medium))
                                                                        .foregroundColor(Color("C_PureWhite").opacity(0.6))
                                                                }
                                                            }
                                                        }
                                                    }
                                                    .padding(.vertical, 12)
                                                    .padding(.horizontal, 12)
                                                }
                                            }
                                        }
                                        .padding(.vertical, 6)
                                        .tag(idx)
                                    }
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                                .frame(width: 196)
                                .matchedGeometryEffect(id: "showMinimumMorph", in: morphNamespace)
                                Spacer()
                            }
                        }
                    }
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: showMinimumChain)
                    if !(showMinimumChain && minimumChainGroups != nil && !(minimumChainGroups?.isEmpty ?? true)) {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                if let onWordLengthChange = onWordLengthChange {
                                    ForEach([3, 4, 5].filter { $0 != currentWordLength }, id: \.self) { length in
                                        Button(action: { onWordLengthChange(length) }) {
                                            Text("\(length) Letter")
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                .foregroundColor(Color("C_PureWhite"))
                                                .padding(.vertical, 12)
                                                .padding(.horizontal, 20)
                                                .background(
                                                    Capsule()
                                                        .fill(Color("BlueGreenDeep"))
                                                )
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color("BlueGreenDeep"), lineWidth: 1.2)
                                                )
                                                .shadow(color: Color("BlueGreenDeep").opacity(0.15), radius: 8, x: 0, y: 4)
                                        }
                                    }
                                }
                                
                                if showFreeRoamButton {
                                    if let onContinueChain = onContinueChain {
                                        Button(action: onContinueChain) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "arrow.triangle.2.circlepath")
                                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                                Text("Continue")
                                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            }
                                            .foregroundColor(.white)
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 20)
                                            .background(Capsule().fill(Color("C_WarmTeal")))
                                            .overlay(
                                                Capsule().stroke(Color("C_WarmTeal"), lineWidth: 1.2)
                                            )
                                            .shadow(color: Color("C_WarmTeal").opacity(0.10), radius: 4, x: 0, y: 2)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    if let onFreeRoam = onFreeRoam {
                                        Button(action: onFreeRoam) {
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 28)
                                                .background(Capsule().fill(Color("BlueGreenDeep")))
                                                .overlay(
                                                    Capsule().stroke(Color("BlueGreenDeep"), lineWidth: 1.2)
                                                )
                                                .shadow(color: Color("BlueGreenDeep").opacity(0.10), radius: 4, x: 0, y: 2)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                if let onNext = onNext {
                                    Button(action: onNext) {
                                        HStack(spacing: 8) {
                                            Text("New")
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                        }
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
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 280)
        .frame(minHeight: 420)
        .padding(.horizontal, 32)
        .padding(.vertical, 36)
        .background(Color("C_PureWhite"))
        .cornerRadius(32)
        .shadow(color: Color("C_Charcoal").opacity(0.08), radius: 24, x: 0, y: 12)
        .frame(width: 280, height: 420)
    }
}
