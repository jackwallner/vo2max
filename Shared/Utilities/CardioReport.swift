import Foundation

/// One VO2 max estimate in a report period.
struct ReportReading: Sendable, Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double
}

/// Result payload rendered by `CardioReportView` (PDF) and the share text.
struct CardioReport: Sendable {
    let title: String
    let periodStart: Date
    let periodEnd: Date
    let readings: [ReportReading]

    let average: Double
    let minValue: Double
    let maxValue: Double
    let latest: ReportReading?
    let peak: ReportReading?

    /// Period-over-period percent change vs. the preceding window of equal length.
    /// nil if there is no prior data to compare against.
    let changePct: Double?

    let targetLower: Double
    let targetUpper: Double
    let readingsInTarget: Int

    let trend: CardioTrend
    let fitnessBand: String?
    let fitnessAge: Int?
    let chronologicalAge: Int

    var readingCount: Int { readings.count }

    var calendarLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        return "\(f.string(from: periodStart)) – \(f.string(from: periodEnd))"
    }
}

@MainActor
enum CardioReportGenerator {
    /// Build a report from a current period's readings plus an optional preceding
    /// period of equal length for the trend percentage, and profile context.
    static func make(
        title: String,
        periodStart: Date,
        periodEnd: Date,
        points: [CardioFitnessPoint],
        previousPoints: [CardioFitnessPoint] = [],
        targetLower: Double,
        targetUpper: Double,
        chronologicalAge: Int,
        referenceSex: ReferenceSex,
        allPointsForTrend: [CardioFitnessPoint]? = nil,
        now: Date = .now
    ) -> CardioReport {
        let readings = points
            .sorted { $0.date < $1.date }
            .map { ReportReading(date: $0.date, value: $0.value) }

        let values = readings.map(\.value)
        let count = max(values.count, 1)
        let average = values.reduce(0, +) / Double(count)
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 0
        let latest = readings.last
        let peak = readings.max { $0.value < $1.value }

        let currentAvg = average
        let previousValues = previousPoints.map(\.value)
        let previousAvg = previousValues.isEmpty ? 0 : previousValues.reduce(0, +) / Double(previousValues.count)
        let changePct: Double? = previousAvg > 0 ? ((currentAvg - previousAvg) / previousAvg) * 100 : nil

        let inTarget = readings.filter { $0.value >= targetLower && $0.value <= targetUpper }.count

        let trendPoints = allPointsForTrend ?? points
        let trend = CardioFitnessAnalysis.trend(points: trendPoints, now: now)

        let band = latest.flatMap {
            CardioFitnessAnalysis.fitnessBand(value: $0.value, age: chronologicalAge, referenceSex: referenceSex)
        }
        let fitnessAge = latest.flatMap {
            CardioFitnessAnalysis.estimatedFitnessAge(value: $0.value, referenceSex: referenceSex)
        }

        return CardioReport(
            title: title,
            periodStart: periodStart,
            periodEnd: periodEnd,
            readings: readings,
            average: average,
            minValue: minValue,
            maxValue: maxValue,
            latest: latest,
            peak: peak,
            changePct: changePct,
            targetLower: targetLower,
            targetUpper: targetUpper,
            readingsInTarget: inTarget,
            trend: trend,
            fitnessBand: band,
            fitnessAge: fitnessAge,
            chronologicalAge: chronologicalAge
        )
    }
}
