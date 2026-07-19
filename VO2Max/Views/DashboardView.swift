import SwiftData
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var settings: GoalSettings
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]
    @StateObject private var health = HealthKitService.shared
    @State private var showSettings = false

    private var points: [CardioFitnessPoint] {
        samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                dashboardContent(availableHeight: geometry.size.height)
                    .frame(minHeight: geometry.size.height, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
            .refreshable { await health.refreshCache() }
        }
        .background(Theme.background)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView() }
        }
    }

    private func dashboardContent(availableHeight: CGFloat) -> some View {
        let compact = availableHeight < 700
        let horizontalPadding: CGFloat = compact ? 18 : 24
        let ringSize = min(max(availableHeight * 0.25, 154), 205)
        let ringLineWidth = min(max(availableHeight * 0.019, 13), 17)
        let cardSpacing: CGFloat = compact ? 10 : 12

        return VStack(spacing: 0) {
            header
                .padding(.horizontal, horizontalPadding)
                .padding(.top, compact ? 8 : 14)

            if let latest = samples.first {
                Spacer(minLength: compact ? 8 : 12)

                NavigationLink {
                    ReadingHistoryDetailView()
                } label: {
                    currentCard(
                        latest,
                        ringSize: ringSize,
                        ringLineWidth: ringLineWidth,
                        compact: compact
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens all Apple Health estimates")

                Color.clear.frame(height: cardSpacing)

                NavigationLink {
                    TrendDetailView()
                } label: {
                    trendCard(compact: compact)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens cardio fitness trend details")

                Color.clear.frame(height: cardSpacing)

                NavigationLink {
                    FitnessAgeDetailView()
                } label: {
                    fitnessAgeCard(value: latest.value, compact: compact)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens fitness age estimate details")
            } else {
                Color.clear.frame(height: compact ? 10 : 18)
                noReadingCard(compact: compact)
                Color.clear.frame(height: 12)
            }

            Spacer(minLength: compact ? 74 : 84)
        }
        .padding(.horizontal, horizontalPadding)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                if let latest = samples.first {
                    Text(latest.date, format: .dateTime.weekday(.wide).month(.wide).day())
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                    HStack(spacing: 6) {
                        if health.isRefreshing {
                            ProgressView()
                                .controlSize(.mini)
                                .tint(Theme.cardio)
                            Text("Refreshing Apple Health…")
                        } else {
                            Text("Latest estimate · \(latest.date, format: .relative(presentation: .named))")
                        }
                    }
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(Theme.secondaryText)
                } else {
                    Text("Cardio Fitness")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                    Text(health.isRefreshing ? "Checking Apple Health…" : "Waiting for your first estimate")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(Theme.secondaryText)
                }
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.secondaryText)
                    .padding(10)
                    .background(Theme.card, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    private func currentCard(
        _ latest: CardioFitnessSample,
        ringSize: CGFloat,
        ringLineWidth: CGFloat,
        compact: Bool
    ) -> some View {
        let status = CardioFitnessAnalysis.targetStatus(
            value: latest.value,
            lower: settings.targetLower,
            upper: settings.targetUpper
        )
        let bandWidth = max(settings.targetUpper - settings.targetLower, 1)
        let floor = settings.targetLower - bandWidth
        let progress = min(max((latest.value - floor) / (settings.targetUpper - floor), 0.02), 1)

        return VStack(spacing: compact ? 7 : 9) {
            ZStack {
                Circle()
                    .stroke(Theme.cardio.opacity(0.16), lineWidth: ringLineWidth)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Theme.cardioGradient,
                        style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.7), value: progress)
                VStack(spacing: 2) {
                    Text(latest.value, format: .number.precision(.fractionLength(1)))
                        .font(Theme.numberFont(compact ? 42 : 48))
                        .foregroundStyle(Theme.primaryText)
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
            .frame(width: ringSize, height: ringSize)

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Latest Apple Health estimate")
                        .font(.headline)
                        .foregroundStyle(Theme.primaryText)
                    Text("Target \(settings.targetLower, format: .number.precision(.fractionLength(0)))–\(settings.targetUpper, format: .number.precision(.fractionLength(0))) mL/kg/min")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                cardChevron
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, compact ? 16 : 20)
        .padding(.vertical, compact ? 12 : 15)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Latest Apple Health estimate \(latest.value.formatted(.number.precision(.fractionLength(1)))) milliliters per kilogram per minute, \(status.label)")
    }

    private func trendCard(compact: Bool) -> some View {
        let trend = CardioFitnessAnalysis.trend(points: points)
        let change = CardioFitnessAnalysis.change(points: points, days: 90)

        return HStack(spacing: 14) {
            Image(systemName: trend.symbol)
                .font(.title2.bold())
                .foregroundStyle(color(for: trend))
                .frame(width: compact ? 40 : 46, height: compact ? 40 : 46)
                .background(color(for: trend).opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Cardio fitness trend")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                Text(trend.label)
                    .font(.headline)
                    .foregroundStyle(Theme.primaryText)
                if let change {
                    Text("\(change, format: .number.precision(.fractionLength(1)).sign(strategy: .always())) over 90 days")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                } else {
                    Text("Four readings within 90 days build a trend")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            cardChevron
        }
        .padding(compact ? 14 : 16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func fitnessAgeCard(value: Double, compact: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: compact ? 34 : 40))
                .foregroundStyle(Theme.cardio)
                .frame(width: compact ? 40 : 46)

            VStack(alignment: .leading, spacing: 3) {
                Text("Fitness age estimate")
                    .font(.headline)
                    .foregroundStyle(Theme.primaryText)
                if let estimate = CardioFitnessAnalysis.estimatedFitnessAge(
                    value: value,
                    referenceSex: settings.referenceSex
                ) {
                    Text("About \(estimate) · chronological age \(settings.chronologicalAge)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                } else {
                    Text("Add a reference profile to calculate this broad estimate")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            cardChevron
        }
        .padding(compact ? 14 : 16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var cardChevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
    }

    private func noReadingCard(compact: Bool) -> some View {
        VStack(spacing: compact ? 12 : 16) {
            Image(systemName: health.isAuthorized ? "applewatch.radiowaves.left.and.right" : "heart.text.square.fill")
                .font(.system(size: compact ? 40 : 48))
                .foregroundStyle(Theme.cardio)

            VStack(spacing: 6) {
                Text(health.isAuthorized ? "Your first estimate will appear here" : "Connect Apple Health")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("Apple Watch creates cardio fitness estimates during qualifying outdoor walks, runs, and hikes. Wear it snugly and record a brisk outdoor workout for at least 20 minutes.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                Task {
                    if health.isAuthorized {
                        await health.refreshCache()
                    } else {
                        try? await health.requestAuthorization()
                    }
                }
            } label: {
                Label(
                    health.isAuthorized ? "Refresh Apple Health" : "Connect Apple Health",
                    systemImage: health.isAuthorized ? "arrow.clockwise" : "heart.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.cardio)

            Button("Open Apple Health") {
                if let url = URL(string: "x-apple-health://") {
                    UIApplication.shared.open(url)
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.cardioBlue)

            if let error = health.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Theme.negative)
                    .multilineTextAlignment(.center)
            }

            Text("Apple Health estimates are for fitness awareness. This app does not diagnose or treat health conditions.")
                .font(.caption2)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(compact ? 18 : 24)
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
