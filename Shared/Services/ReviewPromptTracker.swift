import Foundation

extension Notification.Name {
    /// Posted after a positive cardio moment (a new personal best or entering
    /// the target range). The host may call the system rating prompt after a
    /// short delay, with no question in front of it.
    static let vo2PositiveMomentForReview = Notification.Name("com.jackwallner.vo2max.positiveMomentForReview")
}

/// What the user did about a review. Only opening the review page ends the
/// passive asks: someone who sent feedback can still rate.
enum ReviewPromptOutcome: String, Sendable {
    /// Opened the App Store write-review page from Settings.
    case openedWriteReview
    /// Sent feedback by mail. Never stops the asks.
    case submittedFeedback
}

/// The good results that may ask for a rating. Pure, so the rule is tested
/// without HealthKit: a new personal best, or a reading that moves the user
/// into their target range from outside it. Backfills, flat readings and
/// readings that fall out of range never ask.
enum ReviewMoment {
    static func isGoodResult(
        newest: Double,
        priorLatest: Double,
        priorBest: Double?,
        targetLower: Double,
        targetUpper: Double
    ) -> Bool {
        let isNewPersonalBest = priorBest.map { newest > $0 + 0.01 } ?? false
        let nowInRange = newest >= targetLower && newest <= targetUpper
        let wasInRange = priorLatest >= targetLower && priorLatest <= targetUpper
        return isNewPersonalBest || (nowInRange && !wasInRange)
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

    /// Ask early. Most installs are gone within a week, so the only tenure
    /// gate is "not the first session": a second cold start.
    static let minimumLaunchCount = 2
    /// Days between our calls. Apple shows the prompt at most three times a
    /// year per device and decides each time, so this paces the asks.
    static let cooldownDays = 30
    /// How long a good result stays worth asking about. Past this the result is
    /// old news, and an ask on a later visit would be a launch trigger in
    /// disguise.
    static let momentFreshnessDays = 3

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

    /// When this process saw a good result that has not been asked about yet.
    /// Memory only, on purpose: a result a past launch left behind is old
    /// news, and asking about it on the next open would be a launch trigger.
    /// (The old persisted flag from earlier builds is never read.)
    private static var pendingMomentAt: Date?

    /// A good result is waiting for a calm moment to ask. Cleared when a prompt
    /// is shown, and ignored once it is older than `momentFreshnessDays`.
    static func hasPendingPositiveMoment(now: Date = .now) -> Bool {
        guard let at = pendingMomentAt else { return false }
        guard at <= now else { return true }
        return now.timeIntervalSince(at) < TimeInterval(momentFreshnessDays) * 86_400
    }

    /// Call once per process launch (e.g. from `VO2MaxApp.init`).
    static func recordAppLaunch(now: Date = .now) {
        if firstAppOpenDate == nil {
            firstAppOpenDate = now
        }
        appLaunchCount += 1
    }

    /// Call after a good result (new personal best, entering target range).
    static func recordPositiveMoment(now: Date = .now) {
        positiveMomentCount += 1
        pendingMomentAt = now
    }

    static func consumePendingPositiveMoment() {
        pendingMomentAt = nil
    }

    static func passivePromptAllowed(now: Date = .now) -> Bool {
        guard outcome != .openedWriteReview else { return false }
        guard let last = lastShownDate else { return true }
        let cooldown = TimeInterval(cooldownDays) * 86_400
        return now.timeIntervalSince(last) >= cooldown
    }

    static func canRequestReview(hasCompletedSetup: Bool, now: Date = .now) -> Bool {
        guard !ScreenshotConfig.isEnabled else { return false }
        guard hasCompletedSetup else { return false }
        guard passivePromptAllowed(now: now) else { return false }
        return appLaunchCount >= minimumLaunchCount
    }

    /// A positive moment is pending and the gates allow an ask. A blocked ask
    /// leaves the moment pending so the next one can ask.
    static func shouldRequestAfterPositiveMoment(
        hasCompletedSetup: Bool,
        now: Date = .now
    ) -> Bool {
        guard hasPendingPositiveMoment(now: now) else { return false }
        return canRequestReview(hasCompletedSetup: hasCompletedSetup, now: now)
    }

    static func markShown(now: Date = .now) {
        lastShownDate = now
        consumePendingPositiveMoment()
    }

    static func markOpenedWriteReview() {
        outcome = .openedWriteReview
        markShown()
    }

    /// Never overwrites `.openedWriteReview`: feedback sent after the review
    /// page must not reopen the asks that page ended.
    static func markFeedbackSubmitted() {
        if outcome != .openedWriteReview {
            outcome = .submittedFeedback
        }
    }
}
