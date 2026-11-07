import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum Theme {
    // MARK: - Adaptive colors (light/dark)

    #if os(watchOS)
    static let background = Color.black
    static let cardSurface = Color(white: 0.12)
    static let cardSurfaceLight = Color(white: 0.18)
    static let ringTrack = Color(white: 0.2)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.7)
    static let textTertiary = Color(white: 0.5)
    #else
    static let background = Color(.systemBackground)
    static let cardSurface = Color(.secondarySystemBackground)
    static let cardSurfaceLight = Color(.tertiarySystemBackground)
    static let ringTrack = Color(.systemFill)
    static let textPrimary = Color(.label)
    // secondaryLabel measured 3.4 to 3.7:1 on the grouped card surface in light
    // mode, so light uses a solid gray that clears 4.5:1 there. Dark keeps the
    // system value, which is already above it.
    static let textSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.secondaryLabel
            : UIColor(white: traits.accessibilityContrast == .high ? 0.25 : 0.34, alpha: 1)
    })
    // tertiaryLabel is about 1.7:1 on the system backgrounds. Footnotes and locked
    // rows must reach 4.5:1 in light, dark and increased contrast, so this follows
    // secondaryLabel (about 5:1 or better, and the system darkens it further for
    // increased contrast).
    static let textTertiary = textSecondary
    #endif

    // Cardio fitness palette
    static let cardio = Color(red: 0.06, green: 0.76, blue: 0.78)      // teal
    static let cardioBlue = Color(red: 0.08, green: 0.48, blue: 0.95)  // blue
    static let cardioGlow = Color(red: 0.06, green: 0.76, blue: 0.78).opacity(0.3)

    // Teal drawn as text on a white, grouped or tinted-teal surface is about
    // 2:1. Text uses `cardioText` (4.5:1 or better in light, dark and increased
    // contrast); white text on a teal fill uses `cardioDeep` and `ctaGradient`.
    #if os(watchOS)
    static let cardioText = cardio
    #else
    static let cardioText = Color(UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.06, green: 0.76, blue: 0.78, alpha: 1)
        }
        return traits.accessibilityContrast == .high
            ? UIColor(red: 0.0, green: 0.33, blue: 0.35, alpha: 1)
            : UIColor(red: 0.0, green: 0.42, blue: 0.44, alpha: 1)
    })
    #endif
    static let cardioDeep = Color(red: 0.0, green: 0.45, blue: 0.47)
    static let cardioBlueDeep = Color(red: 0.05, green: 0.34, blue: 0.80)

    // Status colors are drawn as text on the card surface, so light mode uses
    // deeper tones (4.5:1 or better); dark keeps the bright originals.
    #if os(watchOS)
    static let coral = Color(red: 1.0, green: 0.45, blue: 0.40)
    static let positive = Color(red: 0.20, green: 0.72, blue: 0.48)
    static let negative = Color(red: 0.92, green: 0.36, blue: 0.38)
    #else
    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
    static let coral = adaptive(light: UIColor(red: 0.72, green: 0.22, blue: 0.18, alpha: 1),
                                dark: UIColor(red: 1.0, green: 0.45, blue: 0.40, alpha: 1))
    static let positive = adaptive(light: UIColor(red: 0.0, green: 0.46, blue: 0.25, alpha: 1),
                                   dark: UIColor(red: 0.20, green: 0.72, blue: 0.48, alpha: 1))
    static let negative = adaptive(light: UIColor(red: 0.78, green: 0.18, blue: 0.20, alpha: 1),
                                   dark: UIColor(red: 0.92, green: 0.36, blue: 0.38, alpha: 1))
    #endif

    // MARK: - Constants

    static let cardRadius: CGFloat = 20
    static let cardPadding: CGFloat = 20

    // MARK: - Gradients

    static var cardioGradient: LinearGradient {
        LinearGradient(
            colors: [cardioBlue, cardio],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Fill behind white button text.
    static var ctaGradient: LinearGradient {
        LinearGradient(
            colors: [cardioBlueDeep, cardioDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Typography

    static func bigNumber(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}

extension View {
    /// Footer links and quiet text buttons draw small, but their tap area must
    /// still be at least 44 x 44 pt.
    func minimumTapTarget() -> some View {
        frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }
}
