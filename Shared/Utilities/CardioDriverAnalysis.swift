import Foundation

/// The stretch between two consecutive Apple Health estimates, paired with the
/// cardio training that happened inside it.
struct TrainingWindow: Sendable, Equatable {
    let start: Date
    let end: Date
    /// Change in the estimate across the window.
    let change: Double
    let minutesPerWeek: Double
    let sessionsPerWeek: Double

    /// Rising is deliberately a little above zero: estimate-to-estimate noise of
    /// a tenth or two should not be counted as progress.
    var isRising: Bool { change > 0.1 }
}

/// What separated the windows where the estimate rose from the ones where it
/// didn't. Descriptive only — this reports what the user's own history looked
/// like, it does not prescribe training or claim causation.
struct CardioDriverSummary: Sendable, Equatable {
    let risingCount: Int
    let otherCount: Int
    let risingMinutesPerWeek: Double
    let otherMinutesPerWeek: Double
    let risingSessionsPerWeek: Double
    let otherSessionsPerWeek: Double

    var minutesDifference: Double { risingMinutesPerWeek - otherMinutesPerWeek }
    var windowCount: Int { risingCount + otherCount }
}

struct ActivityTotal: Sendable, Equatable, Identifiable {
    let kind: CardioActivityKind
    let minutes: Double
    let sessions: Int

    var id: String { kind.rawValue }
}

/// Cardio load over a chosen window, normalized per week so 30 days and a year
/// are directly comparable, with the same window before it for contrast.
struct CardioLoadSummary: Sendable, Equatable {
    let minutesPerWeek: Double
    let sessionsPerWeek: Double
    /// The share of the load from sessions Apple Health can draw an estimate
    /// from (outdoor walks, runs, hikes).
    let qualifyingMinutesPerWeek: Double
    let totalMinutes: Double
    let sessions: Int
    /// nil when nothing was recorded before the window, which is different from
    /// a genuine zero-minute stretch.
    let previousMinutesPerWeek: Double?

    var change: Double? { previousMinutesPerWeek.map { minutesPerWeek - $0 } }
}

struct WeeklyLoad: Sendable, Equatable, Identifiable {
    let weekStart: Date
    let minutes: Double
    /// Minutes from sessions that can actually refresh the estimate.
    let qualifyingMinutes: Double

    var id: Date { weekStart }
}

/// Pairs Apple Health estimates with the workouts recorded between them, so the
/// app can answer the second question every VO2 max user has: what did I do
/// differently in the stretches where this number went up?
enum CardioDriverAnalysis {
    /// Windows shorter than this are noise (two estimates from the same weekend);
    /// longer ones smear too much training together to say anything useful.
    static let minimumWindowDays = 3
    static let maximumWindowDays = 60
    /// Below this the comparison is a coin flip, so the UI says "keep going".
    static let minimumWindows = 6
    static let minimumPerBucket = 2

    static func windows(
        points: [CardioFitnessPoint],
        workouts: [WorkoutSummary]
    ) -> [TrainingWindow] {
        let sorted = points.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return [] }

        return zip(sorted, sorted.dropFirst()).compactMap { earlier, later in
            let days = later.date.timeIntervalSince(earlier.date) / 86_400
            guard days >= Double(minimumWindowDays), days <= Double(maximumWindowDays) else { return nil }

            let inWindow = workouts.filter { $0.date > earlier.date && $0.date <= later.date }
            let weeks = days / 7
            return TrainingWindow(
                start: earlier.date,
                end: later.date,
                change: later.value - earlier.value,
                minutesPerWeek: inWindow.reduce(0) { $0 + $1.minutes } / weeks,
                sessionsPerWeek: Double(inWindow.count) / weeks
            )
        }
    }

    /// nil until there are enough windows on both sides for the comparison to
    /// mean anything. Showing a confident-looking split off two data points
    /// would be the same mistake as a fabricated forecast.
    static func summary(windows: [TrainingWindow]) -> CardioDriverSummary? {
        guard windows.count >= minimumWindows else { return nil }
        let rising = windows.filter(\.isRising)
        let other = windows.filter { !$0.isRising }
        guard rising.count >= minimumPerBucket, other.count >= minimumPerBucket else { return nil }

        return CardioDriverSummary(
            risingCount: rising.count,
            otherCount: other.count,
            risingMinutesPerWeek: average(rising.map(\.minutesPerWeek)),
            otherMinutesPerWeek: average(other.map(\.minutesPerWeek)),
            risingSessionsPerWeek: average(rising.map(\.sessionsPerWeek)),
            otherSessionsPerWeek: average(other.map(\.sessionsPerWeek))
        )
    }

    /// One-line read on the comparison, phrased as observation, never advice.
    static func headline(summary: CardioDriverSummary) -> String {
        let difference = summary.minutesDifference
        let rising = Int(summary.risingMinutesPerWeek.rounded())
        let other = Int(summary.otherMinutesPerWeek.rounded())
        if difference >= 10 {
            return "In the stretches where your estimate rose, you averaged \(rising) min/week of cardio versus \(other) in the stretches where it didn't."
        }
        if difference <= -10 {
            return "Your estimate rose on \(rising) min/week of cardio and stalled on \(other) — more volume alone hasn't been what moved it."
        }
        return "Your training volume looks similar whether the estimate rose (\(rising) min/week) or not (\(other) min/week)."
    }

    static func activityTotals(
        workouts: [WorkoutSummary],
        days: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [ActivityTotal] {
        let cutoff = calendar.date(byAdding: .day, value: -days, to: now) ?? .distantPast
        let recent = workouts.filter { $0.date >= cutoff }
        let grouped = Dictionary(grouping: recent, by: \.kind)
        return grouped
            .map { kind, sessions in
                ActivityTotal(
                    kind: kind,
                    minutes: sessions.reduce(0) { $0 + $1.minutes },
                    sessions: sessions.count
                )
            }
            .sorted { $0.minutes > $1.minutes }
    }

    /// Cardio load for a selectable window. nil when the window contains no
    /// cardio workouts at all — the UI then says so rather than showing a
    /// confident 0 min/week that is indistinguishable from a denied read.
    static func loadSummary(
        workouts: [WorkoutSummary],
        days: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> CardioLoadSummary? {
        guard days > 0, let start = calendar.date(byAdding: .day, value: -days, to: now) else { return nil }
        let window = workouts.filter { $0.date >= start && $0.date <= now }
        guard !window.isEmpty else { return nil }

        let weeks = Double(days) / 7
        var previousMinutesPerWeek: Double?
        if let priorStart = calendar.date(byAdding: .day, value: -days * 2, to: now) {
            let prior = workouts.filter { $0.date >= priorStart && $0.date < start }
            if !prior.isEmpty {
                previousMinutesPerWeek = prior.reduce(0) { $0 + $1.minutes } / weeks
            }
        }

        let totalMinutes = window.reduce(0) { $0 + $1.minutes }
        return CardioLoadSummary(
            minutesPerWeek: totalMinutes / weeks,
            sessionsPerWeek: Double(window.count) / weeks,
            qualifyingMinutesPerWeek: window.filter(\.refreshesEstimate).reduce(0) { $0 + $1.minutes } / weeks,
            totalMinutes: totalMinutes,
            sessions: window.count,
            previousMinutesPerWeek: previousMinutesPerWeek
        )
    }

    /// Trailing weekly cardio load, oldest week first, including empty weeks so
    /// the chart shows gaps honestly instead of collapsing them.
    static func weeklyLoad(
        workouts: [WorkoutSummary],
        weeks: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [WeeklyLoad] {
        guard weeks > 0 else { return [] }
        let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now

        return (0..<weeks).reversed().compactMap { offset in
            guard let start = calendar.date(byAdding: .weekOfYear, value: -offset, to: thisWeekStart),
                  let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) else { return nil }
            let inWeek = workouts.filter { $0.date >= start && $0.date < end }
            return WeeklyLoad(
                weekStart: start,
                minutes: inWeek.reduce(0) { $0 + $1.minutes },
                qualifyingMinutes: inWeek.filter(\.refreshesEstimate).reduce(0) { $0 + $1.minutes }
            )
        }
    }

    private static func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}
