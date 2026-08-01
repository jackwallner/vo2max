import Foundation

/// Window every VO2+ data screen works from. The user picks it; it is not a
/// fixed editorial choice, because the people who track VO2 max also want to
/// look at 30 days and at a year without leaving the screen.
enum MetricRange: Int, CaseIterable, Identifiable, Sendable {
    case month = 30
    case quarter = 90
    case halfYear = 180
    case year = 365

    var id: Int { rawValue }
    var days: Int { rawValue }

    /// Segmented-picker label.
    var label: String {
        switch self {
        case .month: "30D"
        case .quarter: "90D"
        case .halfYear: "6M"
        case .year: "1Y"
        }
    }

    /// Used mid-sentence: "…in the last 90 days".
    var phrase: String {
        switch self {
        case .month: "last 30 days"
        case .quarter: "last 90 days"
        case .halfYear: "last 6 months"
        case .year: "last 12 months"
        }
    }

    /// Used for the vs-previous comparison line.
    var priorPhrase: String {
        switch self {
        case .month: "prior 30 days"
        case .quarter: "prior 90 days"
        case .halfYear: "prior 6 months"
        case .year: "prior 12 months"
        }
    }

    /// Number of weekly bars that covers the range without crowding the axis.
    var weeks: Int { max(rawValue / 7, 4) }
}

/// The two Apple Health heart series this app trends alongside the estimate.
/// Named after the actual HealthKit quantity types rather than an editorial
/// grouping, because that's what the metric's audience already calls them.
enum HeartMetric: String, CaseIterable, Identifiable, Sendable {
    case restingHeartRate
    case heartRateRecovery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .restingHeartRate: "Resting Heart Rate"
        case .heartRateRecovery: "Heart Rate Recovery"
        }
    }

    /// Short form for tiles and axis labels.
    var abbreviation: String {
        switch self {
        case .restingHeartRate: "RHR"
        case .heartRateRecovery: "HRR"
        }
    }

    var unit: String { "bpm" }

    /// Disambiguates the two: one is a rate, the other a one-minute drop.
    var unitDetail: String {
        switch self {
        case .restingHeartRate: "bpm at rest"
        case .heartRateRecovery: "bpm drop in 1 min"
        }
    }

    var symbol: String {
        switch self {
        case .restingHeartRate: "bed.double"
        case .heartRateRecovery: "arrow.down.heart"
        }
    }

    var subtitle: String {
        switch self {
        case .restingHeartRate: "Recorded in the background while you wear Apple Watch"
        case .heartRateRecovery: "The one-minute fall after a recorded workout ends"
        }
    }

    /// The HealthKit identifier this series is read from, shown verbatim on the
    /// detail screen so the source of every number is checkable.
    var healthKitIdentifier: String {
        switch self {
        case .restingHeartRate: "HKQuantityTypeIdentifierRestingHeartRate"
        case .heartRateRecovery: "HKQuantityTypeIdentifierHeartRateRecoveryOneMinute"
        }
    }

    /// A falling resting heart rate reads as improving fitness; a bigger
    /// one-minute recovery drop reads the same way. The direction differs, so
    /// every change indicator has to be told which way is up.
    var lowerIsBetter: Bool {
        switch self {
        case .restingHeartRate: true
        case .heartRateRecovery: false
        }
    }

    /// Placeholder digits drawn (blurred) behind the VO2+ lock. Deliberately
    /// invented: the real value is never rendered for a locked user.
    var lockedPlaceholder: String {
        switch self {
        case .restingHeartRate: "58"
        case .heartRateRecovery: "27"
        }
    }
}

/// Descriptive statistics for one HealthKit series over a chosen window, paired
/// with the equivalent window immediately before it.
struct MetricSummary: Sendable, Equatable {
    let latest: Double
    let latestDate: Date
    let average: Double
    let minimum: Double
    let maximum: Double
    let count: Int
    /// nil when the prior window holds no samples, which is different from zero.
    let previousAverage: Double?

    var change: Double? { previousAverage.map { average - $0 } }
}

/// One calendar month of a series, reduced to an average. The detail screens
/// show these as a table: a month-by-month read is what people tracking these
/// numbers actually compare.
struct MonthlyAverage: Sendable, Equatable, Identifiable {
    let monthStart: Date
    let average: Double
    let count: Int

    var id: Date { monthStart }
}

enum CardioMetricAnalysis {
    /// nil when the selected window holds no samples at all, so callers can show
    /// an empty state instead of a zeroed-out card.
    static func summarize(
        points: [CardioFitnessPoint],
        days: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> MetricSummary? {
        guard days > 0,
              let start = calendar.date(byAdding: .day, value: -days, to: now) else { return nil }

        let window = points.filter { $0.date >= start && $0.date <= now }
        guard let latest = window.max(by: { $0.date < $1.date }) else { return nil }
        let values = window.map(\.value)

        var previousAverage: Double?
        if let priorStart = calendar.date(byAdding: .day, value: -days * 2, to: now) {
            let prior = points.filter { $0.date >= priorStart && $0.date < start }.map(\.value)
            if !prior.isEmpty { previousAverage = prior.reduce(0, +) / Double(prior.count) }
        }

        return MetricSummary(
            latest: latest.value,
            latestDate: latest.date,
            average: values.reduce(0, +) / Double(values.count),
            minimum: values.min() ?? latest.value,
            maximum: values.max() ?? latest.value,
            count: values.count,
            previousAverage: previousAverage
        )
    }

    /// Month-by-month averages inside the window, newest month first.
    static func monthlyAverages(
        points: [CardioFitnessPoint],
        days: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [MonthlyAverage] {
        guard days > 0, let start = calendar.date(byAdding: .day, value: -days, to: now) else { return [] }
        let window = points.filter { $0.date >= start && $0.date <= now }
        let grouped = Dictionary(grouping: window) { point in
            calendar.dateInterval(of: .month, for: point.date)?.start ?? point.date
        }
        return grouped
            .map { monthStart, samples in
                MonthlyAverage(
                    monthStart: monthStart,
                    average: samples.reduce(0) { $0 + $1.value } / Double(samples.count),
                    count: samples.count
                )
            }
            .sorted { $0.monthStart > $1.monthStart }
    }

    /// Thins a series to at most `limit` points for chart rendering. A year of
    /// resting heart rate is ~365 marks, which Swift Charts will draw but no one
    /// can read.
    static func downsample(_ points: [CardioFitnessPoint], limit: Int = 180) -> [CardioFitnessPoint] {
        guard limit > 0, points.count > limit else { return points }
        let stride = Int((Double(points.count) / Double(limit)).rounded(.up))
        let sorted = points.sorted { $0.date < $1.date }
        var thinned = sorted.enumerated().compactMap { $0.offset.isMultiple(of: stride) ? $0.element : nil }
        if let last = sorted.last, thinned.last?.date != last.date { thinned.append(last) }
        return thinned
    }
}
