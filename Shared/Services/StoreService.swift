import Combine
import Foundation
import os
import WidgetKit
@preconcurrency import RevenueCat

enum RevenueCatConfig {
    /// Replace with the app-specific public key that begins with `appl_`.
    /// Secret `sk_` keys must never ship in an app binary.
    static let publicSDKKey = "appl_fRNEUFcviKvUbOLAnHkzIrbyFPA"
    static let proEntitlement = "pro"
}

enum PurchaseState {
    case purchased
    case cancelled
    case pending
}

enum VO2PackageKind: Int {
    case lifetime = 0
    case yearly = 1
    case monthly = 2
    case other = 3
}

extension VO2PackageKind {
    init(package: Package) {
        switch package.packageType {
        case .lifetime:
            self = .lifetime
        case .annual:
            self = .yearly
        case .monthly:
            self = .monthly
        default:
            let identifiers = [package.identifier, package.storeProduct.productIdentifier].map { $0.lowercased() }
            if identifiers.contains(where: { $0.contains("lifetime") }) {
                self = .lifetime
            } else if identifiers.contains(where: { $0.contains("yearly") || $0.contains("annual") }) {
                self = .yearly
            } else if identifiers.contains(where: { $0.contains("monthly") }) {
                self = .monthly
            } else {
                self = .other
            }
        }
    }
}

extension Package {
    var vo2PackageKind: VO2PackageKind {
        VO2PackageKind(package: self)
    }

    var vo2DisplayName: String {
        switch vo2PackageKind {
        case .lifetime: "Lifetime"
        case .yearly: "Yearly"
        case .monthly: "Monthly"
        case .other: storeProduct.localizedTitle
        }
    }

    var vo2PriceLabel: String {
        guard let period = storeProduct.subscriptionPeriod else { return storeProduct.localizedPriceString }
        let unit: String
        switch period.unit {
        case .day: unit = period.value == 1 ? "day" : "days"
        case .week: unit = period.value == 1 ? "week" : "weeks"
        case .month: unit = period.value == 1 ? "month" : "months"
        case .year: unit = period.value == 1 ? "year" : "years"
        @unknown default: unit = ""
        }
        if period.value == 1 {
            return "\(storeProduct.localizedPriceString) / \(unit)"
        }
        return "\(storeProduct.localizedPriceString) / \(period.value) \(unit)"
    }

    /// Per-week equivalent of the recurring price, shown on the annual card so
    /// the headline yearly figure feels small.
    var vo2PricePerWeekLabel: String? {
        guard storeProduct.subscriptionPeriod != nil else { return nil }
        return storeProduct.localizedPricePerWeek
    }

    var vo2IntroOfferLabel: String? {
        guard let intro = storeProduct.introductoryDiscount, intro.paymentMode == .freeTrial else {
            return nil
        }
        let period = intro.subscriptionPeriod
        switch period.unit {
        case .day: return "\(period.value)-day free trial"
        case .week: return "\(period.value * 7)-day free trial"
        case .month: return period.value == 1 ? "1-month free trial" : "\(period.value)-month free trial"
        case .year: return period.value == 1 ? "1-year free trial" : "\(period.value)-year free trial"
        @unknown default: return nil
        }
    }
}

extension Offering {
    var vo2SortedPackages: [Package] {
        availablePackages.sorted {
            let lhsKind = $0.vo2PackageKind
            let rhsKind = $1.vo2PackageKind
            if lhsKind.rawValue != rhsKind.rawValue {
                return lhsKind.rawValue < rhsKind.rawValue
            }
            return $0.storeProduct.productIdentifier < $1.storeProduct.productIdentifier
        }
    }
}

@MainActor
final class StoreService: NSObject, ObservableObject, PurchasesDelegate {
    static let shared = StoreService()

    /// App Group key mirroring the live `isPro` entitlement for widget gating.
    static let cachedProKey = "isPro"

    @Published private(set) var isPro = false {
        didSet {
            guard oldValue != isPro else { return }
            defaults.set(isPro, forKey: Self.cachedProKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    @Published private(set) var packages: [Package] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var errorMessage: String?

    /// Per-product free-trial eligibility, resolved after products load. Trial
    /// copy stays hidden until resolved so a used-trial user is never promised
    /// a free week StoreKit will not grant (Apple 3.1.2).
    @Published private(set) var introEligibility: [String: Bool] = [:]
    @Published private(set) var introEligibilityResolved = false

    private let logger = Logger(subsystem: "com.jackwallner.vo2max", category: "Store")
    private let defaults = UserDefaults(suiteName: vo2MaxAppGroupID) ?? .standard
    private var isConfigured = false
    /// Dedupes session-scoped paywall impressions (e.g. locked cards the user
    /// can revisit many times per launch).
    private var paywallImpressionsThisSession: Set<String> = []

    private override init() {
        super.init()
        isPro = defaults.bool(forKey: Self.cachedProKey)
    }

    func start() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-DemoPro") {
            isPro = true
            return
        }
        #endif
        configureIfNeeded()
        guard isConfigured else { return }
        Task {
            await refreshStatus()
            await loadOffering()
        }
    }

    var yearlyPackage: Package? { packages.first { $0.vo2PackageKind == .yearly } }
    var lifetimePackage: Package? { packages.first { $0.vo2PackageKind == .lifetime } }

    func isEligibleForIntroOffer(_ package: Package) -> Bool {
        guard package.vo2IntroOfferLabel != nil else { return false }
        guard introEligibilityResolved else { return false }
        return introEligibility[package.storeProduct.productIdentifier] ?? false
    }

    func eligibleIntroLabel(for package: Package) -> String? {
        guard isEligibleForIntroOffer(package) else { return nil }
        return package.vo2IntroOfferLabel
    }

    /// True when the yearly plan can honestly be pitched as a free trial.
    var canPitchFreeTrial: Bool {
        guard let yearly = yearlyPackage else { return false }
        return isEligibleForIntroOffer(yearly)
    }

    /// Short CTA for locked capsule surfaces.
    var shortConversionCTALabel: String {
        VO2ConversionCopy.shortCTALabel(eligibleForTrial: canPitchFreeTrial)
    }

    @discardableResult
    func purchase(_ package: Package) async -> PurchaseState? {
        guard isConfigured else { return nil }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            update(customerInfo: result.customerInfo)
            if result.userCancelled {
                errorMessage = VO2ConversionCopy.purchaseCancelledMessage(
                    eligibleForTrial: isEligibleForIntroOffer(package)
                )
                return .cancelled
            }
            return isPro ? .purchased : .pending
        } catch {
            let nsError = error as NSError
            if nsError.code == ErrorCode.purchaseCancelledError.rawValue {
                errorMessage = VO2ConversionCopy.purchaseCancelledMessage(
                    eligibleForTrial: isEligibleForIntroOffer(package)
                )
                return .cancelled
            }
            await refreshIntroEligibility()
            errorMessage = VO2ConversionCopy.purchaseFailedMessage(
                eligibleForTrial: isEligibleForIntroOffer(package)
            )
            return nil
        }
    }

    func restore() async {
        guard isConfigured else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            update(customerInfo: try await Purchases.shared.restorePurchases())
            errorMessage = isPro ? nil : "No active VO2+ purchase was found for this Apple ID."
        } catch {
            errorMessage = "Restore failed. Please try again."
        }
    }

    /// Reports a custom-paywall impression to RevenueCat so the native paywall
    /// feeds RC's impression count and conversion %. `id` distinguishes entry
    /// points; `oncePerSession` dedupes surfaces the user can revisit.
    func trackPaywallImpression(id: String, oncePerSession: Bool = false) {
        guard isConfigured else { return }
        if oncePerSession {
            guard !paywallImpressionsThisSession.contains(id) else { return }
            paywallImpressionsThisSession.insert(id)
        }
        Purchases.shared.trackCustomPaywallImpression(
            CustomPaywallImpressionParams(paywallId: id)
        )
    }

    #if DEBUG
    func setLocalOverride(isPro: Bool) {
        self.isPro = isPro
        defaults.set(isPro, forKey: Self.cachedProKey)
    }
    #endif

    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.update(customerInfo: customerInfo)
        }
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        #if targetEnvironment(simulator)
        return
        #else
        guard RevenueCatConfig.publicSDKKey.hasPrefix("appl_") else { return }
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: RevenueCatConfig.publicSDKKey)
        Purchases.shared.delegate = self
        isConfigured = true
        #endif
    }

    private func refreshStatus() async {
        do {
            update(customerInfo: try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent))
        } catch {
            errorMessage = "Could not verify purchases."
        }
    }

    private func loadOffering() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let offerings = try await Purchases.shared.offerings()
            let offering = offerings.offering(identifier: "default") ?? offerings.current
            packages = offering?.vo2SortedPackages ?? []
            errorMessage = nil
            await refreshIntroEligibility()
        } catch {
            logger.error("Product fetch failed: \(String(describing: error), privacy: .public)")
            errorMessage = "Couldn't load purchase options. Check your connection and try again."
        }
    }

    /// Resolves StoreKit intro-offer eligibility for the loaded products. On
    /// any failure we mark resolved with an empty map so callers hide trial
    /// framing rather than over-promising.
    private func refreshIntroEligibility() async {
        let identifiers = packages
            .filter { $0.storeProduct.introductoryDiscount != nil }
            .map { $0.storeProduct.productIdentifier }
        guard !identifiers.isEmpty else {
            introEligibility = [:]
            introEligibilityResolved = true
            return
        }
        let result = await Purchases.shared.checkTrialOrIntroDiscountEligibility(productIdentifiers: identifiers)
        introEligibility = result.mapValues { $0.status == .eligible }
        introEligibilityResolved = true
    }

    private func update(customerInfo: CustomerInfo) {
        // Single premium tier: any active entitlement unlocks VO2+, surviving
        // entitlement renames or casing drift in the RevenueCat dashboard.
        isPro = !customerInfo.entitlements.active.isEmpty
        defaults.set(isPro, forKey: Self.cachedProKey)
    }
}
