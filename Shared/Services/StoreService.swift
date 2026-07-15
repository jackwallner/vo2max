import Combine
import Foundation
import RevenueCat

enum RevenueCatConfig {
    /// Replace with the app-specific public key that begins with `appl_`.
    /// Secret `sk_` keys must never ship in an app binary.
    static let publicSDKKey = "appl_fRNEUFcviKvUbOLAnHkzIrbyFPA"
}

@MainActor
final class StoreService: NSObject, ObservableObject, PurchasesDelegate {
    static let shared = StoreService()

    @Published private(set) var isPro = false
    @Published private(set) var packages: [Package] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let defaults = UserDefaults(suiteName: vo2MaxAppGroupID) ?? .standard
    private var isConfigured = false

    private override init() {
        super.init()
        isPro = defaults.bool(forKey: "isPro")
    }

    func start() {
        configureIfNeeded()
        guard isConfigured else { return }
        Task {
            await refreshStatus()
            await loadOffering()
        }
    }

    var yearlyPackage: Package? { packages.first { $0.packageType == .annual } }

    func purchase(_ package: Package) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            update(customerInfo: result.customerInfo)
        } catch {
            let nsError = error as NSError
            if nsError.code != ErrorCode.purchaseCancelledError.rawValue {
                errorMessage = "Purchase failed. Please try again."
            }
        }
    }

    func restore() async {
        guard isConfigured else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            update(customerInfo: try await Purchases.shared.restorePurchases())
        } catch {
            errorMessage = "Restore failed. Please try again."
        }
    }

    #if DEBUG
    func setLocalOverride(isPro: Bool) {
        self.isPro = isPro
        defaults.set(isPro, forKey: "isPro")
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
        do {
            let offering = try await Purchases.shared.offerings().current
            packages = offering?.availablePackages.sorted { lhs, rhs in
                rank(lhs.packageType) < rank(rhs.packageType)
            } ?? []
        } catch {
            errorMessage = "Could not load purchase options."
        }
    }

    private func update(customerInfo: CustomerInfo) {
        isPro = !customerInfo.entitlements.active.isEmpty
        defaults.set(isPro, forKey: "isPro")
    }

    private func rank(_ type: PackageType) -> Int {
        switch type {
        case .annual: 0
        case .monthly: 1
        case .lifetime: 2
        default: 3
        }
    }
}
