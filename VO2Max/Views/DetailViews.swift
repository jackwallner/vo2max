import Charts
import SwiftData
import SwiftUI

// MARK: - Reading history

struct ReadingHistoryDetailView: View {
    @EnvironmentObject private var settings: GoalSettings
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if samples.isEmpty {
                    ContentUnavailableView(
                        "No readings yet",
                        systemImage: "waveform.path.ecg",
                        description: Text("New Apple Health estimates will appear here automatically.")
                    )
                    .frame(minHeight: 300)
                } else {
                    latestSummary
                    chartCard
                    listCard
                    sourceNotice
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("All Readings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var latestSummary: some View {
        let latest = samples[0]
        let status = CardioFitnessAnalysis.targetStatus(
            value: latest.value,
            lower: settings.targetLower,
            upper: settings.targetUpper
        )

        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Latest Apple Health estimate")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                Text(latest.value, format: .number.precision(.fractionLength(1)))
                    .font(Theme.bigNumber(38))
                    .foregroundStyle(Theme.cardio)
                Text("mL/kg/min · \(status.label)")
                    .font(.subheadline)
                    .foregroundStyle(statusColor(status))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(latest.date, format: .dateTime.month(.abbreviated).day().year())
                    .font(.subheadline.weight(.semibold))
                Text(latest.date, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(18)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reading history")
                .font(.headline)
            Text("Every cached Apple Health estimate, shown read-only.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Chart(samples) { sample in
                RuleMark(y: .value("Target lower", settings.targetLower))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Theme.positive.opacity(0.6))
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
            .frame(height: 210)
        }
        .padding()
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var listCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(samples.enumerated()), id: \.element.healthKitID) { index, sample in
                let status = CardioFitnessAnalysis.targetStatus(
                    value: sample.value,
                    lower: settings.targetLower,
                    upper: settings.targetUpper
                )
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(sample.date, format: .dateTime.month(.abbreviated).day().year())
                            .font(.subheadline.weight(.semibold))
                        Text("\(sample.sourceName) · \(status.label)")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Text(sample.value, format: .number.precision(.fractionLength(1)))
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(Theme.textPrimary)
                    Text("mL/kg/min")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.vertical, 12)
                if index < samples.count - 1 { Divider() }
            }
        }
        .padding(.horizontal)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var sourceNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Managed by Apple Health", systemImage: "heart.text.square")
                .font(.headline)
            Text("This app reads these estimates and keeps a local display cache. To change or remove source health data, use Apple Health.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Button("Open Apple Health") {
                if let url = URL(string: "x-apple-health://") {
                    UIApplication.shared.open(url)
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.cardioBlue)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private func statusColor(_ status: TargetRangeStatus) -> Color {
        switch status {
        case .below: Theme.coral
        case .inRange, .above: Theme.positive
        }
    }
}

// MARK: - Trend detail

struct TrendDetailView: View {
    @EnvironmentObject private var settings: GoalSettings
    @EnvironmentObject private var store: StoreService
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]
    @State private var showPaywall = false

    private var points: [CardioFitnessPoint] {
        samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
    }

    var body: some View {
        let trend = CardioFitnessAnalysis.trend(points: points)
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                trendSummary(trend)
                changeWindows
                targetOutlook
                trendMethodology
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Cardio Fitness Trend")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView(focus: .targetProjection)
        }
    }

    private func trendSummary(_ trend: CardioTrend) -> some View {
        VStack(spacing: 10) {
            Image(systemName: trend.symbol)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(trendColor(trend))
                .frame(width: 70, height: 70)
                .background(trendColor(trend).opacity(0.14), in: Circle())
            Text(trend.label)
                .font(.title2.bold())
            Text(summaryText(trend))
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var changeWindows: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Change by window")
                .font(.headline)
            ForEach([30, 90, 180, 365], id: \.self) { days in
                HStack {
                    Text("Last \(days) days")
                        .font(.subheadline)
                    Spacer()
                    if let change = CardioFitnessAnalysis.change(points: points, days: days) {
                        Text(change, format: .number.precision(.fractionLength(1)).sign(strategy: .always()))
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(change >= 0 ? Theme.positive : Theme.negative)
                    } else {
                        Text("Not enough data")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    @ViewBuilder
    private var targetOutlook: some View {
        let projection = CardioFitnessAnalysis.projection(
            points: points,
            targetLower: settings.targetLower
        )

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Target outlook", systemImage: "scope")
                    .font(.headline)
                Spacer()
                if !store.isPro {
                    Text("VO2+")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.cardio.opacity(0.15), in: Capsule())
                        .foregroundStyle(Theme.cardio)
                }
            }

            if store.isPro {
                if let projection {
                    Text(projectionText(projection))
                        .font(.subheadline)
                    Text("Broad extrapolation from recent Apple Health estimates, not a prediction or guarantee.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Text("Target outlook needs at least five readings across the last 180 days.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            } else {
                Text("See whether recent estimates are moving toward your target range and get a broad timeframe when the data supports one.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                Button(store.shortConversionCTALabel) { showPaywall = true }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.cardio)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var trendMethodology: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("How the trend works", systemImage: "info.circle")
                .font(.headline)
            Text("The main trend compares averages from the older and newer halves of the last 90 days. It needs at least four readings and ignores small changes that are likely normal estimate-to-estimate variation.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Text("A cardio fitness trend is motivational context, not a medical assessment.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private func summaryText(_ trend: CardioTrend) -> String {
        switch trend {
        case .improving:
            "Your more recent Apple Health estimates are meaningfully higher than the earlier part of the 90-day window."
        case .stable:
            "Your recent Apple Health estimates are holding within the app's normal-variation threshold."
        case .declining:
            "Your more recent Apple Health estimates are meaningfully lower than the earlier part of the 90-day window."
        case .insufficientData:
            "Four Apple Health estimates within 90 days are needed before the app labels a direction."
        }
    }

    private func projectionText(_ projection: TrendProjection) -> String {
        guard let latest = points.max(by: { $0.date < $1.date }) else { return "" }
        let slope = projection.slopePerMonth.formatted(
            .number.precision(.fractionLength(1)).sign(strategy: .always())
        )
        if latest.value >= settings.targetLower {
            return "Your latest estimate is in or above your target range. Recent pace: \(slope) mL/kg/min per month."
        }
        if let months = projection.monthsToTarget {
            return "At the recent pace of \(slope) mL/kg/min per month, the lower edge of your target range is roughly \(months) \(months == 1 ? "month" : "months") away."
        }
        if projection.slopePerMonth <= 0.05 {
            return "The recent cardio fitness trend is flat or declining, so a time-to-target estimate is not meaningful."
        }
        return "The recent direction is positive, but too gradual for a useful timeframe."
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
    @EnvironmentObject private var store: StoreService
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]
    @State private var showSettings = false
    @State private var showPaywall = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                estimateCard
                typicalRangeCard
                methodologyCard
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Fitness Age")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView() }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(focus: .fitnessBand)
        }
    }

    @ViewBuilder
    private var estimateCard: some View {
        if let latest = samples.first,
           let estimate = CardioFitnessAnalysis.estimatedFitnessAge(
               value: latest.value,
               referenceSex: settings.referenceSex
           ) {
            VStack(spacing: 8) {
                Text("About \(estimate)")
                    .font(Theme.bigNumber(44))
                    .foregroundStyle(Theme.cardio)
                Text("Fitness age estimate")
                    .font(.headline)
                Text("Chronological age: \(settings.chronologicalAge)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                Button("Edit reference profile") { showSettings = true }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.cardioBlue)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        } else {
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.cardio)
                Text("Set a reference profile")
                    .font(.headline)
                Text("Fitness age needs your age and a reference option plus at least one Apple Health estimate.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                Button("Open Settings") { showSettings = true }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.cardio)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
    }

    @ViewBuilder
    private var typicalRangeCard: some View {
        if let latest = samples.first {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Broad reference context", systemImage: "person.2.crop.square.stack")
                        .font(.headline)
                    Spacer()
                    if !store.isPro {
                        Text("VO2+")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.cardio.opacity(0.15), in: Capsule())
                            .foregroundStyle(Theme.cardio)
                    }
                }
                if store.isPro {
                    if let band = CardioFitnessAnalysis.fitnessBand(
                        value: latest.value,
                        age: settings.chronologicalAge,
                        referenceSex: settings.referenceSex
                    ) {
                        Text(band)
                            .font(.title3.bold())
                            .foregroundStyle(Theme.cardio)
                        Text("Your latest Apple Health estimate compared with broad reference values for age \(settings.chronologicalAge) and your selected reference.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        Text("Choose a reference option in Settings to see this context.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                } else {
                    Text("See how your latest estimate sits within broad age-reference context, alongside the fitness age methodology.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    Button(store.shortConversionCTALabel) { showPaywall = true }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.cardio)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
    }

    private var methodologyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("How this is estimated", systemImage: "info.circle")
                .font(.headline)
            Text("Your latest cardio fitness estimate is compared with broad age and sex reference curves to find the age whose typical value most closely matches your number. Higher relative cardio fitness maps to a younger estimate.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Text("Fitness age is a broad motivational estimate. It is not clinically validated, does not diagnose anything, and does not predict longevity or health outcomes.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}
