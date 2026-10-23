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
        ConversionDiagnostics.recordAppOpen()
        #if DEBUG
        if RevenueCatProbe.isEnabled {
            // Same entry point the real paywall screens call, so what this
            // proves is the actual path and not a parallel one.
            StoreService.shared.trackPaywallImpression(id: RevenueCatProbe.impressionID)
            if RevenueCatProbe.wantsPurchase {
                Task { await StoreService.shared.runProbePurchase() }
            }
        }
        #endif
        // Here rather than in the scene's `.task` below, because a scene is not
        // connected when HealthKit background delivery relaunches the app. See
        // `HealthKitService.enableBackgroundDelivery`.
        HealthKitService.shared.enableBackgroundDelivery()
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

/// Collects every sheet open below the tab root (the dashboard's Settings,
/// and the paywall or range sheets on Today's cards and pushed detail
/// screens), so the rating ask never lands on top of one.
@MainActor
final class ReviewPromptCoordinator: ObservableObject {
    static let shared = ReviewPromptCoordinator()

    @Published private(set) var openSheets: Set<UUID> = []

    /// No reported sheet is up.
    var noSheetIsPresented: Bool { openSheets.isEmpty }

    func setSheet(_ id: UUID, isPresented: Bool) {
        if isPresented {
            openSheets.insert(id)
        } else {
            openSheets.remove(id)
        }
    }

    private init() {}
}

extension View {
    /// Reports a sheet to `ReviewPromptCoordinator`, so the rating ask waits
    /// until it closes. Pass the same flag that drives `.sheet(isPresented:)`.
    func blocksReviewPrompt(_ isPresented: Bool) -> some View {
        modifier(ReviewPromptBlockingSheet(isPresented: isPresented))
    }
}

private struct ReviewPromptBlockingSheet: ViewModifier {
    let isPresented: Bool
    @State private var id = UUID()

    func body(content: Content) -> some View {
        content
            .onAppear { ReviewPromptCoordinator.shared.setSheet(id, isPresented: isPresented) }
            .onChange(of: isPresented) { _, shown in
                ReviewPromptCoordinator.shared.setSheet(id, isPresented: shown)
            }
            .onDisappear { ReviewPromptCoordinator.shared.setSheet(id, isPresented: false) }
    }
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

    // Completion handler form, answered on the main thread. The async form's
    // compiler-made thunk calls UIKit's handler from a background thread, and
    // UIKit asserts the main thread there, so a tap could abort the app (the
    // crash Baby build 66 and Recharge build 39 shipped).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let route = response.notification.request.content.userInfo[NotificationService.routeKey] as? String
        nonisolated(unsafe) let done = completionHandler
        Task { @MainActor in
            switch route {
            case NotificationService.recapRouteValue:
                NotificationRouteCoordinator.shared.requestRecap()
            case NotificationService.readingRouteValue:
                NotificationRouteCoordinator.shared.requestToday()
            default:
                break
            }
            done()
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selection = 0
    /// The container's width and fold, measured so the unfolded iPhone Duo can
    /// put Today and Trends on opposite sides of the fold.
    @State private var paneGeometry = PaneGeometry(width: 0, fold: nil)
    /// Settings, from Today's gear or What's New: a sheet, or the trailing pane
    /// while split.
    @State private var showSettings = false
    /// The floating tab bar's measured height, which sizes the leading pane's
    /// tab bar band while split.
    @State private var tabBarHeight: CGFloat = 55
    /// The top of the leading pane's tab bar band in global space, where its
    /// scroll content comes to rest while split.
    @State private var tabBarBandTop: CGFloat?
    @Environment(\.displayScale) private var displayScale
    #if DEBUG
    @State private var tourTodayPush: DuoScreenshotTour.Screen?
    @State private var tourTrendsPush: DuoScreenshotTour.Screen?
    #endif

    // What's New
    @State private var showWhatsNew = false
    @State private var whatsNewEvaluated = false
    @State private var showPaywallFromWhatsNew = false
    @State private var pendingSettingsAfterWhatsNew = false
    @State private var pendingPaywallAfterWhatsNew = false

    // Monthly recap
    @State private var showRecap = false

    // Rating ask
    @State private var reviewPromptShownThisSession = false

    /// Unfolded, Trends has its own pane beside Today, so it is never a tab.
    private var split: UnfoldedSplit? {
        UnfoldedSplit.make(
            width: paneGeometry.width,
            isRegularWidth: horizontalSizeClass == .regular,
            fold: paneGeometry.fold
        )
    }

    /// Each unfolded pane is phone-width, so its screen lays out as on a phone.
    private var paneSizeClass: UserInterfaceSizeClass? {
        split == nil ? horizontalSizeClass : .compact
    }

    private var showsTrends: Bool {
        split == nil ? selection == 1 : !showSettings
    }

    /// Folded, Settings is a sheet. Unfolding with it up moves it to the pane,
    /// so the sheet's own dismissal must not close it.
    private var settingsSheet: Binding<Bool> {
        Binding(
            get: { showSettings && split == nil },
            set: { if !$0, split == nil { showSettings = false } }
        )
    }

    var body: some View {
        // One view tree in every pose: opening or closing the Duo only moves
        // these frames, so no tab is rebuilt and each keeps its scroll position
        // and pushed screens.
        ZStack(alignment: .bottomLeading) {
            // Behind the fold and the inner display's vertical status bar,
            // which the panes leave uncovered.
            Theme.background.ignoresSafeArea()

            tabContent(tab: 0, isVisible: selection == 0, paneWidth: split?.primaryWidth) {
                todayRoot
            }
            tabContent(tab: 2, isVisible: selection == 2, paneWidth: split?.primaryWidth) {
                PlusTabView()
            }
            tabContent(tab: 1, isVisible: showsTrends, paneWidth: split?.secondaryWidth, paneX: split?.secondaryX ?? 0) {
                trendsRoot
            }

            ZStack(alignment: .leading) {
                if let split, showSettings {
                    NavigationStack { SettingsView(onDone: { showSettings = false }) }
                        .environment(\.horizontalSizeClass, .compact)
                        .horizontalToolbarInPane(true)
                        .frame(maxWidth: split.secondaryWidth, maxHeight: .infinity)
                        .padding(.leading, split.secondaryX)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showSettings)

            HStack(spacing: 0) {
                TabButton(icon: "heart.fill", label: "Today", isSelected: selection == 0) { selection = 0 }
                if split == nil {
                    TabButton(icon: "chart.bar.fill", label: "Trends", isSelected: selection == 1) { selection = 1 }
                }
                TabButton(icon: "sparkles", label: "VO2+", isSelected: selection == 2) { selection = 2 }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial.opacity(0.8), in: Capsule())
            .overlay(Capsule().stroke(Color(.separator).opacity(0.3), lineWidth: 0.5))
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { tabBarHeight = $0 }
            .padding(.bottom, UnfoldedSplit.tabBarBottomPadding)
            // Within the leading pane while split, never across the fold.
            .frame(maxWidth: split?.primaryWidth ?? .infinity)
        }
        .onGeometryChange(for: PaneGeometry.self) { proxy in
            PaneGeometry(width: proxy.size.width, fold: proxy.verticalFold())
        } action: { paneGeometry = $0 }
        #if DEBUG
        .onChange(of: paneGeometry) { _, geometry in
            guard DuoScreenshotTour.isEnabled else { return }
            NSLog("DUOGEOM width=%.1f fold=%@ split=%@", geometry.width,
                  String(describing: geometry.fold), String(describing: split))
        }
        #endif
        .onChange(of: split != nil) { _, isSplit in
            if isSplit, selection == 1 { selection = 0 }
        }
        .onChange(of: selection) { _, tab in
            // Notification routes and the screenshot hook still ask for Trends.
            if tab == 1, split != nil { selection = 0 }
        }
        .ignoresSafeArea(edges: .bottom)
        .tint(Theme.cardio)
        .onAppear {
            selection = initialTab
            evaluateWhatsNew()
        }
        #if DEBUG
        .task(id: split != nil) { await runDuoTour(split: split != nil) }
        #endif
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
        .onReceive(NotificationCenter.default.publisher(for: .vo2PositiveMomentForReview)) { _ in
            scheduleReviewPromptAfterPositiveMoment()
        }
        .sheet(isPresented: $showWhatsNew, onDismiss: {
            if pendingSettingsAfterWhatsNew {
                pendingSettingsAfterWhatsNew = false
                showSettings = true
            } else if pendingPaywallAfterWhatsNew {
                pendingPaywallAfterWhatsNew = false
                showPaywallFromWhatsNew = true
            }
        }) {
            WhatsNewSheet(
                isPro: store.isPro,
                // Neutral for the same 3.1.2(c) reason as the purchase CTAs: this
                // routes into the paywall, so it should not pitch the trial ahead
                // of the price the paywall is about to state.
                tryFreeCTATitle: "Explore VO2+",
                onTryFree: { pendingPaywallAfterWhatsNew = true; showWhatsNew = false },
                onOpenSettings: { pendingSettingsAfterWhatsNew = true; showWhatsNew = false },
                onDismiss: { showWhatsNew = false }
            )
        }
        .sheet(isPresented: settingsSheet) {
            NavigationStack { SettingsView() }
                .environmentObject(settings)
                .environmentObject(store)
        }
        .blocksReviewPrompt(showSettings)
        .sheet(isPresented: $showPaywallFromWhatsNew) {
            PaywallView().environmentObject(store)
        }
        .sheet(isPresented: $showRecap) {
            MonthlyRecapView()
                .environmentObject(settings)
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
              !showRecap else { return }
        whatsNewEvaluated = true
        settings.lastWhatsNewVersionShown = WhatsNew.currentVersion
        showWhatsNew = true
    }

    /// The rating ask after a positive cardio moment: Apple's own prompt, no
    /// question in front of it. Waits for the dashboard to settle, then asks
    /// only if Today is still clear. A blocked ask keeps the moment pending in
    /// the tracker for the next one; it never retries off a sheet dismissal.
    private func scheduleReviewPromptAfterPositiveMoment() {
        guard ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: settings.hasCompletedSetup),
              !reviewPromptShownThisSession,
              isTodayClear
        else { return }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            guard isTodayClear,
                  !reviewPromptShownThisSession,
                  ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: settings.hasCompletedSetup)
            else { return }
            reviewPromptShownThisSession = true
            ReviewPromptTracker.markShown()
            requestReview()
        }
    }

    /// Today is on screen with nothing over it: no What's New, paywall, recap
    /// or Settings sheet, including sheets opened from Today's cards and the
    /// detail screens pushed from them.
    private var isTodayClear: Bool {
        selection == 0
            && !showWhatsNew
            && !showSettings
            && !showPaywallFromWhatsNew
            && !pendingSettingsAfterWhatsNew
            && !pendingPaywallAfterWhatsNew
            && !showRecap
            && reviewPromptCoordinator.noSheetIsPresented
    }

    /// All three tabs stay alive in the `ZStack` so each keeps its own scroll
    /// position. The hidden two are also kept out of the accessibility tree —
    /// note the `accessibilityHidden` applied to the tab's root *inside* the
    /// `NavigationStack` as well as to the stack itself: the outer one alone does
    /// not reach the stack's hosted content, so VoiceOver used to walk all three
    /// tabs' worth of elements before reaching the one on screen.
    ///
    /// `paneWidth` and `paneX` place the pane while split; `nil` is the full
    /// width. The frame sits after the inset, which fills its proposal
    /// and would otherwise centre a narrower pane across the fold. Only the
    /// leading pane holds the tab bar, so only it reserves room for it.
    private func tabContent<Content: View>(
        tab: Int,
        isVisible: Bool,
        paneWidth: CGFloat?,
        paneX: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationStack {
            content()
                .environment(\.isActiveTab, isVisible)
                .environment(\.isUnfoldedPane, split != nil)
                .accessibilityHidden(!isVisible)
        }
        .environment(\.horizontalSizeClass, paneSizeClass)
        .environment(\.isUnfoldedPane, split != nil)
        .environment(\.paneRestEdge, split != nil && tab != 1 ? tabBarBandTop : nil)
        .horizontalToolbarInPane(split != nil)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            tabBarBand
                .frame(height: tabBarBandHeight(tab: tab))
                .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { top in
                    if tab == 0 { tabBarBandTop = top }
                }
        }
        .frame(maxWidth: paneWidth ?? .infinity, maxHeight: .infinity)
        .padding(.leading, paneX)
        .tabVisibility(isVisible)
    }

    /// Folded, every tab keeps 92 pt under its content, as before. Split, the
    /// leading pane keeps the bar's own height plus its margins, and Trends,
    /// which has no bar, keeps none.
    private func tabBarBandHeight(tab: Int) -> CGFloat {
        guard split != nil else { return 92 }
        return tab == 1 ? 0 : UnfoldedSplit.tabBarBandHeight(barHeight: tabBarHeight)
    }

    /// The room kept under a pane for the floating tab bar. Folded it stays
    /// clear, as on every iPhone. Split, it is an opaque band with a hairline
    /// top edge, so the leading pane's content stops cleanly above the bar
    /// instead of fading out under it beside an uncovered Trends pane.
    private var tabBarBand: some View {
        Theme.background
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 1 / displayScale)
            }
            .opacity(split == nil ? 0 : 1)
            .allowsHitTesting(false)
    }

    private var todayRoot: some View {
        DashboardView(showSettings: $showSettings)
        #if DEBUG
            .navigationDestination(item: $tourTodayPush) { $0.view }
        #endif
    }

    private var trendsRoot: some View {
        HistoryView()
        #if DEBUG
            .navigationDestination(item: $tourTrendsPush) { $0.view }
        #endif
    }

    #if DEBUG
    /// See `DuoScreenshotTour`. Each route starts from a clean tab: sheets
    /// close and earlier pushes pop first.
    private func runDuoTour(split isSplit: Bool) async {
        guard DuoScreenshotTour.isEnabled else { return }
        if let screen = DuoScreenshotTour.screen {
            // One surface per launch, opened again when the panes split or join.
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            NSLog("DUOSCREEN %@ route=%@", isSplit ? "inner" : "outer", screen)
            openDuoRoute(screen)
            return
        }
        try? await Task.sleep(for: .seconds(DuoScreenshotTour.firstDelay))
        // Loops until the panes split or join, so a slow capture still lands
        // on every route.
        while !Task.isCancelled {
            for route in DuoScreenshotTour.routes(split: isSplit) {
                guard !Task.isCancelled else { return }
                NSLog("DUOTOUR %@ route=%@", isSplit ? "inner" : "outer", route)
                showSettings = false
                tourTodayPush = nil
                tourTrendsPush = nil
                try? await Task.sleep(for: .milliseconds(700))
                openDuoRoute(route)
                try? await Task.sleep(for: .seconds(DuoScreenshotTour.step))
            }
        }
    }

    private func openDuoRoute(_ route: String) {
        switch route {
        case "today": selection = 0
        case "trends": selection = 1
        case "plus": selection = 2
        case "settings":
            selection = 0
            showSettings = true
        case _ where route.hasPrefix("trends/"):
            if split == nil { selection = 1 }
            tourTrendsPush = DuoScreenshotTour.Screen(rawValue: String(route.dropFirst(7)))
        default:
            selection = 0
            tourTodayPush = DuoScreenshotTour.Screen(rawValue: route)
        }
    }
    #endif
}

private struct PaneGeometry: Equatable, Sendable {
    var width: CGFloat
    var fold: ClosedRange<CGFloat>?
}

/// Whether the tab this view sits in is the one on screen. All three tabs are
/// built and kept alive at launch, so anything with a side effect on appearance —
/// the VO2+ tab's embedded paywall logs an impression — has to ask, or it fires
/// for tabs the user never opened.
private struct IsActiveTabKey: EnvironmentKey {
    /// Views outside the tab stack (sheets, previews) are always "on screen".
    static let defaultValue = true
}

/// Whether this screen fills one pane of the unfolded iPhone Duo split.
private struct IsUnfoldedPaneKey: EnvironmentKey {
    static let defaultValue = false
}

/// Where the leading pane's scroll content comes to rest (the tab bar band's
/// top, in global space) while split; `nil` elsewhere.
private struct PaneRestEdgeKey: EnvironmentKey {
    static let defaultValue: CGFloat? = nil
}

extension EnvironmentValues {
    var isActiveTab: Bool {
        get { self[IsActiveTabKey.self] }
        set { self[IsActiveTabKey.self] = newValue }
    }

    var isUnfoldedPane: Bool {
        get { self[IsUnfoldedPaneKey.self] }
        set { self[IsUnfoldedPaneKey.self] = newValue }
    }

    var paneRestEdge: CGFloat? {
        get { self[PaneRestEdgeKey.self] }
        set { self[PaneRestEdgeKey.self] = newValue }
    }
}

private extension View {
    /// iOS 27.1 can move a stack's back button into a vertical bar on its
    /// trailing edge, which in a pane is beside the fold, with the title still
    /// leading. A pane keeps the phone's horizontal bar, back button leading.
    /// Folded, the system default is unchanged.
    @ViewBuilder
    func horizontalToolbarInPane(_ isPane: Bool) -> some View {
        if #available(iOS 27.1, *) {
            toolbarVerticalBehavior(isPane ? .disabled : .automatic)
        } else {
            self
        }
    }

    func tabVisibility(_ isVisible: Bool) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
            // Without a content shape the tap area shrinks to the icon and label:
            // an unselected tab reported a 30x34 target where it draws 72x44.
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        // Without this VoiceOver reads all three tabs identically and never says
        // which one you are on.
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
