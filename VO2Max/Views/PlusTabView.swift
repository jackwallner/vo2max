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
                        detail: highlight.detail,
                        tint: highlight.tint
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
        let tint: Color
    }

    private var highlights: [Highlight] {
        var rows: [Highlight] = []
        if let best = CardioFitnessAnalysis.personalBest(points: points) {
            rows.append(Highlight(
                label: "Personal best",
                value: best.value.formatted(.number.precision(.fractionLength(1))),
                detail: best.date.formatted(.dateTime.month(.abbreviated).day().year()),
                tint: Theme.coral
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
                detail: "Broad context for age \(settings.chronologicalAge)",
                tint: Theme.cardio
            ))
        }
        if let projection = CardioFitnessAnalysis.projection(
            points: points,
            targetLower: settings.targetLower
        ) {
            rows.append(Highlight(
                label: "Target outlook",
                value: projectionHeadline(projection),
                detail: "From the recent cardio fitness trend",
                tint: Theme.positive
            ))
        }
        return rows
    }

    private var highlightDivider: some View {
        Divider().padding(.leading, 16)
    }

    private func highlightRow(
        label: String,
        value: String,
        detail: String,
        tint: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Capsule()
                .fill(tint)
                .frame(width: 3)
                .frame(maxHeight: .infinity)
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .textCase(.uppercase)
                Text(value)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Destinations

    /// The three series that keep moving between Apple Health estimates. Their
    /// screens follow the shared range, so the header states which one.
    private var signalsSection: some View {
        PlusSection(
            title: "Your signals",
            caption: ranges.resolved.spanLabel
        ) {
            PlusLinkRow(
                icon: "bed.double",
                title: "Resting Heart Rate",
                detail: "Latest, average, low, high, and the change vs. the window before"
            ) { HeartMetricDetailView(metric: .restingHeartRate) }
            PlusLinkRow(
                icon: "arrow.down.heart",
                title: "Heart Rate Recovery",
                detail: "The one-minute drop after each recorded workout"
            ) { HeartMetricDetailView(metric: .heartRateRecovery) }
            PlusLinkRow(
                icon: "figure.run.circle",
                title: "Cardio Load",
                detail: "Minutes and sessions per week, and where they went",
                isLast: true
            ) { CardioLoadDetailView() }
        }
    }

    private var estimateSection: some View {
        PlusSection(title: "Your estimate") {
            PlusLinkRow(
                icon: "clock.badge.exclamationmark",
                title: "Estimate Freshness",
                detail: "Whether your estimate is due, and what refreshes it"
            ) { EstimateFreshnessDetailView() }
            PlusLinkRow(
                icon: "chart.bar.xaxis",
                title: "Deep Trends",
                detail: "Compare 30, 90, and 180-day windows in context"
            ) { HistoryView() }
            PlusLinkRow(
                icon: "scope",
                title: "Target Outlook",
                detail: "Direction toward target, and a broad timeframe when supported",
                isLast: true
            ) { TrendDetailView() }
        }
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

    private func projectionHeadline(_ projection: TrendProjection) -> String {
        guard let latest = points.max(by: { $0.date < $1.date }) else { return "Target outlook available" }
        if latest.value >= settings.targetLower {
            return "Latest estimate is in your target range"
        }
        if let months = projection.monthsToTarget {
            return "Roughly \(months) \(months == 1 ? "month" : "months") to target at recent pace"
        }
        return projection.slopePerMonth > 0.05
            ? "Recent direction is positive"
            : "Recent direction is flat or declining"
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

/// One tappable line. Chevron is full-strength rather than tertiary, the whole
/// row highlights on touch, and the title names the screen instead of leading
/// with "Open" on all eight rows.
private struct PlusRowLabel: View {
    let icon: String
    let title: String
    let detail: String
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
}

private struct PlusLinkRow<Destination: View>: View {
    let icon: String
    let title: String
    let detail: String
    var isLast = false
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink { destination() } label: {
            PlusRowLabel(icon: icon, title: title, detail: detail, isLast: isLast)
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
