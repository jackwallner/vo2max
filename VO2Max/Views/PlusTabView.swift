import SwiftData
import SwiftUI

/// VO2+ is both the purchase surface for free users and a concise subscriber
/// hub. Premium results also appear in Today, Trends, and their detail screens,
/// so this tab explains the toolkit and links back to those useful contexts.
struct PlusTabView: View {
    @Environment(\.isActiveTab) private var isActiveTab
    @EnvironmentObject private var settings: GoalSettings
    @EnvironmentObject private var store: StoreService
    @ObservedObject private var ranges = CardioRangeStore.shared
    @ObservedObject private var context = CardioContextService.shared
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]
    @State private var showRecap = false

    private var points: [CardioFitnessPoint] {
        samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
    }

    var body: some View {
        Group {
            if store.isPro {
                subscriberHub
            } else if isActiveTab {
                PaywallView(embedded: true, impressionID: "vo2plus_tab")
                    .navigationTitle("VO2+")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                // All three tabs stay alive so each keeps its scroll position,
                // but a free user's VO2+ tab is a paywall with no state worth
                // preserving — and leaving it built put a whole second screen of
                // elements in front of VoiceOver on Today and Trends, which
                // `accessibilityHidden` did not remove at any level tried
                // against a booted simulator. Building it on arrival also means
                // its impression is logged when it is genuinely seen.
                Color.clear
            }
        }
    }

    private var subscriberHub: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                activeHeader
                currentHighlights
                signalsSection
                estimateSection
                contextSection
                accountNote
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Theme.background)
        .navigationTitle("VO2+")
        .navigationBarTitleDisplayMode(.inline)
        // The signal rows print live numbers now, so this tab needs the same
        // read the Today tiles and Trends cards do.
        .task { await context.load() }
        .sheet(isPresented: $showRecap) {
            MonthlyRecapView().environmentObject(settings)
        }
    }

    // MARK: - Header

    private var activeHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(Theme.positive)
                .frame(width: 44, height: 44)
                .background(Theme.positive.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("VO2+ active")
                    .font(.title3.bold())
                Text("Every screen below is unlocked, and reads the range you pick.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    // MARK: - Highlights

    /// Deliberately styled as a read-only figures table rather than icon rows:
    /// the old version used the same circular-icon layout as the links below it,
    /// which is why nothing on this tab looked tappable. Data reads as data here,
    /// and only the sectioned rows underneath read as buttons.
    @ViewBuilder
    private var currentHighlights: some View {
        if points.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.cardio)
                Text("Insights build with your readings")
                    .font(.headline)
                Text("As Apple Health records estimates, VO2+ will compare periods, add target context, and keep your personal best visible.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(22)
            .frame(maxWidth: .infinity)
            .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        } else {
            VStack(spacing: 0) {
                // Separators are interleaved rather than trailed after each row:
                // age reference needs a reference profile and target outlook needs
                // five readings, so the early-history card (personal best alone)
                // used to end on a divider with nothing under it.
                ForEach(Array(highlights.enumerated()), id: \.element.label) { index, highlight in
                    if index > 0 { highlightDivider }
                    highlightRow(
                        label: highlight.label,
                        value: highlight.value,
                        detail: highlight.detail
                    )
                }
            }
            .padding(.vertical, 4)
            .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
    }

    private struct Highlight {
        let label: String
        let value: String
        let detail: String
    }

    private var highlights: [Highlight] {
        var rows: [Highlight] = []
        if let best = CardioFitnessAnalysis.personalBest(points: points) {
            rows.append(Highlight(
                label: "Personal best",
                value: best.value.formatted(.number.precision(.fractionLength(1))),
                detail: best.date.formatted(.dateTime.month(.abbreviated).day().year())
            ))
        }
        if let latest = points.max(by: { $0.date < $1.date }),
           let band = CardioFitnessAnalysis.fitnessBand(
               value: latest.value,
               age: settings.chronologicalAge,
               referenceSex: settings.referenceSex
           ) {
            rows.append(Highlight(
                label: "Age reference",
                value: band,
                detail: "Broad context for age \(settings.chronologicalAge)"
            ))
        }
        if let projection = CardioFitnessAnalysis.projection(
            points: points,
            targetLower: settings.targetLower
        ) {
            let outlook = projectionHighlight(projection)
            rows.append(Highlight(
                label: "Target outlook",
                value: outlook.value,
                detail: outlook.detail
            ))
        }
        return rows
    }

    private var highlightDivider: some View {
        Divider().padding(.leading, 16)
    }

    /// Name on the left, figure on the right, nothing in the gutter. The tinted
    /// capsule that used to run down the leading edge of each row read as a
    /// decorative rail rather than as structure, and the three colours it
    /// carried meant nothing the label didn't already say.
    private func highlightRow(
        label: String,
        value: String,
        detail: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .textCase(.uppercase)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Text(value)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Destinations

    /// The three series that keep moving between Apple Health estimates. Their
    /// screens follow the shared range, so the header states which one, and each
    /// row prints the current figure rather than describing what is behind it —
    /// a subscriber should not have to tap three times to read three numbers.
    private var signalsSection: some View {
        PlusSection(
            title: "Your signals",
            caption: ranges.resolved.spanLabel
        ) {
            ForEach(Array(CardioSignal.all.enumerated()), id: \.element.id) { index, signal in
                signalRow(signal, isLast: index == CardioSignal.all.count - 1)
            }
        }
    }

    private func signalRow(_ signal: CardioSignal, isLast: Bool) -> some View {
        let reading = SignalReading.make(signal: signal, range: ranges.resolved, context: context)
        return PlusLinkRow(
            icon: signal.symbol,
            title: signal.title,
            detail: reading?.compactDetail ?? emptySignalDetail(signal),
            value: reading.map { reading in
                PlusRowValue(
                    text: reading.value.formatted(.number.precision(.fractionLength(0))),
                    unit: signal.shortUnit,
                    change: reading.change,
                    lowerIsBetter: signal.lowerIsBetter
                )
            },
            isLast: isLast
        ) {
            switch signal {
            case .heart(let metric): HeartMetricDetailView(metric: metric)
            case .load: CardioLoadDetailView()
            }
        }
    }

    /// Shown when the selected range holds nothing for a signal: the row keeps
    /// saying what the screen behind it is for rather than printing a zero.
    private func emptySignalDetail(_ signal: CardioSignal) -> String {
        switch signal {
        case .heart(.restingHeartRate): "Latest, average, low, high, and the change vs. the window before"
        case .heart(.heartRateRecovery): "The one-minute drop after each recorded workout"
        case .load: "Minutes and sessions per week, and where they went"
        }
    }

    private var estimateSection: some View {
        PlusSection(title: "Your estimate") {
            PlusLinkRow(
                icon: "clock.badge.exclamationmark",
                title: "Estimate Freshness",
                detail: freshnessRowDetail,
                value: freshnessRowValue
            ) { EstimateFreshnessDetailView() }
            PlusLinkRow(
                icon: "chart.bar.xaxis",
                title: "Deep Trends",
                detail: deepTrendsRowDetail,
                value: deepTrendsRowValue
            ) { HistoryView() }
            PlusLinkRow(
                icon: "scope",
                title: "Target Outlook",
                detail: targetOutlookRowDetail,
                value: targetOutlookRowValue,
                isLast: true
            ) { TrendDetailView() }
        }
    }

    // MARK: - Estimate row figures

    private var freshness: EstimateFreshness {
        CardioFreshnessAnalysis.assess(points: points)
    }

    private var freshnessRowValue: PlusRowValue? {
        guard let days = freshness.daysSinceLatest else { return nil }
        guard days > 0 else { return PlusRowValue(text: "Today") }
        return PlusRowValue(text: "\(days)", unit: days == 1 ? "day ago" : "days ago")
    }

    private var freshnessRowDetail: String {
        let freshness = self.freshness
        guard freshness.state != .noReadings else {
            return "Whether your estimate is due, and what refreshes it"
        }
        guard let gap = freshness.typicalGapDays else { return freshness.headline }
        return "\(freshness.headline) · you usually get one every \(gap) days"
    }

    private var deepTrendsComparison: PeriodComparison? {
        CardioFitnessAnalysis.periodComparison(points: points, days: 90)
    }

    private var deepTrendsRowValue: PlusRowValue? {
        guard let comparison = deepTrendsComparison else { return nil }
        return PlusRowValue(
            text: comparison.currentAverage.formatted(.number.precision(.fractionLength(1))),
            unit: "90-day avg",
            change: comparison.change
        )
    }

    private var deepTrendsRowDetail: String {
        guard let comparison = deepTrendsComparison else {
            return "Compare 30, 90, and 180-day windows in context"
        }
        let unit = comparison.currentCount == 1 ? "reading" : "readings"
        return "\(comparison.currentCount) \(unit) in the last 90 days"
    }

    private var targetOutlookRowValue: PlusRowValue? {
        guard let latest = points.max(by: { $0.date < $1.date }) else { return nil }
        guard latest.value < settings.targetLower else { return PlusRowValue(text: "In range") }
        let gap = settings.targetLower - latest.value
        return PlusRowValue(text: gap.formatted(.number.precision(.fractionLength(1))), unit: "to target")
    }

    private var targetOutlookRowDetail: String {
        guard let latest = points.max(by: { $0.date < $1.date }) else {
            return "Direction toward target, and a broad timeframe when supported"
        }
        // Deliberately not the highlight card's sentence: that one says the
        // estimate cleared the target, this one states what the target is.
        guard latest.value < settings.targetLower else {
            return "Your target range is \(targetLowerLabel)–\(targetUpperLabel)"
        }
        guard let projection = CardioFitnessAnalysis.projection(
            points: points,
            targetLower: settings.targetLower
        ) else {
            return "Your target starts at \(targetLowerLabel)"
        }
        if let months = projection.monthsToTarget {
            return "About \(months) \(months == 1 ? "month" : "months") away at your recent pace"
        }
        return projection.slopePerMonth > 0.05
            ? "Recent direction is positive, no timeframe yet"
            : "Recent direction is flat or declining"
    }

    private var contextSection: some View {
        PlusSection(title: "Context and recaps") {
            PlusLinkRow(
                icon: "person.crop.circle",
                title: "Fitness Context",
                detail: "Fitness age methodology and broad age references"
            ) { FitnessAgeDetailView() }
            PlusActionRow(
                icon: "calendar.badge.checkmark",
                title: "Monthly Recap",
                detail: "Your 30-day trend, target progress, and best reading",
                isLast: true
            ) { showRecap = true }
        }
    }

    private var accountNote: some View {
        Text("VO2+ is active on this Apple ID. Restore Purchases remains available in Settings if access ever looks incorrect.")
            .font(.caption)
            .foregroundStyle(Theme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
    }

    /// Short enough to sit in the figures column, with the sentence that used to
    /// be the value moved down to the detail line where it has room.
    private func projectionHighlight(_ projection: TrendProjection) -> (value: String, detail: String) {
        let target = targetLowerLabel
        guard let latest = points.max(by: { $0.date < $1.date }) else {
            return ("Available", "From the recent cardio fitness trend")
        }
        if latest.value >= settings.targetLower {
            return ("In target range", "Latest estimate is at or above \(target)")
        }
        if let months = projection.monthsToTarget {
            return (
                "About \(months) \(months == 1 ? "month" : "months")",
                "To \(target) at your recent pace"
            )
        }
        return projection.slopePerMonth > 0.05
            ? ("Trending up", "No timeframe yet from the recent trend")
            : ("Flat or declining", "From the recent cardio fitness trend")
    }

    private var targetLowerLabel: String { targetLabel(settings.targetLower) }
    private var targetUpperLabel: String { targetLabel(settings.targetUpper) }

    /// Targets are usually set to whole numbers on the slider, so a trailing
    /// ".0" would be noise in a one-line row.
    private func targetLabel(_ target: Double) -> String {
        let digits = target == target.rounded() ? 0 : 1
        return target.formatted(.number.precision(.fractionLength(digits)))
    }
}

// MARK: - Sectioned rows

/// A titled group of rows drawn as one inset card with hairline separators. The
/// grouped-list idiom is what iOS uses everywhere for "these lines open a
/// screen", which is exactly what these do.
private struct PlusSection<Content: View>: View {
    let title: String
    var caption: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .textCase(.uppercase)
                Spacer(minLength: 8)
                if let caption {
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) { content }
                .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
    }
}

/// The current figure for a row, printed before the tap. Rows that have no
/// number to show (a range with no readings, or a link to a screen that isn't a
/// single series) simply pass nil and keep their descriptive subtitle.
private struct PlusRowValue {
    let text: String
    var unit: String?
    var change: Double?
    /// Which direction of `change` reads as progress. Resting heart rate falls
    /// when fitness improves; everything else here rises.
    var lowerIsBetter = false
}

/// One tappable line. Chevron is full-strength rather than tertiary, the whole
/// row highlights on touch, and the title names the screen instead of leading
/// with "Open" on all eight rows.
private struct PlusRowLabel: View {
    let icon: String
    let title: String
    let detail: String
    var value: PlusRowValue?
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.cardio)
                    .frame(width: 32, height: 32)
                    .background(Theme.cardio.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                if let value { figures(value) }
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.cardio)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            if !isLast {
                Divider().padding(.leading, 58)
            }
        }
        .contentShape(Rectangle())
    }

    private func figures(_ value: PlusRowValue) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(value.text)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
                .contentTransition(.numericText())
            if let unit = value.unit {
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
            if let change = value.change {
                ChangeBadge(change: change, lowerIsBetter: value.lowerIsBetter)
                    .padding(.top, 1)
            }
        }
        .multilineTextAlignment(.trailing)
        .layoutPriority(1)
    }
}

private struct PlusLinkRow<Destination: View>: View {
    let icon: String
    let title: String
    let detail: String
    var value: PlusRowValue?
    var isLast = false
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink { destination() } label: {
            PlusRowLabel(icon: icon, title: title, detail: detail, value: value, isLast: isLast)
        }
        .buttonStyle(PlusRowButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens \(title)")
    }
}

private struct PlusActionRow: View {
    let icon: String
    let title: String
    let detail: String
    var isLast = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PlusRowLabel(icon: icon, title: title, detail: detail, isLast: isLast)
        }
        .buttonStyle(PlusRowButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens \(title)")
    }
}

/// Touch feedback the old plain-styled rows had none of: without it a tap on a
/// card that only navigates a moment later reads as a dead press.
private struct PlusRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Theme.cardio.opacity(0.10) : .clear)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
