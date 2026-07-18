import SwiftUI

enum Theme {
    #if os(watchOS)
    static let background = Color.black
    static let card = Color(white: 0.12)
    static let primaryText = Color.white
    static let secondaryText = Color(white: 0.72)
    #else
    static let background = Color(.systemBackground)
    static let card = Color(.secondarySystemBackground)
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    #endif

    static let cardio = Color(red: 0.06, green: 0.76, blue: 0.78)
    static let cardioBlue = Color(red: 0.08, green: 0.48, blue: 0.95)
    static let onboardingBackground = Color(red: 0.025, green: 0.075, blue: 0.17)
    static let onboardingCard = Color(red: 0.06, green: 0.13, blue: 0.25)
    static let onboardingPrimaryText = Color.white
    static let onboardingSecondaryText = Color(red: 0.66, green: 0.74, blue: 0.84)
    static let onboardingMuted = Color(red: 0.39, green: 0.48, blue: 0.61)
    static let coral = Color(red: 1.0, green: 0.45, blue: 0.40)
    static let positive = Color(red: 0.20, green: 0.72, blue: 0.48)
    static let negative = Color(red: 0.92, green: 0.36, blue: 0.38)
    static let cardRadius: CGFloat = 22

    static var cardioGradient: LinearGradient {
        LinearGradient(colors: [cardioBlue, cardio], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func numberFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}

