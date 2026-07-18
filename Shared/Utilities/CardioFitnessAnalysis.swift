import Foundation

enum CardioTrend: String, Sendable {
    case improving
    case stable
    case declining
    case insufficientData

    var label: String {
        switch self {
        case .improving: "Improving"
        case .stable: "Stable"
        case .declining: "Declining"
        case .insufficientData: "Building trend"
        }
    }

    var symbol: String {
        switch self {
        case .improving: "arrow.up.right"
        case .stable: "arrow.right"
        case .declining: "arrow.down.right"
        case .insufficientData: "ellipsis"
        }
    }
}

enum TargetRangeStatus: Sendable {
    case below
    case inRange
    case above

    var label: String {
        switch self {
        case .below: "Below target"
        case .inRange: "In target range"
        case .above: "Above target"
        }
    }
}

struct CardioFitnessPoint: Sendable, Equatable {
    let date: Date
    let value: Double
}

enum ReferenceSex: Int, CaseIterable, Sendable {
    case unspecified = 0
    case female = 1
    case male = 2

    var label: String {
        switch self {
        case .unspecified: "Not set"
        case .female: "Female reference"
        case .male: "Male reference"
        }
    }
}

/// One period-over-period comparison for the VO2+ Deep Trends card.
struct PeriodComparison: Sendable, Equatable {
    let days: Int
    let currentAverage: Double
    let previousAverage: Double?
    let currentCount: Int
    let previousCount: Int

    var change: Double? {
        guard let previousAverage else { return nil }
        return currentAverage - previousAverage
    }
}

/// A slope-based projection for the VO2+ target-range outlook.
struct TrendProjection: Sendable, Equatable {
    /// mL/kg/min change per 30 days over the sampled window.
    let slopePerMonth: Double
    /// Broad month estimate until the target lower bound is reached.
    /// nil when already in/above range or the trend points away from it.
    let monthsToTarget: Int?
    let sampleCount: Int
}

enum CardioFitnessAnalysis {
    /// Average of the last `days` vs the `days` before that. nil current
    /// average means no data in the window (comparison omitted).
    static func periodComparison(
        points: [CardioFitnessPoint],
        days: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> PeriodComparison? {
        guard let currentStart = calendar.date(byAdding: .day, value: -days, to: now),
              let previousStart = calendar.date(byAdding: .day, value: -days * 2, to: now) else { return nil }
        let current = points.filter { $0.date >= currentStart && $0.date <= now }
        let previous = points.filter { $0.date >= previousStart && $0.date < currentStart }
        guard !current.isEmpty else { return nil }
        let currentAverage = current.reduce(0.0) { $0 + $1.value } / Double(current.count)
        let previousAverage = previous.isEmpty
            ? nil
            : previous.reduce(0.0) { $0 + $1.value } / Double(previous.count)
        return PeriodComparison(
            days: days,
            currentAverage: currentAverage,
            previousAverage: previousAverage,
            currentCount: current.count,
            previousCount: previous.count
        )
    }

    /// Least-squares slope over the trailing 180 days, projected toward the
    /// target range. Requires 5+ readings so sparse data never fabricates a
    /// confident-looking forecast. Capped at 24 months — beyond that the
    /// extrapolation is meaningless and we say so instead.
    static func projection(
        points: [CardioFitnessPoint],
        targetLower: Double,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> TrendProjection? {
        let cutoff = calendar.date(byAdding: .day, value: -180, to: now) ?? now
        let recent = points.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
        guard recent.count >= 5, let first = recent.first else { return nil }

        let xs = recent.map { $0.date.timeIntervalSince(first.date) / 86_400 }
        let ys = recent.map(\.value)
        let n = Double(recent.count)
        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).reduce(0) { $0 + $1.0 * $1.1 }
        let sumXX = xs.reduce(0) { $0 + $1 * $1 }
        let denominator = n * sumXX - sumX * sumX
        guard denominator != 0 else { return nil }
        let slopePerDay = (n * sumXY - sumX * sumY) / denominator
        let slopePerMonth = slopePerDay * 30

        guard let latest = recent.last else { return nil }
        var monthsToTarget: Int?
        let gap = targetLower - latest.value
        if gap > 0, slopePerMonth > 0.05 {
            let months = Int((gap / slopePerMonth).rounded(.up))
            monthsToTarget = months <= 24 ? max(months, 1) : nil
        }
        return TrendProjection(
            slopePerMonth: slopePerMonth,
            monthsToTarget: monthsToTarget,
            sampleCount: recent.count
        )
    }

    /// Personal-record and consistency milestones for the VO2+ insights card.
    static func personalBest(points: [CardioFitnessPoint]) -> CardioFitnessPoint? {
        points.max { $0.value < $1.value }
    }

    static func trend(
        points: [CardioFitnessPoint],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> CardioTrend {
        let cutoff = calendar.date(byAdding: .day, value: -90, to: now) ?? now
        let recent = points.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
        guard recent.count >= 4 else { return .insufficientData }

        let midpoint = recent.count / 2
        let older = recent[..<midpoint]
        let newer = recent[midpoint...]
        let olderAverage = older.reduce(0.0) { $0 + $1.value } / Double(older.count)
        let newerAverage = newer.reduce(0.0) { $0 + $1.value } / Double(newer.count)
        let threshold = max(0.5, olderAverage * 0.02)
        let change = newerAverage - olderAverage

        if change > threshold { return .improving }
        if change < -threshold { return .declining }
        return .stable
    }

    static func targetStatus(value: Double, lower: Double, upper: Double) -> TargetRangeStatus {
        if value < lower { return .below }
        if value > upper { return .above }
        return .inRange
    }

    static func change(points: [CardioFitnessPoint], days: Int, now: Date = .now) -> Double? {
        let sorted = points.sorted { $0.date < $1.date }
        guard let latest = sorted.last else { return nil }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        guard let baseline = sorted.first(where: { $0.date >= cutoff }), baseline.date < latest.date else {
            return nil
        }
        return latest.value - baseline.value
    }

    /// Broad reference band for target-setting context. This is motivational
    /// context, not a medical threshold or a performance prescription.
    static func typicalRange(age: Int, referenceSex: ReferenceSex) -> ClosedRange<Double> {
        switch referenceSex {
        case .female, .male:
            let reference = referenceValue(age: age, referenceSex: referenceSex) ?? 35
            return (reference * 0.85)...(reference * 1.15)
        case .unspecified:
            let female = referenceValue(age: age, referenceSex: .female) ?? 35
            let male = referenceValue(age: age, referenceSex: .male) ?? 35
            return (min(female, male) * 0.85)...(max(female, male) * 1.15)
        }
    }

    /// Broad qualitative band for the latest estimate relative to age/sex
    /// reference curves. Purely motivational context, mirroring the coarse
    /// "cardio fitness levels" idea without claiming clinical meaning.
    static func fitnessBand(value: Double, age: Int, referenceSex: ReferenceSex) -> String? {
        guard let reference = referenceValue(age: age, referenceSex: referenceSex) else { return nil }
        let ratio = value / reference
        switch ratio {
        case ..<0.85: return "Below typical range"
        case ..<1.0: return "Around typical range"
        case ..<1.15: return "Above typical range"
        default: return "Well above typical range"
        }
    }

    private static func referenceValue(age: Int, referenceSex: ReferenceSex) -> Double? {
        let references: [(age: Double, value: Double)]
        switch referenceSex {
        case .female:
            references = [(20, 41), (30, 38), (40, 35), (50, 31), (60, 27), (70, 24)]
        case .male:
            references = [(20, 49), (30, 46), (40, 42), (50, 38), (60, 34), (70, 30)]
        case .unspecified:
            return nil
        }
        let clampedAge = min(max(Double(age), references[0].age), references[references.count - 1].age)
        for index in 0..<(references.count - 1) {
            let younger = references[index]
            let older = references[index + 1]
            guard clampedAge >= younger.age, clampedAge <= older.age else { continue }
            let fraction = (clampedAge - younger.age) / (older.age - younger.age)
            return younger.value + fraction * (older.value - younger.value)
        }
        return references.last?.value
    }

    /// A broad fitness-age estimate based on interpolated age-reference curves.
    /// It is intentionally clamped and must never be presented as a clinical result.
    static func estimatedFitnessAge(value: Double, referenceSex: ReferenceSex) -> Int? {
        let references: [(age: Double, value: Double)]
        switch referenceSex {
        case .female:
            references = [(20, 41), (30, 38), (40, 35), (50, 31), (60, 27), (70, 24)]
        case .male:
            references = [(20, 49), (30, 46), (40, 42), (50, 38), (60, 34), (70, 30)]
        case .unspecified:
            return nil
        }

        if value >= references[0].value { return Int(references[0].age) }
        if value <= references[references.count - 1].value { return Int(references[references.count - 1].age) }

        for index in 0..<(references.count - 1) {
            let younger = references[index]
            let older = references[index + 1]
            guard value <= younger.value, value >= older.value else { continue }
            let fraction = (younger.value - value) / (younger.value - older.value)
            return Int((younger.age + fraction * (older.age - younger.age)).rounded())
        }
        return nil
    }
}

