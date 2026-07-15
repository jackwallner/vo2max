import SwiftData
import SwiftUI

struct WatchTodayView: View {
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]
    @StateObject private var health = HealthKitService.shared

    private var points: [CardioFitnessPoint] {
        samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
    }

    var body: some View {
        ScrollView {
            if let latest = samples.first {
                VStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Theme.cardio)
                    Text(latest.value, format: .number.precision(.fractionLength(1)))
                        .font(Theme.numberFont(40))
                    Text("mL/kg/min")
                        .font(.caption2).foregroundStyle(.secondary)
                    Label(
                        CardioFitnessAnalysis.trend(points: points).label,
                        systemImage: CardioFitnessAnalysis.trend(points: points).symbol
                    )
                    .font(.headline)
                    Text(latest.date, format: .dateTime.month(.abbreviated).day())
                        .font(.caption2).foregroundStyle(.secondary)
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

