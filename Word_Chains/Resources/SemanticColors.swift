// SemanticColors.swift
// Defines semantic color roles for the app UI
//
// Reference Table:
// | Semantic Name         | Asset Name         | Usage Example                        |
// |----------------------|-------------------|--------------------------------------|
// | backgroundMain       | C_PureWhite       | Card backgrounds, overlays           |
// | backgroundSoft       | C_SoftCream       | Gradient backgrounds                 |
// | backgroundPaper      | SandstoneBeige    | Main app background                  |
// | backgroundKeyboard   | SoftSand          | Keyboard, secondary surfaces         |
// | textPrimary          | C_Charcoal        | Main text, headings                  |
// | textSecondary        | DustyGray         | Secondary text, borders              |
// | textTile             | MutedNavy         | Letter tile text                     |
// | accentPrimary        | C_WarmTeal        | Primary actions, focus, success      |
// | accentSecondary      | BlueGreenDeep     | Primary actions, celebration         |
// | accentTertiary       | SlateBlueGrey     | Secondary buttons, navigation        |
// | error                | C_SoftCoral       | Errors, invalid input, reset         |
// | border               | AshGray           | Borders, dividers                    |
// | confetti1            | SeaFoam           | Confetti, celebration                |
// | confetti2            | C_SoftCoral       | Confetti, celebration                |
// | confetti3            | Yellow            | Confetti, celebration                |

import SwiftUI

// MARK: - Semantic Colors
struct SemanticColors {
    // MARK: - Primary Colors
    static let accentPrimary = Color("C_WarmTeal")
    static let accentSecondary = Color("BlueGreenDeep")
    static let accentTertiary = Color("SlateBlueGrey")
    
    // MARK: - Background Colors
    static let backgroundMain = Color("C_PureWhite")
    static let backgroundSecondary = Color("SandstoneBeige")
    static let backgroundTertiary = Color("SoftSand")
    
    // MARK: - Text Colors
    static let textPrimary = Color("C_Charcoal")
    static let textSecondary = Color("AshGray")
    static let textTile = Color("C_Charcoal")
    static let textInverted = Color("C_PureWhite")
    
    // MARK: - Status Colors
    static let success = Color("C_WarmTeal")
    static let error = Color("C_SoftCoral")
    static let warning = Color("TerracottaClay")
    
    // MARK: - Interactive Colors
    static let buttonPrimary = Color("C_WarmTeal")
    static let buttonSecondary = Color("BlueGreenDeep")
    static let buttonDisabled = Color("DustyGray")
}

// MARK: - Responsive Sizing System
struct ResponsiveSizing {
    // MARK: - Screen Size Detection
    static let screenWidth = UIScreen.main.bounds.width
    static let screenHeight = UIScreen.main.bounds.height
    
    // MARK: - Device Type Detection
    static var isCompact: Bool {
        screenWidth < 375 // iPhone SE, mini
    }
    
    static var isStandard: Bool {
        screenWidth >= 375 && screenWidth < 428 // iPhone 12/13/14, etc.
    }
    
    static var isLarge: Bool {
        screenWidth >= 428 && !isIPad // iPhone 14 Plus, Pro Max, etc.
    }
    
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // iPad tiers
    static var isIPadMini: Bool {
        isIPad && screenWidth <= 750
    }
    
    static var isIPadStandard: Bool {
        isIPad && screenWidth > 750 && screenWidth < 900
    }
    
    static var isIPadLarge: Bool {
        isIPad && screenWidth >= 900
    }
    
    // MARK: - Responsive Scaling Factors
    static var scaleFactor: CGFloat {
        if isIPadLarge {
            return 1.4
        } else if isIPadStandard {
            return 1.33
        } else if isIPadMini {
            return 1.4 // extremely large on iPad Mini
        } else if isIPad {
            return 1.3
        } else if isLarge {
            return 1.15
        } else if isStandard {
            return 1.0
        } else {
            return 0.85 // Compact
        }
    }
    
    // MARK: - Keyboard-Specific Scaling
    static var keyboardScaleBoost: CGFloat {
        if isIPadLarge {
            return 1.18
        } else if isIPadStandard {
            return 1.15
        } else if isIPadMini {
            return 1.1 // extremely large keyboard on iPad Mini
        } else if isIPad {
            return 1.5
        } else {
            return 0.92
        }
    }
    
    // MARK: - Dynamic Sizing Functions
    static func tileSize(for wordLength: Int) -> CGFloat {
        let baseSize: CGFloat = 64
        let adjustedSize = baseSize * scaleFactor
        if isIPadLarge {
            return max(64, adjustedSize)
        } else if isIPadStandard {
            return max(60, adjustedSize)
        } else if isIPadMini {
            return max(56, adjustedSize)
        } else {
            return max(48, adjustedSize)
        }
    }
    
    static func keyboardKeySize() -> CGSize {
        let baseWidth: CGFloat = 32
        let baseHeight: CGFloat = 56
        let adjustedWidth = baseWidth * scaleFactor * keyboardScaleBoost
        let adjustedHeight = baseHeight * scaleFactor * keyboardScaleBoost
        if isIPadLarge {
            return CGSize(
                width: max(32, adjustedWidth),
                height: max(56, adjustedHeight)
            )
        } else if isIPadStandard {
            return CGSize(
                width: max(30, adjustedWidth),
                height: max(52, adjustedHeight)
            )
        } else if isIPadMini {
            return CGSize(
                width: max(28, adjustedWidth),
                height: max(48, adjustedHeight)
            )
        } else {
            return CGSize(
                width: max(28, adjustedWidth),
                height: max(48, adjustedHeight)
            )
        }
    }
    
    static func fontSize(baseSize: CGFloat) -> CGFloat {
        return baseSize * scaleFactor
    }
    
    static func spacing(baseSpacing: CGFloat) -> CGFloat {
        return baseSpacing * scaleFactor
    }
    
    static func padding(basePadding: CGFloat) -> CGFloat {
        return basePadding * scaleFactor
    }
    
    static func cornerRadius(baseRadius: CGFloat) -> CGFloat {
        return baseRadius * scaleFactor
    }
    
    // MARK: - Layout Constraints
    static var maxTileSpacing: CGFloat {
        return spacing(baseSpacing: 12)
    }
    
    static var minTileSpacing: CGFloat {
        return spacing(baseSpacing: 2)
    }
    
    static var containerPadding: CGFloat {
        return padding(basePadding: 24)
    }
    
    static var sectionSpacing: CGFloat {
        return spacing(baseSpacing: 16)
    }
    
    // MARK: - Adaptive Layout
    static func adaptiveTilePadding(for wordLength: Int) -> CGFloat {
        let basePadding: CGFloat
        switch wordLength {
        case 5: basePadding = 2
        case 4: basePadding = 3
        case 3: basePadding = 6
        default: basePadding = 4
        }
        return spacing(baseSpacing: basePadding)
    }
    
    static func adaptiveKeyboardSpacing() -> CGFloat {
        return spacing(baseSpacing: 6)
    }
    
    static func adaptiveKeyboardPadding() -> CGFloat {
        return padding(basePadding: 8)
    }
}

// MARK: - Responsive Layout Modifiers
struct AdaptiveFrame: ViewModifier {
    let width: CGFloat?
    let height: CGFloat?
    func body(content: Content) -> some View {
        content
            .frame(
                width: width.map { ResponsiveSizing.tileSize(for: 4) * ($0 / 64) },
                height: height.map { ResponsiveSizing.tileSize(for: 4) * ($0 / 64) }
            )
    }
}

struct AdaptiveFont: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    func body(content: Content) -> some View {
        content
            .font(.system(
                size: ResponsiveSizing.fontSize(baseSize: size),
                weight: weight,
                design: design
            ))
    }
}

struct AdaptivePadding: ViewModifier {
    let edges: Edge.Set
    let length: CGFloat
    func body(content: Content) -> some View {
        content
            .padding(edges, ResponsiveSizing.padding(basePadding: length))
    }
}

struct AdaptiveSpacing: ViewModifier {
    let length: CGFloat
    func body(content: Content) -> some View {
        content
            .padding(Edge.Set.bottom, ResponsiveSizing.spacing(baseSpacing: length))
    }
}

// MARK: - View Extensions for Responsive Design
extension View {
    func responsiveFrame(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        self.modifier(AdaptiveFrame(width: width, height: height))
    }
    
    func responsiveFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        self.modifier(AdaptiveFont(size: size, weight: weight, design: design))
    }
    
    func responsivePadding(_ edges: Edge.Set = .all, _ length: CGFloat) -> some View {
        self.modifier(AdaptivePadding(edges: edges, length: length))
    }
    
    func responsiveSpacing(_ length: CGFloat) -> some View {
        self.modifier(AdaptiveSpacing(length: length))
    }
} 
