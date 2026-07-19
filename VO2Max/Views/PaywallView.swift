import SwiftUI
@preconcurrency import RevenueCat

/// Single source of truth for what VO2+ sells. Focused paywalls lead with the
/// capability the user just reached for, while the VO2+ tab shows the strongest
/// overall outcomes in one compact screen.
enum PlusFeature: CaseIterable {
    case deepTrends
    case targetProjection
    case fitnessBand
    case personalBest
    case extendedInsights

    var title: String {
        switch self {
        case .deepTrends: "Compare every period with the one before"
        case .targetProjection: "Understand direction toward your target"
        case .fitnessBand: "Add broad age-reference context"
        case .personalBest: "Keep personal bests visible"
        case .extendedInsights: "Get new VO2+ insights as they arrive"
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
        case .targetProjection: "Understand your target direction"
        case .fitnessBand: "Add context to your estimate"
        case .personalBest: "Recognize your progress"
        case .extendedInsights: "Go further with VO2+"
        }
    }

    var intentSubheadline: String {
        switch self {
        case .deepTrends: "See matching-window averages and changes across 30, 90, and 180 days."
        case .targetProjection: "Put the recent cardio fitness trend in target context when the data supports it."
        case .fitnessBand: "Compare the latest estimate with broad reference values for your age and selected reference."
        case .personalBest: "Keep the strongest Apple Health estimate and its date easy to find."
        case .extendedInsights: "Deeper context that appears inside the screens you already use."
        }
    }
}

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreService
    var focus: PlusFeature?
    var embedded = false
    var impressionID = "vo2plus_paywall"

    @State private var selectedPackage: Package?
    @State private var restoreMessage: String?

    private var bullets: [PlusFeature] {
        if let focus {
            return [focus] + PlusFeature.allCases.filter { $0 != focus }.prefix(3)
        }
        return [.deepTrends, .targetProjection, .fitnessBand, .personalBest]
    }

    var body: some View {
        Group {
            if embedded {
                gated
            } else {
                NavigationStack {
                    gated
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { dismiss() }
                            }
                        }
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
        GeometryReader { geometry in
            let compact = geometry.size.height < 730
            ScrollView(showsIndicators: false) {
                VStack(spacing: compact ? 8 : 10) {
                    header(compact: compact)
                    featureList(compact: compact)
                    planCards(compact: compact)
                }
                .padding(.horizontal, 22)
                .padding(.top, embedded ? 10 : 4)
                .padding(.bottom, compact ? 136 : 148)
                .frame(minHeight: geometry.size.height, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                checkoutFooter(compact: compact)
            }
        }
    }

    private func header(compact: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: compact ? 18 : 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: compact ? 40 : 44, height: compact ? 40 : 44)
                .background(Theme.cardioGradient, in: Circle())
                .shadow(color: Theme.cardio.opacity(0.25), radius: 8, y: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(focus?.intentHeadline ?? "Go further with VO2+")
                    .font(.system(compact ? .headline : .title3, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Text(focus?.intentSubheadline ?? "More useful context inside Today, Trends, and your reading details.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(compact ? 2 : 3)
                    .minimumScaleFactor(0.88)
            }
            Spacer(minLength: 0)
        }
        .padding(.bottom, 2)
    }

    private func featureList(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 5 : 7) {
            ForEach(bullets, id: \.self) { feature in
                let highlighted = feature == focus
                HStack(spacing: 10) {
                    Image(systemName: feature.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.cardio)
                        .frame(width: 24)
                    Text(feature.title)
                        .font(.system(.subheadline, design: .rounded, weight: highlighted ? .semibold : .regular))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, highlighted ? 9 : 0)
                .padding(.vertical, highlighted ? 6 : 0)
                .background(
                    highlighted ? Theme.cardio.opacity(0.1) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 10)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func planCards(compact: Bool) -> some View {
        VStack(spacing: compact ? 6 : 8) {
            ForEach(store.packages, id: \.identifier) { package in
                PlanCard(
                    package: package,
                    isSelected: selectedPackage?.identifier == package.identifier,
                    savingsPercent: savingsPercent(for: package),
                    trialLabel: store.eligibleIntroLabel(for: package),
                    compact: compact
                ) {
                    selectedPackage = package
                }
            }
        }
    }

    private func checkoutFooter(compact: Bool) -> some View {
        VStack(spacing: compact ? 4 : 6) {
            Button {
                guard let package = selectedPackage else { return }
                Task { await store.purchase(package) }
            } label: {
                ZStack {
                    Text(ctaTitle)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .opacity(store.isLoading ? 0 : 1)
                    if store.isLoading { ProgressView().tint(.white) }
                }
                .frame(maxWidth: .infinity)
                .frame(height: compact ? 46 : 50)
                .background(Theme.cardioGradient, in: Capsule())
            }
            .buttonStyle(.plain)
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
            .foregroundStyle(Theme.secondaryText)
            .multilineTextAlignment(.center)
            .lineLimit(compact ? 3 : 4)
            .minimumScaleFactor(0.88)
            .frame(maxWidth: .infinity, minHeight: compact ? 30 : 38, alignment: .top)

            HStack(spacing: 12) {
                Button("Restore") {
                    Task {
                        await store.restore()
                        if !store.isPro {
                            restoreMessage = store.errorMessage ?? "No active VO2+ purchase was found."
                        }
                    }
                }
                Link("Terms", destination: OnboardingLegalFooter.termsURL)
                Link("Privacy", destination: OnboardingLegalFooter.privacyURL)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Theme.secondaryText)
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, embedded ? 16 : 10)
        .background(Theme.background)
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading plans…").foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 42))
                .foregroundStyle(Theme.secondaryText)
            Text("Couldn't Load Plans").font(.title3.bold())
            Text("Check your connection and try again.")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            Button("Try Again") { store.start() }
                .buttonStyle(.borderedProminent)
                .tint(Theme.cardio)
            #if targetEnvironment(simulator)
            Text("Purchases are disabled in the simulator. Use the local Pro override in Settings to inspect subscriber screens.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
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
    let compact: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Theme.cardio : Theme.secondaryText.opacity(0.35), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(Theme.cardio).frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(package.vo2DisplayName)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(Theme.primaryText)
                        if let savingsPercent {
                            badge("SAVE \(savingsPercent)%")
                        } else if package.vo2PackageKind == .yearly {
                            badge("BEST VALUE")
                        }
                    }
                    Group {
                        if let trialLabel {
                            Text(trialLabel.capitalized)
                        } else if package.vo2PackageKind == .yearly,
                                  let perWeek = package.vo2PricePerWeekLabel {
                            Text("Just \(perWeek)/week")
                        } else {
                            Text(" ")
                        }
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.positive)
                    .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text(package.vo2PriceLabel)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }
            .frame(minHeight: compact ? 48 : 54)
            .padding(.horizontal, 14)
            .padding(.vertical, compact ? 7 : 9)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Theme.cardio : Color.clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Theme.cardio.opacity(0.15), in: Capsule())
            .foregroundStyle(Theme.cardio)
    }
}
