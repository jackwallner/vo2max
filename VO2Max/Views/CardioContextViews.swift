import Charts
import SwiftData
import SwiftUI

// MARK: - Shared range

/// Range control for every window-scoped screen, plus the date span it resolves
/// to. Ported from the Vitals period selector: plain buttons in a capsule rather
/// than `.pickerStyle(.segmented)`, because a segmented control claims the
/// horizontal drag — a finger that lands on it slides the selection sideways
/// instead of scrolling the page under it.
struct MetricRangePicker: View {
    @ObservedObject private var ranges = CardioRangeStore.shared
    @EnvironmentObject private var store: StoreService
    @State private var showCustomSheet = false
    @State private var showPaywall = false
    @State private var draftStart = Date.now
    @State private var draftEnd = Date.now

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(MetricRange.allCases) { option in
                    RangeSegmentButton(
                        title: option.label,
                        isSelected: ranges.selection == option,
                        locked: option == .custom && !store.isPro
                    ) {
                        tap(option)
                    }
                }
            }
            .padding(3)
            .background(Theme.cardSurface, in: Capsule())
            // Five equal segments in one capsule cannot grow indefinitely:
            // past this size "Custom" truncates to "Cust…". UISegmentedControl
            // capped its own text the same way, so this is no worse than the
            // control it replaced, and every label stays legible.
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)

            Text(ranges.resolved.spanLabel)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
                .accessibilityLabel("Showing \(ranges.resolved.spanLabel)")
        }
        .onAppear { ranges.revertCustomIfLocked(isPro: store.isPro) }
        .onChange(of: store.isPro) { _, isPro in ranges.revertCustomIfLocked(isPro: isPro) }
        .sheet(isPresented: $showCustomSheet) {
            CustomRangeSheet(start: $draftStart, end: $draftEnd) {
                ranges.applyCustom(start: draftStart, end: draftEnd)
                showCustomSheet = false
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(focus: .customRange)
        }
    }

    private func tap(_ option: MetricRange) {
        guard option == .custom else {
            ranges.select(option)
            return
        }
        guard store.isPro else {
            showPaywall = true
            return
        }
        draftStart = ranges.customStart
        draftEnd = ranges.customEnd
        showCustomSheet = true
    }
}

private struct RangeSegmentButton: View {
    let title: String
    let isSelected: Bool
    var locked = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .bold))
                }
                Text(title)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .foregroundStyle(locked ? Theme.textTertiary : (isSelected ? Theme.textPrimary : Theme.textSecondary))
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Theme.cardSurfaceLight : .clear, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityHint(locked ? "VO2+: pick any date range" : "")
    }
}

/// Start/end picker behind the Custom segment. Ported from Vitals, with the
/// same two-year ceiling: beyond that the weekly charts stop being readable.
private struct CustomRangeSheet: View {
    @Binding var start: Date
    @Binding var end: Date
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var spanDays: Int {
        Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }

    private var isValid: Bool {
        start < end && spanDays <= CardioRange.maximumCustomDays
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Start", selection: $start, in: ...Date.now, displayedComponents: .date)
                DatePicker("End", selection: $end, in: ...Date.now, displayedComponents: .date)
                if isValid {
                    Section {
                        Text("\(spanDays) days selected")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                } else {
                    Section {
                        Text(start >= end
                             ? "Start date must be before end date."
                             : "Maximum range is 2 years.")
                            .font(.caption)
                            .foregroundStyle(Theme.negative)
                    }
                }
            }
            .navigationTitle("Custom Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") { onApply() }
                        .bold()
                        .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - VO2+ gate

/// A locked number. The real value is never drawn for a locked user: an
/// invented placeholder is rendered, blurred past legibility, and covered with a
/// lock — so the card keeps its exact shape without leaking the data it sells.
struct LockedNumber: View {
    let placeholder: String
    let size: CGFloat

    var body: some View {
        Text(placeholder)
            .font(Theme.bigNumber(size))
            .foregroundStyle(Theme.textSecondary.opacity(0.85))
            // Enough blur that no digit survives, little enough that the reader
            // can still see a number is being withheld.
            .blur(radius: size * 0.22)
            .overlay {
                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(Theme.cardio)
                    .shadow(color: Theme.background, radius: 3)
            }
            .accessibilityLabel("Locked. Included with VO2+")
    }
}

extension View {
    /// Blurs a whole locked region (sparklines, stat rows) to match the lock on
    /// the headline number beside it.
    func plusBlurred(_ radius: CGFloat = 8) -> some View {
        blur(radius: radius)
            .opacity(0.7)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Signals

/// The three VO2+ series that move between Apple Health estimates. Named after
/// the data itself, because that is what the people tracking VO2 max call them.
enum CardioSignal: Identifiable, Hashable {
    case heart(HeartMetric)
    case load

    static let all: [CardioSignal] = [.heart(.restingHeartRate), .heart(.heartRateRecovery), .load]

    var id: String {
        switch self {
        case .heart(let metric): metric.rawValue
        case .load: "cardioLoad"
        }
    }

    var isLoad: Bool { self == .load }

    var title: String {
        switch self {
        case .heart(let metric): metric.title
        case .load: "Cardio Load"
        }
    }

    var abbreviation: String {
        switch self {
        case .heart(let metric): metric.abbreviation
        case .load: "LOAD"
        }
    }

    var unit: String {
        switch self {
        case .heart(let metric): metric.unitDetail
        case .load: "min/week"
        }
    }

    var shortUnit: String {
        switch self {
        case .heart: "bpm"
        case .load: "min/wk"
        }
    }

    var symbol: String {
        switch self {
        case .heart(let metric): metric.symbol
        case .load: "figure.run.circle"
        }
    }

    var subtitle: String {
        switch self {
        case .heart(let metric): metric.subtitle
        case .load: "Cardio minutes and sessions from your workout history"
        }
    }

    var lowerIsBetter: Bool {
        switch self {
        case .heart(let metric): metric.lowerIsBetter
        case .load: false
        }
    }

    /// Invented digits drawn behind the lock. Never the user's own value.
    var lockedPlaceholder: String {
        switch self {
        case .heart(let metric): metric.lockedPlaceholder
        case .load: "146"
        }
    }

    var feature: PlusFeature {
        switch self {
        case .heart(.restingHeartRate): .restingHeartRate
        case .heart(.heartRateRecovery): .heartRateRecovery
        case .load: .cardioLoad
        }
    }
}

/// Current value, change, and series for one signal over the selected range,
/// pulled from whichever analysis owns it.
struct SignalReading {
    let value: Double
    let change: Double?
    let detail: String
    let series: [CardioFitnessPoint]

    @MainActor
    static func make(
        signal: CardioSignal,
        range: CardioRange,
        context: CardioContextService
    ) -> SignalReading? {
        switch signal {
        case .heart(let metric):
            let points = context.points(for: metric)
            guard let summary = CardioMetricAnalysis.summarize(
                points: points,
                days: range.days,
                now: range.end
            ) else { return nil }
            let low = Int(summary.minimum.rounded())
            let high = Int(summary.maximum.rounded())
            let average = summary.average.formatted(.number.precision(.fractionLength(1)))
            return SignalReading(
                value: summary.latest,
                change: summary.change,
                detail: "avg \(average) · range \(low)–\(high) · \(summary.count) readings",
                series: CardioMetricAnalysis.downsample(points.filter { range.contains($0.date) })
            )
        case .load:
            guard let summary = CardioDriverAnalysis.loadSummary(
                workouts: context.workouts,
                days: range.days,
                now: range.end
            ) else { return nil }
            let sessions = summary.sessionsPerWeek.formatted(.number.precision(.fractionLength(1)))
            let qualifying = Int(summary.qualifyingMinutesPerWeek.rounded())
            return SignalReading(
                value: summary.minutesPerWeek,
                change: summary.change,
                detail: "\(sessions) sessions/week · \(qualifying) min/week can refresh the estimate",
                series: CardioDriverAnalysis.weeklyLoad(
                    workouts: context.workouts,
                    weeks: range.chartWeeks,
                    now: range.end
                )
                .map { CardioFitnessPoint(date: $0.weekStart, value: $0.minutes) }
            )
        }
    }
}

// MARK: - Full-width signal card (Trends)

/// Shows the number without a tap. Locked users see the same card with the
/// value blurred out behind a lock, so the shape of what they'd get is honest.
struct CardioSignalCard: View {
    let signal: CardioSignal
    let range: CardioRange

    @EnvironmentObject private var store: StoreService
    @ObservedObject private var context = CardioContextService.shared
    @State private var showPaywall = false

    var body: some View {
        Group {
            if store.isPro {
                NavigationLink { destination } label: { card }
                    .buttonStyle(.plain)
            } else {
                Button { showPaywall = true } label: { card }
                    .buttonStyle(.plain)
            }
        }
        .task { await context.load() }
        .sheet(isPresented: $showPaywall) {
            PaywallView(focus: signal.feature)
        }
    }

    @ViewBuilder
    private var destination: some View {
        switch signal {
        case .heart(let metric): HeartMetricDetailView(metric: metric)
        case .load: CardioLoadDetailView()
        }
    }

    private var reading: SignalReading? {
        SignalReading.make(signal: signal, range: range, context: context)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if store.isPro {
                if let reading {
                    unlockedBody(reading)
                } else {
                    Text(emptyMessage)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                lockedBody
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .contentShape(Rectangle())
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: signal.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.cardio)
                .frame(width: 30, height: 30)
                .background(Theme.cardio.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(signal.title)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(signal.subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 6)
            if store.isPro {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textTertiary)
            } else {
                Text("VO2+")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.cardio.opacity(0.15), in: Capsule())
                    .foregroundStyle(Theme.cardio)
            }
        }
    }

    private func unlockedBody(_ reading: SignalReading) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(reading.value, format: .number.precision(.fractionLength(0)))
                    .font(Theme.bigNumber(34))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                Text(signal.unit)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                Spacer(minLength: 4)
                if let change = reading.change {
                    ChangeBadge(
                        change: change,
                        lowerIsBetter: signal.lowerIsBetter,
                        caption: "vs. \(range.priorPhrase)"
                    )
                }
            }
            sparkline(reading.series)
            Text(reading.detail)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var lockedBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                LockedNumber(placeholder: signal.lockedPlaceholder, size: 34)
                Text(signal.unit)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                Spacer(minLength: 4)
            }
            sparkline(Self.placeholderSeries).plusBlurred()
            Text(signal.feature.intentSubheadline)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(store.shortConversionCTALabel) { showPaywall = true }
                .buttonStyle(.borderedProminent)
                .tint(Theme.cardio)
                .controlSize(.small)
        }
    }

    @ViewBuilder
    private func sparkline(_ points: [CardioFitnessPoint]) -> some View {
        if points.count > 1 {
            Chart(points, id: \.date) { point in
                if signal.isLoad {
                    BarMark(
                        x: .value("Week", point.date, unit: .weekOfYear),
                        y: .value("Minutes", point.value)
                    )
                    .foregroundStyle(Theme.cardioGradient)
                    .cornerRadius(2)
                } else {
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(signal.abbreviation, point.value)
                    )
                    .foregroundStyle(Theme.cardioGradient)
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: .automatic(includesZero: signal.isLoad))
            .frame(height: 54)
        }
    }

    private var emptyMessage: String {
        switch signal {
        case .heart(let metric):
            "No \(metric.title.lowercased()) recorded in the \(range.phrase). Choose a longer range, or check that Apple Health holds this data."
        case .load:
            "No cardio workouts recorded in the \(range.phrase)."
        }
    }

    /// Invented shape for the locked sparkline — never the user's own series.
    private static let placeholderSeries: [CardioFitnessPoint] = (0..<14).compactMap { index in
        guard let date = Calendar.current.date(byAdding: .day, value: -(13 - index) * 5, to: .now) else { return nil }
        return CardioFitnessPoint(date: date, value: 50 + sin(Double(index) * 0.8) * 6 + Double(index) * 0.6)
    }
}

/// Signed change, coloured by which direction is better for this metric: a
/// falling resting heart rate is progress, a falling recovery is not.
struct ChangeBadge: View {
    let change: Double
    let lowerIsBetter: Bool
    var caption: String?

    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(change, format: .number.precision(.fractionLength(1)).sign(strategy: .always()))
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(color)
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var color: Color {
        if abs(change) < 0.5 { return Theme.textSecondary }
        return (lowerIsBetter ? change < 0 : change > 0) ? Theme.positive : Theme.coral
    }
}

// MARK: - Compact tile (Today)

/// Third-width tile for the Today dashboard row. Same lock-and-blur treatment,
/// scaled down.
struct CardioSignalTile: View {
    let signal: CardioSignal
    let range: CardioRange

    @EnvironmentObject private var store: StoreService
    @ObservedObject private var context = CardioContextService.shared
    @State private var showPaywall = false

    var body: some View {
        Group {
            if store.isPro {
                NavigationLink { destination } label: { tile }
                    .buttonStyle(.plain)
            } else {
                Button { showPaywall = true } label: { tile }
                    .buttonStyle(.plain)
            }
        }
        .task { await context.load() }
        .sheet(isPresented: $showPaywall) {
            PaywallView(focus: signal.feature)
        }
    }

    @ViewBuilder
    private var destination: some View {
        switch signal {
        case .heart(let metric): HeartMetricDetailView(metric: metric)
        case .load: CardioLoadDetailView()
        }
    }

    private var reading: SignalReading? {
        SignalReading.make(signal: signal, range: range, context: context)
    }

    private var tile: some View {
        VStack(spacing: 3) {
            Text(signal.abbreviation)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.cardio)

            if store.isPro {
                if let reading {
                    Text(reading.value, format: .number.precision(.fractionLength(0)))
                        .font(Theme.bigNumber(26))
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText())
                } else {
                    Text("—")
                        .font(Theme.bigNumber(26))
                        .foregroundStyle(Theme.textTertiary)
                }
            } else {
                LockedNumber(placeholder: signal.lockedPlaceholder, size: 26)
            }

            Text(signal.shortUnit)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(Theme.textSecondary)

            if store.isPro, let change = reading?.change {
                ChangeBadge(change: change, lowerIsBetter: signal.lowerIsBetter)
            } else {
                // Keeps all three tiles the same height whether or not a
                // comparison window exists.
                Text(" ").font(.subheadline.monospacedDigit())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(signal.title)
    }
}

/// The Today row: resting heart rate, heart rate recovery, cardio load. These
/// move while the estimate itself is quiet, which is most of the time.
struct CardioSignalRow: View {
    @ObservedObject private var ranges = CardioRangeStore.shared

    var body: some View {
        HStack(spacing: 10) {
            ForEach(CardioSignal.all) { signal in
                CardioSignalTile(signal: signal, range: ranges.resolved)
            }
        }
    }
}

// MARK: - Heart metric detail

/// One HealthKit series in full. The range picker at the top drives every number
/// on the screen.
struct HeartMetricDetailView: View {
    let metric: HeartMetric

    @ObservedObject private var context = CardioContextService.shared
    @ObservedObject private var ranges = CardioRangeStore.shared

    private var range: CardioRange { ranges.resolved }

    private var points: [CardioFitnessPoint] { context.points(for: metric) }

    private var windowPoints: [CardioFitnessPoint] {
        points.filter { range.contains($0.date) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                MetricRangePicker()
                if let summary = CardioMetricAnalysis.summarize(
                    points: points,
                    days: range.days,
                    now: range.end
                ) {
                    summaryCard(summary)
                    chartCard(summary)
                    monthlyCard
                } else {
                    emptyCard
                }
                sourceCard
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle(metric.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await context.load() }
        .overlay {
            if context.isLoading, context.lastLoaded == nil {
                ProgressView().tint(Theme.cardio)
            }
        }
    }

    private func summaryCard(_ summary: MetricSummary) -> some View {
        VStack(spacing: 12) {
            Text(summary.latest, format: .number.precision(.fractionLength(0)))
                .font(Theme.bigNumber(48))
                .foregroundStyle(Theme.cardio)
            Text(metric.unitDetail)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Text("Latest reading \(summary.latestDate, format: .dateTime.month(.abbreviated).day())")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)

            Divider()

            HStack(spacing: 0) {
                statBlock("Average", summary.average.formatted(.number.precision(.fractionLength(1))))
                Divider().frame(height: 34)
                statBlock("Low", "\(Int(summary.minimum.rounded()))")
                Divider().frame(height: 34)
                statBlock("High", "\(Int(summary.maximum.rounded()))")
                Divider().frame(height: 34)
                statBlock("Readings", "\(summary.count)")
            }

            if let change = summary.change {
                VStack(spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Average vs. \(range.priorPhrase)")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        ChangeBadge(change: change, lowerIsBetter: metric.lowerIsBetter)
                    }
                    if let prior = range.priorSpanLabel() {
                        Text(prior)
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            } else {
                Text("No readings in the \(range.priorPhrase) to compare against.")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private func statBlock(_ title: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Theme.bigNumber(19))
                .foregroundStyle(Theme.textPrimary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func chartCard(_ summary: MetricSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Label("\(metric.abbreviation) over the \(range.phrase)", systemImage: metric.symbol)
                    .font(.headline)
                Text(range.spanLabel)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Chart {
                RuleMark(y: .value("Average", summary.average))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Theme.textTertiary)
                ForEach(CardioMetricAnalysis.downsample(windowPoints), id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(metric.abbreviation, point.value)
                    )
                    .foregroundStyle(Theme.cardioGradient)
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYAxisLabel(metric.unit)
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 180)
            Text("Dashed line is the \(range.phrase) average.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    @ViewBuilder
    private var monthlyCard: some View {
        let months = CardioMetricAnalysis.monthlyAverages(points: points, days: range.days, now: range.end)
        if months.count > 1 {
            VStack(alignment: .leading, spacing: 10) {
                Label("Monthly averages", systemImage: "calendar")
                    .font(.headline)
                ForEach(months) { month in
                    HStack {
                        Text(month.monthStart, format: .dateTime.month(.wide).year())
                            .font(.subheadline)
                        Spacer()
                        Text("\(month.count) \(month.count == 1 ? "reading" : "readings")")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        Text(month.average, format: .number.precision(.fractionLength(1)))
                            .font(.subheadline.bold().monospacedDigit())
                            .frame(width: 52, alignment: .trailing)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
    }

    private var emptyCard: some View {
        VStack(spacing: 12) {
            Image(systemName: metric.symbol)
                .font(.system(size: 38))
                .foregroundStyle(Theme.cardio)
            Text("No readings in the \(range.phrase)")
                .font(.headline)
            Text(metric == .restingHeartRate
                 ? "Apple Watch records resting heart rate in the background as you wear it. Choose a longer range, or check that Apple Health holds this data."
                 : "Apple Watch records the one-minute drop after a recorded workout. Choose a longer range, or record a workout with your Watch on.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Where this comes from", systemImage: "info.circle")
                .font(.headline)
            Text("\(metric.subtitle). Read directly from Apple Health, never written to.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(metric.healthKitIdentifier)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textTertiary)
            Text("A fitness-awareness signal, not a medical measurement. This app does not diagnose, treat, or monitor any condition. Discuss heart health concerns with a qualified clinician.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}

// MARK: - Cardio load detail

/// Cardio minutes and sessions, plus how they line up with the stretches where
/// the estimate rose. Strictly descriptive: it reports what the record shows,
/// never prescribes training and never claims the training caused the change.
struct CardioLoadDetailView: View {
    @Query(sort: \CardioFitnessSample.date) private var samples: [CardioFitnessSample]
    @ObservedObject private var context = CardioContextService.shared
    @ObservedObject private var ranges = CardioRangeStore.shared

    private var range: CardioRange { ranges.resolved }

    private var points: [CardioFitnessPoint] {
        samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
    }

    private var windows: [TrainingWindow] {
        CardioDriverAnalysis.windows(points: points, workouts: context.workouts)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                MetricRangePicker()
                loadCard
                weeklyLoadCard
                comparisonCard
                activityCard
                methodologyCard
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Cardio Load")
        .navigationBarTitleDisplayMode(.inline)
        .task { await context.load() }
    }

    @ViewBuilder
    private var loadCard: some View {
        if let summary = CardioDriverAnalysis.loadSummary(
            workouts: context.workouts,
            days: range.days,
            now: range.end
        ) {
            VStack(spacing: 12) {
                Text(summary.minutesPerWeek, format: .number.precision(.fractionLength(0)))
                    .font(Theme.bigNumber(48))
                    .foregroundStyle(Theme.cardio)
                Text("min/week over the \(range.phrase)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)

                Divider()

                HStack(spacing: 0) {
                    statBlock("Sessions", "\(summary.sessions)")
                    Divider().frame(height: 34)
                    statBlock("Per week", summary.sessionsPerWeek.formatted(.number.precision(.fractionLength(1))))
                    Divider().frame(height: 34)
                    statBlock("Total min", "\(Int(summary.totalMinutes.rounded()))")
                    Divider().frame(height: 34)
                    statBlock("Qual. min/wk", "\(Int(summary.qualifyingMinutesPerWeek.rounded()))")
                }

                if let change = summary.change {
                    VStack(spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Minutes per week vs. \(range.priorPhrase)")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                            ChangeBadge(change: change, lowerIsBetter: false)
                        }
                        if let prior = range.priorSpanLabel() {
                            Text(prior)
                                .font(.caption2)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }

                Text("Qualifying is the share of your weekly minutes from outdoor walks, runs, and hikes — the only sessions Apple Health can draw a new estimate from.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        } else {
            VStack(spacing: 10) {
                Image(systemName: "figure.run.circle")
                    .font(.system(size: 38))
                    .foregroundStyle(Theme.cardio)
                Text("No cardio workouts in the \(range.phrase)")
                    .font(.headline)
                Text("Walks, runs, hikes, rides, swims, rows, elliptical, and interval sessions recorded in Apple Health all count here.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
    }

    private func statBlock(_ title: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Theme.bigNumber(19))
                .foregroundStyle(Theme.textPrimary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var weeklyLoadCard: some View {
        let load = CardioDriverAnalysis.weeklyLoad(
            workouts: context.workouts,
            weeks: range.chartWeeks,
            now: range.end
        )
        if !load.allSatisfy({ $0.minutes == 0 }) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Weekly cardio minutes", systemImage: "chart.bar.fill")
                        .font(.headline)
                    Text(range.spanLabel)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
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
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
    }

    @ViewBuilder
    private var comparisonCard: some View {
        let summary = CardioDriverAnalysis.summary(windows: windows)

        VStack(alignment: .leading, spacing: 12) {
            Label("Load in rising vs. flat stretches", systemImage: "arrow.up.arrow.down")
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
    private var activityCard: some View {
        let totals = CardioDriverAnalysis.activityTotals(
            workouts: context.workouts,
            days: range.days,
            now: range.end
        )
        if !totals.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label("Where the minutes went", systemImage: "list.bullet")
                    .font(.headline)
                Text(range.spanLabel)
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
            Text("Cardio minutes come from your recorded workouts in Apple Health, totalled across the selected range and divided by its length in weeks. For the rising-vs-flat comparison, each pair of consecutive estimates forms a stretch, the workouts inside it are converted to minutes per week, and the stretches where your estimate rose are averaged separately from the ones where it stayed flat or fell.")
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

// MARK: - Estimate freshness

/// Reached from the VO2+ tab and the freshness-nudge setting. Today no longer
/// carries a standing "estimate is current" block: when the estimate is current
/// there is nothing to say, and the header line already carries the date.
struct EstimateFreshnessDetailView: View {
    @EnvironmentObject private var settings: GoalSettings
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]
    @ObservedObject private var context = CardioContextService.shared

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
                Text("No outdoor walks, runs, or hikes found in Apple Health. Those are the sessions Apple Health can draw a new estimate from.")
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
