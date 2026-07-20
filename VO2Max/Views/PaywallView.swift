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

    /// Generic (no-focus) presentations list every benefit and scroll; a focused
    /// pitch is short and pins to a single non-scrolling page.
    private var showsFullBenefitList: Bool { focus == nil }

    var body: some View {
        ZStack {
            if store.isLoadingProducts && store.packages.isEmpty {
                loadingState
            } else if store.packages.isEmpty {
                emptyState
            } else {
                content
            }

            if !embedded {
                closeButton
            }
        }
        // Full-bleed background as a `.background` modifier, NOT a ZStack child.
        // As a child, `Theme.background.ignoresSafeArea()` made the ZStack ignore
        // the bottom safe area, which swallowed both the checkout footer's own
        // `.safeAreaInset` and the VO2+ tab's floating-capsule reserve — so the
        // Restore/Terms/Privacy row rendered under the tab bar. Behind the ZStack
        // instead, the content keeps its safe area and the footer clears the bar.
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            store.trackPaywallImpression(id: impressionID)
            selectDefaultPackageIfNeeded()
        }
        .onChange(of: store.packages) { _, _ in selectDefaultPackageIfNeeded() }
        .onChange(of: store.isPro) { _, isPro in
            if isPro, !embedded { dismiss() }
        }
    }

    /// Hero + benefits + plans; checkout pinned slim below via `safeAreaInset`.
    /// No GeometryReader: the full list scrolls, a focused pitch fills the height
    /// with a trailing Spacer. This is the Vitals paywall structure verbatim,
    /// which is what keeps everything on one page.
    private var content: some View {
        Group {
            if showsFullBenefitList {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        header
                        featureList
                        planCards
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, embedded ? 20 : 44)
                    .padding(.bottom, 8)
                }
                .scrollBounceBehavior(.basedOnSize)
            } else {
                VStack(spacing: 12) {
                    header
                    featureList
                    planCards
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 22)
                .padding(.top, embedded ? 20 : 44)
                .padding(.bottom, 4)
                .frame(maxHeight: .infinity)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            checkoutFooter
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Theme.cardioGradient)
                    .frame(width: 52, height: 52)
                    .shadow(color: Theme.cardio.opacity(0.3), radius: 10, y: 4)
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(focus?.intentHeadline ?? "Go further with VO2+")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Text(focus?.intentSubheadline ?? "Extras that sit on top of your Apple Health estimates.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.88)
        }
        .frame(maxWidth: .infinity)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(bullets, id: \.self) { feature in
                let highlighted = feature == focus
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: feature.symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.cardio)
                        .frame(width: 24)
                    Text(feature.title)
                        .font(.system(.subheadline, design: .rounded, weight: highlighted ? .semibold : .regular))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, highlighted ? 10 : 0)
                .padding(.vertical, highlighted ? 8 : 0)
                .background {
                    if highlighted {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.cardio.opacity(0.1))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var planCards: some View {
        VStack(spacing: 8) {
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

    /// CTA + required 3.1.2 disclosure. The disclosure/legal sit in a fixed-height
    /// slot so the button never jumps when the selected plan changes.
    private var checkoutFooter: some View {
        VStack(spacing: 6) {
            Button {
                guard let package = selectedPackage else { return }
                Task { await store.purchase(package) }
            } label: {
                ZStack {
                    Text(ctaTitle)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .opacity(store.isLoading ? 0 : 1)
                    if store.isLoading { ProgressView().tint(.white) }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Theme.cardioGradient, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(store.isLoading || selectedPackage == nil)

            VStack(spacing: 4) {
                Group {
                    if let error = store.errorMessage {
                        Text(error).foregroundStyle(Theme.negative)
                    } else if let restoreMessage {
                        Text(restoreMessage).foregroundStyle(Theme.textSecondary)
                    } else {
                        Text(disclosureText).foregroundStyle(Theme.textTertiary)
                    }
                }
                .font(.system(.caption2, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.9)
                .frame(maxWidth: .infinity)

                HStack(spacing: 12) {
                    Button("Restore") {
                        Task {
                            await store.restore()
                            if !store.isPro {
                                restoreMessage = store.errorMessage ?? "No active VO2+ purchase was found."
                            }
                        }
                    }
                    Link("Terms", destination: VO2Links.standardEULA)
                    Link("Privacy", destination: VO2Links.privacyPolicy)
                }
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            }
            .frame(minHeight: 60, alignment: .top)
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, embedded ? 16 : 10)
        .background(Theme.background)
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(16)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading plans…").foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 42))
                .foregroundStyle(Theme.textSecondary)
            Text("Couldn't Load Plans").font(.title3.bold())
            Text("Check your connection and try again.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
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
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Theme.cardio : Theme.textSecondary.opacity(0.35), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(Theme.cardio).frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(package.vo2DisplayName)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
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
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }
            .frame(minHeight: 54)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: 16))
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
