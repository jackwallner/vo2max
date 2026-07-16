import SwiftData
import SwiftUI

struct WatchTodayView: View {
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]
    @StateObject private var health = HealthKitService.shared

    private var points: [CardioFitnessPoint] {
        samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
    }

    private var sparkline: some View {
        let recent = points.suffix(12).sorted { $0.date < $1.date }
        let values = recent.map(\.value)
        let low = values.min() ?? 0
        let span = max((values.max() ?? 1) - low, 0.5)
        return GeometryReader { geometry in
            Path { path in
                for (index, point) in recent.enumerated() {
                    let x = geometry.size.width * CGFloat(index) / CGFloat(max(recent.count - 1, 1))
                    let y = geometry.size.height * (1 - CGFloat((point.value - low) / span))
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Theme.cardio, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .accessibilityLabel("Recent readings trend")
    }

    var body: some View {
        ScrollView {
            if let latest = samples.first {
                let trend = CardioFitnessAnalysis.trend(points: points)
                VStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Theme.cardio)
                    Text(latest.value, format: .number.precision(.fractionLength(1)))
                        .font(Theme.numberFont(40))
                    Text("mL/kg/min")
                        .font(.caption2).foregroundStyle(.secondary)
                    Label(trend.label, systemImage: trend.symbol)
                        .font(.headline)
                    Text(latest.date, format: .dateTime.month(.abbreviated).day())
                        .font(.caption2).foregroundStyle(.secondary)
                    if points.count >= 2 {
                        sparkline
                            .frame(height: 44)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "heart.text.square").font(.largeTitle).foregroundStyle(Theme.cardio)
                    Text("No VO2 max estimate").font(.headline).multilineTextAlignment(.center)
                    Text("Record a brisk outdoor walk, run, or hike with Apple Watch.")
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button("Connect Health") {
                        Task {
                            do { try await health.requestAuthorization() } catch { }
                        }
                    }
                    .buttonStyle(.borderedProminent).tint(Theme.cardio)
                }
            }
        }
        .navigationTitle("VO2 Max")
        .task { await health.synchronizeAuthorization() }
    }
}

