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

    private let defaults: UserDefaults
    private var isNormalizing = false

    private init() {
        defaults = UserDefaults(suiteName: vo2MaxAppGroupID) ?? .standard
        hasCompletedSetup = defaults.bool(forKey: "hasCompletedSetup")
        targetLower = defaults.object(forKey: "targetLower") as? Double ?? 35
        targetUpper = defaults.object(forKey: "targetUpper") as? Double ?? 45
        chronologicalAge = defaults.object(forKey: "chronologicalAge") as? Int ?? 35
        referenceSex = ReferenceSex(rawValue: defaults.integer(forKey: "referenceSex")) ?? .unspecified
        appearance = AppAppearance(rawValue: defaults.integer(forKey: "appearance")) ?? .system
        showDeepTrends = defaults.object(forKey: "showDeepTrends") as? Bool ?? true
        showProjection = defaults.object(forKey: "showProjection") as? Bool ?? true
        showFitnessBand = defaults.object(forKey: "showFitnessBand") as? Bool ?? true
        showPersonalBest = defaults.object(forKey: "showPersonalBest") as? Bool ?? true
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

