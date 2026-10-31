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
    private var refreshTask: Task<Void, Never>?

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

    /// Re-executes the observer query. **Must be called on every launch,
    /// including the background ones nobody sees.**
    ///
    /// `installObserver` was reachable only through `markAuthorized`, which is
    /// only reachable from `requestAuthorization` and `synchronizeAuthorization`
    /// — and the latter is called from the scene's `.task`. A scene is not
    /// connected when HealthKit background delivery relaunches the app, so the
    /// wake a new estimate generates arrived at a process with no observer
    /// query running and did nothing: the cache was never refreshed and the
    /// iOS widgets stayed on the previous reading until somebody opened the
    /// app. Apple's guidance is to re-execute observer queries as early in
    /// launch as possible. The same gap was found and fixed in Recharge, where
    /// it broke the whole phone → watch chain. VO2MaxWatch reads Health itself
    /// and calls this from its own `App.init`; both targets need the
    /// background-delivery entitlement or the call fails.
    ///
    /// Gated on the persisted grant rather than on a live probe: the probe is
    /// asynchronous and can transiently fail on a cold launch, which is the
    /// whole reason `hasGrantedHealthAccess` exists. Idempotent, so the
    /// authorization paths calling it again cost nothing.
    func enableBackgroundDelivery() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-DemoData") { return }
        #endif
        guard hasGrantedHealthAccess, HKHealthStore.isHealthDataAvailable() else { return }
        installObserver()
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
            lastError = String(localized: "Apple Health is not available on this device.")
            return
        }
        // Ask for the estimate and its supporting cardio signals in one sheet.
        // Only VO2 max gates the connected state and the dashboard; resting heart
        // rate, recovery, and workouts feed VO2+ context and degrade to empty
        // states if the user declines them individually.
        var readTypes: Set<HKObjectType> = [vo2Type]
        readTypes.formUnion(CardioContextService.extendedReadTypes)
        try await store.requestAuthorization(toShare: [], read: readTypes)
        CardioContextService.markExtendedTypesRequested()
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

    /// Runs one refresh at a time. A caller that arrives mid-refresh waits for
    /// it instead of returning early, so the observer acknowledges a background
    /// wake only after the cache, widgets and alerts are updated.
    func refreshCache() async {
        if let inFlight = refreshTask {
            await inFlight.value
            return
        }
        let task = Task { await performRefresh() }
        refreshTask = task
        await task.value
        refreshTask = nil
    }

    private func performRefresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let readings = try await fetchReadings(days: 365)
            // Snapshot the pre-sync latest reading so we can tell a genuinely new
            // estimate from a backfill of old data before mutating the cache.
            let context = DataService.sharedModelContainer.mainContext
            let existing = (try? context.fetch(FetchDescriptor<CardioFitnessSample>())) ?? []
            let priorLatest = existing.max { $0.date < $1.date }
            let priorBest = existing.map(\.value).max()

            let inserted = try cache(readings: readings)
            handleNewReadings(inserted: inserted, priorLatest: priorLatest, priorBest: priorBest)
            syncFreshnessNudge()

            lastError = nil
            // Rows came back, which is only possible with read access granted.
            // Lock in the connected state so a later flaky probe can't undo it.
            if !readings.isEmpty {
                markAuthorized()
                ReviewPromptTracker.recordReadingsAvailable()
                if ReviewPromptTracker.recordReturnWithReading() {
                    NotificationCenter.default.post(name: .vo2PositiveMomentForReview, object: nil)
                }
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
            lastError = String(localized: "Could not refresh Apple Health data.")
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

    /// Applies the fetched readings to the cache and returns the readings that
    /// were newly inserted (not previously present), so callers can react to
    /// genuinely new estimates.
    @discardableResult
    private func cache(readings: [CardioFitnessReading]) throws -> [CardioFitnessReading] {
        let context = DataService.sharedModelContainer.mainContext
        let existing = try context.fetch(FetchDescriptor<CardioFitnessSample>())
        var byID = Dictionary(uniqueKeysWithValues: existing.map { ($0.healthKitID, $0) })

        // Samples deleted from Apple Health must disappear here too.
        let prunable = HealthKitCacheReconciliation.prunableIDs(
            existing: existing.map { CachedRecordKey(id: $0.healthKitID, date: $0.date) },
            fetchedIDs: Set(readings.map(\.id)),
            fetchWindowStart: Calendar.current.date(byAdding: .day, value: -365, to: .now) ?? .distantPast,
            earliestPermitted: store.earliestPermittedSampleDate()
        )
        for record in existing where prunable.contains(record.healthKitID) {
            context.delete(record)
            byID.removeValue(forKey: record.healthKitID)
        }

        var inserted: [CardioFitnessReading] = []
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
                inserted.append(reading)
            }
        }
        try context.save()
        return inserted
    }

    /// Reacts to genuinely new Apple Health estimates: records rating-ask
    /// positive moments (new personal best or entering target range) and, for
    /// entitled opted-in users, posts a new-reading notification with context.
    ///
    /// Guards on `priorLatest`: the first-ever sync backfills a year of history,
    /// and none of that is "new" to the user, so we stay silent until there's an
    /// established latest reading to compare against.
    private func handleNewReadings(
        inserted: [CardioFitnessReading],
        priorLatest: CardioFitnessSample?,
        priorBest: Double?
    ) {
        guard let priorLatest else { return }
        guard let newest = inserted.max(by: { $0.date < $1.date }) else { return }
        // Only treat it as new if it's more recent than everything we already had.
        guard newest.date > priorLatest.date else { return }

        let defaults = UserDefaults(suiteName: vo2MaxAppGroupID) ?? .standard
        let targetLower = defaults.object(forKey: "targetLower") as? Double ?? 35
        let targetUpper = defaults.object(forKey: "targetUpper") as? Double ?? 45

        let isNewPersonalBest = priorBest.map { newest.value > $0 + 0.01 } ?? false
        let nowInRange = newest.value >= targetLower && newest.value <= targetUpper
        let wasInRange = priorLatest.value >= targetLower && priorLatest.value <= targetUpper
        let enteredTarget = nowInRange && !wasInRange

        if isNewPersonalBest || enteredTarget {
            ReviewPromptTracker.recordPositiveMoment()
            NotificationCenter.default.post(name: .vo2PositiveMomentForReview, object: nil)
        }

        // Reading alerts are a VO2+ opt-in feature; both flags live in the app group.
        let isPro = defaults.bool(forKey: vo2CachedProKey)
        let alertsEnabled = defaults.bool(forKey: GoalSettings.readingAlertsKey)
        guard isPro, alertsEnabled else { return }

        let context = readingAlertContext(
            newest: newest.value,
            previous: priorLatest.value,
            isNewPersonalBest: isNewPersonalBest,
            enteredTarget: enteredTarget
        )
        Task {
            await NotificationService.scheduleNewReadingAlert(value: newest.value, context: context)
        }
    }

    /// The VO2+ freshness nudge. VO2 max only refreshes after a qualifying
    /// outdoor workout, so an estimate going quiet is the app's most actionable
    /// moment — and the one users misread as the app being broken.
    ///
    /// Scheduled ahead for the day the estimate turns stale, because nothing
    /// wakes the app then: the observer only fires when a sample is saved or
    /// deleted, and a new sample makes the estimate fresh again. Each refresh
    /// replaces the pending request, so a new estimate pushes it back. Called
    /// after every refresh and whenever entitlement or the toggle changes.
    func syncFreshnessNudge() {
        let defaults = UserDefaults(suiteName: vo2MaxAppGroupID) ?? .standard
        guard defaults.bool(forKey: vo2CachedProKey),
              defaults.bool(forKey: GoalSettings.freshnessNudgesKey) else {
            NotificationService.cancelFreshnessNudge()
            return
        }

        let context = DataService.sharedModelContainer.mainContext
        let samples = (try? context.fetch(FetchDescriptor<CardioFitnessSample>())) ?? []
        let points = samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
        let lastNudge = defaults.object(forKey: Self.lastFreshnessNudgeKey) as? Date
        guard let latest = points.map(\.date).max(),
              let date = CardioFreshnessAnalysis.nextNudgeDate(points: points, lastNudge: lastNudge) else {
            NotificationService.cancelFreshnessNudge()
            return
        }
        let days = Calendar.current.dateComponents([.day], from: latest, to: date).day ?? 0

        Task {
            if await NotificationService.scheduleFreshnessNudge(at: date, daysSinceLatest: days) {
                defaults.set(date, forKey: Self.lastFreshnessNudgeKey)
            }
        }
    }

    private static let lastFreshnessNudgeKey = "lastFreshnessNudge"

    private func readingAlertContext(
        newest: Double,
        previous: Double,
        isNewPersonalBest: Bool,
        enteredTarget: Bool
    ) -> String {
        if isNewPersonalBest { return String(localized: "A new personal best.") }
        if enteredTarget { return String(localized: "That's in your target range.") }
        let delta = newest - previous
        let magnitude = abs(delta).formatted(.number.precision(.fractionLength(1)))
        if delta > 0.05 { return String(localized: "Up \(magnitude) from your last estimate.") }
        if delta < -0.05 { return String(localized: "Down \(magnitude) from your last estimate.") }
        return String(localized: "In line with your last estimate.")
    }

    private func installObserver() {
        guard observerQuery == nil else { return }
        let query = HKObserverQuery(sampleType: vo2Type, predicate: nil) { [weak self] _, completion, error in
            if let error {
                healthLogger.error("Observer failed: \(String(describing: error), privacy: .public)")
                completion()
                return
            }
            // Acknowledge only once the refresh is done: on a background
            // launch the system may suspend the app as soon as HealthKit has
            // its answer, before the cache, widgets and alerts are updated.
            // HealthKit's handler is safe to call from any thread.
            nonisolated(unsafe) let acknowledge = completion
            Task { @MainActor in
                await self?.refreshCache()
                acknowledge()
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

struct CachedRecordKey: Sendable, Equatable {
    let id: String
    let date: Date
}

/// Which cached estimates a fetch proves were deleted from Apple Health.
enum HealthKitCacheReconciliation {
    /// A cached record is gone from Apple Health only if the fetch could have
    /// returned it: it falls inside the fetch window and on or after the store's
    /// `earliestPermittedSampleDate()`. Apple Watch keeps about a week of
    /// HealthKit data, so on the watch anything older is simply out of reach and
    /// must stay cached, or the watch trend never gets the four readings it
    /// needs. On iPhone the permitted date is far in the past and this prunes
    /// the whole window as before.
    ///
    /// An empty fetch prunes nothing: HealthKit returns nothing when read access
    /// is off, and that must not wipe a previously valid cache.
    static func prunableIDs(
        existing: [CachedRecordKey],
        fetchedIDs: Set<String>,
        fetchWindowStart: Date,
        earliestPermitted: Date
    ) -> Set<String> {
        guard !fetchedIDs.isEmpty else { return [] }
        let cutoff = max(fetchWindowStart, earliestPermitted)
        return Set(existing.lazy.filter { $0.date >= cutoff && !fetchedIDs.contains($0.id) }.map(\.id))
    }
}
