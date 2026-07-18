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

    @Test func typicalRangeUsesAgeReference() {
        let range = CardioFitnessAnalysis.typicalRange(age: 40, referenceSex: .male)
        #expect(abs(range.lowerBound - 35.7) < 0.001)
        #expect(abs(range.upperBound - 48.3) < 0.001)
    }

    @Test func typicalRangeUsesBroadEnvelopeWithoutReferenceSex() {
        let range = CardioFitnessAnalysis.typicalRange(age: 40, referenceSex: .unspecified)
        #expect(range.lowerBound == 29.75)
        #expect(range.upperBound == 48.3)
    }

    @Test func typicalRangeClampsAgeToReferenceCurves() {
        let young = CardioFitnessAnalysis.typicalRange(age: 12, referenceSex: .female)
        let oldest = CardioFitnessAnalysis.typicalRange(age: 90, referenceSex: .female)
        #expect(abs(young.lowerBound - 34.85) < 0.001)
        #expect(abs(oldest.upperBound - 27.6) < 0.001)
    }

    @Test func fitnessBandTracksReferenceRatio() {
        #expect(CardioFitnessAnalysis.fitnessBand(value: 40, age: 35, referenceSex: .unspecified) == nil)
        // Male age 35 reference = 44. 30/44 < 0.85 -> below.
        #expect(CardioFitnessAnalysis.fitnessBand(value: 30, age: 35, referenceSex: .male) == "Below typical range")
        #expect(CardioFitnessAnalysis.fitnessBand(value: 42, age: 35, referenceSex: .male) == "Around typical range")
        #expect(CardioFitnessAnalysis.fitnessBand(value: 46, age: 35, referenceSex: .male) == "Above typical range")
        #expect(CardioFitnessAnalysis.fitnessBand(value: 55, age: 35, referenceSex: .male) == "Well above typical range")
    }

    @Test func fitnessBandClampsAgeOutsideCurve() {
        #expect(CardioFitnessAnalysis.fitnessBand(value: 30, age: 90, referenceSex: .male) != nil)
        #expect(CardioFitnessAnalysis.fitnessBand(value: 45, age: 18, referenceSex: .female) != nil)
    }

    @Test func periodComparisonSplitsWindows() {
        let calendar = Calendar.current
        let points = [
            CardioFitnessPoint(date: calendar.date(byAdding: .day, value: -45, to: referenceDate)!, value: 38),
            CardioFitnessPoint(date: calendar.date(byAdding: .day, value: -40, to: referenceDate)!, value: 40),
            CardioFitnessPoint(date: calendar.date(byAdding: .day, value: -20, to: referenceDate)!, value: 42),
            CardioFitnessPoint(date: calendar.date(byAdding: .day, value: -10, to: referenceDate)!, value: 44)
        ]
        let comparison = CardioFitnessAnalysis.periodComparison(points: points, days: 30, now: referenceDate)
        #expect(comparison?.currentAverage == 43)
        #expect(comparison?.previousAverage == 39)
        #expect(comparison?.change == 4)
    }

    @Test func periodComparisonNilWithoutCurrentData() {
        let calendar = Calendar.current
        let points = [
            CardioFitnessPoint(date: calendar.date(byAdding: .day, value: -50, to: referenceDate)!, value: 38)
        ]
        #expect(CardioFitnessAnalysis.periodComparison(points: points, days: 30, now: referenceDate) == nil)
    }

    @Test func projectionRequiresFiveReadings() {
        let points = makePoints([38, 39, 40, 41])
        #expect(CardioFitnessAnalysis.projection(points: points, targetLower: 45, now: referenceDate) == nil)
    }

    @Test func projectionEstimatesMonthsToTarget() {
        // Steady +1 per 10 days = +3/month, 5 below target -> ~2 months.
        let calendar = Calendar.current
        let points = (0..<6).map { index in
            CardioFitnessPoint(
                date: calendar.date(byAdding: .day, value: -50 + index * 10, to: referenceDate)!,
                value: 35 + Double(index)
            )
        }
        let projection = CardioFitnessAnalysis.projection(points: points, targetLower: 45, now: referenceDate)
        #expect(projection != nil)
        #expect(projection!.slopePerMonth > 2.5 && projection!.slopePerMonth < 3.5)
        #expect(projection!.monthsToTarget == 2)
    }

    @Test func projectionNoTimeframeWhenDeclining() {
        let calendar = Calendar.current
        let points = (0..<6).map { index in
            CardioFitnessPoint(
                date: calendar.date(byAdding: .day, value: -50 + index * 10, to: referenceDate)!,
                value: 40 - Double(index)
            )
        }
        let projection = CardioFitnessAnalysis.projection(points: points, targetLower: 45, now: referenceDate)
        #expect(projection?.monthsToTarget == nil)
    }

    @Test func personalBestFindsMaximum() {
        let points = makePoints([40, 43, 41])
        #expect(CardioFitnessAnalysis.personalBest(points: points)?.value == 43)
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

