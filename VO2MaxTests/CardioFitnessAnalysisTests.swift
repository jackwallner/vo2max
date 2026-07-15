import Foundation
import Testing
@testable import VO2Max

struct CardioFitnessAnalysisTests {
    @Test func improvingTrendUsesRecentHalfComparison() {
        let points = makePoints([35, 35.2, 38, 38.4])
        #expect(CardioFitnessAnalysis.trend(points: points, now: referenceDate) == .improving)
    }

    @Test func smallChangesAreStable() {
        let points = makePoints([40, 40.1, 40.2, 40.3])
        #expect(CardioFitnessAnalysis.trend(points: points, now: referenceDate) == .stable)
    }

    @Test func fewerThanFourReadingsBuildsTrend() {
        let points = makePoints([40, 41, 42])
        #expect(CardioFitnessAnalysis.trend(points: points, now: referenceDate) == .insufficientData)
    }

    @Test func targetRangeIncludesBounds() {
        #expect(CardioFitnessAnalysis.targetStatus(value: 35, lower: 35, upper: 45) == .inRange)
        #expect(CardioFitnessAnalysis.targetStatus(value: 34.9, lower: 35, upper: 45) == .below)
        #expect(CardioFitnessAnalysis.targetStatus(value: 45.1, lower: 35, upper: 45) == .above)
    }

    @Test func fitnessAgeRequiresReferenceSex() {
        #expect(CardioFitnessAnalysis.estimatedFitnessAge(value: 40, referenceSex: .unspecified) == nil)
        #expect(CardioFitnessAnalysis.estimatedFitnessAge(value: 42, referenceSex: .male) == 40)
        #expect(CardioFitnessAnalysis.estimatedFitnessAge(value: 35, referenceSex: .female) == 40)
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_800_000_000)
    }

    private func makePoints(_ values: [Double]) -> [CardioFitnessPoint] {
        values.enumerated().map { index, value in
            CardioFitnessPoint(
                date: Calendar.current.date(byAdding: .day, value: index * 10 - 40, to: referenceDate)!,
                value: value
            )
        }
    }
}

