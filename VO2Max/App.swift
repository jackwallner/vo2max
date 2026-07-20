import SwiftData
import SwiftUI
import UserNotifications

@main
struct VO2MaxApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var settings = GoalSettings.shared
    @StateObject private var store = StoreService.shared

    init() {
        // Route recap / new-reading notification taps, and count this launch for
        // the review funnel. `App.init()` is main-actor isolated, so the
        // @MainActor trackers are safe to touch here.
        UNUserNotificationCenter.current().delegate = VO2NotificationDelegate.shared
        ReviewPromptTracker.recordAppLaunch()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(store)
                .preferredColorScheme(settings.appearance.colorScheme)
                .task {
                    store.start()
                    #if DEBUG
                    if RootView.screenshotTab != nil, settings.referenceSex == .unspecified {
                        // Seed a reference profile so screenshot captures show the
                        // real Fitness Age card and VO2+ fitness band, not the
                        // "set a profile" prompt. DEBUG + flag only.
                        settings.chronologicalAge = 42
                        settings.referenceSex = .male
                    }
                    if RootView.shouldSeedScreenshotData {
                        Self.seedScreenshotDataIfNeeded()
                    }
                    #endif
                    await HealthKitService.shared.synchronizeAuthorization()
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    Task {
                        // Always refresh on foreground: "no data" and "denied" are
                        // indistinguishable for reads, so gating on isAuthorized
                        // meant a flaky launch-time probe blanked the screen.
                        // refreshCache self-guards the never-authorized case (it
                        // swallows errorAuthorizationNotDetermined) so this no
                        // longer paints a red error on a fresh install.
                        await HealthKitService.shared.refreshCache()
                    }
                }
        }
        .modelContainer(DataService.sharedModelContainer)
    }

    #if DEBUG
    @MainActor
    private static func seedScreenshotDataIfNeeded() {
        let context = DataService.sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<CardioFitnessSample>()
        guard (try? context.fetchCount(descriptor)) == 0 else { return }

        let calendar = Calendar.current
        let values: [(Int, Double)] = [
            (-150, 37.2), (-120, 37.8), (-95, 38.1), (-70, 38.8),
            (-48, 39.5), (-28, 40.2), (-14, 40.8), (-3, 41.4)
        ]
        for (days, value) in values {
            guard let date = calendar.date(byAdding: .day, value: days, to: .now) else { continue }
            context.insert(CardioFitnessSample(
                healthKitID: "screenshot-\(abs(days))",
                date: date,
                value: value,
                sourceName: "Apple Health"
            ))
        }
        try? context.save()
    }
    #endif
}

/// Routes a tapped notification to the right surface. The
/// `UNUserNotificationCenterDelegate` posts here; `MainTabView` observes.
@MainActor
final class NotificationRouteCoordinator: ObservableObject {
    static let shared = NotificationRouteCoordinator()

    /// Set when a monthly-recap notification is tapped.
    @Published var pendingRecap = false
    /// Set when a new-reading notification is tapped (open Today).
    @Published var pendingToday = false

    private init() {}

    func requestRecap() { pendingRecap = true }
    func requestToday() { pendingToday = true }
}

/// Handles notification taps (and foreground presentation) and forwards to
/// `NotificationRouteCoordinator`. Installed as the notification-center delegate
/// in `VO2MaxApp.init`.
final class VO2NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = VO2NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let route = response.notification.request.content.userInfo[NotificationService.routeKey] as? String
        switch route {
        case NotificationService.recapRouteValue:
            await MainActor.run { NotificationRouteCoordinator.shared.requestRecap() }
        case NotificationService.readingRouteValue:
            await MainActor.run { NotificationRouteCoordinator.shared.requestToday() }
        default:
            break
        }
    }
}

private struct RootView: View {
    @EnvironmentObject private var settings: GoalSettings
    @EnvironmentObject private var store: StoreService

    var body: some View {
        if ProcessInfo.processInfo.arguments.contains("-PaywallSnapshot") {
            PaywallView()
        } else if Self.screenshotTab != nil {
            // DEBUG-only capture hook: jump straight into the tab bar on a chosen
            // tab, bypassing onboarding, so App Store screenshots can be taken
            // without UI automation. Never triggers in Release.
            MainTabView(initialTab: Self.screenshotTab ?? 0)
        } else if !settings.hasCompletedSetup {
            // Onboarding is the root view, not a sheet, so pages simply exist
            // instead of swiping up from the bottom. The trial pitch is folded
            // in as the final onboarding step (zero-shift CTA), so there's no
            // separate pop-up after setup.
            OnboardingView()
        } else {
            MainTabView()
        }
    }

    #if DEBUG
    static var shouldSeedScreenshotData: Bool {
        ProcessInfo.processInfo.arguments.contains("-SeedScreenshotData")
    }
    #else
    static let shouldSeedScreenshotData = false
    #endif

    /// DEBUG-only: `-ScreenshotTab N` (0 Today, 1 Trends, 2 VO2+) opens that tab
    /// with onboarding skipped, for App Store screenshot capture. nil in Release.
    static var screenshotTab: Int? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-ScreenshotTab"), idx + 1 < args.count else { return nil }
        return Int(args[idx + 1])
        #else
        return nil
        #endif
    }
}

private struct MainTabView: View {
    var initialTab: Int = 0

    @EnvironmentObject private var settings: GoalSettings
    @EnvironmentObject private var store: StoreService
    @StateObject private var routeCoordinator = NotificationRouteCoordinator.shared
    @StateObject private var reviewPromptCoordinator = ReviewPromptCoordinator.shared
    @Environment(\.requestReview) private var requestReview

    @State private var selection = 0

    // What's New
    @State private var showWhatsNew = false
    @State private var whatsNewEvaluated = false
    @State private var showSettingsFromWhatsNew = false
    @State private var showPaywallFromWhatsNew = false
    @State private var pendingSettingsAfterWhatsNew = false
    @State private var pendingPaywallAfterWhatsNew = false

    // Monthly recap
    @State private var showRecap = false

    // Review funnel
    @State private var showReviewPrompt = false
    @State private var reviewPromptInitialStep: ReviewPromptSheet.Step = .enjoyment
    @State private var reviewPromptShownThisSession = false

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent(NavigationStack { DashboardView() }, tab: 0)
            tabContent(NavigationStack { HistoryView() }, tab: 1)
            tabContent(NavigationStack { PlusTabView() }, tab: 2)

            HStack(spacing: 0) {
                TabButton(icon: "heart.fill", label: "Today", isSelected: selection == 0) { selection = 0 }
                TabButton(icon: "chart.bar.fill", label: "Trends", isSelected: selection == 1) { selection = 1 }
                TabButton(icon: "sparkles", label: "VO2+", isSelected: selection == 2) { selection = 2 }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial.opacity(0.8), in: Capsule())
            .overlay(Capsule().stroke(Color(.separator).opacity(0.3), lineWidth: 0.5))
            .padding(.bottom, 12)
        }
        .ignoresSafeArea(edges: .bottom)
        .tint(Theme.cardio)
        .onAppear {
            selection = initialTab
            evaluateWhatsNew()
            evaluatePendingReviewPrompt()
        }
        .task(id: recapSchedulingKey) { await syncMonthlyRecapSchedule() }
        .onChange(of: routeCoordinator.pendingRecap) { _, pending in
            guard pending else { return }
            routeCoordinator.pendingRecap = false
            showRecap = true
        }
        .onChange(of: routeCoordinator.pendingToday) { _, pending in
            guard pending else { return }
            routeCoordinator.pendingToday = false
            selection = 0
        }
        .onChange(of: reviewPromptCoordinator.pendingPresentation) { _, presentation in
            guard let presentation else { return }
            defer { reviewPromptCoordinator.clear() }
            switch presentation {
            case .enjoymentPrompt: presentReviewPrompt(step: .enjoyment)
            case .feedbackOnly: presentReviewPrompt(step: .feedback)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .vo2PositiveMomentForReview)) { _ in
            evaluatePendingReviewPrompt()
        }
        .sheet(isPresented: $showWhatsNew, onDismiss: {
            if pendingSettingsAfterWhatsNew {
                pendingSettingsAfterWhatsNew = false
                showSettingsFromWhatsNew = true
            } else if pendingPaywallAfterWhatsNew {
                pendingPaywallAfterWhatsNew = false
                showPaywallFromWhatsNew = true
            }
        }) {
            WhatsNewSheet(
                isPro: store.isPro,
                tryFreeCTATitle: store.canPitchFreeTrial ? "Try VO2+ free" : "Explore VO2+",
                onTryFree: { pendingPaywallAfterWhatsNew = true; showWhatsNew = false },
                onOpenSettings: { pendingSettingsAfterWhatsNew = true; showWhatsNew = false },
                onDismiss: { showWhatsNew = false }
            )
        }
        .sheet(isPresented: $showSettingsFromWhatsNew) {
            NavigationStack { SettingsView() }
                .environmentObject(settings)
                .environmentObject(store)
        }
        .sheet(isPresented: $showPaywallFromWhatsNew) {
            PaywallView().environmentObject(store)
        }
        .sheet(isPresented: $showRecap) {
            MonthlyRecapView()
                .environmentObject(settings)
        }
        .sheet(isPresented: $showReviewPrompt, onDismiss: {
            if reviewPromptCoordinator.pendingPresentation == nil,
               ReviewPromptTracker.outcome == nil,
               ReviewPromptTracker.isSoftDeferred {
                // "Maybe later": Apple often no-ops requestReview(), so we keep a
                // short cooldown rather than the long jail markShown() would set.
                requestReview()
            }
        }) {
            ReviewPromptSheet(initialStep: reviewPromptInitialStep, onFinish: handleReviewPromptFinish)
        }
    }

    /// Recomputes the recap schedule whenever entitlement or the toggle changes.
    private var recapSchedulingKey: String { "\(store.isPro)-\(settings.monthlyRecapEnabled)" }

    private func syncMonthlyRecapSchedule() async {
        if store.isPro, settings.monthlyRecapEnabled {
            await NotificationService.scheduleMonthlyRecap()
        } else {
            NotificationService.cancelMonthlyRecap()
        }
    }

    private func evaluateWhatsNew() {
        guard !whatsNewEvaluated,
              settings.hasCompletedSetup,
              !ScreenshotConfig.isEnabled,
              WhatsNew.shouldShow(lastShown: settings.lastWhatsNewVersionShown),
              !showReviewPrompt, !showRecap else { return }
        whatsNewEvaluated = true
        settings.lastWhatsNewVersionShown = WhatsNew.currentVersion
        showWhatsNew = true
    }

    private func evaluatePendingReviewPrompt() {
        guard !reviewPromptShownThisSession,
              !showReviewPrompt, !showWhatsNew, !showRecap,
              ReviewPromptTracker.shouldShowAfterPositiveMoment(hasCompletedSetup: settings.hasCompletedSetup) else { return }
        ReviewPromptTracker.consumePendingPositiveMoment()
        presentReviewPrompt(step: .enjoyment)
    }

    private func presentReviewPrompt(step: ReviewPromptSheet.Step) {
        reviewPromptInitialStep = step
        reviewPromptShownThisSession = true
        showReviewPrompt = true
    }

    private func handleReviewPromptFinish(_ outcome: ReviewPromptDismissOutcome) {
        showReviewPrompt = false
    }

    private func tabContent(_ content: some View, tab: Int) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: 92)
            }
            .tabVisibility(selection == tab)
    }
}

private extension View {
    func tabVisibility(_ isVisible: Bool) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(isVisible ? 1 : 0)
            .allowsHitTesting(isVisible)
            .accessibilityHidden(!isVisible)
    }
}

private struct TabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSelected ? Theme.cardio : Color(.tertiaryLabel))
            .frame(width: 72, height: 44)
            .background(
                isSelected ? Theme.cardio.opacity(0.12) : .clear,
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
