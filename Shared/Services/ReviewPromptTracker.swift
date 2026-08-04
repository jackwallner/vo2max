import Foundation

extension Notification.Name {
    /// Posted when the user hits a positive cardio moment (new personal best or
    /// entering their target range) — host may present the enjoyment funnel after a short delay.
    static let vo2PositiveMomentForReview = Notification.Name("com.jackwallner.vo2max.positiveMomentForReview")
}

/// How the user last resolved the in-app review / feedback prompt.
enum ReviewPromptOutcome: String, Sendable {
    /// Opened the App Store write-review page (explicit CTA).
    case openedWriteReview
    /// Opened the feedback mail composer with a message.
    case submittedFeedback
}

/// Pure eligibility rules for the passive enjoyment funnel, kept free of
/// `UserDefaults` so the thresholds can be unit-tested directly.
struct ReviewPromptEligibility: Sendable {
    /// Cumulative genuine cardio wins: new personal bests or entering target.
    var positiveMomentCount: Int
    /// Cold starts since install.
    var appLaunchCount: Int
    /// Whole days since the first app open.
    var daysSinceFirstOpen: Int
    /// True once Apple Health has returned at least one estimate.
    var hasSeenReading: Bool

    /// Why the funnel is allowed to open. `positiveMoment` is the stronger
    /// signal and takes precedence when both hold.
    enum Trigger: Equatable, Sendable {
        case positiveMoment
        case engagedUse
    }

    /// Minimum cold starts before the positive-moment path is considered.
    static let minimumLaunchCount = 3
    /// Minimum days since first open for the positive-moment path.
    static let minimumDaysSinceFirstOpen = 3
    /// A single genuine positive moment is meaningful signal on a metric this slow.
    static let minimumPositiveMoments = 1

    /// VO2 max moves too slowly for a personal best or a target crossing to be a
    /// reliable trigger — most users would never hit one, so the funnel would
    /// never open. Someone still opening the app in week two, with real data on
    /// screen, is telling us the same thing more quietly.
    static let engagedLaunchCount = 5
    /// Minimum days since first open for the engaged path.
    static let engagedDaysSinceFirstOpen = 7

    var trigger: Trigger? {
        if positiveMomentCount >= Self.minimumPositiveMoments,
           appLaunchCount >= Self.minimumLaunchCount,
           daysSinceFirstOpen >= Self.minimumDaysSinceFirstOpen {
            return .positiveMoment
        }
        // No point asking someone who has never seen an estimate whether they
        // are enjoying an app whose whole job is showing one.
        if hasSeenReading,
           appLaunchCount >= Self.engagedLaunchCount,
           daysSinceFirstOpen >= Self.engagedDaysSinceFirstOpen {
            return .engagedUse
        }
        return nil
    }
}

/// Persists launch counts, positive moments, and review-prompt eligibility in the app group.
@MainActor
enum ReviewPromptTracker {
    private static let defaults = UserDefaults(suiteName: vo2MaxAppGroupID) ?? .standard

    private static let launchCountKey = "reviewPrompt.appLaunchCount"
    private static let firstOpenKey = "reviewPrompt.firstAppOpenDate"
    private static let lastShownKey = "reviewPrompt.lastShownDate"
    private static let outcomeKey = "reviewPrompt.outcome"
    private static let positiveMomentCountKey = "reviewPrompt.positiveMomentCount"
    private static let pendingPositiveMomentKey = "reviewPrompt.pendingPositiveMoment"
    private static let softDeferKey = "reviewPrompt.softDefer"
    private static let hasSeenReadingKey = "reviewPrompt.hasSeenReading"

    /// Days before "Not now" can surface the enjoyment prompt again.
    static let cooldownDays = 120
    /// Shorter cooldown after "Maybe later" on the review pitch — Apple's
    /// `requestReview()` often shows nothing, so a 120-day jail was burning asks.
    static let softDeferCooldownDays = 30

    static var appLaunchCount: Int {
        get { max(defaults.integer(forKey: launchCountKey), 0) }
        set { defaults.set(newValue, forKey: launchCountKey) }
    }

    static var firstAppOpenDate: Date? {
        get { defaults.object(forKey: firstOpenKey) as? Date }
        set {
            if let date = newValue {
                defaults.set(date, forKey: firstOpenKey)
            } else {
                defaults.removeObject(forKey: firstOpenKey)
            }
        }
    }

    static var lastShownDate: Date? {
        get { defaults.object(forKey: lastShownKey) as? Date }
        set {
            if let date = newValue {
                defaults.set(date, forKey: lastShownKey)
            } else {
                defaults.removeObject(forKey: lastShownKey)
            }
        }
    }

    static var outcome: ReviewPromptOutcome? {
        get {
            guard let raw = defaults.string(forKey: outcomeKey) else { return nil }
            return ReviewPromptOutcome(rawValue: raw)
        }
        set {
            if let value = newValue {
                defaults.set(value.rawValue, forKey: outcomeKey)
            } else {
                defaults.removeObject(forKey: outcomeKey)
            }
        }
    }

    static var positiveMomentCount: Int {
        get { max(defaults.integer(forKey: positiveMomentCountKey), 0) }
        set { defaults.set(newValue, forKey: positiveMomentCountKey) }
    }

    /// Set when a positive moment fires; cleared when a passive prompt is shown or consumed.
    static var hasPendingPositiveMoment: Bool {
        get { defaults.bool(forKey: pendingPositiveMomentKey) }
        set { defaults.set(newValue, forKey: pendingPositiveMomentKey) }
    }

    /// True once Apple Health has handed us at least one estimate.
    static var hasSeenReading: Bool {
        get { defaults.bool(forKey: hasSeenReadingKey) }
        set { defaults.set(newValue, forKey: hasSeenReadingKey) }
    }

    /// Call once per process launch (e.g. from `VO2MaxApp.init`).
    static func recordAppLaunch(now: Date = .now) {
        if firstAppOpenDate == nil {
            firstAppOpenDate = now
        }
        appLaunchCount += 1
    }

    /// Call after a satisfaction moment (new personal best, entering target range).
    static func recordPositiveMoment() {
        positiveMomentCount += 1
        hasPendingPositiveMoment = true
    }

    /// Call whenever a refresh returns at least one estimate.
    static func recordReadingsAvailable() {
        guard !hasSeenReading else { return }
        hasSeenReading = true
    }

    static func consumePendingPositiveMoment() {
        hasPendingPositiveMoment = false
    }

    static func passivePromptAllowed(now: Date = .now) -> Bool {
        guard outcome == nil else { return false }
        guard let last = lastShownDate else { return true }
        let days = defaults.bool(forKey: softDeferKey) ? softDeferCooldownDays : cooldownDays
        let cooldown = TimeInterval(days) * 86_400
        return now.timeIntervalSince(last) >= cooldown
    }

    /// Which trigger, if any, currently allows the enjoyment funnel to open.
    static func eligibilityTrigger(
        hasCompletedSetup: Bool,
        now: Date = .now
    ) -> ReviewPromptEligibility.Trigger? {
        guard !ScreenshotConfig.isEnabled else { return nil }
        guard hasCompletedSetup else { return nil }
        guard passivePromptAllowed(now: now) else { return nil }
        guard let first = firstAppOpenDate else { return nil }
        let eligibility = ReviewPromptEligibility(
            positiveMomentCount: positiveMomentCount,
            appLaunchCount: appLaunchCount,
            daysSinceFirstOpen: Int(now.timeIntervalSince(first) / 86_400),
            hasSeenReading: hasSeenReading
        )
        return eligibility.trigger
    }

    /// Base eligibility for the enjoyment funnel (passive or Settings).
    static func canPresentEnjoymentPrompt(
        hasCompletedSetup: Bool,
        now: Date = .now
    ) -> Bool {
        eligibilityTrigger(hasCompletedSetup: hasCompletedSetup, now: now) != nil
    }

    /// Passive prompt: eligibility plus a recent positive moment.
    static func shouldShowAfterPositiveMoment(
        hasCompletedSetup: Bool,
        now: Date = .now
    ) -> Bool {
        guard hasPendingPositiveMoment else { return false }
        return eligibilityTrigger(hasCompletedSetup: hasCompletedSetup, now: now) == .positiveMoment
    }

    /// Passive prompt for users who keep coming back without ever tripping a
    /// personal best. There is no pending token to consume here, so the host
    /// must call `markShown()` when it presents — otherwise a swipe-away would
    /// re-prompt on every single launch.
    static func shouldShowForEngagedUse(
        hasCompletedSetup: Bool,
        now: Date = .now
    ) -> Bool {
        guard !hasPendingPositiveMoment else { return false }
        return eligibilityTrigger(hasCompletedSetup: hasCompletedSetup, now: now) == .engagedUse
    }

    static func markShown(now: Date = .now) {
        lastShownDate = now
        defaults.set(false, forKey: softDeferKey)
        consumePendingPositiveMoment()
    }

    /// True after "Maybe later" until the next hard `markShown` / outcome.
    /// Hosts must not call `markShown()` on sheet dismiss when this is true —
    /// that would clear the soft-defer flag and apply the 120-day jail instead.
    static var isSoftDeferred: Bool {
        defaults.bool(forKey: softDeferKey)
    }

    /// User said Yes then "Maybe later" — we fire `requestReview()` which Apple
    /// often silently no-ops. Use a short cooldown so we can ask again instead
    /// of jailing them for 120 days.
    static func markSoftDeferred(now: Date = .now) {
        lastShownDate = now
        defaults.set(true, forKey: softDeferKey)
        consumePendingPositiveMoment()
    }

    static func markOpenedWriteReview() {
        outcome = .openedWriteReview
        markShown()
    }

    static func markFeedbackSubmitted() {
        outcome = .submittedFeedback
        markShown()
    }
}
