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

    private var chartDomain: ClosedRange<Double> {
        var values = visibleSamples.map(\.value)
        values.append(contentsOf: [settings.targetLower, settings.targetUpper])
        let lower = max((values.min() ?? 20) - 3, 0)
        let upper = (values.max() ?? 60) + 3
        return lower...max(upper, lower + 8)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                periodPicker

                if visibleSamples.isEmpty {
                    emptyState
                } else {
                    statsCard
                    chartCard
                    allReadingsLink
                    plusTeaserCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            // The tab bar's height is already reserved via the safe-area inset;
            // this keeps the Deep Trends CTA from sitting flush against it.
            .padding(.bottom, 28)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Theme.background)
        .navigationTitle("Trends")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPlusPaywall) {
            PaywallView(focus: .deepTrends)
        }
    }

    private var periodPicker: some View {
        Picker("Period", selection: $period) {
            Text("30D").tag(30)
            Text("90D").tag(90)
            Text("6M").tag(180)
            Text("1Y").tag(365)
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Trend period")
    }

    private var statsCard: some View {
        let values = visibleSamples.map(\.value)
        let average = values.reduce(0, +) / Double(values.count)
        let change = CardioFitnessAnalysis.change(
            points: samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) },
            days: period
        )

        return HStack(spacing: 0) {
            statBlock("Readings", "\(values.count)")
            Divider().frame(height: 36)
            statBlock("Average", average.formatted(.number.precision(.fractionLength(1))))
            Divider().frame(height: 36)
            statBlock(
                "Change",
                change?.formatted(.number.precision(.fractionLength(1)).sign(strategy: .always())) ?? "—",
                color: change.map { $0 >= 0 ? Theme.positive : Theme.negative }
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private func statBlock(_ title: String, _ value: String, color: Color? = nil) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Theme.bigNumber(21))
                .foregroundStyle(color ?? Theme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cardio fitness trend")
                        .font(.headline)
                    Text("Apple Health estimates in the selected period")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Label("Target", systemImage: "scope")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.positive)
            }

            Chart(visibleSamples) { sample in
                RuleMark(y: .value("Target lower", settings.targetLower))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Theme.positive.opacity(0.65))
                RuleMark(y: .value("Target upper", settings.targetUpper))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Theme.positive.opacity(0.65))
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
            .frame(height: 156)
        }
        .padding(16)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var allReadingsLink: some View {
        NavigationLink {
            ReadingHistoryDetailView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.title3)
                    .foregroundStyle(Theme.cardio)
                    .frame(width: 38, height: 38)
                    .background(Theme.cardio.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("All Readings")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("View every Apple Health estimate and source date")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 42))
                .foregroundStyle(Theme.cardio)
            Text("No estimates in this period")
                .font(.title3.bold())
            Text("Choose a longer window, or return after Apple Health records another cardio fitness estimate.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            if !samples.isEmpty, period != 365 {
                Button("Show 1 Year") { period = 365 }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.cardio)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 20)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    @ViewBuilder
    private var plusTeaserCard: some View {
        deepTrendsContent(locked: !store.isPro)
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
                Text("Deep Trends compare each period with the matching one before it once both windows contain Apple Health estimates.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                comparisonRows(comparisons)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private func comparisonRows(_ comparisons: [PeriodComparison]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(comparisons, id: \.days) { comparison in
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Last \(comparison.days) days")
                            .font(.subheadline.weight(.medium))
                        Text("vs. previous \(comparison.days) days")
                            .font(.caption2)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Text(comparison.currentAverage, format: .number.precision(.fractionLength(1)))
                        .font(.subheadline.bold().monospacedDigit())
                    if let change = comparison.change {
                        Text(change, format: .number.precision(.fractionLength(1)).sign(strategy: .always()))
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(change >= 0 ? Theme.positive : Theme.negative)
                            .frame(width: 44, alignment: .trailing)
                    } else {
                        Text("—")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .frame(width: 44, alignment: .trailing)
                    }
                }
            }
        }
    }

    private func lockedTeaser(comparisons: [PeriodComparison]) -> some View {
        ZStack {
            Group {
                if comparisons.isEmpty {
                    placeholderRows
                } else {
                    comparisonRows(comparisons)
                }
            }
            .blur(radius: 14)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .overlay(
                LinearGradient(
                    colors: [
                        Theme.cardSurface.opacity(0.3),
                        Theme.cardSurface.opacity(0.55),
                        Theme.cardSurface.opacity(0.82)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            VStack(spacing: 9) {
                Image(systemName: "lock.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.cardio)
                Text("Compare every period")
                    .font(.headline)
                Text("See matching-window averages, direction toward target, broad age-reference context, and personal bests.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    showPlusPaywall = true
                } label: {
                    Text(store.shortConversionCTALabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Theme.cardioGradient, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .padding(14)
        }
    }

    private var placeholderRows: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach([30, 90, 180], id: \.self) { days in
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Last \(days) days").font(.subheadline.weight(.medium))
                        Text("vs. previous \(days) days")
                            .font(.caption2)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Text("41.3").font(.subheadline.bold().monospacedDigit())
                    Text("+0.8")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(Theme.positive)
                        .frame(width: 44, alignment: .trailing)
                }
            }
        }
    }
}
