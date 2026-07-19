import SwiftData
import SwiftUI

/// VO2+ is both the purchase surface for free users and a concise subscriber
/// hub. Premium results also appear in Today, Trends, and their detail screens,
/// so this tab explains the toolkit and links back to those useful contexts.
struct PlusTabView: View {
    @EnvironmentObject private var settings: GoalSettings
    @EnvironmentObject private var store: StoreService
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]

    private var points: [CardioFitnessPoint] {
        samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
    }

    var body: some View {
        Group {
            if store.isPro {
                subscriberHub
            } else {
                PaywallView(embedded: true, impressionID: "vo2plus_tab")
                    .navigationTitle("VO2+")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private var subscriberHub: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                activeHeader
                currentHighlights
                destinationLinks
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
    }

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
                Text("Premium context is now integrated across the app.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

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
            }
            .padding(22)
            .frame(maxWidth: .infinity)
            .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Current highlights")
                    .font(.headline)
                if let best = CardioFitnessAnalysis.personalBest(points: points) {
                    highlightRow(
                        icon: "trophy.fill",
                        color: Theme.coral,
                        title: "Personal best \(best.value.formatted(.number.precision(.fractionLength(1))))",
                        detail: best.date.formatted(.dateTime.month(.abbreviated).day().year())
                    )
                }
                if let latest = points.max(by: { $0.date < $1.date }),
                   let band = CardioFitnessAnalysis.fitnessBand(
                       value: latest.value,
                       age: settings.chronologicalAge,
                       referenceSex: settings.referenceSex
                   ) {
                    highlightRow(
                        icon: "person.2.crop.square.stack",
                        color: Theme.cardio,
                        title: band,
                        detail: "Broad context for age \(settings.chronologicalAge)"
                    )
                }
                if let projection = CardioFitnessAnalysis.projection(
                    points: points,
                    targetLower: settings.targetLower
                ) {
                    highlightRow(
                        icon: "scope",
                        color: Theme.positive,
                        title: projectionHeadline(projection),
                        detail: "Based on the recent cardio fitness trend"
                    )
                }
            }
            .padding(16)
            .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
    }

    private var destinationLinks: some View {
        VStack(spacing: 10) {
            NavigationLink {
                HistoryView()
            } label: {
                destinationRow(
                    icon: "chart.bar.xaxis",
                    title: "Open Deep Trends",
                    detail: "Compare 30, 90, and 180-day windows in context"
                )
            }
            NavigationLink {
                TrendDetailView()
            } label: {
                destinationRow(
                    icon: "scope",
                    title: "Open Target Outlook",
                    detail: "See direction and a broad timeframe when supported"
                )
            }
            NavigationLink {
                FitnessAgeDetailView()
            } label: {
                destinationRow(
                    icon: "person.crop.circle",
                    title: "Open Fitness Context",
                    detail: "Review fitness age methodology and broad references"
                )
            }
        }
        .buttonStyle(.plain)
    }

    private var accountNote: some View {
        Text("VO2+ is active on this Apple ID. Restore Purchases remains available in Settings if access ever looks incorrect.")
            .font(.caption)
            .foregroundStyle(Theme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
    }

    private func highlightRow(
        icon: String,
        color: Color,
        title: String,
        detail: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
    }

    private func destinationRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.cardio)
                .frame(width: 40, height: 40)
                .background(Theme.cardio.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .contentShape(Rectangle())
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
