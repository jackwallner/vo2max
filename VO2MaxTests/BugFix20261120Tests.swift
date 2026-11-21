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
}
