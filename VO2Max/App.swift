import SwiftData
import SwiftUI

@main
struct VO2MaxApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var settings = GoalSettings.shared
    @StateObject private var store = StoreService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(store)
                .preferredColorScheme(settings.appearance.colorScheme)
                .task {
                    store.start()
                    await HealthKitService.shared.synchronizeAuthorization()
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    Task { await HealthKitService.shared.refreshCache() }
                }
        }
        .modelContainer(DataService.sharedModelContainer)
    }
}

private struct RootView: View {
    @EnvironmentObject private var settings: GoalSettings
    @EnvironmentObject private var store: StoreService
    @State private var showOnboarding = false
    @State private var showTrialOffer = false

    var body: some View {
        if ProcessInfo.processInfo.arguments.contains("-PaywallSnapshot") {
            PaywallView()
        } else {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Today", systemImage: "heart.text.square") }

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }

            NavigationStack {
                PlusTabView()
            }
            .tabItem { Label("VO2+", systemImage: "sparkles") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Theme.cardio)
        .onAppear { showOnboarding = !settings.hasCompletedSetup }
        .sheet(isPresented: $showOnboarding, onDismiss: maybeShowTrialOffer) {
            OnboardingView(isPresented: $showOnboarding)
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showTrialOffer) { TrialOfferView() }
        .onChange(of: store.introEligibilityResolved) { _, _ in maybeShowTrialOffer() }
        }
    }

    /// Shows the focused first-run trial sheet once, after onboarding, only when
    /// the yearly plan is genuinely trial-eligible and the 14-day cooldown has
    /// elapsed. RC eligibility resolves asynchronously, so this is retried when
    /// `introEligibilityResolved` flips as well as on onboarding dismiss.
    private func maybeShowTrialOffer() {
        guard settings.hasCompletedSetup, !showOnboarding, !showTrialOffer else { return }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-DemoTrial") {
            showTrialOffer = true
            return
        }
        #endif
        guard !store.isPro, store.canPitchFreeTrial else { return }
        guard settings.passiveTrialOfferAllowed() else { return }
        settings.lastTrialOfferShownDate = .now
        showTrialOffer = true
    }
}
