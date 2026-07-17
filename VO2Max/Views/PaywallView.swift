import SwiftUI
@preconcurrency import RevenueCat

/// Single source of truth for what VO2+ sells. Each case can headline a
/// focused paywall when the user tapped that specific locked feature.
enum PlusFeature: CaseIterable {
    case deepTrends
    case targetProjection
    case fitnessBand
    case personalBest
    case extendedInsights

    var title: String {
        switch self {
        case .deepTrends: "Deep Trends: every period vs. the one before"
        case .targetProjection: "Target outlook: broad time-to-range estimate"
        case .fitnessBand: "Typical-range context for your age and sex"
        case .personalBest: "Personal best tracking and milestones"
        case .extendedInsights: "All future VO2+ insights included"
        }
    }

    var symbol: String {
        switch self {
        case .deepTrends: "chart.bar.xaxis"
        case .targetProjection: "scope"
        case .fitnessBand: "person.2.crop.square.stack"
        case .personalBest: "trophy"
        case .extendedInsights: "sparkles"
        }
    }

    var intentHeadline: String {
        switch self {
        case .deepTrends: "Compare every period"
        case .targetProjection: "See your target outlook"
        case .fitnessBand: "Context for your number"
        case .personalBest: "Track your personal best"
        case .extendedInsights: "Go further with VO2+"
        }
    }
}

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreService
    var focus: PlusFeature?
    /// When embedded in the VO2+ tab there's no sheet to dismiss and no Done
    /// button; the tab swaps to the Pro insights hub on its own when `isPro`
    /// flips. Standalone (sheet) presentation keeps the Done button + dismiss.
    var embedded: Bool = false
    var impressionID: String = "vo2plus_paywall"
    @State private var selectedPackage: Package?
    @State private var restoreMessage: String?

    var body: some View {
        Group {
            if embedded {
                gated
            } else {
                NavigationStack {
                    gated
                        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
                }
            }
        }
        .onAppear {
            store.trackPaywallImpression(id: impressionID)
            selectDefaultPackageIfNeeded()
        }
        .onChange(of: store.packages) { _, _ in selectDefaultPackageIfNeeded() }
        .onChange(of: store.isPro) { _, isPro in
            if isPro, !embedded { dismiss() }
        }
    }

    private var gated: some View {
        Group {
            if store.isLoadingProducts && store.packages.isEmpty {
                loadingState
            } else if store.packages.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .background(Theme.background)
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                featureList
                planCards
                ctaSection
                footer
            }
            .padding(22)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 46))
                .foregroundStyle(.white)
                .frame(width: 92, height: 92)
                .background(Theme.cardioGradient, in: Circle())
            Text(focus?.intentHeadline ?? (embedded ? "Go further with VO2+" : "VO2+"))
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Deeper context for your cardio fitness trend.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featureList: some View {
        let bullets: [PlusFeature] = {
            if let focus {
                return [focus] + PlusFeature.allCases.filter { $0 != focus }
            }
            return PlusFeature.allCases
        }()
        return VStack(alignment: .leading, spacing: 13) {
            ForEach(bullets, id: \.self) { feature in
                HStack(spacing: 12) {
                    Image(systemName: feature.symbol)
                        .foregroundStyle(Theme.cardio)
                        .frame(width: 26)
                    Text(feature.title)
                        .font(feature == focus ? .subheadline.bold() : .subheadline)
                    Spacer(minLength: 0)
                }
                .padding(feature == focus ? 10 : 0)
                .background(
                    feature == focus ? Theme.cardio.opacity(0.10) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 10)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var planCards: some View {
        VStack(spacing: 10) {
            ForEach(store.packages, id: \.identifier) { package in
                PlanCard(
                    package: package,
                    isSelected: selectedPackage?.identifier == package.identifier,
                    savingsPercent: savingsPercent(for: package),
                    trialLabel: store.eligibleIntroLabel(for: package)
                ) {
                    selectedPackage = package
                }
            }
        }
    }

    private var ctaSection: some View {
        VStack(spacing: 10) {
            Button {
                guard let package = selectedPackage else { return }
                Task { await store.purchase(package) }
            } label: {
                Text(ctaTitle)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Theme.cardio)
            .disabled(store.isLoading || selectedPackage == nil)

            Group {
                if let error = store.errorMessage {
                    Text(error).foregroundStyle(Theme.negative)
                } else if let restoreMessage {
                    Text(restoreMessage)
                } else {
                    Text(disclosureText)
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(minHeight: 44)
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Button("Restore Purchases") {
                Task {
                    await store.restore()
                    if !store.isPro { restoreMessage = store.errorMessage }
                }
            }
            .font(.footnote)
            HStack {
                Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Text("·")
                Link("Privacy Policy", destination: URL(string: "https://jackwallner.github.io/vo2max/privacy-policy.html")!)
            }
            .font(.caption2)
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading plans…").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            Text("Couldn't Load Plans").font(.title3.bold())
            Text("Check your connection and try again.")
                .font(.subheadline).foregroundStyle(.secondary)
            Button("Try Again") {
                store.start()
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.cardio)
            #if targetEnvironment(simulator)
            Text("RevenueCat is disabled in the simulator. Use the local Pro override in Settings.")
                .font(.caption2).foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var ctaTitle: String {
        guard let package = selectedPackage else { return "Continue" }
        if package.vo2PackageKind == .lifetime { return "Unlock Lifetime" }
        if store.isEligibleForIntroOffer(package) { return "Start Free Trial" }
        return "Subscribe"
    }

    private var disclosureText: String {
        guard let package = selectedPackage else { return "" }
        if package.vo2PackageKind == .lifetime {
            return "\(package.storeProduct.localizedPriceString). One-time purchase. Lifetime access, no subscription."
        }
        return VO2ConversionCopy.disclosure(
            trialLabel: package.vo2IntroOfferLabel,
            priceLabel: package.vo2PriceLabel,
            eligibleForTrial: store.isEligibleForIntroOffer(package),
            renewClause: "Auto-renews unless cancelled at least 24 hours before the end of the current period. Manage or cancel in Settings."
        )
    }

    private func selectDefaultPackageIfNeeded() {
        guard selectedPackage == nil else { return }
        selectedPackage = store.yearlyPackage ?? store.packages.first
    }

    /// "SAVE X%" for annual vs 12 monthly payments; only when actually cheaper.
    private func savingsPercent(for package: Package) -> Int? {
        guard package.vo2PackageKind == .yearly,
              let monthly = store.packages.first(where: { $0.vo2PackageKind == .monthly }) else { return nil }
        let yearlyPrice = package.storeProduct.price as Decimal
        let annualized = (monthly.storeProduct.price as Decimal) * 12
        guard annualized > yearlyPrice, annualized > 0 else { return nil }
        let fraction = NSDecimalNumber(decimal: (annualized - yearlyPrice) / annualized).doubleValue
        return Int((fraction * 100).rounded())
    }
}

private struct PlanCard: View {
    let package: Package
    let isSelected: Bool
    let savingsPercent: Int?
    let trialLabel: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Theme.cardio : .secondary)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(package.vo2DisplayName).font(.headline)
                        if let savingsPercent {
                            badge("SAVE \(savingsPercent)%")
                        } else if package.vo2PackageKind == .yearly {
                            badge("BEST VALUE")
                        }
                    }
                    if let trialLabel {
                        Text(trialLabel)
                            .font(.caption)
                            .foregroundStyle(Theme.positive)
                    } else if package.vo2PackageKind == .yearly, let perWeek = package.vo2PricePerWeekLabel {
                        Text("Just \(perWeek)/week")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(package.storeProduct.localizedPriceString)
                    .font(.headline.monospacedDigit())
            }
            .padding(14)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Theme.cardio : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(package.vo2DisplayName), \(package.storeProduct.localizedPriceString)\(trialLabel.map { ", \($0)" } ?? "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Theme.cardio.opacity(0.15), in: Capsule())
            .foregroundStyle(Theme.cardio)
    }
}
