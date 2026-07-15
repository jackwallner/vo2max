import Charts
import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \CardioFitnessSample.date) private var samples: [CardioFitnessSample]
    @State private var period = 90

    private var visibleSamples: [CardioFitnessSample] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -period, to: .now) ?? .distantPast
        return samples.filter { $0.date >= cutoff }
    }

    private var chartDomain: ClosedRange<Double> {
        let values = visibleSamples.map(\.value)
        let lower = max((values.min() ?? 20) - 4, 0)
        let upper = (values.max() ?? 60) + 4
        return lower...max(upper, lower + 8)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Picker("Period", selection: $period) {
                    Text("30D").tag(30)
                    Text("90D").tag(90)
                    Text("1Y").tag(365)
                }
                .pickerStyle(.segmented)

                if visibleSamples.isEmpty {
                    ContentUnavailableView(
                        "No readings in this period",
                        systemImage: "chart.xyaxis.line",
                        description: Text("New Apple Health estimates will appear here automatically.")
                    )
                    .frame(minHeight: 340)
                } else {
                    Chart(visibleSamples) { sample in
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
                    .chartYScale(domain: chartDomain)
                    .frame(height: 320)
                    .padding()
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))

                    VStack(spacing: 0) {
                        ForEach(visibleSamples.reversed()) { sample in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(sample.date, format: .dateTime.month(.abbreviated).day().year())
                                    Text(sample.sourceName).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(sample.value, format: .number.precision(.fractionLength(1)))
                                    .font(.headline.monospacedDigit())
                                Text("mL/kg/min").font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 12)
                            if sample.healthKitID != visibleSamples.first?.healthKitID { Divider() }
                        }
                    }
                    .padding(.horizontal)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Trends")
    }
}
