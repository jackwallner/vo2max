import Foundation
import HealthKit
import os

private let contextLogger = Logger(subsystem: "com.jackwallner.vo2max", category: "CardioContext")

/// Reads the cardio signals that surround the VO2 max estimate: resting heart
/// rate, one-minute heart rate recovery, and cardio workouts.
///
/// Deliberately not cached in SwiftData. Widgets and complications show the
/// estimate only, so this data has no cross-process consumer, and keeping it in
/// memory avoids putting a second schema (and its migrations) in front of every
/// target for data that is re-read in well under a second.
@MainActor
final class CardioContextService: ObservableObject {
    static let shared = CardioContextService()

    @Published private(set) var restingHeartRate: [CardioFitnessPoint] = []
    @Published private(set) var heartRateRecovery: [CardioFitnessPoint] = []
    @Published private(set) var workouts: [WorkoutSummary] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastLoaded: Date?

    /// Widest window any screen can ask for. Every VO2+ data screen has a user
    /// range picker up to 1Y, so the read has to cover a full year plus the
    /// preceding year that the vs-previous comparisons need.
    static let historyDays = 730

    private let store = HKHealthStore()
    private let bpm = HKUnit.count().unitDivided(by: .minute())

    /// One-time flag for the extended read prompt. Users who installed before
    /// these types existed were only ever asked about VO2 max, so the upgrade
    /// has to ask again — lazily, when they first open a screen that needs it,
    /// rather than with an unexplained sheet at launch.
    private static let requestedExtendedKey = "hasRequestedExtendedHealthTypes"

    private init() {}

    func points(for metric: HeartMetric) -> [CardioFitnessPoint] {
        switch metric {
        case .restingHeartRate: restingHeartRate
        case .heartRateRecovery: heartRateRecovery
        }
    }

    /// Read types beyond VO2 max. Requested together so the user sees a single
    /// Health sheet rather than one prompt per screen.
    static var extendedReadTypes: Set<HKObjectType> {
        [
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.heartRateRecoveryOneMinute),
            HKObjectType.workoutType()
        ]
    }

    private var hasRequestedExtendedTypes: Bool {
        (UserDefaults(suiteName: vo2MaxAppGroupID) ?? .standard).bool(forKey: Self.requestedExtendedKey)
    }

    /// Records that the extended types have been through a Health prompt. Also
    /// called by `HealthKitService` when onboarding requests everything at once,
    /// so a fresh install never gets a second sheet.
    static func markExtendedTypesRequested() {
        (UserDefaults(suiteName: vo2MaxAppGroupID) ?? .standard).set(true, forKey: requestedExtendedKey)
    }

    func requestAuthorizationIfNeeded() async {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-DemoData") { return }
        #endif
        guard HKHealthStore.isHealthDataAvailable(), !hasRequestedExtendedTypes else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: Self.extendedReadTypes)
            Self.markExtendedTypesRequested()
        } catch {
            contextLogger.error("Extended authorization failed: \(String(describing: error), privacy: .public)")
        }
    }

    /// Loads all three series. Re-reads at most once a minute unless forced —
    /// these screens are navigated between freely and HealthKit queries are not
    /// free, but the data must never look stale after a workout lands.
    func load(force: Bool = false) async {
        if !force, let lastLoaded, Date.now.timeIntervalSince(lastLoaded) < 60 { return }
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        await requestAuthorizationIfNeeded()

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-DemoData") {
            restingHeartRate = Self.demoRestingHeartRate()
            heartRateRecovery = Self.demoHeartRateRecovery()
            workouts = Self.demoWorkouts()
            lastLoaded = .now
            return
        }
        #endif

        guard HKHealthStore.isHealthDataAvailable() else { return }

        async let resting = quantitySeries(type: HKQuantityType(.restingHeartRate), unit: bpm)
        async let recovery = quantitySeries(type: HKQuantityType(.heartRateRecoveryOneMinute), unit: bpm)
        async let sessions = cardioWorkouts()

        restingHeartRate = await resting
        heartRateRecovery = await recovery
        workouts = await sessions
        lastLoaded = .now
    }

    // MARK: - Queries

    /// A denied read type is indistinguishable from "no data" and simply comes
    /// back empty, which every consumer already renders as an empty state — so
    /// query failures are logged, never surfaced as an error banner.
    private func quantitySeries(type: HKQuantityType, unit: HKUnit) async -> [CardioFitnessPoint] {
        let start = Calendar.current.date(byAdding: .day, value: -Self.historyDays, to: .now) ?? .distantPast
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictEndDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    contextLogger.error("Query failed: \(String(describing: error), privacy: .public)")
                    continuation.resume(returning: [])
                    return
                }
                let points = (samples as? [HKQuantitySample] ?? []).map {
                    CardioFitnessPoint(date: $0.endDate, value: $0.quantity.doubleValue(for: unit))
                }
                continuation.resume(returning: points)
            }
            store.execute(query)
        }
    }

    private func cardioWorkouts() async -> [WorkoutSummary] {
        let start = Calendar.current.date(byAdding: .day, value: -Self.historyDays, to: .now) ?? .distantPast
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictEndDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    contextLogger.error("Workout query failed: \(String(describing: error), privacy: .public)")
                    continuation.resume(returning: [])
                    return
                }
                let summaries = (samples as? [HKWorkout] ?? []).compactMap { workout -> WorkoutSummary? in
                    guard let kind = CardioActivityKind(activityType: workout.workoutActivityType) else { return nil }
                    return WorkoutSummary(
                        id: workout.uuid.uuidString,
                        date: workout.endDate,
                        kind: kind,
                        minutes: workout.duration / 60,
                        isIndoor: workout.metadata?[HKMetadataKeyIndoorWorkout] as? Bool ?? false
                    )
                }
                continuation.resume(returning: summaries)
            }
            store.execute(query)
        }
    }

    // MARK: - Demo data

    #if DEBUG
    private static func demoRestingHeartRate() -> [CardioFitnessPoint] {
        // A full 500 days so every range in the picker, and the window before it,
        // has something to draw.
        (0..<500).compactMap { index in
            let daysAgo = 499 - index
            guard let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) else { return nil }
            let drift = -Double(index) * 0.012
            return CardioFitnessPoint(date: date, value: 62 + drift + sin(Double(index) * 0.4) * 1.6)
        }
    }

    private static func demoHeartRateRecovery() -> [CardioFitnessPoint] {
        (0..<125).compactMap { index in
            let daysAgo = (124 - index) * 4
            guard let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) else { return nil }
            return CardioFitnessPoint(date: date, value: 21 + Double(index) * 0.06 + sin(Double(index) * 0.7))
        }
    }

    private static func demoWorkouts() -> [WorkoutSummary] {
        let pattern: [(CardioActivityKind, Double, Bool)] = [
            (.run, 38, false), (.walk, 46, false), (.cycle, 52, false),
            (.run, 30, false), (.hike, 74, false), (.intervals, 24, true)
        ]
        return (0..<166).compactMap { index in
            let daysAgo = 495 - index * 3
            guard daysAgo >= 0,
                  let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) else { return nil }
            let (kind, minutes, indoor) = pattern[index % pattern.count]
            // Volume ramps over the window so the rising-vs-flat comparison has
            // a real signal to find in demo mode.
            let ramp = 0.7 + Double(index) / 166 * 0.7
            return WorkoutSummary(
                id: "demo-workout-\(index)",
                date: date,
                kind: kind,
                minutes: minutes * ramp,
                isIndoor: indoor
            )
        }
    }
    #endif
}
