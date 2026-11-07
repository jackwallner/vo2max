import Foundation
import Testing
@testable import VO2Max

/// Regression guards for the 2026-11-06 state machine audit
/// (`project-docs/audits/state-machines-2026-11-06-fixes.md`).
struct StateMachineFixTests {
    private let calendar = Calendar.current

    /// Two readings 40 and 47 days ago: no personal cadence (needs four), so
    /// the default 10-day cadence applies and the estimate is long stale.
    private func staleEstimate(now: Date) -> [CardioFitnessPoint] {
        [40, 47].map {
            CardioFitnessPoint(date: calendar.date(byAdding: .day, value: -$0, to: now)!, value: 40)
        }
    }

    /// Replays `HealthKitService.syncFreshnessNudge`: read `lastNudge`, compute
    /// the real `nextNudgeDate`, store it once scheduled (permission granted).
    /// A pending request delivers once its date has passed; the 1 s floor is
    /// `NotificationService.scheduleFreshnessNudge`'s.
    private struct FreshnessNudgeModel {
        var pending: Date?
        var lastNudge: Date?
        var delivered: [Date] = []

        mutating func sync(points: [CardioFitnessPoint], now: Date) {
            deliverDue(by: now)
            guard let date = CardioFreshnessAnalysis.nextNudgeDate(points: points, lastNudge: lastNudge, now: now) else {
                pending = nil
                return
            }
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

    // MARK: - SM-1: freshness nudge spacing

    /// Model-free: a second sync seconds after a spaced one (a cold launch runs
    /// two) must keep the spaced date, not pull it forward to now.
    @Test func sm1_secondSyncSecondsLaterKeepsSpacing() throws {
        let now = Date.now
        let points = staleEstimate(now: now)
        let delivered = try #require(calendar.date(byAdding: .day, value: -1, to: now))

        let first = try #require(CardioFreshnessAnalysis.nextNudgeDate(points: points, lastNudge: delivered, now: now))
        #expect(first == calendar.date(byAdding: .day, value: 5, to: delivered))

        let later = now.addingTimeInterval(5)
        let second = try #require(CardioFreshnessAnalysis.nextNudgeDate(points: points, lastNudge: first, now: later))
        #expect(second == first)
    }

    @Test func sm1_secondForegroundDoesNotPullTheSpacedNudgeForward() throws {
        let t0 = Date.now
        let points = staleEstimate(now: t0)
        var model = FreshnessNudgeModel()
        model.sync(points: points, now: t0)
        let t1 = t0.addingTimeInterval(3600)
        model.sync(points: points, now: t1)
        #expect(model.delivered.count == 1)
        let earliestAllowed = try #require(calendar.date(byAdding: .day, value: 5, to: t0))
        #expect(try #require(model.pending) >= earliestAllowed)

        model.sync(points: points, now: t1.addingTimeInterval(3600))
        #expect(try #require(model.pending) >= earliestAllowed)
    }

    @Test func sm1_staleUserOpeningDailyForTwoWeeksGetsAtMostOneNudgePerFiveDays() throws {
        let start = Date.now
        let points = staleEstimate(now: start)
        var model = FreshnessNudgeModel()
        for day in 0..<14 {
            let open = try #require(calendar.date(byAdding: .day, value: day, to: start))
            // A cold launch syncs twice within seconds.
            model.sync(points: points, now: open)
            model.sync(points: points, now: open.addingTimeInterval(3))
        }
        model.deliverDue(by: try #require(calendar.date(byAdding: .day, value: 15, to: start)))

        #expect(model.delivered.count >= 2)
        let gaps = zip(model.delivered, model.delivered.dropFirst()).map { $1.timeIntervalSince($0) / 86_400 }
        #expect((gaps.min() ?? .infinity) >= 5)
        #expect(model.delivered.count <= 3)
    }

    /// A new estimate still pushes a pending nudge back.
    @Test func sm1_newEstimatePushesPendingNudgeLater() throws {
        let now = Date.now
        let stale = staleEstimate(now: now)
        let pending = try #require(calendar.date(byAdding: .day, value: 3, to: now))
        let fresh = stale + [CardioFitnessPoint(date: now, value: 41)]

        let next = try #require(CardioFreshnessAnalysis.nextNudgeDate(points: fresh, lastNudge: pending, now: now))
        #expect(next > pending)
        #expect(!CardioFreshnessAnalysis.assess(points: fresh, now: next.addingTimeInterval(-86_400)).isStale)
    }
}
