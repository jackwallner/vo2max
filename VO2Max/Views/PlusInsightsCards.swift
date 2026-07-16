import SwiftUI

/// VO2+ dashboard cards. Pro users see live insights; free users see a locked
/// teaser card that opens the focused paywall (feature stays visible, Vitals
/// style, so the upgrade has a concrete "what you get").
struct PlusInsightsSection: View {
    @EnvironmentObject private var settings: GoalSettings
    @EnvironmentObject private var store: StoreService
    let points: [CardioFitnessPoint]
    @Binding var paywallFocus: PlusFeature?
    @Binding var showPaywall: Bool

    var body: some View {
        if store.isPro {
            if settings.showDeepTrends { deepTrendsCard }
            if settings.showProjection { projectionCard }
            if settings.showFitnessBand { fitnessBandCard }
            if settings.showPersonalBest { personalBestCard }
        } else {
            lockedCard
        }
    }

    // MARK: Pro cards

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
                .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            } else {
                EmptyView()
            }
        }
    }

    // MARK: Locked teaser

    private var lockedCard: some View {
        Button {
            paywallFocus = .deepTrends
            showPaywall = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("VO2+ insights", systemImage: "sparkles")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 8) {
                    teaserRow("chart.bar.xaxis", "30/90/180-day period comparisons")
                    teaserRow("scope", "Broad time-to-target outlook")
                    teaserRow("person.2.crop.square.stack", "Typical-range context for your age")
                    teaserRow("trophy", "Personal best tracking")
                }
                Text(store.shortConversionCTALabel)
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.cardio, in: Capsule())
                    .foregroundStyle(.white)
            }
            .padding(18)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("VO2+ insights (locked). \(store.shortConversionCTALabel)")
    }

    private func teaserRow(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(Theme.cardio)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
