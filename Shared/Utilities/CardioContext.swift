import Foundation
import HealthKit

/// Cardio activity buckets used by the VO2+ cardio-load analysis. Only
/// activity types that plausibly build cardio fitness are modelled; anything
/// else is ignored rather than folded into a misleading "other" total.
enum CardioActivityKind: String, Sendable, CaseIterable {
    case walk
    case run
    case hike
    case cycle
    case swim
    case elliptical
    case rowing
    case intervals

    var label: String {
        switch self {
        case .walk: "Walking"
        case .run: "Running"
        case .hike: "Hiking"
        case .cycle: "Cycling"
        case .swim: "Swimming"
        case .elliptical: "Elliptical"
        case .rowing: "Rowing"
        case .intervals: "Intervals"
        }
    }

    var symbol: String {
        switch self {
        case .walk: "figure.walk"
        case .run: "figure.run"
        case .hike: "figure.hiking"
        case .cycle: "figure.outdoor.cycle"
        case .swim: "figure.pool.swim"
        case .elliptical: "figure.elliptical"
        case .rowing: "figure.rower"
        case .intervals: "figure.highintensity.intervaltraining"
        }
    }

    /// Apple Health only records a VO2 max estimate from outdoor walks, runs,
    /// and hikes recorded with Apple Watch. Everything else builds fitness but
    /// never refreshes the number itself, which is the distinction users are
    /// missing when they ask why their estimate hasn't moved.
    var canRefreshEstimate: Bool {
        switch self {
        case .walk, .run, .hike: true
        default: false
        }
    }

    init?(activityType: HKWorkoutActivityType) {
        switch activityType {
        case .walking: self = .walk
        case .running: self = .run
        case .hiking: self = .hike
        case .cycling: self = .cycle
        case .swimming: self = .swim
        case .elliptical: self = .elliptical
        case .rowing: self = .rowing
        case .highIntensityIntervalTraining: self = .intervals
        default: return nil
        }
    }
}

/// A single cardio workout reduced to the fields the analysis needs. `HKWorkout`
/// is not `Sendable`, so the HealthKit query maps to this inside its callback.
struct WorkoutSummary: Sendable, Equatable, Identifiable {
    let id: String
    let date: Date
    let kind: CardioActivityKind
    let minutes: Double
    let isIndoor: Bool

    /// True when this session is the kind Apple Health can use to log a new
    /// VO2 max estimate.
    var refreshesEstimate: Bool { kind.canRefreshEstimate && !isIndoor }
}
