import Foundation
import Testing
@testable import VO2Max

/// State machine audit repro, 2026-11-06. Failing tests are expected: each one
/// asserts the promised behaviour. Preconditions are asserted first so a failure
/// means the claim, not a broken setup. Controls pass.
///
/// SM-1: the freshness nudge's "at most once every five days" rule.
/// `HealthKitService.syncFreshnessNudge` (HealthKitService.swift:337-361) does:
///     lastNudge = defaults["lastFreshnessNudge"]
///     date = CardioFreshnessAnalysis.nextNudgeDate(points:, lastNudge:)
///     if await scheduleFreshnessNudge(at: date, ...) { defaults["lastFreshnessNudge"] = date }
/// `FreshnessNudgeModel` below replays exactly that read, compute, write cycle
/// against the real `nextNudgeDate`, and delivers a pending request once its
/// date has passed (a replaced request never delivers).
struct StateMachineAuditRepro {
    private let calendar = Calendar.current

    /// Two readings 40 days ago: no personal cadence (needs four), so the
    /// default 10-day cadence applies and the estimate has been stale for 19 days.
    private func staleEstimate(now: Date) -> [CardioFitnessPoint] {
        [40, 47].map {
            CardioFitnessPoint(date: calendar.date(byAdding: .day, value: -$0, to: now)!, value: 40)
        }
    }

    private struct FreshnessNudgeModel {
        var pending: Date?
        var lastNudge: Date?
        var delivered: [Date] = []

        /// One `syncFreshnessNudge` run at `now`, assuming notification
        /// permission is granted and the schedule call succeeds.
        mutating func sync(points: [CardioFitnessPoint], now: Date) {
            deliverDue(by: now)
            guard let date = CardioFreshnessAnalysis.nextNudgeDate(points: points, lastNudge: lastNudge, now: now) else {
                pending = nil
                return
            }
            // scheduleFreshnessNudge: interval = max(date.timeIntervalSinceNow, 1)
            pending = max(date, now.addingTimeInterval(1))
            lastNudge = date
        }

        mutating func deliverDue(by now: Date) {
            if let p = pending, p <= now {
                delivered.append(p)
                pending = nil
            }
        }
    }

    // MARK: - Control: a single evaluation after a delivered nudge is spaced

    @Test func control_firstEvaluationAfterDeliveredNudgeKeepsSpacing() throws {
        let now = Date.now
        let points = staleEstimate(now: now)
        #expect(CardioFreshnessAnalysis.assess(points: points, now: now).isStale)
        let delivered = try #require(calendar.date(byAdding: .day, value: -1, to: now))

        let next = try #require(CardioFreshnessAnalysis.nextNudgeDate(points: points, lastNudge: delivered, now: now))
        #expect(next == calendar.date(byAdding: .day, value: 5, to: delivered))
    }

    // MARK: - Bug: the second evaluation treats the spaced request as "pending" and cancels the spacing

    @Test func secondForegroundDoesNotPullTheSpacedNudgeForward() throws {
        let t0 = Date.now
        let points = staleEstimate(now: t0)
        #expect(CardioFreshnessAnalysis.assess(points: points, now: t0).isStale)

        var model = FreshnessNudgeModel()
        // Toggle on while stale: first nudge goes out right away.
        model.sync(points: points, now: t0)
        let first = try #require(model.pending)
        #expect(first <= t0.addingTimeInterval(2))
        // Foreground one hour later: the first one has been delivered, so the next is spaced.
        let t1 = t0.addingTimeInterval(3600)
        model.sync(points: points, now: t1)
        #expect(model.delivered.count == 1)
        let spaced = try #require(model.pending)
        let earliestAllowed = try #require(calendar.date(byAdding: .day, value: 5, to: t0))
        #expect(spaced >= earliestAllowed)   // precondition: spacing held once

        // Foreground again one hour after that.
        let t2 = t1.addingTimeInterval(3600)
        model.sync(points: points, now: t2)
        let afterSecond = try #require(model.pending)
        print("RECORDED earliestAllowed=\(earliestAllowed) spaced=\(spaced) afterSecond=\(afterSecond) t2=\(t2)")
        #expect(afterSecond >= earliestAllowed, "nudge pulled forward to \(afterSecond), earliest allowed \(earliestAllowed)")
    }

    @Test func staleUserOpeningDailyForTwoWeeksGetsAtMostOneNudgePerFiveDays() throws {
        let start = Date.now
        let points = staleEstimate(now: start)
        #expect(CardioFreshnessAnalysis.assess(points: points, now: start).isStale)

        var model = FreshnessNudgeModel()
        for day in 0..<14 {
            let open = try #require(calendar.date(byAdding: .day, value: day, to: start))
            model.sync(points: points, now: open)
        }
        model.deliverDue(by: try #require(calendar.date(byAdding: .day, value: 15, to: start)))

        #expect(model.delivered.count >= 2)   // precondition: more than one delivered, so gaps exist
        let gaps = zip(model.delivered, model.delivered.dropFirst()).map { $1.timeIntervalSince($0) / 86_400 }
        let minGap = gaps.min() ?? .infinity
        print("RECORDED delivered=\(model.delivered.count) gapsDays=\(gaps.map { String(format: "%.2f", $0) })")
        #expect(minGap >= 5, "two nudges \(minGap) days apart; delivered \(model.delivered.count) in 14 days")
        #expect(model.delivered.count <= 3, "delivered \(model.delivered.count) nudges in 14 days")
    }
}
