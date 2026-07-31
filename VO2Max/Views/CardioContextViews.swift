import Charts
import SwiftData
import SwiftUI

// MARK: - Shared gate

/// Card chrome shared by the VO2+ context surfaces: a titled header with the
/// VO2+ badge, then either the real content or a short pitch plus CTA. Same
/// idiom as the existing gated cards in Trends and the detail screens.
struct PlusContextCard<Content: View, Locked: View>: View {
    let title: String
    let symbol: String
    let isLocked: Bool
    @ViewBuilder var content: () -> Content
    @ViewBuilder var locked: () -> Locked

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: isLocked ? "lock.fill" : symbol)
                    .font(.headline)
                Spacer()
                if isLocked {
                    Text("VO2+")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.cardio.opacity(0.15), in: Capsule())
                        .foregroundStyle(Theme.cardio)
                }
            }
            if isLocked { locked() } else { content() }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}

/// Pitch + CTA body for a locked card.
struct PlusContextLockedBody: View {
    let feature: PlusFeature
    let ctaTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(feature.intentSubheadline)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(ctaTitle, action: action)
                .buttonStyle(.borderedProminent)
                .tint(Theme.cardio)
        }
    }
}

// MARK: - Estimate freshness (Today)

/// Answers "why hasn't my number changed?" — the most common real question from
/// people watching an Apple Health VO2 max estimate, and the app's only
/// actionable daily moment.
struct EstimateFreshnessCard: View {
    @EnvironmentObject private var store: StoreService
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]
    @State private var showPaywall = false

    private var freshness: EstimateFreshness {
        CardioFreshnessAnalysis.assess(
            points: samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
        )
    }

    var body: some View {
        let state = freshness

        return Group {
            if store.isPro {
                NavigationLink { EstimateFreshnessDetailView() } label: { card(state, chevron: true) }
                    .buttonStyle(.plain)
            } else {
                Button { showPaywall = true } label: { card(state, chevron: false) }
                    .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(focus: .freshnessNudges)
        }
    }

    private func card(_ state: EstimateFreshness, chevron: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: store.isPro ? symbol(state) : "lock.fill")
                .font(.title2.bold())
                .foregroundStyle(tint(state))
                .frame(width: 46, height: 46)
                .background(tint(state).opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Estimate freshness")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                Text(store.isPro ? state.headline : "Know when it's time to refresh")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(store.isPro ? shortDetail(state) : "VO2 max only refreshes after a qualifying outdoor workout.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            Image(systemName: chevron ? "chevron.right" : "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(chevron ? Theme.textTertiary : Theme.cardio)
        }
        .padding(Theme.cardPadding)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func shortDetail(_ state: EstimateFreshness) -> String {
        guard let days = state.daysSinceLatest else { return "No estimate recorded yet" }
        if let typical = state.typicalGapDays {
            return "Last estimate \(CardioFreshnessAnalysis.dayPhrase(days)) · usually every \(typical) days"
        }
        return "Last estimate \(CardioFreshnessAnalysis.dayPhrase(days))"
    }

    private func symbol(_ state: EstimateFreshness) -> String {
        switch state.state {
        case .fresh: "checkmark.circle.fill"
        case .aging: "clock"
        case .stale: "clock.badge.exclamationmark"
        case .noReadings: "questionmark.circle"
        }
    }

    private func tint(_ state: EstimateFreshness) -> Color {
        guard store.isPro else { return Theme.cardio }
        switch state.state {
        case .fresh: return Theme.positive
        case .aging: return Theme.cardio
        case .stale: return Theme.coral
        case .noReadings: return Theme.cardio
        }
    }
}

struct EstimateFreshnessDetailView: View {
    @EnvironmentObject private var settings: GoalSettings
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]
    @StateObject private var context = CardioContextService.shared

    private var freshness: EstimateFreshness {
        CardioFreshnessAnalysis.assess(
            points: samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                statusCard
                qualifyingCard
                recentQualifyingCard
                nudgeCard
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Estimate Freshness")
        .navigationBarTitleDisplayMode(.inline)
        .task { await context.load() }
    }

    private var statusCard: some View {
        let state = freshness
        return VStack(spacing: 10) {
            Text(state.daysSinceLatest.map(String.init) ?? "—")
                .font(Theme.bigNumber(46))
                .foregroundStyle(Theme.cardio)
            Text(state.daysSinceLatest == 1 ? "day since your last estimate" : "days since your last estimate")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Text(state.headline)
                .font(.title3.bold())
            Text(state.detail)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var qualifyingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("What refreshes the estimate", systemImage: "applewatch.radiowaves.left.and.right")
                .font(.headline)
            ForEach(Self.requirements, id: \.self) { requirement in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.positive)
                        .padding(.top, 3)
                    Text(requirement)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Text("Apple Health, not this app, decides when an estimate is recorded. These are the conditions Apple documents for cardio fitness.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private static let requirements = [
        "An outdoor walk, run, or hike recorded with Apple Watch.",
        "At least 20 minutes of steady, brisk effort.",
        "Apple Watch worn snugly, with wrist detection on.",
        "Location enabled so pace and elevation are available."
    ]

    @ViewBuilder
    private var recentQualifyingCard: some View {
        let recent = context.workouts.filter(\.refreshesEstimate).suffix(5).reversed()
        VStack(alignment: .leading, spacing: 10) {
            Label("Recent qualifying sessions", systemImage: "figure.walk.motion")
                .font(.headline)
            if recent.isEmpty {
                Text("No outdoor walks, runs, or hikes found in the last \(CardioContextService.historyDays) days. Those are the sessions Apple Health can draw a new estimate from.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(Array(recent)) { workout in
                    HStack(spacing: 10) {
                        Image(systemName: workout.kind.symbol)
                            .font(.subheadline)
                            .foregroundStyle(Theme.cardio)
                            .frame(width: 26)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(workout.kind.label)
                                .font(.subheadline.weight(.medium))
                            Text(workout.date, format: .dateTime.month(.abbreviated).day())
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Text("\(Int(workout.minutes.rounded())) min")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var nudgeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Freshness nudges", systemImage: "bell.badge")
                .font(.headline)
            Text(settings.freshnessNudgesEnabled
                 ? "On. You'll get a nudge when an estimate is overdue against your own cadence, at most once every five days."
                 : "Off. Turn nudges on in Settings to be told when your estimate goes overdue against your own cadence.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}

// MARK: - What moved it

struct WhatMovedItCard: View {
    @EnvironmentObject private var store: StoreService
    @State private var showPaywall = false

    var body: some View {
        PlusContextCard(
            title: "What moved it",
            symbol: "figure.run.circle",
            isLocked: !store.isPro
        ) {
            NavigationLink { WhatMovedItDetailView() } label: {
                HStack {
                    Text("Compare the training behind your rising and flat stretches.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } locked: {
            PlusContextLockedBody(
                feature: .whatMovedIt,
                ctaTitle: store.shortConversionCTALabel
            ) { showPaywall = true }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(focus: .whatMovedIt)
        }
    }
}

/// Correlates the user's own workout history with the stretches between their
/// estimates. Strictly descriptive: it reports what the record shows, never
/// prescribes training and never claims the training caused the change.
struct WhatMovedItDetailView: View {
    @Query(sort: \CardioFitnessSample.date) private var samples: [CardioFitnessSample]
    @StateObject private var context = CardioContextService.shared

    private var points: [CardioFitnessPoint] {
        samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
    }

    private var windows: [TrainingWindow] {
        CardioDriverAnalysis.windows(points: points, workouts: context.workouts)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                comparisonCard
                weeklyLoadCard
                activityCard
                methodologyCard
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("What Moved It")
        .navigationBarTitleDisplayMode(.inline)
        .task { await context.load() }
    }

    @ViewBuilder
    private var comparisonCard: some View {
        let summary = CardioDriverAnalysis.summary(windows: windows)

        VStack(alignment: .leading, spacing: 12) {
            Label("Rising vs. flat stretches", systemImage: "arrow.up.arrow.down")
                .font(.headline)

            if let summary {
                Text(CardioDriverAnalysis.headline(summary: summary))
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 0) {
                    driverBlock(
                        title: "Estimate rose",
                        minutes: summary.risingMinutesPerWeek,
                        sessions: summary.risingSessionsPerWeek,
                        count: summary.risingCount,
                        color: Theme.positive
                    )
                    Divider().frame(height: 62)
                    driverBlock(
                        title: "Flat or down",
                        minutes: summary.otherMinutesPerWeek,
                        sessions: summary.otherSessionsPerWeek,
                        count: summary.otherCount,
                        color: Theme.textSecondary
                    )
                }
                .padding(.top, 2)
            } else {
                Text("This comparison needs at least \(CardioDriverAnalysis.minimumWindows) stretches between estimates, with a few in each group. Keep recording workouts and it will fill in as Apple Health logs more estimates.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(windows.count) of \(CardioDriverAnalysis.minimumWindows) usable stretches so far.")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private func driverBlock(
        title: String,
        minutes: Double,
        sessions: Double,
        count: Int,
        color: Color
    ) -> some View {
        VStack(spacing: 3) {
            Text("\(Int(minutes.rounded()))")
                .font(Theme.bigNumber(26))
                .foregroundStyle(color)
            Text("min/week")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("\(sessions.formatted(.number.precision(.fractionLength(1)))) sessions/week · \(count) stretches")
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var weeklyLoadCard: some View {
        let load = CardioDriverAnalysis.weeklyLoad(workouts: context.workouts, weeks: 12)
        VStack(alignment: .leading, spacing: 10) {
            Label("Weekly cardio minutes", systemImage: "chart.bar.fill")
                .font(.headline)
            if load.allSatisfy({ $0.minutes == 0 }) {
                Text("No cardio workouts found in Apple Health for the last 12 weeks.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                Chart(load) { week in
                    BarMark(
                        x: .value("Week", week.weekStart, unit: .weekOfYear),
                        y: .value("Minutes", week.minutes)
                    )
                    .foregroundStyle(Theme.cardioGradient)
                    .cornerRadius(3)
                }
                .chartYAxisLabel("minutes")
                .frame(height: 150)
                Text("Sessions that can refresh your estimate (outdoor walks, runs, hikes) are a subset of this total.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    @ViewBuilder
    private var activityCard: some View {
        let totals = CardioDriverAnalysis.activityTotals(workouts: context.workouts, days: 90)
        if !totals.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label("Where the minutes went", systemImage: "list.bullet")
                    .font(.headline)
                Text("Last 90 days")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                ForEach(totals) { total in
                    HStack(spacing: 10) {
                        Image(systemName: total.kind.symbol)
                            .font(.subheadline)
                            .foregroundStyle(total.kind.canRefreshEstimate ? Theme.cardio : Theme.textSecondary)
                            .frame(width: 26)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(total.kind.label)
                                .font(.subheadline.weight(.medium))
                            Text("\(total.sessions) \(total.sessions == 1 ? "session" : "sessions")")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Text("\(Int(total.minutes.rounded())) min")
                            .font(.subheadline.monospacedDigit())
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
    }

    private var methodologyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("How this is calculated", systemImage: "info.circle")
                .font(.headline)
            Text("Each pair of consecutive Apple Health estimates forms a stretch. The app totals the cardio workouts recorded inside that stretch, converts them to minutes per week, and then averages the stretches where your estimate rose separately from the ones where it stayed flat or fell.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("This describes patterns in your own history. It does not establish cause, and it is not a training plan or medical advice.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}

// MARK: - Heart signals

struct HeartSignalsCard: View {
    @EnvironmentObject private var store: StoreService
    @State private var showPaywall = false

    var body: some View {
        PlusContextCard(
            title: "Heart signals",
            symbol: "heart.text.square",
            isLocked: !store.isPro
        ) {
            NavigationLink { HeartSignalsDetailView() } label: {
                HStack {
                    Text("Resting heart rate and 1-minute recovery, between estimates.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } locked: {
            PlusContextLockedBody(
                feature: .heartSignals,
                ctaTitle: store.shortConversionCTALabel
            ) { showPaywall = true }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(focus: .heartSignals)
        }
    }
}

/// VO2 max lands every week or three. Resting heart rate moves nightly and
/// heart rate recovery moves after every workout, so these are what make the
/// quiet stretches legible.
struct HeartSignalsDetailView: View {
    @StateObject private var context = CardioContextService.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                signalCard(
                    title: "Resting heart rate",
                    symbol: "bed.double",
                    unit: "bpm",
                    points: context.restingHeartRate,
                    lowerIsBetter: true,
                    emptyMessage: "No resting heart rate found in Apple Health for the last \(CardioContextService.historyDays) days. Apple Watch records it in the background as you wear it."
                )
                signalCard(
                    title: "Heart rate recovery",
                    symbol: "arrow.down.heart",
                    unit: "bpm drop",
                    points: context.heartRateRecovery,
                    lowerIsBetter: false,
                    emptyMessage: "No recovery values found in Apple Health for the last \(CardioContextService.historyDays) days. Apple Watch records the one-minute drop after a recorded workout."
                )
                methodologyCard
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Heart Signals")
        .navigationBarTitleDisplayMode(.inline)
        .task { await context.load() }
        .overlay {
            if context.isLoading, context.lastLoaded == nil {
                ProgressView().tint(Theme.cardio)
            }
        }
    }

    private func signalCard(
        title: String,
        symbol: String,
        unit: String,
        points: [CardioFitnessPoint],
        lowerIsBetter: Bool,
        emptyMessage: String
    ) -> some View {
        let recent = average(points, days: 30)
        let previous = average(points, days: 30, offsetDays: 30)
        var change: Double?
        if let recent, let previous { change = recent - previous }

        return VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.headline)

            if points.isEmpty {
                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(points.last?.value.formatted(.number.precision(.fractionLength(0))) ?? "—")
                        .font(Theme.bigNumber(34))
                        .foregroundStyle(Theme.cardio)
                    Text(unit)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    if let change {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(change, format: .number.precision(.fractionLength(1)).sign(strategy: .always()))
                                .font(.subheadline.bold().monospacedDigit())
                                .foregroundStyle(changeColor(change, lowerIsBetter: lowerIsBetter))
                            Text("vs. prior 30 days")
                                .font(.caption2)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }

                Chart(points, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(title, point.value)
                    )
                    .foregroundStyle(Theme.cardioGradient)
                    .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 130)

                if let recent {
                    Text("30-day average \(recent.formatted(.number.precision(.fractionLength(1)))) \(unit).")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var methodologyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Reading these together", systemImage: "info.circle")
                .font(.headline)
            Text("Resting heart rate is what Apple Health records overnight and at rest. Heart rate recovery is how far your heart rate falls in the minute after a recorded workout ends. Both are read-only from Apple Health and shown here for context alongside your cardio fitness estimate.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("These are fitness-awareness signals, not medical measurements. This app does not diagnose, treat, or monitor any condition. Discuss heart health concerns with a qualified clinician.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private func average(_ points: [CardioFitnessPoint], days: Int, offsetDays: Int = 0) -> Double? {
        let calendar = Calendar.current
        let now = Date.now
        guard let end = calendar.date(byAdding: .day, value: -offsetDays, to: now),
              let start = calendar.date(byAdding: .day, value: -days, to: end) else { return nil }
        let window = points.filter { $0.date >= start && $0.date <= end }
        guard !window.isEmpty else { return nil }
        return window.reduce(0.0) { $0 + $1.value } / Double(window.count)
    }

    private func changeColor(_ change: Double, lowerIsBetter: Bool) -> Color {
        if abs(change) < 0.5 { return Theme.textSecondary }
        let improving = lowerIsBetter ? change < 0 : change > 0
        return improving ? Theme.positive : Theme.coral
    }
}
