import SwiftUI

struct LetterKeyboard: View {
    let onLetterTap: (String) -> Void
    let onDelete: () -> Void
    
    private let letters = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]
    
    // MARK: - Computed Properties
    private var keySize: CGSize {
        ResponsiveSizing.keyboardKeySize()
    }
    
    private var keySpacing: CGFloat {
        ResponsiveSizing.adaptiveKeyboardSpacing()
    }
    
    private var rowSpacing: CGFloat {
        ResponsiveSizing.spacing(baseSpacing: 8)
    }
    
    private var keyboardPadding: CGFloat {
        ResponsiveSizing.adaptiveKeyboardPadding()
    }
    
    private var cornerRadius: CGFloat {
        ResponsiveSizing.cornerRadius(baseRadius: 12)
    }
    
    private var keyboardCornerRadius: CGFloat {
        ResponsiveSizing.cornerRadius(baseRadius: 20)
    }
    
    var body: some View {
        VStack(spacing: rowSpacing) {
            ForEach(letters, id: \.self) { row in
                HStack(spacing: keySpacing) {
                    ForEach(row, id: \.self) { letter in
                        Button(action: {
                            Haptics.soft()
                            onLetterTap(letter)
                        }) {
                            Text(letter)
                                .responsiveFont(size: 24, weight: .medium, design: .rounded)
                                .frame(width: keySize.width, height: keySize.height)
                                .background(
                                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                        .fill(Color("SoftSand"))
                                        .shadow(color: Color(.black).opacity(0.05), radius: ResponsiveSizing.spacing(baseSpacing: 2), x: 0, y: ResponsiveSizing.spacing(baseSpacing: 1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                        .stroke(Color("AshGray").opacity(0.3), lineWidth: 1)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.2),
                                                    Color.white.opacity(0.05)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .responsivePadding(.horizontal, 8)
        .responsivePadding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: keyboardCornerRadius, style: .continuous)
                .fill(Color("SandstoneBeige").opacity(0.95))
                .shadow(color: Color("AshGray").opacity(0.1), radius: ResponsiveSizing.spacing(baseSpacing: 8), x: 0, y: ResponsiveSizing.spacing(baseSpacing: 4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: keyboardCornerRadius, style: .continuous)
                .stroke(Color("AshGray").opacity(0.15), lineWidth: 1)
        )
    }
} 
