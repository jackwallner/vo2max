import Foundation

/// How current the latest Apple Health estimate is, relative to how often this
/// person's estimates actually arrive.
enum EstimateFreshnessState: String, Sendable {
    case noReadings
    case fresh
    case aging
    case stale
}

struct EstimateFreshness: Sendable, Equatable {
    let state: EstimateFreshnessState
    let daysSinceLatest: Int?
    /// Median days between this person's own estimates, when there is enough
    /// history to establish a cadence. nil falls back to the generic default.
    let typicalGapDays: Int?

    var isStale: Bool { state == .stale }

    var headline: String {
        switch state {
        case .noReadings: "No estimate yet"
        case .fresh: "Estimate is current"
        case .aging: "Estimate is getting old"
        case .stale: "Time to refresh your estimate"
        }
    }

    var detail: String {
        guard let daysSinceLatest else {
            return "Apple Health records a VO2 max estimate after a qualifying outdoor workout with Apple Watch. \(CardioFreshnessAnalysis.refreshInstruction)"
        }
        let ago = CardioFreshnessAnalysis.dayPhrase(daysSinceLatest)
        switch state {
        case .noReadings:
            return "Apple Health records a VO2 max estimate after a qualifying outdoor workout with Apple Watch. \(CardioFreshnessAnalysis.refreshInstruction)"
        case .fresh:
            if let typicalGapDays {
                return "Your last estimate landed \(ago), in line with your usual cadence of about \(typicalGapDays) days."
            }
            return "Your last estimate landed \(ago)."
        case .aging:
            if let typicalGapDays {
                return "Your last estimate landed \(ago). You usually get one about every \(typicalGapDays) days. \(CardioFreshnessAnalysis.refreshInstruction)"
            }
            return "Your last estimate landed \(ago). \(CardioFreshnessAnalysis.refreshInstruction)"
        case .stale:
            if let typicalGapDays {
                return "Your last estimate landed \(ago), well past your usual \(typicalGapDays) days. \(CardioFreshnessAnalysis.refreshInstruction)"
            }
            return "Your last estimate landed \(ago). \(CardioFreshnessAnalysis.refreshInstruction)"
        }
    }
}

/// Answers the question the number itself can't: "why hasn't it updated?"
///
/// VO2 max is not a daily metric — Apple Health only writes an estimate after a
/// qualifying outdoor walk, run, or hike recorded with Apple Watch. Rather than
/// applying a fixed staleness threshold, this compares the gap since the last
/// estimate with the person's own median cadence, so a twice-a-week runner and a
/// once-a-month walker both get an honest read.
enum CardioFreshnessAnalysis {
    /// Used when there isn't enough history to measure a personal cadence.
    static let defaultGapDays = 10
    /// Personal cadence is clamped into this range: a very dense or very sparse
    /// history should not produce absurd expectations.
    static let minimumGapDays = 5
    static let maximumGapDays = 30

    /// The action that actually refreshes the number. Deliberately concrete, and
    /// deliberately not a training prescription.
    static let refreshInstruction = "A brisk outdoor walk, run, or hike of about 20 minutes with Apple Watch on your wrist lets Apple Health record a new one."

    static func assess(
        points: [CardioFitnessPoint],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> EstimateFreshness {
        guard let latest = points.max(by: { $0.date < $1.date }) else {
            return EstimateFreshness(state: .noReadings, daysSinceLatest: nil, typicalGapDays: nil)
        }

        let days = max(calendar.dateComponents([.day], from: latest.date, to: now).day ?? 0, 0)
        let typical = typicalGapDays(points: points, now: now, calendar: calendar)
        let reference = typical ?? defaultGapDays

        let state: EstimateFreshnessState
        if days <= reference {
            state = .fresh
        } else if days <= reference * 2 {
            state = .aging
        } else {
            state = .stale
        }
        return EstimateFreshness(state: state, daysSinceLatest: days, typicalGapDays: typical)
    }

    /// Median gap between consecutive estimates over the last year. Needs four
    /// readings (three gaps) before it claims to know a cadence.
    static func typicalGapDays(
        points: [CardioFitnessPoint],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int? {
        let cutoff = calendar.date(byAdding: .day, value: -365, to: now) ?? .distantPast
        let recent = points.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
        guard recent.count >= 4 else { return nil }

        let gaps = zip(recent, recent.dropFirst()).map {
            $1.date.timeIntervalSince($0.date) / 86_400
        }
        guard !gaps.isEmpty else { return nil }

        let sorted = gaps.sorted()
        let middle = sorted.count / 2
        let median = sorted.count.isMultiple(of: 2)
            ? (sorted[middle - 1] + sorted[middle]) / 2
            : sorted[middle]

        let rounded = Int(median.rounded())
        return min(max(rounded, minimumGapDays), maximumGapDays)
    }

    static func dayPhrase(_ days: Int) -> String {
        switch days {
        case ..<1: "today"
        case 1: "yesterday"
        default: "\(days) days ago"
        }
    }
}
