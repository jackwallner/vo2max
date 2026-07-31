import Foundation
import Testing
@testable import VO2Max

struct CardioFreshnessTests {
    @Test func noReadingsReportsNoReadings() {
        let freshness = CardioFreshnessAnalysis.assess(points: [], now: referenceDate)
        #expect(freshness.state == .noReadings)
        #expect(freshness.daysSinceLatest == nil)
    }

    @Test func recentReadingIsFresh() {
        let points = makePoints(daysAgo: [0, 9, 18, 27])
        let freshness = CardioFreshnessAnalysis.assess(points: points, now: referenceDate)
        #expect(freshness.state == .fresh)
        #expect(freshness.daysSinceLatest == 0)
    }

    /// The cadence is personal: 20 days is stale for a weekly runner and merely
    /// aging for someone who gets an estimate every three weeks.
    @Test func stalenessFollowsPersonalCadence() {
        let dense = makePoints(daysAgo: [20, 27, 34, 41, 48])
        #expect(CardioFreshnessAnalysis.assess(points: dense, now: referenceDate).state == .stale)

        let sparse = makePoints(daysAgo: [35, 63, 91, 119, 147])
        #expect(CardioFreshnessAnalysis.assess(points: sparse, now: referenceDate).state == .aging)
    }

    @Test func typicalGapNeedsFourReadings() {
        #expect(CardioFreshnessAnalysis.typicalGapDays(points: makePoints(daysAgo: [1, 8, 15]), now: referenceDate) == nil)
        #expect(CardioFreshnessAnalysis.typicalGapDays(points: makePoints(daysAgo: [1, 8, 15, 22]), now: referenceDate) == 7)
    }

    @Test func typicalGapIsClamped() {
        let veryDense = makePoints(daysAgo: [0, 1, 2, 3, 4, 5])
        #expect(CardioFreshnessAnalysis.typicalGapDays(points: veryDense, now: referenceDate)
                == CardioFreshnessAnalysis.minimumGapDays)

        let verySparse = makePoints(daysAgo: [0, 60, 120, 180, 240])
        #expect(CardioFreshnessAnalysis.typicalGapDays(points: verySparse, now: referenceDate)
                == CardioFreshnessAnalysis.maximumGapDays)
    }

    @Test func fallbackThresholdAppliesWithoutCadence() {
        // Two readings: not enough for a personal cadence, so the default applies.
        let points = makePoints(daysAgo: [25, 40])
        let freshness = CardioFreshnessAnalysis.assess(points: points, now: referenceDate)
        #expect(freshness.typicalGapDays == nil)
        #expect(freshness.state == .stale)
    }

    @Test func staleDetailNamesTheRefreshAction() {
        let points = makePoints(daysAgo: [40, 47, 54, 61])
        let freshness = CardioFreshnessAnalysis.assess(points: points, now: referenceDate)
        #expect(freshness.isStale)
        #expect(freshness.detail.contains(CardioFreshnessAnalysis.refreshInstruction))
    }

    // MARK: - Helpers

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_760_000_000)
    }

    private func makePoints(daysAgo: [Int]) -> [CardioFitnessPoint] {
        daysAgo.map { days in
            CardioFitnessPoint(
                date: Calendar.current.date(byAdding: .day, value: -days, to: referenceDate) ?? referenceDate,
                value: 40
            )
        }
    }
}
