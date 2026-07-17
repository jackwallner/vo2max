import SwiftData
import SwiftUI

/// The VO2+ tab. Pro users get a dedicated insights hub (Deep Trends, target
/// outlook, typical-range context, personal best). Free users get a focused
/// pitch that opens the paywall — mirrors the Vitals+ "Pro tab" structure.
struct PlusTabView: View {
    @EnvironmentObject private var settings: GoalSettings
    @EnvironmentObject private var store: StoreService
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]
    @State private var showPaywall = false

    private var points: [CardioFitnessPoint] {
        samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if store.isPro {
                    proContent
                } else {
                    pitch
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("VO2+")
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: Pro insights hub

    @ViewBuilder
    private var proContent: some View {
        activeHeader
        if points.isEmpty {
            emptyProNotice
        } else {
            deepTrendsCard
            projectionCard
            fitnessBandCard
            personalBestCard
        }
    }

    private var activeHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(Theme.positive)
            VStack(alignment: .leading, spacing: 2) {
                Text("VO2+ active").font(.headline)
                Text("Deeper context for your cardio fitness trend.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var emptyProNotice: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(Theme.cardio)
            Text("Insights appear here as you build readings")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Once Apple Health records a few VO2 max estimates, your Deep Trends, target outlook, and personal best show up on this tab.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var deepTrendsCard: some View {
        let comparisons = [30, 90, 180].compactMap {
            CardioFitnessAnalysis.periodComparison(points: points, days: $0)
        }
        return Group {
            if comparisons.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Deep Trends", systemImage: "chart.bar.xaxis")
                        .font(.headline)
                    ForEach(comparisons, id: \.days) { comparison in
                        HStack {
                            Text("Last \(comparison.days) days")
                                .font(.subheadline)
                            Spacer()
                            Text(comparison.currentAverage, format: .number.precision(.fractionLength(1)))
                                .font(.subheadline.bold().monospacedDigit())
                            changeLabel(comparison.change)
                        }
                    }
                    Text("Average of readings in each period vs. the period before.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            }
        }
    }

    private var projectionCard: some View {
        let projection = CardioFitnessAnalysis.projection(
            points: points,
            targetLower: settings.targetLower
        )
        return Group {
            if let projection {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Target outlook", systemImage: "scope")
                        .font(.headline)
                    Text(projectionText(projection))
                        .font(.subheadline)
                    Text("A broad extrapolation of your recent Apple Health estimates, not a prediction or guarantee.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            } else {
                EmptyView()
            }
        }
    }

    private var fitnessBandCard: some View {
        Group {
            if let latest = points.max(by: { $0.date < $1.date }),
               let band = CardioFitnessAnalysis.fitnessBand(
                   value: latest.value,
                   age: settings.chronologicalAge,
                   referenceSex: settings.referenceSex
               ) {
                HStack(spacing: 14) {
                    Image(systemName: "person.2.crop.square.stack")
                        .font(.title2)
                        .foregroundStyle(Theme.cardio)
                        .frame(width: 46, height: 46)
                        .background(Theme.cardio.opacity(0.14), in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(band).font(.headline)
                        Text("vs. broad age \(settings.chronologicalAge) reference values")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            } else {
                EmptyView()
            }
        }
    }

    private var personalBestCard: some View {
        Group {
            if let best = CardioFitnessAnalysis.personalBest(points: points),
               let latest = points.max(by: { $0.date < $1.date }) {
                HStack(spacing: 14) {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.coral)
                        .frame(width: 46, height: 46)
                        .background(Theme.coral.opacity(0.14), in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Personal best \(best.value, format: .number.precision(.fractionLength(1)))")
                            .font(.headline)
                        Text(bestDetail(best: best, latest: latest))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            } else {
                EmptyView()
            }
        }
    }

    // MARK: Free pitch

    private var pitch: some View {
        VStack(spacing: 18) {
            VStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
                    .frame(width: 84, height: 84)
                    .background(Theme.cardioGradient, in: Circle())
                Text("VO2+")
                    .font(.largeTitle.bold())
                Text("Go beyond today's number with deeper context for your cardio fitness trend.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            VStack(spacing: 12) {
                pitchRow("chart.bar.xaxis", "Deep Trends", "30 / 90 / 180-day period comparisons")
                pitchRow("scope", "Target outlook", "A broad time-to-target estimate")
                pitchRow("person.2.crop.square.stack", "Typical-range context", "How your number compares for your age")
                pitchRow("trophy", "Personal best", "Track and celebrate your best readings")
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))

            Button {
                showPaywall = true
            } label: {
                Text(store.shortConversionCTALabel)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Theme.cardio)

            Button("Restore Purchases") { Task { await store.restore() } }
                .font(.footnote)

            Text("Your free dashboard keeps its current reading, trend, target, and fitness-age estimate.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func pitchRow(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Theme.cardio)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: Helpers

    private func changeLabel(_ change: Double?) -> some View {
        Group {
            if let change {
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

    private func projectionText(_ projection: TrendProjection) -> String {
        guard let latest = points.max(by: { $0.date < $1.date }) else { return "" }
        if latest.value >= settings.targetLower {
            return "You're in your target range. Recent trend: \(slopeText(projection.slopePerMonth)) per month."
        }
        if let months = projection.monthsToTarget {
            let unit = months == 1 ? "month" : "months"
            return "At your recent pace (\(slopeText(projection.slopePerMonth))/month), you could reach your target range in roughly \(months) \(unit)."
        }
        if projection.slopePerMonth <= 0.05 {
            return "Your recent trend is flat or declining, so a time-to-target estimate isn't meaningful yet."
        }
        return "Progress toward your target is too gradual to estimate a timeframe."
    }

    private func slopeText(_ slope: Double) -> String {
        slope.formatted(.number.precision(.fractionLength(1)).sign(strategy: .always()))
    }

    private func bestDetail(best: CardioFitnessPoint, latest: CardioFitnessPoint) -> String {
        let dateText = best.date.formatted(.dateTime.month(.abbreviated).day().year())
        if abs(latest.value - best.value) < 0.05 {
            return "Your latest reading is your best yet (\(dateText))."
        }
        let gap = (best.value - latest.value).formatted(.number.precision(.fractionLength(1)))
        return "Set \(dateText) · \(gap) above your latest reading."
    }
}
