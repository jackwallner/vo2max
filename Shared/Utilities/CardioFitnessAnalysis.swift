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

enum CardioFitnessAnalysis {
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

