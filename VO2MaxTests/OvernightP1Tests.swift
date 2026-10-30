import Foundation
import Testing
@testable import VO2Max

/// Guards for the 2026-10-30 overnight report's P1 findings (V01 to V04).
struct OvernightP1Tests {
    // MARK: - V01: Settings restore always reports an outcome

    @Test func restoreWithNothingFoundSaysSo() {
        let message = VO2ConversionCopy.restoreResultMessage(isPro: false, errorMessage: nil)
        #expect(message == "No active VO2+ purchase was found.")
    }

    @Test func restoreFailureShowsTheError() {
        let message = VO2ConversionCopy.restoreResultMessage(isPro: false, errorMessage: "Restore failed. Please try again.")
        #expect(message == "Restore failed. Please try again.")
    }

    @Test func restoreSuccessConfirms() {
        #expect(VO2ConversionCopy.restoreResultMessage(isPro: true, errorMessage: nil) == "VO2+ restored.")
    }

    // MARK: - V02: the stale nudge is scheduled ahead, not only on open

    /// Weekly cadence (7 days), latest 3 days ago: stale after 2 x 7 days, so
    /// the nudge belongs 15 days after the latest estimate, 12 days from now.
    @Test func nudgeIsScheduledForTheDayTheEstimateGoesStale() throws {
        let points = makePoints(daysAgo: [3, 10, 17, 24])
        let date = try #require(CardioFreshnessAnalysis.nextNudgeDate(points: points, lastNudge: nil, now: now))
        let latest = day(-3)
        #expect(date == Calendar.current.date(byAdding: .day, value: 15, to: latest))
        #expect(CardioFreshnessAnalysis.assess(points: points, now: date).isStale)
        let dayBefore = try #require(Calendar.current.date(byAdding: .day, value: -1, to: date))
        #expect(!CardioFreshnessAnalysis.assess(points: points, now: dayBefore).isStale)
    }

    @Test func alreadyStaleNudgesNow() {
        let points = makePoints(daysAgo: [40, 47, 54, 61])
        #expect(CardioFreshnessAnalysis.nextNudgeDate(points: points, lastNudge: nil, now: now) == now)
    }

    @Test func deliveredNudgeKeepsFiveDaySpacing() {
        let points = makePoints(daysAgo: [40, 47, 54, 61])
        let lastNudge = day(-2)
        #expect(
            CardioFreshnessAnalysis.nextNudgeDate(points: points, lastNudge: lastNudge, now: now)
                == Calendar.current.date(byAdding: .day, value: 5, to: lastNudge)
        )
    }

    /// A nudge still pending in the future is the one being replaced, so it
    /// must not push its own replacement back.
    @Test func pendingNudgeDoesNotDelayItsReplacement() {
        let points = makePoints(daysAgo: [3, 10, 17, 24])
        let pending = day(12)
        #expect(CardioFreshnessAnalysis.nextNudgeDate(points: points, lastNudge: pending, now: now) == pending)
    }

    @Test func noReadingsNoNudge() {
        #expect(CardioFreshnessAnalysis.nextNudgeDate(points: [], lastNudge: nil, now: now) == nil)
    }

    // MARK: - V03: the watch keeps estimates its HealthKit has purged

    @Test func purgedOnWatchSurvivesANonEmptyFetch() {
        let existing = [
            CachedRecordKey(id: "old", date: day(-60)),
            CachedRecordKey(id: "recent", date: day(-2)),
            CachedRecordKey(id: "deleted", date: day(-3)),
        ]
        let prunable = HealthKitCacheReconciliation.prunableIDs(
            existing: existing,
            fetchedIDs: ["recent"],
            fetchWindowStart: day(-365),
            earliestPermitted: day(-7)
        )
        #expect(prunable == ["deleted"])
    }

    @Test func iPhoneStillPrunesDeletedHistory() {
        let existing = [CachedRecordKey(id: "old", date: day(-60)), CachedRecordKey(id: "recent", date: day(-2))]
        let prunable = HealthKitCacheReconciliation.prunableIDs(
            existing: existing,
            fetchedIDs: ["recent"],
            fetchWindowStart: day(-365),
            earliestPermitted: .distantPast
        )
        #expect(prunable == ["old"])
    }

    @Test func emptyFetchPrunesNothing() {
        let prunable = HealthKitCacheReconciliation.prunableIDs(
            existing: [CachedRecordKey(id: "a", date: day(-2))],
            fetchedIDs: [],
            fetchWindowStart: day(-365),
            earliestPermitted: .distantPast
        )
        #expect(prunable.isEmpty)
    }

    // MARK: - V04: every target that runs the observer can get background wakes

    @Test(arguments: ["VO2Max/VO2Max.entitlements", "VO2MaxWatch/VO2MaxWatch.entitlements"])
    func targetHasBackgroundDeliveryEntitlement(path: String) throws {
        let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: repo.appendingPathComponent(path))
        let plist = try #require(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        #expect(plist["com.apple.developer.healthkit.background-delivery"] as? Bool == true)
    }

    @Test func watchAppEnablesBackgroundDeliveryAtLaunch() throws {
        let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: repo.appendingPathComponent("VO2MaxWatch/App.swift"), encoding: .utf8)
        #expect(source.contains("init()"))
        #expect(source.contains("enableBackgroundDelivery()"))
    }

    // MARK: - P2 guards

    /// V05: no estimate in the report window is not a 100% decline.
    @MainActor @Test func reportWithNoRecentEstimateHasNoChange() {
        let report = CardioReportGenerator.make(
            title: "Cardio Fitness Report",
            periodStart: day(-180),
            periodEnd: now,
            points: [],
            previousPoints: [CardioFitnessPoint(date: day(-200), value: 42)],
            targetLower: 35,
            targetUpper: 45,
            chronologicalAge: 40,
            referenceSex: .male,
            now: now
        )
        #expect(report.changePct == nil)
    }

    /// V09: an estimate from 23:00 last night is "yesterday" at 09:00.
    @Test func lastNightsEstimateIsYesterday() throws {
        let calendar = Calendar.current
        let morning = try #require(calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now))
        let lastNight = try #require(calendar.date(byAdding: .hour, value: -10, to: morning))
        let freshness = CardioFreshnessAnalysis.assess(points: [CardioFitnessPoint(date: lastNight, value: 40)], now: morning)
        #expect(freshness.daysSinceLatest == 1)
    }

    /// V11: the watch sparkline ends on the newest estimate, given newest first.
    @Test func watchSparklineEndsOnTheNewestEstimate() {
        let newestFirst = (0..<20).map { CardioFitnessPoint(date: day(-$0 * 7), value: 40 + Double(20 - $0) * 0.1) }
        let recent = WatchSparkline.recent(newestFirst)
        #expect(recent.count == 12)
        #expect(recent.last?.date == now)
        #expect(recent.first?.date == day(-11 * 7))
    }

    // MARK: - Helpers

    private var now: Date { Date(timeIntervalSince1970: 1_760_000_000) }

    private func day(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: now) ?? now
    }

    private func makePoints(daysAgo: [Int]) -> [CardioFitnessPoint] {
        daysAgo.map { CardioFitnessPoint(date: day(-$0), value: 40) }
    }
}
