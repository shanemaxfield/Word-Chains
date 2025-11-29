import SwiftUI

struct AchievementBanner: View {
    let achievement: Achievement
    @Binding var isShowing: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Image(systemName: achievement.icon)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(achievement.color)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Achievement Unlocked!")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color("C_Charcoal").opacity(0.7))

                    Text(achievement.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color("C_Charcoal"))

                    Text(achievement.description)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color("C_Charcoal").opacity(0.8))
                        .lineLimit(2)
                }

                Spacer()

                Button(action: {
                    withAnimation {
                        isShowing = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("C_Charcoal").opacity(0.5))
                        .padding(8)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("C_PureWhite"))
                    .shadow(color: achievement.color.opacity(0.3), radius: 16, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(achievement.color.opacity(0.5), lineWidth: 2)
            )
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.top, 60)
        .transition(.move(edge: .top).combined(with: .opacity))
        .zIndex(1000)
        .onAppear {
            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    isShowing = false
                }
            }
        }
    }
}

struct StreakDisplay: View {
    @ObservedObject var streakManager: StreakManager

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(streakManager.getStreakEmoji())
                        .font(.system(size: 24))

                    Text("\(streakManager.currentStreak)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color("C_WarmTeal"))
                }

                Text("Day Streak")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color("C_Charcoal").opacity(0.7))

                if streakManager.currentStreak > 0 {
                    Text(streakManager.getStreakMessage())
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color("C_WarmTeal"))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                statBubble(
                    value: "\(streakManager.longestStreak)",
                    label: "Best",
                    color: Color("BlueGreenDeep")
                )

                statBubble(
                    value: "\(streakManager.totalPuzzlesCompleted)",
                    label: "Solved",
                    color: Color("C_SoftCoral")
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("C_PureWhite"))
                .shadow(color: Color("C_Charcoal").opacity(0.05), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("C_Charcoal").opacity(0.08), lineWidth: 1)
        )
    }

    private func statBubble(value: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Color("C_Charcoal").opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}
