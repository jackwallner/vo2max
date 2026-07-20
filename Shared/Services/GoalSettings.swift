import Combine
import SwiftUI
import WidgetKit

enum AppAppearance: Int, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

@MainActor
final class GoalSettings: ObservableObject {
    static let shared = GoalSettings()

    @Published var hasCompletedSetup: Bool { didSet { save() } }
    @Published var targetLower: Double { didSet { normalizeTargets(changedLower: true); save() } }
    @Published var targetUpper: Double { didSet { normalizeTargets(changedLower: false); save() } }
    @Published var chronologicalAge: Int { didSet { save() } }
    @Published var referenceSex: ReferenceSex { didSet { save() } }
    @Published var appearance: AppAppearance { didSet { save() } }

    // VO2+ feature toggles. Persisted regardless of entitlement; views gate on
    // `store.isPro && toggle` so a lapse hides features without erasing choices.
    @Published var showDeepTrends: Bool { didSet { defaults.set(showDeepTrends, forKey: "showDeepTrends"); save() } }
    @Published var showProjection: Bool { didSet { defaults.set(showProjection, forKey: "showProjection"); save() } }
    @Published var showFitnessBand: Bool { didSet { defaults.set(showFitnessBand, forKey: "showFitnessBand"); save() } }
    @Published var showPersonalBest: Bool { didSet { defaults.set(showPersonalBest, forKey: "showPersonalBest"); save() } }

    // VO2+ retention toggles. New-reading alerts and the monthly recap notification
    // both default off (opt-in); the reading-alert key is also read by
    // HealthKitService (from the app group) to decide whether to post.
    @Published var readingAlertsEnabled: Bool { didSet { defaults.set(readingAlertsEnabled, forKey: Self.readingAlertsKey); save() } }
    @Published var monthlyRecapEnabled: Bool { didSet { defaults.set(monthlyRecapEnabled, forKey: "monthlyRecapEnabled"); save() } }

    /// Content version of the last What's New announcement the user has seen.
    @Published var lastWhatsNewVersionShown: String? {
        didSet { defaults.set(lastWhatsNewVersionShown, forKey: "lastWhatsNewVersionShown") }
    }

    /// App-group key for the reading-alert opt-in, shared with HealthKitService.
    static let readingAlertsKey = "readingAlertsEnabled"

    private let defaults: UserDefaults
    private var isNormalizing = false

    private init() {
        defaults = UserDefaults(suiteName: vo2MaxAppGroupID) ?? .standard
        let completedSetup = defaults.bool(forKey: "hasCompletedSetup")
        hasCompletedSetup = completedSetup
        targetLower = defaults.object(forKey: "targetLower") as? Double ?? 35
        targetUpper = defaults.object(forKey: "targetUpper") as? Double ?? 45
        chronologicalAge = defaults.object(forKey: "chronologicalAge") as? Int ?? 35
        referenceSex = ReferenceSex(rawValue: defaults.integer(forKey: "referenceSex")) ?? .unspecified
        appearance = AppAppearance(rawValue: defaults.integer(forKey: "appearance")) ?? .system
        showDeepTrends = defaults.object(forKey: "showDeepTrends") as? Bool ?? true
        showProjection = defaults.object(forKey: "showProjection") as? Bool ?? true
        showFitnessBand = defaults.object(forKey: "showFitnessBand") as? Bool ?? true
        showPersonalBest = defaults.object(forKey: "showPersonalBest") as? Bool ?? true
        readingAlertsEnabled = defaults.object(forKey: Self.readingAlertsKey) as? Bool ?? false
        monthlyRecapEnabled = defaults.object(forKey: "monthlyRecapEnabled") as? Bool ?? false
        // Fresh installs are seeded past the What's New announcement so they get
        // onboarding, not a "what changed" pitch for an app they've never used.
        if let stored = defaults.string(forKey: "lastWhatsNewVersionShown") {
            lastWhatsNewVersionShown = stored
        } else if !completedSetup {
            lastWhatsNewVersionShown = WhatsNew.currentVersion
            defaults.set(WhatsNew.currentVersion, forKey: "lastWhatsNewVersionShown")
        } else {
            lastWhatsNewVersionShown = nil
        }
    }

    private func normalizeTargets(changedLower: Bool) {
        guard !isNormalizing else { return }
        isNormalizing = true
        targetLower = min(max(targetLower, 10), 89)
        targetUpper = min(max(targetUpper, 11), 90)
        if targetLower >= targetUpper {
            if changedLower {
                targetUpper = min(targetLower + 1, 90)
            } else {
                targetLower = max(targetUpper - 1, 10)
            }
        }
        isNormalizing = false
    }

    private func save() {
        guard !isNormalizing else { return }
        defaults.set(hasCompletedSetup, forKey: "hasCompletedSetup")
        defaults.set(targetLower, forKey: "targetLower")
        defaults.set(targetUpper, forKey: "targetUpper")
        defaults.set(chronologicalAge, forKey: "chronologicalAge")
        defaults.set(referenceSex.rawValue, forKey: "referenceSex")
        defaults.set(appearance.rawValue, forKey: "appearance")
        WidgetCenter.shared.reloadAllTimelines()
    }
}

