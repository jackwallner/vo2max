import SwiftUI

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
    // System secondary/tertiary labels measure 3.4:1 and below on white; these stay above 4.5:1.
    static let textSecondary = adaptive(light: (0.33, 0.33, 0.35), dark: (0.72, 0.72, 0.74))
    static let textTertiary = adaptive(light: (0.40, 0.40, 0.42), dark: (0.62, 0.62, 0.65))

    private static func adaptive(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
        Color(UIColor { trait in
            let c = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
    }
    #endif

    // Cardio fitness palette. Text and white-on-fill pairings need 4.5:1, so the
    // light-mode teal is deeper; dark mode keeps the bright teal.
    #if os(watchOS)
    static let cardio = Color(red: 0.06, green: 0.76, blue: 0.78)      // teal
    #else
    static let cardio = adaptive(light: (0.0, 0.40, 0.45), dark: (0.06, 0.76, 0.78))
    #endif
    #if os(watchOS)
    static let cardioBlue = Color(red: 0.08, green: 0.48, blue: 0.95)  // blue
    #else
    static let cardioBlue = adaptive(light: (0.05, 0.36, 0.80), dark: (0.08, 0.48, 0.95))
    #endif
    static let cardioGlow = Color(red: 0.06, green: 0.76, blue: 0.78).opacity(0.3)

    #if os(watchOS)
    static let coral = Color(red: 1.0, green: 0.45, blue: 0.40)
    static let positive = Color(red: 0.20, green: 0.72, blue: 0.48)
    static let negative = Color(red: 0.92, green: 0.36, blue: 0.38)
    #else
    static let coral = adaptive(light: (0.75, 0.22, 0.20), dark: (1.0, 0.45, 0.40))
    static let positive = adaptive(light: (0.04, 0.46, 0.25), dark: (0.20, 0.72, 0.48))
    static let negative = adaptive(light: (0.78, 0.15, 0.18), dark: (0.92, 0.36, 0.38))
    #endif

    /// Fixed-dark fills for buttons that carry white text (4.5:1 in both appearances).
    static let buttonGradient = LinearGradient(
        colors: [Color(red: 0.05, green: 0.34, blue: 0.80), Color(red: 0.0, green: 0.40, blue: 0.45)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let buttonFill = Color(red: 0.0, green: 0.40, blue: 0.45)

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

    // MARK: - Typography

    static func bigNumber(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}

#if !os(watchOS)
extension View {
    /// Footer text links (Restore, Terms, Privacy): 44pt tap target, same look.
    func footerTapTarget() -> some View {
        padding(.horizontal, 6)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }
}
#endif

#if !os(watchOS)
/// One figure in a `StatStrip`.
struct StatItem {
    let title: String
    let value: String
    var color: Color?
}

/// Side-by-side figures with dividers. At accessibility text sizes three or
/// four columns leave each one narrower than its own caption, so the label
/// broke mid-word ("Read-ings"); there the figures stack as label and value rows.
struct StatStrip: View {
    let items: [StatItem]
    var valueSize: CGFloat = 19
    var captionFont: Font = .caption2
    var dividerHeight: CGFloat = 34
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(spacing: 10) {
                ForEach(items.indices, id: \.self) { index in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(items[index].title)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(items[index].value)
                            .font(Theme.bigNumber(valueSize))
                            .foregroundStyle(items[index].color ?? Theme.textPrimary)
                            .lineLimit(1)
                    }
                    .accessibilityElement(children: .combine)
                    if index < items.count - 1 { Divider() }
                }
            }
            .padding(.horizontal, 14)
        } else {
            HStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { index in
                    VStack(spacing: 3) {
                        Text(items[index].value)
                            .font(Theme.bigNumber(valueSize))
                            .foregroundStyle(items[index].color ?? Theme.textPrimary)
                        Text(items[index].title)
                            .font(captionFont)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    if index < items.count - 1 { Divider().frame(height: dividerHeight) }
                }
            }
        }
    }
}
#endif
