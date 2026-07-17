import SwiftData
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var settings: GoalSettings
    @EnvironmentObject private var store: StoreService
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]
    @StateObject private var health = HealthKitService.shared
    @State private var showSettings = false

    private var points: [CardioFitnessPoint] {
        samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let latest = samples.first {
                    currentCard(latest)
                    trendCard
                    fitnessAgeCard(value: latest.value)
                    estimateNotice
                } else {
                    noReadingCard
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Cardio Fitness")
        .refreshable { await health.refreshCache() }
        .toolbar {
            if health.isRefreshing {
                ToolbarItem(placement: .topBarLeading) { ProgressView() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView() }
        }
    }

    private func currentCard(_ latest: CardioFitnessSample) -> some View {
        // Ring is a progress-toward-target gauge: entering the band reads near
        // half, hitting the upper bound fills it. Anchoring the floor one band
        // width below the lower bound keeps normal reading-to-reading noise a
        // small, smooth, meaningful move instead of a jump on an arbitrary scale.
        let status = CardioFitnessAnalysis.targetStatus(
            value: latest.value,
            lower: settings.targetLower,
            upper: settings.targetUpper
        )
        let bandWidth = max(settings.targetUpper - settings.targetLower, 1)
        let floor = settings.targetLower - bandWidth
        let progress = min(max((latest.value - floor) / (settings.targetUpper - floor), 0.02), 1)
        return VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Theme.cardio.opacity(0.16), lineWidth: 18)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.cardioGradient, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.7), value: progress)
                VStack(spacing: 2) {
                    Text(latest.value, format: .number.precision(.fractionLength(1)))
                        .font(Theme.numberFont(56))
                        .contentTransition(.numericText())
                    Text("mL/kg/min")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.secondaryText)
                    Text(status.label)
                        .font(.subheadline.bold())
                        .foregroundStyle(statusColor(status))
                        .padding(.top, 2)
                }
            }
            .frame(width: 220, height: 220)

            Text("Latest Apple Health estimate")
                .font(.headline)
            Text("\(latest.date, format: .dateTime.month(.abbreviated).day().year()) · \(latest.date, format: .relative(presentation: .named))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Image(systemName: "scope").font(.caption)
                Text("Target \(settings.targetLower, format: .number.precision(.fractionLength(0)))–\(settings.targetUpper, format: .number.precision(.fractionLength(0)))")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            Text(latest.sourceName)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Latest estimate \(latest.value.formatted(.number.precision(.fractionLength(1)))) mL/kg/min, \(status.label)")
    }

    private var trendCard: some View {
        let trend = CardioFitnessAnalysis.trend(points: points)
        let change = CardioFitnessAnalysis.change(points: points, days: 90)
        return HStack(spacing: 14) {
            Image(systemName: trend.symbol)
                .font(.title2.bold())
                .foregroundStyle(color(for: trend))
                .frame(width: 46, height: 46)
                .background(color(for: trend).opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(trend.label).font(.headline)
                if let change {
                    Text("\(change, format: .number.precision(.fractionLength(1)).sign(strategy: .always())) over 90 days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Four readings within 90 days build a trend")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private func fitnessAgeCard(value: Double) -> some View {
        Group {
            if let estimate = CardioFitnessAnalysis.estimatedFitnessAge(value: value, referenceSex: settings.referenceSex) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Fitness age estimate").font(.headline)
                        Text("About \(estimate)").font(Theme.numberFont(34)).foregroundStyle(Theme.cardio)
                        Text("Chronological age: \(settings.chronologicalAge)")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 48)).foregroundStyle(Theme.cardio)
                }
            } else {
                Button {
                    showSettings = true
                } label: {
                    HStack {
                        Label("Set a reference profile to estimate fitness age", systemImage: "person.crop.circle.badge.questionmark")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var estimateNotice: some View {
        Label("Fitness age uses broad age and sex reference curves. It is a motivational estimate, not a medical assessment.", systemImage: "info.circle")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }

    private var noReadingCard: some View {
        VStack(spacing: 18) {
            Image(systemName: "waveform.path.ecg.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(Theme.cardio)
            Text("No cardio fitness estimate yet")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("Apple Watch estimates VO2 max during qualifying outdoor walks, runs, and hikes. Wear your watch snugly, record a brisk outdoor workout for at least 20 minutes, and keep age, sex, height, and weight current in Health.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                Task {
                    do { try await health.requestAuthorization() } catch { }
                }
            } label: {
                Label(health.isAuthorized ? "Refresh Apple Health" : "Connect Apple Health", systemImage: "heart.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.cardio)
            Button("Open Health Settings") {
                if let url = URL(string: "x-apple-health://") { UIApplication.shared.open(url) }
            }
            .buttonStyle(.bordered)
            if let error = health.lastError {
                Text(error).font(.caption).foregroundStyle(Theme.negative)
            }
        }
        .padding(24)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private func color(for trend: CardioTrend) -> Color {
        switch trend {
        case .improving: Theme.positive
        case .declining: Theme.negative
        case .stable, .insufficientData: Theme.cardio
        }
    }

    private func statusColor(_ status: TargetRangeStatus) -> Color {
        switch status {
        case .below: Theme.coral
        case .inRange, .above: Theme.positive
        }
    }
}

