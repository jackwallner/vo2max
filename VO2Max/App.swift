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

    var body: some View {
        if ProcessInfo.processInfo.arguments.contains("-PaywallSnapshot") {
            PaywallView()
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
}

private struct MainTabView: View {
    var body: some View {
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
        }
        .tint(Theme.cardio)
    }
}
