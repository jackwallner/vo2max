import Foundation
import Testing
@testable import VO2Max

/// Regression guards for the 2026-11-20 bug catalog
/// (`project-docs/audits/2026-11-20-bug-ux.html`, fixes in
/// `project-docs/audits/2026-11-20-bug-fixes.md`).
@MainActor
@Suite(.serialized)
struct BugFix20261120Tests {
    private let calendar = Calendar.current

    private func date(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    /// Applies a pick through the real store, reads what every screen reads,
    /// then puts the shared selection back.
    private func applied(start: Date, end: Date, now: Date) -> CardioRange {
        let store = CardioRangeStore.shared
        let previous = store.selection
        store.applyCustom(start: start, end: end, now: now, calendar: calendar)
        let range = store.resolved
        store.select(previous == .custom ? .quarter : previous)
        return range
    }

    // MARK: - B3: a custom range covers the whole first and last day

    /// The date-only pickers keep the clock time of their seed (9:00 here).
    @Test func b3_readingEarlyOnThePickedStartDayIsInside() {
        let range = applied(start: date(3, 1, 9), end: date(3, 31, 9), now: date(4, 15, 12))
        #expect(range.contains(date(3, 1, 7, 30)))
    }

    @Test func b3_readingLateOnThePickedEndDayIsInside() {
        let range = applied(start: date(3, 1, 9), end: date(3, 31, 9), now: date(4, 15, 12))
        #expect(range.contains(date(3, 31, 18)))
    }

    @Test func b3_dayBeforeAndAfterStayOutside() {
        let range = applied(start: date(3, 1, 9), end: date(3, 31, 9), now: date(4, 15, 12))
        #expect(!range.contains(date(2, 28, 23, 30)))
        #expect(!range.contains(date(4, 1, 0, 30)))
    }

    // MARK: - B9: picking the same date twice shows that day

    @Test func b9_sameDayPickCoversTheWholeDay() {
        let range = applied(start: date(3, 5, 10), end: date(3, 5, 10), now: date(4, 15, 12))
        #expect(range.contains(date(3, 5, 8)))
        #expect(range.contains(date(3, 5, 15)))
        #expect(!range.contains(date(3, 6, 8)))
    }

    /// The sheet counts whole days, both ends included, so the same date twice
    /// is a valid one-day pick whatever clock times the pickers carry.
    @Test func b9_sheetCountsTheSameDateAsOneDay() {
        #expect(CardioRange.customDayCount(start: date(3, 5, 14), end: date(3, 5, 9), calendar: calendar) == 1)
        #expect(CardioRange.customDayCount(start: date(3, 1, 9), end: date(3, 31, 9), calendar: calendar) == 31)
        #expect(CardioRange.customDayCount(start: date(3, 6, 9), end: date(3, 5, 9), calendar: calendar) < 1)
    }

    /// A one-day range compares against the day before it.
    @Test func b9_oneDayRangeReadsAsOneDay() {
        let range = applied(start: date(3, 5, 10), end: date(3, 5, 10), now: date(4, 15, 12))
        #expect(range.days == 1)
        #expect(range.priorPhrase == "previous 1 day")
    }

    /// Ending today never runs past today, and never more than two years back.
    @Test func b3_pickIsClampedToTodayAndTwoYears() {
        let now = date(4, 15, 12)
        let range = applied(start: date(3, 1, 9), end: calendar.date(byAdding: .day, value: 3, to: now)!, now: now)
        #expect(range.contains(date(4, 15, 23)))
        #expect(!range.contains(date(4, 16, 1)))
        let long = applied(start: calendar.date(byAdding: .year, value: -5, to: now)!, end: now, now: now)
        #expect(long.days == CardioRange.maximumCustomDays)
    }

    // MARK: - B6: VO2+ statistics read the same window as Trends

    /// The catalog's case: a custom range from Oct 10 10:00 to Nov 20 09:00 and
    /// a reading on Oct 10 at 15:00, which Trends lists.
    @Test func b6_signalSummaryAgreesWithRangeContains() throws {
        let range = CardioRange.custom(start: date(10, 10, 10), end: date(11, 20, 9), calendar: calendar)
        let reading = CardioFitnessPoint(date: date(10, 10, 15), value: 58)
        #expect(range.contains(reading.date))
        // Read exactly as `SignalReading.make` and the detail screen read it.
        let summary = CardioMetricAnalysis.summarize(
            points: [reading, CardioFitnessPoint(date: date(10, 10, 8), value: 60)],
            days: range.days,
            start: range.start,
            now: range.end,
            calendar: calendar
        )
        // The 08:00 reading is before the range starts and stays out.
        #expect(summary?.count == 1)
        let months = CardioMetricAnalysis.monthlyAverages(
            points: [reading], days: range.days, start: range.start, now: range.end, calendar: calendar
        )
        #expect(months.first?.count == 1)
    }

    @Test func b6_cardioLoadAgreesWithRangeContains() {
        let range = CardioRange.custom(start: date(10, 10, 10), end: date(11, 20, 9), calendar: calendar)
        let workout = WorkoutSummary(id: "w", date: date(10, 10, 15), kind: .run, minutes: 30, isIndoor: false)
        #expect(range.contains(workout.date))
        let summary = CardioDriverAnalysis.loadSummary(
            workouts: [workout],
            days: range.days,
            start: range.start,
            now: range.end,
            calendar: calendar
        )
        #expect(summary?.sessions == 1)
        let totals = CardioDriverAnalysis.activityTotals(
            workouts: [workout],
            days: range.days,
            start: range.start,
            now: range.end,
            calendar: calendar
        )
        #expect(totals.first?.sessions == 1)
    }

    /// Trends' Change figure starts from the same first reading Trends lists.
    @Test func b6_trendsChangeStartsAtTheRangeStart() {
        let range = CardioRange.custom(start: date(10, 10, 10), end: date(11, 20, 9), calendar: calendar)
        let points = [
            CardioFitnessPoint(date: date(10, 10, 8), value: 40),
            CardioFitnessPoint(date: date(10, 10, 15), value: 44),
            CardioFitnessPoint(date: date(11, 15, 9), value: 46),
        ]
        let change = CardioFitnessAnalysis.change(points: points, days: range.days, start: range.start, now: range.end)
        #expect(change == 2)
    }

    /// The vs-previous window sits directly before the range, for a fixed
    /// window exactly where it always was.
    @Test func b6_previousWindowEndsWhereTheRangeStarts() throws {
        let range = CardioRange.custom(start: date(10, 10, 10), end: date(11, 20, 9), calendar: calendar)
        let before = CardioFitnessPoint(date: date(10, 9, 20), value: 50)
        let inside = CardioFitnessPoint(date: date(10, 10, 15), value: 58)
        let summary = try #require(CardioMetricAnalysis.summarize(
            points: [before, inside], days: range.days, start: range.start, now: range.end, calendar: calendar
        ))
        #expect(summary.previousAverage == 50)

        let fixed = CardioRange.fixed(.month, now: date(11, 20, 9), calendar: calendar)
        let points = [CardioFitnessPoint(date: date(10, 1, 9), value: 41), CardioFitnessPoint(date: date(11, 1, 9), value: 43)]
        #expect(
            CardioMetricAnalysis.summarize(points: points, days: fixed.days, start: fixed.start, now: fixed.end, calendar: calendar)
                == CardioMetricAnalysis.summarize(points: points, days: fixed.days, now: fixed.end, calendar: calendar)
        )
    }

    // MARK: - B4: a purchase waiting for approval is not a failure

    /// RevenueCat's error codes (`ErrorCode` raw values, stable public API):
    /// 20 paymentPendingError, 1 purchaseCancelledError, 10 networkError. The
    /// test bundle does not link RevenueCat, so they are written out here.
    private func revenueCatError(_ code: Int) -> NSError {
        NSError(domain: "RevenueCat.ErrorCode", code: code)
    }

    @Test func b4_deferredPurchaseIsPending() {
        #expect(StoreService.outcome(ofThrown: revenueCatError(20)) == .pending)
        #expect(StoreService.outcome(ofThrown: revenueCatError(1)) == .cancelled)
        #expect(StoreService.outcome(ofThrown: revenueCatError(10)) == nil)
    }

    @Test func b4_pendingCopyDoesNotInviteARetry() {
        let message = VO2ConversionCopy.purchasePendingMessage
        #expect(message.contains("approv"))
        #expect(!message.localizedCaseInsensitiveContains("try again"))
        #expect(message != VO2ConversionCopy.purchaseFailedMessage(eligibleForTrial: true))
    }

    // MARK: - B8: the freshness nudge arrives in the daytime

    /// Weekly cadence and a last estimate written at 5:40 after a dawn run.
    @Test func b8_nudgeAfterADawnEstimateWaitsForDaytime() throws {
        let latest = date(11, 3, 5, 40)
        let points = [21, 14, 7, 0].map {
            CardioFitnessPoint(date: calendar.date(byAdding: .day, value: -$0, to: latest)!, value: 42)
        }
        let nudge = try #require(CardioFreshnessAnalysis.nextNudgeDate(
            points: points, lastNudge: nil, now: date(11, 4, 12), calendar: calendar
        ))
        let hour = calendar.component(.hour, from: nudge)
        #expect((10..<19).contains(hour), "nudge at \(nudge)")
        // Never earlier than the day the estimate goes stale.
        #expect(CardioFreshnessAnalysis.assess(points: points, now: nudge, calendar: calendar).isStale)
    }

    /// Already stale, synced by a background wake at 2:00.
    @Test func b8_staleNudgeFromANightWakeWaitsForMorning() throws {
        let points = [61, 54, 47, 40].map {
            CardioFitnessPoint(date: calendar.date(byAdding: .day, value: -$0, to: date(11, 4, 12))!, value: 42)
        }
        let wake = date(11, 4, 2)
        let nudge = try #require(CardioFreshnessAnalysis.nextNudgeDate(
            points: points, lastNudge: nil, now: wake, calendar: calendar
        ))
        #expect(nudge == date(11, 4, 10))
    }

    @Test func b8_lateEveningNudgeMovesToNextMorning() throws {
        let points = [61, 54, 47, 40].map {
            CardioFitnessPoint(date: calendar.date(byAdding: .day, value: -$0, to: date(11, 4, 12))!, value: 42)
        }
        let nudge = try #require(CardioFreshnessAnalysis.nextNudgeDate(
            points: points, lastNudge: nil, now: date(11, 4, 21, 15), calendar: calendar
        ))
        #expect(nudge == date(11, 5, 10))
    }

    /// The five-day spacing still holds after the move.
    @Test func b8_daytimeMoveKeepsTheSpacing() throws {
        let points = [61, 54, 47, 40].map {
            CardioFitnessPoint(date: calendar.date(byAdding: .day, value: -$0, to: date(11, 4, 12))!, value: 42)
        }
        let delivered = date(11, 1, 22)
        let nudge = try #require(CardioFreshnessAnalysis.nextNudgeDate(
            points: points, lastNudge: delivered, now: date(11, 4, 12), calendar: calendar
        ))
        #expect(nudge == date(11, 7, 10))
        #expect(nudge >= calendar.date(byAdding: .day, value: 5, to: delivered)!)
    }

    // MARK: - B7: Estimate Freshness rereads the notification setting

    private func source(_ path: String) throws -> String {
        let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        return try String(contentsOf: repo.appendingPathComponent(path), encoding: .utf8)
    }

    /// Same pattern as Settings: on returning to the app, ask iOS again.
    @Test func b7_freshnessScreenRereadsDenialOnReturn() throws {
        let file = try source("VO2Max/Views/CardioContextViews.swift")
        let start = try #require(file.range(of: "struct EstimateFreshnessDetailView"))
        let view = file[start.lowerBound...]
        let body = String(view[..<(view.range(of: "private var statusCard")?.lowerBound ?? view.endIndex)])
        #expect(body.contains("@Environment(\\.scenePhase)"))
        #expect(body.contains(".onChange(of: scenePhase)"))
        #expect(body.contains("phase == .active"))
        #expect(body.components(separatedBy: "NotificationService.isDenied()").count == 3)
    }
}
