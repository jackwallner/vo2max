import Foundation
import HealthKit
import os
import SwiftData
import WidgetKit

private let healthLogger = Logger(subsystem: "com.jackwallner.vo2max", category: "HealthKit")

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    @Published private(set) var isAuthorized: Bool
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastError: String?

    private let store = HKHealthStore()
    private let vo2Type = HKQuantityType(.vo2Max)
    private let unit = HKUnit.literUnit(with: .milli)
        .unitDivided(by: .gramUnit(with: .kilo))
        .unitDivided(by: .minute())
    private var observerQuery: HKObserverQuery?

    private static let grantedKey = "hasGrantedHealthAccess"

    /// Persisted proof that we have actually *read* a VO2 sample at least once —
    /// the only unambiguous signal of read access. HealthKit never reveals read
    /// grants, and `requestAuthorization` returns identically whether the user
    /// allowed or denied, so we must NOT infer "connected" from the request
    /// returning or from an `.unnecessary` probe (both are true after a denial).
    /// A real data read is the one thing a denial can't fake. This seeds
    /// `isAuthorized` from the first frame so users with data never flap, and is
    /// only ever set true.
    private var hasGrantedHealthAccess: Bool {
        get { (UserDefaults(suiteName: vo2MaxAppGroupID) ?? .standard).bool(forKey: Self.grantedKey) }
        set { (UserDefaults(suiteName: vo2MaxAppGroupID) ?? .standard).set(newValue, forKey: Self.grantedKey) }
    }

    private init() {
        // Read defaults directly: instance members aren't available until init
        // completes. Users who have ever read data start out connected.
        isAuthorized = (UserDefaults(suiteName: vo2MaxAppGroupID) ?? .standard).bool(forKey: Self.grantedKey)
    }

    /// Lock in the connected state from the one unambiguous signal: a fetch that
    /// actually returned rows. Persists across launches and only moves toward
    /// connected, so a later transient probe failure can't downgrade a working
    /// install. Never call this merely because a request/probe completed — a
    /// denied read-only app satisfies both of those.
    private func markConnected() {
        hasGrantedHealthAccess = true
        if !isAuthorized { isAuthorized = true }
        installObserver()  // idempotent: no-op if already running
    }

    func requestAuthorization() async throws {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-DemoData") {
            isAuthorized = true
            await refreshCache()
            return
        }
        #endif
        guard HKHealthStore.isHealthDataAvailable() else {
            lastError = "Apple Health is not available on this device."
            return
        }
        try await store.requestAuthorization(toShare: [], read: [vo2Type])
        // The request returns the same for allow and deny, so we can't claim
        // access here. Install the observer for background delivery and let a
        // real data read confirm the connection (see refreshCache/markConnected).
        installObserver()
        await refreshCache()
    }

    func synchronizeAuthorization() async {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-DemoData") {
            isAuthorized = true
            await refreshCache()
            return
        }
        #endif
        guard HKHealthStore.isHealthDataAvailable() else { return }

        // If we were already prompted, keep the observer alive for background
        // delivery, but don't treat that as "connected" — a denial also reports
        // `.unnecessary`. Only a data read (below) proves access.
        if await authorizationRequestStatus() == .unnecessary {
            installObserver()
        }

        // Always attempt a fetch. "No data" and "denied" are indistinguishable
        // for reads, so a flaky probe must never stop us loading data; a fetch
        // that returns rows is itself proof of access and locks in the connected
        // state (see refreshCache).
        await refreshCache()
    }

    func refreshCache() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let readings = try await fetchReadings(days: 365)
            try cache(readings: readings)
            lastError = nil
            // Rows came back, which is only possible with read access granted.
            // Lock in the connected state so a later flaky probe can't undo it.
            if !readings.isEmpty {
                markConnected()
            }
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            // A never-determined authorization state throws here (fresh install
            // before onboarding grants access). That's expected, not a failure,
            // and must not paint a user-facing "Could not refresh" error.
            if (error as? HKError)?.code == .errorAuthorizationNotDetermined {
                healthLogger.info("Refresh skipped: HealthKit authorization not yet determined")
                return
            }
            healthLogger.error("Refresh failed: \(String(describing: error), privacy: .public)")
            lastError = "Could not refresh Apple Health data."
        }
    }

    func fetchReadings(days: Int) async throws -> [CardioFitnessReading] {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-DemoData") {
            return Self.demoReadings(days: days)
        }
        #endif
        let start = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .distantPast
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictEndDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: vo2Type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { [unit] _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let readings = (samples as? [HKQuantitySample] ?? []).map {
                    CardioFitnessReading(
                        id: $0.uuid.uuidString,
                        date: $0.endDate,
                        value: $0.quantity.doubleValue(for: unit),
                        sourceName: $0.sourceRevision.source.name
                    )
                }
                continuation.resume(returning: readings)
            }
            store.execute(query)
        }
    }

    private func authorizationRequestStatus() async -> HKAuthorizationRequestStatus? {
        await withCheckedContinuation { continuation in
            store.getRequestStatusForAuthorization(toShare: [], read: [vo2Type]) { status, error in
                if let error {
                    healthLogger.error("Authorization status failed: \(String(describing: error), privacy: .public)")
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: status)
            }
        }
    }

    private func cache(readings: [CardioFitnessReading]) throws {
        let context = DataService.sharedModelContainer.mainContext
        let existing = try context.fetch(FetchDescriptor<CardioFitnessSample>())
        var byID = Dictionary(uniqueKeysWithValues: existing.map { ($0.healthKitID, $0) })

        // Samples deleted from Apple Health must disappear here too. An empty
        // fetch is left alone: HealthKit returns nothing when read access is
        // off, and that must not wipe a previously valid cache.
        if !readings.isEmpty {
            let fetchedIDs = Set(readings.map(\.id))
            let cutoff = Calendar.current.date(byAdding: .day, value: -365, to: .now) ?? .distantPast
            for record in existing where record.date >= cutoff && !fetchedIDs.contains(record.healthKitID) {
                context.delete(record)
                byID.removeValue(forKey: record.healthKitID)
            }
        }

        for reading in readings {
            if let record = byID[reading.id] {
                record.date = reading.date
                record.value = reading.value
                record.sourceName = reading.sourceName
                record.lastUpdated = .now
            } else {
                let record = CardioFitnessSample(
                    healthKitID: reading.id,
                    date: reading.date,
                    value: reading.value,
                    sourceName: reading.sourceName
                )
                context.insert(record)
                byID[reading.id] = record
            }
        }
        try context.save()
    }

    private func installObserver() {
        guard observerQuery == nil else { return }
        let query = HKObserverQuery(sampleType: vo2Type, predicate: nil) { [weak self] _, completion, error in
            if let error {
                healthLogger.error("Observer failed: \(String(describing: error), privacy: .public)")
                completion()
                return
            }
            completion()
            Task { @MainActor in
                await self?.refreshCache()
            }
        }
        observerQuery = query
        store.execute(query)
        store.enableBackgroundDelivery(for: vo2Type, frequency: .daily) { success, error in
            if !success, let error {
                healthLogger.error("Background delivery failed: \(String(describing: error), privacy: .public)")
            }
        }
    }

    #if DEBUG
    private static func demoReadings(days: Int) -> [CardioFitnessReading] {
        let count = min(max(days / 6, 8), 45)
        return (0..<count).map { index in
            let daysAgo = (count - index - 1) * 6
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
            let wave = sin(Double(index) * 0.65) * 0.7
            return CardioFitnessReading(
                id: "demo-\(index)",
                date: date,
                value: 38.2 + Double(index) * 0.12 + wave,
                sourceName: "Apple Watch"
            )
        }
    }
    #endif
}
