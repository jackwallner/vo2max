import Charts
import SwiftData
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var settings: GoalSettings
    @Query(sort: \CardioFitnessSample.date) private var samples: [CardioFitnessSample]
    @State private var period = 90

    private var visibleSamples: [CardioFitnessSample] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -period, to: .now) ?? .distantPast
        return samples.filter { $0.date >= cutoff }
    }

    /// Domain spans the readings plus the target bounds so both dashed target
    /// lines stay visible. It's safe to include the target here now that the
    /// range is drawn as thin lines rather than a filled band (the filled band
    /// was what ballooned into the old "gigantic green space").
    private var chartDomain: ClosedRange<Double> {
        var values = visibleSamples.map(\.value)
        values.append(contentsOf: [settings.targetLower, settings.targetUpper])
        let lower = max((values.min() ?? 20) - 3, 0)
        let upper = (values.max() ?? 60) + 3
        return lower...max(upper, lower + 8)
    }

    private var statsCard: some View {
        let values = visibleSamples.map(\.value)
        let average = values.reduce(0, +) / Double(values.count)
        return HStack {
            statBlock("Readings", "\(values.count)")
            Divider().frame(height: 34)
            statBlock("Average", average.formatted(.number.precision(.fractionLength(1))))
            Divider().frame(height: 34)
            statBlock("Best", (values.max() ?? 0).formatted(.number.precision(.fractionLength(1))))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private func statBlock(_ title: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(Theme.numberFont(22))
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Picker("Period", selection: $period) {
                    Text("30D").tag(30)
                    Text("90D").tag(90)
                    Text("6M").tag(180)
                    Text("1Y").tag(365)
                }
                .pickerStyle(.segmented)

                if !visibleSamples.isEmpty {
                    statsCard
                }

                if visibleSamples.isEmpty {
                    ContentUnavailableView(
                        "No readings in this period",
                        systemImage: "chart.xyaxis.line",
                        description: Text("New Apple Health estimates will appear here automatically.")
                    )
                    .frame(minHeight: 280)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Chart(visibleSamples) { sample in
                            // Target range shown as two dashed boundary lines, not
                            // a filled band: when readings sit inside a wide target
                            // the fill balloons to cover the whole plot (the old
                            // "gigantic green space"). Lines read cleanly either way.
                            RuleMark(y: .value("Target lower", settings.targetLower))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .foregroundStyle(Theme.positive.opacity(0.6))
                                .annotation(position: .top, alignment: .leading) {
                                    Text("Target").font(.caption2).foregroundStyle(Theme.positive)
                                }
                            RuleMark(y: .value("Target upper", settings.targetUpper))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .foregroundStyle(Theme.positive.opacity(0.6))
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
                        .frame(height: 260)

                        Label("Dashed lines mark your target range", systemImage: "scope")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
