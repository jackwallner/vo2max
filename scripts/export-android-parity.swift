import Foundation

let now = Date(timeIntervalSince1970: 1_760_000_000)
let null = NSNull()
var rows: [[String: Any]] = []
for scenario in 0..<60 {
    let count = scenario % 16
    let gap = (scenario % 9 + 1) * 3
    let points = (0..<count).map { index in
        CardioFitnessPoint(date: now.addingTimeInterval(Double(-gap * (count - index) + scenario % 5) * 86_400), value: 31 + Double(index) * Double(scenario % 5 - 2) * 0.31 + sin(Double(index)) * 0.3)
    }
    let days = [30, 90, 180, 365][scenario % 4]
    let sex = ReferenceSex(rawValue: scenario % 3)!
    let age = 12 + scenario * 2
    let summary = CardioMetricAnalysis.summarize(points: points, days: days, now: now)
    let projection = CardioFitnessAnalysis.projection(points: points, targetLower: 45, now: now)
    let fresh = CardioFreshnessAnalysis.assess(points: points, now: now)
    let comparison = CardioFitnessAnalysis.periodComparison(points: points, days: days, now: now)
    let typical = CardioFitnessAnalysis.typicalRange(age: age, referenceSex: sex)
    rows.append([
        "name": "swift-scenario-\(scenario)", "now": now.timeIntervalSince1970, "days": days,
        "points": points.map { ["date": $0.date.timeIntervalSince1970, "value": $0.value] },
        "sex": scenario % 3, "age": age,
        "trend": CardioFitnessAnalysis.trend(points: points, now: now).rawValue,
        "change": CardioFitnessAnalysis.change(points: points, days: days, now: now) as Any? ?? null,
        "fitnessAge": CardioFitnessAnalysis.estimatedFitnessAge(value: 31 + Double(scenario), referenceSex: sex) as Any? ?? null,
        "band": CardioFitnessAnalysis.fitnessBand(value: 31 + Double(scenario), age: age, referenceSex: sex) as Any? ?? null,
        "typicalLower": typical.lowerBound, "typicalUpper": typical.upperBound,
        "summary": summary.map { ["latest": $0.latest, "average": $0.average, "minimum": $0.minimum, "maximum": $0.maximum, "count": $0.count, "previous": $0.previousAverage as Any? ?? null] } as Any? ?? null,
        "projection": projection.map { ["slope": $0.slopePerMonth, "months": $0.monthsToTarget as Any? ?? null, "count": $0.sampleCount] } as Any? ?? null,
        "freshness": ["state": fresh.state.rawValue, "days": fresh.daysSinceLatest as Any? ?? null, "gap": fresh.typicalGapDays as Any? ?? null],
        "comparison": comparison.map { ["current": $0.currentAverage, "previous": $0.previousAverage as Any? ?? null, "count": $0.currentCount, "priorCount": $0.previousCount] } as Any? ?? null
    ])
}
let data = try JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print("Exported \(rows.count) parity scenarios from unchanged Swift analysis")
