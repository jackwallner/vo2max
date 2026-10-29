import SwiftData
import SwiftUI

/// VO2+ monthly recap surface. Presented when the user taps the monthly
/// notification or the inline "view recap" affordance on the VO2+ tab. Reads its
/// own data from the SwiftData cache so callers just present `MonthlyRecapView()`.
struct MonthlyRecapView: View {
    @EnvironmentObject private var settings: GoalSettings
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]

    @State private var recap: CardioRecap?
    @State private var loaded = false

    private var points: [CardioFitnessPoint] {
        samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
            }
            .navigationTitle("This Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.bold()
                }
            }
            .preferredColorScheme(settings.appearance.colorScheme)
        }
        .task {
            guard !loaded else { return }
            recap = CardioRecapBuilder.build(
                points: points,
                targetLower: settings.targetLower,
                targetUpper: settings.targetUpper
            )
            loaded = true
        }
    }

    @ViewBuilder
    private var content: some View {
        if let recap, recap.hasContent {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    headline(recap)
                    averageCard(recap)
                    if let status = recap.targetStatus {
                        targetCard(status: status, recap: recap)
                    }
                    if let best = recap.periodBest {
                        bestCard(best, isAllTime: recap.personalBest.map { abs($0.value - best.value) < 0.001 } ?? false)
                    }
                }
                .padding(20)
            }
        } else {
            emptyState
        }
    }

    private func headline(_ recap: CardioRecap) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Theme.cardioGradient)
            Text("Last 30 days")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(CardioRange.fixed(.month).spanLabel)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
            Text(String(localized: "\(recap.readingsThisPeriod) estimates from Apple Health"))
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func averageCard(_ recap: CardioRecap) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Average cardio fitness")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Label(recap.trend.label, systemImage: recap.trend.symbol)
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.cardio)
            }
            Text("\(recap.currentAverage.formatted(.number.precision(.fractionLength(1)))) mL/kg/min")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.cardio)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let pct = recap.changePct {
                let up = pct >= 0
                Label("\(pct.formatted(.number.precision(.fractionLength(1)).sign(strategy: .always())))% vs. prior 30 days",
                      systemImage: up ? "arrow.up.forward" : "arrow.down.forward")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(up ? Theme.positive : Theme.coral)
                    .labelStyle(.titleAndIcon)
            } else {
                Text("No prior 30-day window yet")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func targetCard(status: TargetRangeStatus, recap: CardioRecap) -> some View {
        HStack(spacing: 14) {
            Image(systemName: status == .inRange ? "target" : "scope")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(status == .inRange ? Theme.positive : Theme.cardio)
            VStack(alignment: .leading, spacing: 2) {
                Text(status.label)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(recap.latest.map { latest in
                    String(localized: "Target range: \(settings.targetLower.formatted(.number.precision(.fractionLength(0))))–\(settings.targetUpper.formatted(.number.precision(.fractionLength(0)))) mL/kg/min. Latest: \(latest.value.formatted(.number.precision(.fractionLength(1)))).")
                } ?? String(localized: "Target range: \(settings.targetLower.formatted(.number.precision(.fractionLength(0))))–\(settings.targetUpper.formatted(.number.precision(.fractionLength(0)))) mL/kg/min."))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func bestCard(_ best: CardioFitnessPoint, isAllTime: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Theme.coral)
            VStack(alignment: .leading, spacing: 2) {
                Text(isAllTime ? String(localized: "Personal best") : String(localized: "Best this month"))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(best.date.formatted(.dateTime.month(.abbreviated).day())) · \(best.value.formatted(.number.precision(.fractionLength(1)))) mL/kg/min")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(Theme.textTertiary)
            Text("Not enough data yet")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
            Text("Once Apple Health records a few estimates this month, your recap will appear here.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}
