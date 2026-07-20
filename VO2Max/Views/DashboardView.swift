import SwiftData
import SwiftUI

/// Today dashboard. Direct port of the Vitals / Total Calories dashboard
/// structure: full-bleed hero metric (ring + big rounded number, not boxed in
/// a card), date header with a gear button and an "Updated…" line, and
/// card-style secondary rows — with VO2 max data swapped in.
struct DashboardView: View {
    @EnvironmentObject private var settings: GoalSettings
    @EnvironmentObject private var store: StoreService
    @Query(sort: \CardioFitnessSample.date, order: .reverse) private var samples: [CardioFitnessSample]
    @StateObject private var health = HealthKitService.shared
    @State private var showSettings = false
    @State private var animateRing = false
    @State private var animateContent = false
    /// Measured top safe-area inset, used to size the mask that keeps scrolled
    /// content from colliding with the status bar (nav bar is hidden here).
    @State private var topSafeAreaInset: CGFloat = 0

    private var points: [CardioFitnessPoint] {
        samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
    }

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()
                .overlay {
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear { topSafeAreaInset = proxy.safeAreaInsets.top }
                            .onChange(of: proxy.safeAreaInsets.top) { _, v in topSafeAreaInset = v }
                    }
                }

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    mainContent(availableHeight: geo.size.height)
                        .frame(minHeight: geo.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
                .refreshable { await health.refreshCache() }
            }
        }
        // The dashboard hides the navigation bar for its custom date header, so
        // repaint the status-bar strip with the page background above the
        // scroll content (same fix as Vitals).
        .overlay(alignment: .top) { statusBarMask }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView() }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { animateContent = true }
            withAnimation(.spring(duration: 1.0, bounce: 0.15).delay(0.3)) { animateRing = true }
        }
    }

    private var statusBarMask: some View {
        Theme.background
            .frame(height: topSafeAreaInset)
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
    }

    private func mainContent(availableHeight: CGFloat) -> some View {
        let numberSize: CGFloat = min(availableHeight * 0.085, 72)
        let ringSize: CGFloat = min(availableHeight * 0.32, 260)
        let ringLineWidth: CGFloat = min(availableHeight * 0.022, 18)

        return VStack(spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 10)

            if let latest = samples.first {
                Spacer(minLength: 16)

                heroRing(
                    latest,
                    numberSize: numberSize,
                    ringSize: ringSize,
                    ringLineWidth: ringLineWidth
                )

                // Keep the ring, its target caption, and the cards together as one
                // group so the caption never strands in a large void; the flexible
                // Spacers above and below center the whole cluster.
                Color.clear.frame(height: 24)

                trendCard
                    .padding(.horizontal, 24)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)

                Color.clear.frame(height: 12)

                fitnessAgeCard(value: latest.value)
                    .padding(.horizontal, 24)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
            } else {
                Spacer(minLength: 16)
                noReadingCard
                    .padding(.horizontal, 24)
                    .opacity(animateContent ? 1 : 0)
            }

            Spacer(minLength: 16)
        }
    }

    // MARK: - Header (Vitals date + gear pattern)

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(10)
                        .background(Theme.cardSurface, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }
            HStack(spacing: 8) {
                if health.isRefreshing {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(Theme.cardio)
                    Text("Refreshing…")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                } else if let latest = samples.first {
                    Text("Latest estimate \(latest.date, format: .relative(presentation: .named))")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                } else {
                    Text("Waiting for your first Apple Health estimate")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: health.isRefreshing)
        }
    }

    // MARK: - Hero ring (Vitals calorie-ring pattern, VO2 data)

    private func heroRing(
        _ latest: CardioFitnessSample,
        numberSize: CGFloat,
        ringSize: CGFloat,
        ringLineWidth: CGFloat
    ) -> some View {
        let status = CardioFitnessAnalysis.targetStatus(
            value: latest.value,
            lower: settings.targetLower,
            upper: settings.targetUpper
        )
        let bandWidth = max(settings.targetUpper - settings.targetLower, 1)
        let floor = settings.targetLower - bandWidth
        let progress = min(max((latest.value - floor) / (settings.targetUpper - floor), 0.02), 1)

        return NavigationLink {
            ReadingHistoryDetailView()
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    ProgressRing(
                        progress: animateRing ? progress : 0,
                        gradient: Theme.cardioGradient,
                        glowColor: Theme.cardioGlow,
                        lineWidth: ringLineWidth,
                        size: ringSize
                    )
                    VStack(spacing: 2) {
                        Text(latest.value, format: .number.precision(.fractionLength(1)))
                            .font(Theme.bigNumber(numberSize))
                            .foregroundStyle(Theme.textPrimary)
                            .contentTransition(.numericText())
                        Text("mL/kg/min")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                        Text(status.label)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(statusColor(status))
                            .padding(.top, 2)
                    }
                }
                HStack(spacing: 3) {
                    Text("Target \(settings.targetLower, format: .number.precision(.fractionLength(0)))–\(settings.targetUpper, format: .number.precision(.fractionLength(0)))")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(animateContent ? 1 : 0)
        .scaleEffect(animateContent ? 1 : 0.9)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Latest Apple Health estimate")
        .accessibilityValue("\(latest.value.formatted(.number.precision(.fractionLength(1)))) milliliters per kilogram per minute, \(status.label)")
        .accessibilityHint("Opens all Apple Health estimates")
    }

    // MARK: - Cards (Vitals card idiom)

    private var trendCard: some View {
        let trend = CardioFitnessAnalysis.trend(points: points)
        let change = CardioFitnessAnalysis.change(points: points, days: 90)

        return NavigationLink {
            TrendDetailView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: trend.symbol)
                    .font(.title2.bold())
                    .foregroundStyle(color(for: trend))
                    .frame(width: 46, height: 46)
                    .background(color(for: trend).opacity(0.14), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text("Cardio fitness trend")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Text(trend.label)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    if let change {
                        Text("\(change, format: .number.precision(.fractionLength(1)).sign(strategy: .always())) over 90 days")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        Text("Four readings within 90 days build a trend")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.cardPadding)
            .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens cardio fitness trend details")
    }

    private func fitnessAgeCard(value: Double) -> some View {
        NavigationLink {
            FitnessAgeDetailView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(Theme.cardio)
                    .frame(width: 46)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Fitness age estimate")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                    if let estimate = CardioFitnessAnalysis.estimatedFitnessAge(
                        value: value,
                        referenceSex: settings.referenceSex
                    ) {
                        Text("About \(estimate)")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Chronological age \(settings.chronologicalAge)")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        Text("Add a reference profile")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Used to calculate this broad estimate")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.cardPadding)
            .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens fitness age estimate details")
    }

    private var noReadingCard: some View {
        VStack(spacing: 16) {
            Image(systemName: health.isAuthorized ? "applewatch.radiowaves.left.and.right" : "heart.text.square.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.cardio)

            VStack(spacing: 6) {
                Text(health.isAuthorized ? "Your first estimate will appear here" : "Connect Apple Health")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(health.isAuthorized
                     ? "Apple Watch creates cardio fitness estimates during qualifying outdoor walks, runs, and hikes. Wear it snugly and record a brisk outdoor workout for at least 20 minutes."
                     : "Allow VO2 max access when Apple Health asks. If you already dismissed that prompt, iOS won't show it again, so turn access on in Settings below.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                Task {
                    if health.isAuthorized {
                        await health.refreshCache()
                    } else if await health.canPresentAuthorizationSheet() {
                        try? await health.requestAuthorization()
                    } else {
                        // iOS only shows the Health permission sheet once per
                        // install; after that a re-request does nothing, so send
                        // the user where access can actually be toggled on.
                        openHealthSettings()
                    }
                }
            } label: {
                Label(
                    health.isAuthorized ? "Refresh Apple Health" : "Connect Apple Health",
                    systemImage: health.isAuthorized ? "arrow.clockwise" : "heart.fill"
                )
                .font(.system(.headline, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.cardio)

            Button("Turn on access in Settings") { openHealthSettings() }
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(Theme.cardioBlue)

            Button("Open Apple Health") {
                if let url = URL(string: "x-apple-health://") {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(.footnote, design: .rounded, weight: .semibold))
            .foregroundStyle(Theme.textSecondary)

            if let error = health.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Theme.negative)
                    .multilineTextAlignment(.center)
            }

            Text("Apple Health estimates are for fitness awareness. This app does not diagnose or treat health conditions.")
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    /// Opens this app's Settings page, which carries the Health row and the VO2
    /// max read toggle. This is the only place a previously-denied read-only app
    /// can be re-enabled, since iOS never re-presents the HealthKit sheet.
    private func openHealthSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
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
