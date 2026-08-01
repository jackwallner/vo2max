import Foundation
import Testing
@testable import VO2Max

struct CardioMetricAnalysisTests {
    private let now = Date(timeIntervalSince1970: 1_750_000_000)

    @Test func summarizeCoversOnlyTheSelectedWindow() {
        // 10 and 20 days ago are inside 30D; 45 days ago is not.
        let points = makePoints([(10, 54), (20, 58), (45, 70)])
        let summary = CardioMetricAnalysis.summarize(points: points, days: 30, now: now)
        #expect(summary?.count == 2)
        #expect(summary?.latest == 54)
        #expect(summary?.average == 56)
        #expect(summary?.minimum == 54)
        #expect(summary?.maximum == 58)
    }

    @Test func summarizeReturnsNilWhenTheWindowIsEmpty() {
        let points = makePoints([(120, 54)])
        #expect(CardioMetricAnalysis.summarize(points: points, days: 30, now: now) == nil)
    }

    /// The comparison window is the same length, immediately before the current
    /// one — not an arbitrary fixed 30 days.
    @Test func changeComparesAgainstTheEquivalentPriorWindow() {
        let points = makePoints([(10, 50), (20, 52), (100, 60), (150, 64)])
        let summary = CardioMetricAnalysis.summarize(points: points, days: 90, now: now)
        #expect(summary?.average == 51)
        #expect(summary?.previousAverage == 62)
        #expect(summary?.change == -11)
    }

    /// No samples in the prior window is different from a prior average of zero,
    /// so the change has to be absent rather than misleading.
    @Test func changeIsNilWithoutAPriorWindow() {
        let points = makePoints([(10, 50), (20, 52)])
        let summary = CardioMetricAnalysis.summarize(points: points, days: 90, now: now)
        #expect(summary?.previousAverage == nil)
        #expect(summary?.change == nil)
    }

    @Test func monthlyAveragesAreGroupedNewestFirst() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        // Two readings in one month, one in an earlier month.
        let points = makePoints([(5, 50), (9, 54), (45, 60)])
        let months = CardioMetricAnalysis.monthlyAverages(points: points, days: 90, now: now, calendar: calendar)
        #expect(months.count == 2)
        #expect(months[0].monthStart > months[1].monthStart)
        #expect(months[0].count == 2)
        #expect(months[0].average == 52)
    }

    @Test func downsampleKeepsTheMostRecentPoint() {
        let points = (0..<400).map {
            CardioFitnessPoint(date: now.addingTimeInterval(Double($0) * 86_400), value: Double($0))
        }
        let thinned = CardioMetricAnalysis.downsample(points, limit: 50)
        #expect(thinned.count <= 51)
        #expect(thinned.last?.value == 399)
    }

    @Test func downsampleLeavesShortSeriesAlone() {
        let points = makePoints([(1, 50), (2, 51)])
        #expect(CardioMetricAnalysis.downsample(points, limit: 50).count == 2)
    }

    @Test func rangeWeeksCoverTheWindow() {
        #expect(MetricRange.month.weeks == 4)
        #expect(MetricRange.quarter.weeks == 12)
        #expect(MetricRange.year.weeks == 52)
    }

    /// A falling resting heart rate is progress; a falling recovery is not. The
    /// change indicators read this, so it must not drift.
    @Test func heartMetricsDeclareTheirGoodDirection() {
        #expect(HeartMetric.restingHeartRate.lowerIsBetter)
        #expect(!HeartMetric.heartRateRecovery.lowerIsBetter)
    }

    private func makePoints(_ entries: [(Int, Double)]) -> [CardioFitnessPoint] {
        entries.map { daysAgo, value in
            CardioFitnessPoint(date: now.addingTimeInterval(-Double(daysAgo) * 86_400), value: value)
        }
    }
}
