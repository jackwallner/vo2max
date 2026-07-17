import SwiftUI
@preconcurrency import RevenueCat

/// Focused first-run trial pitch. A single decision (start the free trial or
/// not) instead of the full multi-plan paywall — shown once after onboarding
/// when the yearly plan is genuinely trial-eligible. "See all plans" escalates
/// to the full `PaywallView` for users who want to compare.
struct TrialOfferView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreService
    @State private var showFullPaywall = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Spacer(minLength: 4)
                Image(systemName: "sparkles")
                    .font(.system(size: 42))
                    .foregroundStyle(.white)
                    .frame(width: 88, height: 88)
                    .background(Theme.cardioGradient, in: Circle())
                VStack(spacing: 8) {
                    Text(headline)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text("Deeper context for your cardio fitness trend, free to try.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 14) {
                    benefitRow("chart.bar.xaxis", "Deep Trends: every period vs. the one before")
                    benefitRow("scope", "A broad time-to-target outlook")
                    benefitRow("person.2.crop.square.stack", "Typical-range context for your age")
                    benefitRow("trophy", "Personal best tracking")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

                Spacer()

                VStack(spacing: 10) {
                    Button {
                        guard let yearly = store.yearlyPackage else { return }
                        Task { await store.purchase(yearly) }
                    } label: {
                        Text(ctaLabel)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Theme.cardio)
                    .disabled(store.isLoading || store.yearlyPackage == nil)

                    if let error = store.errorMessage {
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(Theme.negative)
                            .multilineTextAlignment(.center)
                    } else {
                        Text(disclosure)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Button("See all plans") { showFullPaywall = true }
                        .font(.footnote)
                    Button("Maybe later") { dismiss() }
                        .font(.subheadline)
                }
            }
            .padding(24)
            .background(Theme.background)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
        .sheet(isPresented: $showFullPaywall) { PaywallView() }
        .onAppear { store.trackPaywallImpression(id: "vo2plus_trial_offer") }
        .onChange(of: store.isPro) { _, isPro in if isPro { dismiss() } }
    }

    private var eligible: Bool {
        guard let yearly = store.yearlyPackage else { return false }
        return store.isEligibleForIntroOffer(yearly)
    }

    private var headline: String {
        eligible ? "Try VO2+ free" : "Unlock VO2+"
    }

    private var ctaLabel: String {
        eligible ? "Start Free Trial" : "Continue with VO2+"
    }

    private var disclosure: String {
        guard let yearly = store.yearlyPackage else { return "" }
        return VO2ConversionCopy.sheetDisclosure(
            trialLabel: yearly.vo2IntroOfferLabel,
            priceLabel: yearly.vo2PriceLabel,
            eligibleForTrial: eligible
        )
    }

    private func benefitRow(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(Theme.cardio)
                .frame(width: 26)
            Text(text).font(.subheadline)
            Spacer(minLength: 0)
        }
    }
}
