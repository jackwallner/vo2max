import Foundation
import Testing
@testable import VO2Max

/// The range a user picks is resolved into real dates once, here, and every
/// screen reads those dates. A custom window is just a window of `days` that
/// ends somewhere other than today, so the analysis layer never learns about it.
struct CardioRangeTests {
    private let now = Date(timeIntervalSince1970: 1_750_000_000)
    private let calendar = Calendar(identifier: .gregorian)

    @Test func fixedRangeEndsNowAndSpansItsOwnDayCount() {
        let range = CardioRange.fixed(.quarter, now: now, calendar: calendar)
        #expect(range.days == 90)
        #expect(range.end == now)
        #expect(range.start == calendar.date(byAdding: .day, value: -90, to: now))
        #expect(range.contains(now))
        #expect(range.contains(calendar.date(byAdding: .day, value: -89, to: now)!))
        #expect(!range.contains(calendar.date(byAdding: .day, value: -91, to: now)!))
    }

    @Test func customRangeHasNoFixedLength() {
        #expect(MetricRange.custom.fixedDays == nil)
        #expect(MetricRange.quarter.fixedDays == 90)
    }

    @Test func customRangeMeasuresTheGapBetweenTheChosenDates() {
        let start = calendar.date(byAdding: .day, value: -47, to: now)!
        let range = CardioRange.custom(start: start, end: now, calendar: calendar)
        #expect(range.selection == .custom)
        #expect(range.days == 47)
        #expect(range.end == now)
    }

    /// A backwards pair is ordered rather than rejected: the sheet already
    /// blocks it, and a view should never end up with a negative window.
    @Test func customRangeOrdersReversedDates() {
        let earlier = calendar.date(byAdding: .day, value: -30, to: now)!
        let range = CardioRange.custom(start: now, end: earlier, calendar: calendar)
        #expect(range.start == earlier)
        #expect(range.end == now)
        #expect(range.days == 30)
    }

    @Test func customRangeOfOneDayNeverCollapsesToZero() {
        let range = CardioRange.custom(start: now, end: now, calendar: calendar)
        #expect(range.days == 1)
    }

    @Test func trailingRangeCoversAnArbitraryDayCount() {
        let range = CardioRange.trailing(days: 45, now: now, calendar: calendar)
        #expect(range.days == 45)
        #expect(range.end == now)
        #expect(range.start == calendar.date(byAdding: .day, value: -45, to: now))
    }

    /// A custom window's comparison line names its own length, because "prior
    /// 90 days" would be wrong for a 47-day pick.
    @Test func customPriorPhraseNamesItsOwnLength() {
        let start = calendar.date(byAdding: .day, value: -47, to: now)!
        let range = CardioRange.custom(start: start, end: now, calendar: calendar)
        #expect(range.priorPhrase == "previous 47 days")
        #expect(CardioRange.fixed(.quarter, now: now, calendar: calendar).priorPhrase == "prior 90 days")
    }

    /// A one-day custom pick should read "previous 1 day", not "1 days".
    @Test func customPriorPhraseSingularizesOneDay() {
        let range = CardioRange.custom(start: now, end: now, calendar: calendar)
        #expect(range.days == 1)
        #expect(range.priorPhrase == "previous 1 day")
    }

    @Test func weeklyBarsNeverDropBelowFour() {
        #expect(CardioRange.trailing(days: 7, now: now, calendar: calendar).weeks == 4)
        #expect(CardioRange.fixed(.year, now: now, calendar: calendar).weeks == 52)
    }

    /// `weeklyLoad` always trails back from `end`, so padding a short custom
    /// range up to `weeks`' 4-bar floor would pull in weeks before `start`
    /// that the span caption above the chart never claimed to cover. The
    /// fixed presets keep the floor since their day counts already round to
    /// close to a multiple of 7.
    @Test func chartWeeksDoesNotPadACustomRangePastItsOwnSpan() {
        let short = CardioRange.custom(
            start: calendar.date(byAdding: .day, value: -3, to: now)!,
            end: now,
            calendar: calendar
        )
        #expect(short.days == 3)
        #expect(short.chartWeeks == 1)

        let month = CardioRange.custom(
            start: calendar.date(byAdding: .day, value: -30, to: now)!,
            end: now,
            calendar: calendar
        )
        #expect(month.chartWeeks == 5)

        #expect(CardioRange.fixed(.month, now: now, calendar: calendar).chartWeeks == 4)
        #expect(CardioRange.fixed(.year, now: now, calendar: calendar).chartWeeks == 52)
    }

    @Test func spanLabelStatesBothEnds() {
        let range = CardioRange.fixed(.month, now: now, calendar: calendar)
        #expect(range.spanLabel.contains("–"))
        #expect(range.priorSpanLabel(calendar: calendar) != nil)
        #expect(range.priorSpanLabel(calendar: calendar) != range.spanLabel)
    }
}
