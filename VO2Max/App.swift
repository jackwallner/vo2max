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
                    #if DEBUG
                    if RootView.screenshotTab != nil, settings.referenceSex == .unspecified {
                        // Seed a reference profile so screenshot captures show the
                        // real Fitness Age card and VO2+ fitness band, not the
                        // "set a profile" prompt. DEBUG + flag only.
                        settings.chronologicalAge = 42
                        settings.referenceSex = .male
                    }
                    #endif
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
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Today", systemImage: "heart.text.square") }
            .tag(0)

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }
            .tag(1)

            NavigationStack {
                PlusTabView()
            }
            .tabItem { Label("VO2+", systemImage: "sparkles") }
            .tag(2)
        }
        .tint(Theme.cardio)
        .onAppear { selection = initialTab }
    }
}
