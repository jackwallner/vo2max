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
                    if RootView.shouldSeedScreenshotData {
                        Self.seedScreenshotDataIfNeeded()
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
    @State private var selection = 0

    var body: some View {
        // Floating glass capsule tab bar (the Total Calories pattern): content
        // lives in a ZStack and scrolls edge-to-edge under a custom
        // ultraThinMaterial capsule, instead of the opaque native tab bar.
        // Tabs stay alive and toggle via opacity so switching is instant.
        ZStack(alignment: .bottom) {
            tabContent(NavigationStack { DashboardView() }, tab: 0)
            tabContent(NavigationStack { HistoryView() }, tab: 1, reservesTabBarSpace: true)
            tabContent(NavigationStack { PlusTabView() }, tab: 2, reservesTabBarSpace: true)

            HStack(spacing: 0) {
                TabButton(icon: "heart.text.square", label: "Today", isSelected: selection == 0) { selection = 0 }
                TabButton(icon: "chart.xyaxis.line", label: "Trends", isSelected: selection == 1) { selection = 1 }
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
        .onAppear { selection = initialTab }
    }

    @ViewBuilder
    private func tabContent(
        _ content: some View,
        tab: Int,
        reservesTabBarSpace: Bool = false
    ) -> some View {
        if reservesTabBarSpace {
            content
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear.frame(height: 68)
                }
                .tabVisibility(selection == tab)
        } else {
            content
                .tabVisibility(selection == tab)
        }
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
