import SwiftUI

/// Personalized VO2+ trial offer sheet. Leads with the capability the user just
/// reached for (a locked Settings toggle, the upgrade row), frames the free
/// trial as a deal when the Apple ID is still eligible, and buys the yearly
/// package directly. Ported from the Vitals+ TrialOfferSheet and adapted to the
/// cardio (teal) theme and VO2+ copy.
struct TrialOfferSheet: View {
    /// When set, the sheet leads with and highlights this feature instead of the
    /// generic toolkit pitch. `nil` for a plain upgrade tap.
    let focus: PlusFeature?
    /// Free-trial label only when the user is eligible; nil frames a paid yearly buy.
    let offerLabel: String?
    /// Recurring price, e.g. "$29.99 / year". Required in directPurchase mode.
    let priceLabel: String?
    /// Primary button title (trial or paid yearly).
    let ctaTitle: String
    /// Apple 3.1.2 disclosure under the CTA. Hidden while an error is shown so
    /// the two never overlap in the fixed footer.
    let disclosureText: String?
    /// When true the primary button buys the yearly product directly via StoreKit.
    let directPurchase: Bool
    let isPurchasing: Bool
    let errorMessage: String?
    let onStartTrial: () -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animateGlow = false
    @State private var shimmerPhase: CGFloat = -1

    /// Headline copy. Trial language only when `offerLabel` is set (eligible).
    private var headline: String {
        if let focus { return focus.intentHeadline }
        if let offerLabel {
            return "\(offerLabel.capitalized), on us."
        }
        return "Go further with VO2+"
    }

    private var subheadline: String {
        if let focus {
            if offerLabel != nil {
                return "\(focus.intentSubheadline) Free during your trial. Cancel anytime."
            }
            return focus.intentSubheadline
        }
        return offerLabel != nil
            ? "Deeper trends, alerts, and reports on top of your Apple Health estimates. No charge until your trial ends."
            : "Deeper trends, alerts, and reports on top of your Apple Health estimates."
    }

    /// Focused feature first with two related companions; generic trio otherwise.
    private var bulletFeatures: [PlusFeature] {
        if let focus { return [focus] + focus.companionFeatures }
        return [.deepTrends, .targetProjection, .personalBest]
    }

    /// Deal badge text derived from the real offer, e.g. "7-day free trial" →
    /// "7 DAYS FREE". Falls back to a generic label if the day count can't be
    /// parsed. Never invents a number — only reflects the loaded offer.
    private var trialBadgeText: String {
        guard let offerLabel,
              let days = offerLabel.split(whereSeparator: { !$0.isNumber }).first,
              !days.isEmpty else {
            return "VO2+"
        }
        return "\(days) DAYS FREE"
    }

    /// Repeat-forever animation timing for the ambient glow. Scoped to the
    /// specific views that read `animateGlow` via `.animation(_:value:)` so the
    /// animation context can't leak into unrelated layout changes.
    private var glowAnimation: Animation {
        .easeInOut(duration: 2.2).repeatForever(autoreverses: true)
    }

    private var shimmerAnimation: Animation {
        .linear(duration: 2.6).repeatForever(autoreverses: false).delay(0.4)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            // Teal ambient glows, consistent with the cardio theme.
            Circle()
                .fill(Theme.cardio.opacity(0.22))
                .frame(width: 240, height: 240)
                .blur(radius: 38)
                .offset(x: animateGlow ? 96 : -96, y: animateGlow ? -220 : -180)
                .animation(glowAnimation, value: animateGlow)
            Circle()
                .fill(Theme.cardioBlue.opacity(0.20))
                .frame(width: 190, height: 190)
                .blur(radius: 34)
                .offset(x: animateGlow ? -110 : 110, y: animateGlow ? 250 : 210)
                .animation(glowAnimation, value: animateGlow)
            // Light "shine" particles drifting behind the hero. Suppressed when
            // Reduce Motion is on so we stay accessibility-compliant.
            if !reduceMotion {
                SparkleField(phase: animateGlow ? 1 : 0)
                    .allowsHitTesting(false)
                    .opacity(0.55)
                    .animation(glowAnimation, value: animateGlow)
            }

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.cardioGradient)
                        .frame(width: 60, height: 60)
                        .shadow(color: Theme.cardio.opacity(0.45), radius: 14, x: 0, y: 4)
                        .scaleEffect(animateGlow ? 1.06 : 0.96)
                    Circle()
                        .stroke(.white.opacity(0.35), lineWidth: 1)
                        .frame(width: 50, height: 50)
                        .scaleEffect(animateGlow ? 1.03 : 0.98)
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(animateGlow ? 6 : -6))
                }
                .padding(.top, 4)
                .animation(glowAnimation, value: animateGlow)

                // Deal badge only when pitching an eligible free trial.
                if offerLabel != nil {
                    Text(trialBadgeText)
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                        .tracking(1.5)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Theme.cardioGradient, in: Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.35), lineWidth: 1))
                        .shadow(color: Theme.cardio.opacity(0.5), radius: animateGlow ? 12 : 6, x: 0, y: 2)
                        .scaleEffect(animateGlow ? 1.03 : 1.0)
                        .animation(glowAnimation, value: animateGlow)
                        .accessibilityLabel(trialBadgeText.capitalized)
                }

                VStack(spacing: 4) {
                    Text(headline)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .overlay(shimmerOverlay)
                        .mask(
                            // Must mirror the base Text's layout modifiers exactly
                            // (including minimumScaleFactor) or a scaled-down longer
                            // headline misaligns with the mask and renders garbled.
                            Text(headline)
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                        )
                    Text(subheadline)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                }

                VStack(spacing: 6) {
                    ForEach(bulletFeatures, id: \.self) { feature in
                        TrialBulletRow(
                            bullet: TrialBullet(
                                icon: feature.symbol,
                                tint: feature.tint,
                                title: feature.title,
                                detail: feature.detail
                            ),
                            highlighted: feature == focus,
                            compact: focus != nil ? feature != focus : true
                        )
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 8) {
                    // Error replaces disclosure in the same slot — never stack both.
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Theme.negative)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if directPurchase, let disclosureText {
                        Text(disclosureText)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button(action: onStartTrial) {
                        ZStack {
                            Text(ctaTitle)
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)
                                .multilineTextAlignment(.center)
                                .opacity(isPurchasing ? 0 : 1)
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Theme.cardioGradient, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurchasing)

                    Button(action: onDismiss) {
                        Text("Not now")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurchasing)

                    HStack(spacing: 4) {
                        Link("Terms", destination: VO2Links.standardEULA)
                        Text("·")
                        Link("Privacy Policy", destination: VO2Links.privacyPolicy)
                    }
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            // Plain state set — each animated view applies the repeating
            // animation locally via `.animation(_:value:)`, so the animation
            // context cannot leak into unrelated layout changes.
            animateGlow = true
            shimmerPhase = 1.4
        }
    }

    /// A diagonal moving highlight masked to the headline. Kept subtle so it
    /// reads as "premium" rather than "loading skeleton".
    private var shimmerOverlay: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .white.opacity(0.55), location: 0.5),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width * 0.5)
            .offset(x: shimmerPhase * width)
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
            .animation(shimmerAnimation, value: shimmerPhase)
        }
    }
}

private struct TrialBullet: Identifiable {
    let id = UUID()
    let icon: String
    let tint: Color
    let title: String
    let detail: String
}

private struct TrialBulletRow: View {
    let bullet: TrialBullet
    /// The feature the user tapped for: render it with a stronger tinted fill and
    /// border so it reads as the headline benefit of this pitch.
    var highlighted: Bool = false
    /// Title-only rows for the one-screen trial sheet.
    var compact: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: compact ? 10 : 12) {
            ZStack {
                Circle()
                    .fill(bullet.tint.opacity(0.18))
                    .frame(width: compact ? 28 : 34, height: compact ? 28 : 34)
                Image(systemName: bullet.icon)
                    .font(.system(size: compact ? 13 : 15, weight: .semibold))
                    .foregroundStyle(bullet.tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(bullet.title)
                    .font(.system(compact ? .footnote : .subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                if !compact {
                    Text(bullet.detail)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, compact ? 10 : 12)
        .padding(.vertical, compact ? 7 : 10)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(highlighted ? bullet.tint.opacity(0.12) : Theme.cardSurface.opacity(0.55))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(bullet.tint.opacity(highlighted ? 0.45 : 0.18), lineWidth: highlighted ? 1.5 : 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(bullet.title). \(bullet.detail)")
    }
}

/// Lightweight ambient "shine" — a handful of tiny dots that drift + pulse
/// behind the hero icon. Driven by `phase` (0…1) so the parent owns the
/// animation lifecycle.
private struct SparkleField: View {
    let phase: CGFloat

    private struct Sparkle: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let driftX: CGFloat
        let driftY: CGFloat
        let opacity: Double
        let phaseOffset: CGFloat
    }

    private static let sparkles: [Sparkle] = (0..<14).map { i in
        // Deterministic pseudo-random so layout doesn't jitter on re-render.
        let seed = Double(i) * 12.9898
        let r1 = (sin(seed) * 43758.5453).truncatingRemainder(dividingBy: 1)
        let r2 = (sin(seed + 1) * 43758.5453).truncatingRemainder(dividingBy: 1)
        let r3 = (sin(seed + 2) * 43758.5453).truncatingRemainder(dividingBy: 1)
        let r4 = (sin(seed + 3) * 43758.5453).truncatingRemainder(dividingBy: 1)
        return Sparkle(
            id: i,
            x: CGFloat(abs(r1)) * 320 - 160,
            y: CGFloat(abs(r2)) * 460 - 230,
            size: 2 + CGFloat(abs(r3)) * 3,
            driftX: CGFloat(r4) * 12,
            driftY: CGFloat(r3 - 0.5) * 18,
            opacity: 0.35 + abs(r2) * 0.5,
            phaseOffset: CGFloat(abs(r1))
        )
    }

    var body: some View {
        ZStack {
            ForEach(Self.sparkles) { sparkle in
                Circle()
                    .fill(.white)
                    .frame(width: sparkle.size, height: sparkle.size)
                    .opacity(sparkle.opacity * (0.4 + 0.6 * Double(abs(sin(.pi * (phase + sparkle.phaseOffset))))))
                    .offset(x: sparkle.x + sparkle.driftX * phase,
                            y: sparkle.y + sparkle.driftY * phase)
                    .blur(radius: 0.4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
