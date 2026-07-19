import Charts
import SwiftData
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var settings: GoalSettings
    @EnvironmentObject private var store: StoreService
    @Query(sort: \CardioFitnessSample.date) private var samples: [CardioFitnessSample]
    @State private var period = 90
    @State private var showPlusPaywall = false

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
                        .frame(height: 220)

                        Label("Dashed lines mark your target range", systemImage: "scope")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))

                    plusTeaserCard

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
        .sheet(isPresented: $showPlusPaywall) { PaywallView(focus: .deepTrends) }
    }

    // MARK: - VO2+ Deep Trends (teaser for free users, live data for Pro)

    /// The Vitals+ pattern: free users see the *shape* of Deep Trends built
    /// from their real data, blurred, with an Unlock CTA on top. Pro users see
    /// the real thing here too, so the Trends tab shows the advantage in place.
    @ViewBuilder
    private var plusTeaserCard: some View {
        if store.isPro {
            deepTrendsContent(locked: false)
        } else {
            deepTrendsContent(locked: true)
        }
    }

    private func deepTrendsContent(locked: Bool) -> some View {
        let points = samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
        let comparisons = [30, 90, 180].compactMap {
            CardioFitnessAnalysis.periodComparison(points: points, days: $0)
        }
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: locked ? "lock.fill" : "chart.bar.xaxis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.cardio)
                Text("Deep Trends")
                    .font(.headline)
                Spacer()
                Text(locked ? "VO2+" : "Active")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.cardio.opacity(0.15), in: Capsule())
                    .foregroundStyle(Theme.cardio)
            }

            if locked {
                lockedTeaser(comparisons: comparisons)
            } else if comparisons.isEmpty {
                Text("Deep Trends compare each period to the one before once you have readings in back-to-back periods.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                comparisonRows(comparisons)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private func comparisonRows(_ comparisons: [PeriodComparison]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(comparisons, id: \.days) { comparison in
                HStack {
                    Text("Last \(comparison.days) days").font(.subheadline)
                    Spacer()
                    Text(comparison.currentAverage, format: .number.precision(.fractionLength(1)))
                        .font(.subheadline.bold().monospacedDigit())
                    if let change = comparison.change {
                        Text(change, format: .number.precision(.fractionLength(1)).sign(strategy: .always()))
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(change >= 0 ? Theme.positive : Theme.negative)
                            .frame(width: 44, alignment: .trailing)
                    } else {
                        Text("—").font(.caption).foregroundStyle(.tertiary)
                            .frame(width: 44, alignment: .trailing)
                    }
                }
            }
            Text("Average of readings in each period vs. the period before.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Real rows (or representative placeholders) crushed under a blur with an
    /// unlock CTA stamped on top. Blurred content takes no taps.
    private func lockedTeaser(comparisons: [PeriodComparison]) -> some View {
        ZStack {
            Group {
                if comparisons.isEmpty {
                    placeholderRows
                } else {
                    comparisonRows(comparisons)
                }
            }
            .blur(radius: 12)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Unlock Deep Trends")
                    .font(.headline)
                Text("Every period compared to the one before, target outlook, typical-range context, and personal best.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    showPlusPaywall = true
                } label: {
                    Text(store.yearlyPackage.flatMap { store.eligibleIntroLabel(for: $0) } != nil ? "Try VO2+ Free" : "Unlock VO2+")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Theme.cardioGradient, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)
            }
            .padding(.vertical, 6)
        }
    }

    private var placeholderRows: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach([30, 90, 180], id: \.self) { days in
                HStack {
                    Text("Last \(days) days").font(.subheadline)
                    Spacer()
                    Text("41.3").font(.subheadline.bold().monospacedDigit())
                    Text("+0.8")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(Theme.positive)
                        .frame(width: 44, alignment: .trailing)
                }
            }
            Text("Average of readings in each period vs. the period before.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
