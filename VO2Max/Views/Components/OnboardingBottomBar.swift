import SwiftUI

/// Fleet zero-shift CTA contract (see ~/ios/onboarding/trial-conversion-thumb-zone.md).
///
/// The primary button occupies a byte-identical frame on every onboarding page
/// and on the trial page, so the user's thumb never moves as the label switches
/// from "Continue" to "Start … free trial". Guaranteed structurally:
///
/// - The primary is bottom-pinned above a fixed-height legal-footer slot that is
///   rendered on *every* page. On the trial page it holds the real
///   Terms/Privacy/Restore links; on the setup pages it renders the exact same
///   view hidden (`opacity 0` + no hit testing + AX hidden), so its height is
///   identical to the pixel.
/// - All page-specific, variable-height content (page dots, soft exit,
///   disclosure, error text) lives in the `above` slot, expanding upward into
///   the flexible region where it can never move the button.
struct OnboardingBottomBar<Above: View>: View {
    let primaryTitle: String
    var isBusy: Bool = false
    var isDisabled: Bool = false
    let primaryAction: () -> Void
    let footer: OnboardingLegalFooter
    @ViewBuilder var above: () -> Above

    var body: some View {
        VStack(spacing: 0) {
            above()

            Button(action: primaryAction) {
                ZStack {
                    Text(primaryTitle).opacity(isBusy ? 0 : 1)
                    if isBusy { ProgressView().tint(.white) }
                }
            }
            .buttonStyle(PrimaryCTAButtonStyle())
            .disabled(isDisabled)
            .padding(.top, 16)

            footer
                .padding(.top, 12)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }
}

/// The primary CTA look, shared across every onboarding page and the trial page
/// so width, height, and corner radius match. Fixed height is the point — a
/// `.borderedProminent`/`.controlSize(.large)` button would vary by label.
struct PrimaryCTAButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                Theme.cardio.opacity(isEnabled ? 1 : 0.5),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// The Terms / Privacy / Restore row that anchors the bottom bar. The same view
/// is rendered on every onboarding page so the reserved footer slot is exactly
/// the same height; `isPlaceholder` hides it on the non-trial pages.
struct OnboardingLegalFooter: View {
    var isPlaceholder: Bool = false
    var isRestoring: Bool = false
    var onRestore: () -> Void = {}

    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacyURL = URL(string: "https://jackwallner.github.io/vo2max/privacy-policy.html")!

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onRestore) {
                Text(isRestoring ? "Restoring…" : "Restore")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
            }
            .buttonStyle(.plain)
            .disabled(isRestoring)

            HStack(spacing: 4) {
                Link("Terms", destination: Self.termsURL)
                Text("·")
                Link("Privacy", destination: Self.privacyURL)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .opacity(isPlaceholder ? 0 : 1)
        .allowsHitTesting(!isPlaceholder)
        .accessibilityHidden(isPlaceholder)
    }
}
