import Foundation

/// Lightweight screenshot-mode probe. VO2Max drives App Store captures through
/// launch arguments (`-ScreenshotTab`, `-PaywallSnapshot`, `-SeedScreenshotData`),
/// so retention surfaces that must stay out of marketing shots (review funnel,
/// What's New) gate on this. Always false in Release.
enum ScreenshotConfig {
    #if DEBUG
    static var isEnabled: Bool {
        let args = ProcessInfo.processInfo.arguments
        return args.contains("-ScreenshotTab")
            || args.contains("-PaywallSnapshot")
            || args.contains("-SeedScreenshotData")
    }
    #else
    static let isEnabled = false
    #endif
}
