import Charts
import SwiftData
import SwiftUI

/// Detail screens reached by tapping the Today cards (the Total Calories
/// pattern: every dashboard stat opens its history/context).

// MARK: - Reading history

struct ReadingHistoryDetailView: View {
    @EnvironmentObject private var settings: GoalSettings
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if samples.isEmpty {
                    ContentUnavailableView(
                        "No readings yet",
                        systemImage: "waveform.path.ecg",
                        description: Text("New Apple Health estimates will appear here automatically.")
                    )
                    .frame(minHeight: 280)
                } else {
                    chartCard
                    listCard
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("All Readings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Every Apple Health estimate on record.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Chart(samples) { sample in
                LineMark(
                    x: .value("Date", sample.date),
                    y: .value("VO2 max", sample.value)
                )
                .foregroundStyle(Theme.cardioGradient)
                .interpolationMethod(.catmullRom)
                PointMark(
                    x: .value("Date", sample.date),
                    y: .value("VO2 max", sample.value)
                )
                .foregroundStyle(Theme.cardio)
            }
            .chartYAxisLabel("mL/kg/min")
            .frame(height: 200)
        }
        .padding()
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var listCard: some View {
        VStack(spacing: 0) {
            ForEach(samples) { sample in
                HStack {
                    VStack(alignment: .leading) {
                        Text(sample.date, format: .dateTime.month(.abbreviated).day().year())
                        Text(sample.sourceName).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(sample.value, format: .number.precision(.fractionLength(1)))
                        .font(.headline.monospacedDigit())
                }
                .padding(.vertical, 12)
                if sample.healthKitID != samples.last?.healthKitID { Divider() }
            }
        }
        .padding(.horizontal)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}

// MARK: - Trend detail

struct TrendDetailView: View {
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]

    private var points: [CardioFitnessPoint] {
        samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
    }

    var body: some View {
        let trend = CardioFitnessAnalysis.trend(points: points)
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 10) {
                    Image(systemName: trend.symbol)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(trendColor(trend))
                        .frame(width: 76, height: 76)
                        .background(trendColor(trend).opacity(0.14), in: Circle())
                    Text(trend.label).font(.title2.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Change by window").font(.headline)
                    ForEach([30, 90, 180, 365], id: \.self) { days in
                        HStack {
                            Text("Last \(days) days").font(.subheadline)
                            Spacer()
                            if let change = CardioFitnessAnalysis.change(points: points, days: days) {
                                Text(change, format: .number.precision(.fractionLength(1)).sign(strategy: .always()))
                                    .font(.subheadline.bold().monospacedDigit())
                                    .foregroundStyle(change >= 0 ? Theme.positive : Theme.negative)
                            } else {
                                Text("—").font(.subheadline).foregroundStyle(.tertiary)
                            }
                        }
                    }
                    Text("A trend needs four readings within 90 days. Changes compare the first and last reading inside each window.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Trend")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func trendColor(_ trend: CardioTrend) -> Color {
        switch trend {
        case .improving: Theme.positive
        case .declining: Theme.negative
        case .stable, .insufficientData: Theme.cardio
        }
    }
}

// MARK: - Fitness age detail

struct FitnessAgeDetailView: View {
    @EnvironmentObject private var settings: GoalSettings
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]
    @State private var showSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let latest = samples.first,
                   let estimate = CardioFitnessAnalysis.estimatedFitnessAge(value: latest.value, referenceSex: settings.referenceSex) {
                    VStack(spacing: 8) {
                        Text("About \(estimate)")
                            .font(Theme.numberFont(44))
                            .foregroundStyle(Theme.cardio)
                        Text("Fitness age estimate")
                            .font(.headline)
                        Text("Chronological age: \(settings.chronologicalAge)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.cardio)
                        Text("Set a reference profile")
                            .font(.headline)
                        Text("Fitness age needs your age and a reference option plus at least one Apple Health estimate.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Open Settings") { showSettings = true }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.cardio)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("How this is estimated", systemImage: "info.circle")
                        .font(.headline)
                    Text("Your latest cardio fitness estimate is compared against broad age and sex reference curves to find the age whose typical range best matches your number. Higher relative cardio fitness maps to a younger fitness age.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Fitness age uses broad reference curves. It is a motivational estimate, not a medical assessment, and does not diagnose or predict anything about your health.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Fitness Age")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView() }
        }
    }
}
