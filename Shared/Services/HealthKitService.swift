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

    /// Persisted "we have been through the Health permission prompt" flag, mirror
    /// of Vitals/Total Calories. HealthKit never reveals read grants and the
    /// request-status probe can transiently fail (healthd not ready after a cold
    /// launch), so this seeds `isAuthorized` from the first frame and is only ever
    /// set true — a flaky probe can never flip it back, which is what caused the
    /// original "no data connected" flap. Data display is independent of it (the
    /// dashboard reads cached samples directly), so a denied user still sees a
    /// graceful "waiting for your first estimate" state, not a dead end.
    private var hasGrantedHealthAccess: Bool {
        get { (UserDefaults(suiteName: vo2MaxAppGroupID) ?? .standard).bool(forKey: Self.grantedKey) }
        set { (UserDefaults(suiteName: vo2MaxAppGroupID) ?? .standard).set(newValue, forKey: Self.grantedKey) }
    }

    private init() {
        // Read defaults directly: instance members aren't available until init
        // completes. Users who have been prompted before start out connected.
        isAuthorized = (UserDefaults(suiteName: vo2MaxAppGroupID) ?? .standard).bool(forKey: Self.grantedKey)
    }

    /// Mark that we've completed the authorization prompt. Like Vitals, this flips
    /// on after the request returns or an `.unnecessary` probe — HealthKit can't
    /// tell us allow vs deny for reads, so "prompted" is the strongest signal we
    /// get, and treating it as connected is what lets the UI show data (or the
    /// encouraging waiting state) immediately after the user grants, instead of
    /// sending them back to Apple Health. Only ever moves toward authorized.
    private func markAuthorized() {
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
        // Prompt complete: show the connected state right away (matches Vitals),
        // then load data. A denial can't be distinguished here, but the dashboard
        // reads cached samples independently so that stays graceful.
        markAuthorized()
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

        // Mirror Vitals' re-check: `.unnecessary` means we were already prompted,
        // so lock in the connected state. Any other result (including a transient
        // nil) is left as-is and never downgrades the flag.
        if await authorizationRequestStatus() == .unnecessary {
            markAuthorized()
        }

        // Always attempt a fetch. "No data" and "denied" are indistinguishable
        // for reads, so a flaky probe must never stop us loading cached data.
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
                markAuthorized()
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
