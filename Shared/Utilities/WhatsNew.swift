import Foundation

/// Gates the one-time "What's New" announcement that advertises the opt-in VO2+
/// extras after an update. The core app is unchanged for everyone — this is
/// purely an awareness surface, and every feature it mentions stays off until the
/// user turns it on.
///
/// Existing users (who completed setup on a prior build) see the announcement
/// once per content version. Fresh installs are seeded past it in
/// `GoalSettings.init` so they get onboarding instead of a "what changed" pitch
/// for an app they've never used.
enum WhatsNew {
    /// Bump this when there's a new announcement to surface. It tracks the
    /// *announcement content*, not the app's marketing version, so unrelated
    /// build bumps don't re-trigger the sheet. "1.2" — the release that rebuilds
    /// VO2+ around what moved the estimate, heart signals, and freshness nudges.
    static let currentVersion = "1.2"

    /// True when the user hasn't yet seen the announcement for `currentVersion`.
    static func shouldShow(lastShown: String?) -> Bool {
        lastShown != currentVersion
    }
}
