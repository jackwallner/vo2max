import Foundation
import Testing
@testable import VO2Max

struct CardioDriverAnalysisTests {
    @Test func windowsPairConsecutiveEstimates() {
        let points = makePoints([(60, 40.0), (46, 40.6), (32, 40.4)])
        let windows = CardioDriverAnalysis.windows(points: points, workouts: [])
        #expect(windows.count == 2)
        #expect(windows[0].isRising)
        #expect(!windows[1].isRising)
    }

    @Test func windowsDropTooShortAndTooLongGaps() {
        let tooShort = makePoints([(30, 40.0), (29, 41.0)])
        #expect(CardioDriverAnalysis.windows(points: tooShort, workouts: []).isEmpty)

        let tooLong = makePoints([(200, 40.0), (30, 41.0)])
        #expect(CardioDriverAnalysis.windows(points: tooLong, workouts: []).isEmpty)
    }

    @Test func windowMinutesAreNormalizedPerWeek() {
        let points = makePoints([(28, 40.0), (14, 41.0)])
        // Four 60-minute sessions inside a 14-day window: 240 minutes over 2 weeks.
        let workouts = makeWorkouts(daysAgo: [26, 24, 20, 16], minutes: 60)
        let windows = CardioDriverAnalysis.windows(points: points, workouts: workouts)
        #expect(windows.count == 1)
        #expect(abs(windows[0].minutesPerWeek - 120) < 0.001)
        #expect(abs(windows[0].sessionsPerWeek - 2) < 0.001)
    }

    /// Workouts belong to the window they fall inside, not a neighbouring one.
    @Test func workoutsOutsideAWindowAreExcluded() {
        let points = makePoints([(28, 40.0), (14, 41.0)])
        let workouts = makeWorkouts(daysAgo: [40, 5], minutes: 60)
        let windows = CardioDriverAnalysis.windows(points: points, workouts: workouts)
        #expect(windows[0].minutesPerWeek == 0)
    }

    @Test func summaryNeedsEnoughWindowsInBothBuckets() {
        // Five windows: below the minimum, regardless of the split.
        let sparse = (0..<6).map { index in
            window(change: index.isMultiple(of: 2) ? 1.0 : -1.0, minutes: 100)
        }
        #expect(CardioDriverAnalysis.summary(windows: Array(sparse.prefix(5))) == nil)

        // Enough windows, but all of them rising: nothing to compare against.
        let allRising = (0..<8).map { _ in window(change: 1.0, minutes: 100) }
        #expect(CardioDriverAnalysis.summary(windows: allRising) == nil)

        #expect(CardioDriverAnalysis.summary(windows: sparse) != nil)
    }

    @Test func summaryAveragesEachBucketSeparately() {
        let windows = (0..<3).map { _ in window(change: 0.5, minutes: 150) }
            + (0..<3).map { _ in window(change: -0.5, minutes: 50) }
        let summary = CardioDriverAnalysis.summary(windows: windows)
        #expect(summary?.risingCount == 3)
        #expect(summary?.otherCount == 3)
        #expect(summary?.risingMinutesPerWeek == 150)
        #expect(summary?.otherMinutesPerWeek == 50)
        #expect(summary?.minutesDifference == 100)
    }

    /// A tenth of a point is estimate noise, not progress.
    @Test func tinyChangesDoNotCountAsRising() {
        #expect(!window(change: 0.1, minutes: 0).isRising)
        #expect(window(change: 0.2, minutes: 0).isRising)
    }

    @Test func headlineReportsBothAveragesWithoutClaimingCause() {
        let summary = CardioDriverSummary(
            risingCount: 4,
            otherCount: 4,
            risingMinutesPerWeek: 120,
            otherMinutesPerWeek: 60,
            risingSessionsPerWeek: 3,
            otherSessionsPerWeek: 2
        )
        let headline = CardioDriverAnalysis.headline(summary: summary)
        #expect(headline.contains("120"))
        #expect(headline.contains("60"))
    }

    @Test func activityTotalsGroupAndSortByMinutes() {
        let workouts = [
            workout(daysAgo: 5, kind: .walk, minutes: 30),
            workout(daysAgo: 6, kind: .run, minutes: 90),
            workout(daysAgo: 7, kind: .walk, minutes: 45),
            workout(daysAgo: 200, kind: .run, minutes: 500)
        ]
        let totals = CardioDriverAnalysis.activityTotals(workouts: workouts, days: 90, now: referenceDate)
        #expect(totals.count == 2)
        #expect(totals[0].kind == .run)
        #expect(totals[0].minutes == 90)
        #expect(totals[1].kind == .walk)
        #expect(totals[1].sessions == 2)
    }

    @Test func weeklyLoadSeparatesQualifyingMinutes() {
        let workouts = [
            workout(daysAgo: 2, kind: .run, minutes: 40),
            workout(daysAgo: 2, kind: .cycle, minutes: 60),
            workout(daysAgo: 2, kind: .run, minutes: 20, isIndoor: true)
        ]
        let load = CardioDriverAnalysis.weeklyLoad(workouts: workouts, weeks: 4, now: referenceDate)
        #expect(load.count == 4)
        let total = load.reduce(0.0) { $0 + $1.minutes }
        let qualifying = load.reduce(0.0) { $0 + $1.qualifyingMinutes }
        #expect(total == 120)
        // Indoor running and cycling build fitness but can't refresh the estimate.
        #expect(qualifying == 40)
    }

    @Test func indoorSessionsNeverRefreshTheEstimate() {
        #expect(workout(daysAgo: 1, kind: .run, minutes: 30).refreshesEstimate)
        #expect(!workout(daysAgo: 1, kind: .run, minutes: 30, isIndoor: true).refreshesEstimate)
        #expect(!workout(daysAgo: 1, kind: .cycle, minutes: 30).refreshesEstimate)
    }

    // MARK: - Helpers

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_760_000_000)
    }

    private func date(daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: referenceDate) ?? referenceDate
    }

    private func makePoints(_ entries: [(Int, Double)]) -> [CardioFitnessPoint] {
        entries.map { CardioFitnessPoint(date: date(daysAgo: $0.0), value: $0.1) }
    }

    private func makeWorkouts(daysAgo: [Int], minutes: Double) -> [WorkoutSummary] {
        daysAgo.map { workout(daysAgo: $0, kind: .run, minutes: minutes) }
    }

    private func workout(
        daysAgo: Int,
        kind: CardioActivityKind,
        minutes: Double,
        isIndoor: Bool = false
    ) -> WorkoutSummary {
        WorkoutSummary(
            id: "\(kind.rawValue)-\(daysAgo)-\(minutes)-\(isIndoor)",
            date: date(daysAgo: daysAgo),
            kind: kind,
            minutes: minutes,
            isIndoor: isIndoor
        )
    }

    private func window(change: Double, minutes: Double) -> TrainingWindow {
        TrainingWindow(
            start: date(daysAgo: 30),
            end: date(daysAgo: 16),
            change: change,
            minutesPerWeek: minutes,
            sessionsPerWeek: 3
        )
    }
}
