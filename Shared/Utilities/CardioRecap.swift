import Foundation

/// Aggregated cardio-fitness metrics for the VO2+ monthly recap surface.
/// Built from the same `CardioFitnessPoint` history the rest of the app uses,
/// with a 30-day current window compared against the preceding 30 days.
struct CardioRecap: Sendable, Equatable {
    let readingsThisPeriod: Int
    let currentAverage: Double
    let previousAverage: Double?
    let latest: CardioFitnessPoint?
    let periodBest: CardioFitnessPoint?
    let personalBest: CardioFitnessPoint?
    let trend: CardioTrend
    let targetStatus: TargetRangeStatus?

    /// Signed percent change of the current 30-day average vs the prior 30 days.
    /// nil when there is no prior window to compare against.
    var changePct: Double? {
        guard let previousAverage, previousAverage > 0 else { return nil }
        return ((currentAverage - previousAverage) / previousAverage) * 100
    }

    /// True once we have enough to render a meaningful recap.
    var hasContent: Bool { readingsThisPeriod > 0 }
}

@MainActor
enum CardioRecapBuilder {
    /// Build a monthly recap from the full point history plus target/profile context.
    static func build(
        points: [CardioFitnessPoint],
        targetLower: Double,
        targetUpper: Double,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> CardioRecap? {
        guard let windowStart = calendar.date(byAdding: .day, value: -30, to: now) else { return nil }
        let current = points.filter { $0.date >= windowStart && $0.date <= now }
        guard !current.isEmpty else { return nil }

        let comparison = CardioFitnessAnalysis.periodComparison(points: points, days: 30, now: now, calendar: calendar)
        let latest = points.max { $0.date < $1.date }
        let periodBest = current.max { $0.value < $1.value }
        let personalBest = CardioFitnessAnalysis.personalBest(points: points)
        let trend = CardioFitnessAnalysis.trend(points: points, now: now, calendar: calendar)
        let targetStatus = latest.map {
            CardioFitnessAnalysis.targetStatus(value: $0.value, lower: targetLower, upper: targetUpper)
        }

        return CardioRecap(
            readingsThisPeriod: current.count,
            currentAverage: comparison?.currentAverage
                ?? current.reduce(0.0) { $0 + $1.value } / Double(current.count),
            previousAverage: comparison?.previousAverage,
            latest: latest,
            periodBest: periodBest,
            personalBest: personalBest,
            trend: trend,
            targetStatus: targetStatus
        )
    }
}
