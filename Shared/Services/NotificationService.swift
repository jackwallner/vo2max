import Foundation
import UserNotifications
import os

/// Local notifications for VO2+. Two distinct loops, both re-engagement:
///
/// 1. **Monthly recap** — a repeating nudge on the 1st that reminds the user to
///    open their cardio fitness month in review. Local notifications can't
///    compute content at fire time, so it carries no live numbers; the real
///    recap is rendered on open by `MonthlyRecapView`. This is the deliberate
///    low-cadence "monthly heartbeat".
/// 2. **New-reading alert** — fired at detection time (Apple Health logs VO2 max
///    ~1–2×/week), so it *can* carry the live value. `HealthKitService` calls
///    `scheduleNewReadingAlert` when a genuinely new estimate lands.
///
/// Not actor-isolated: every call goes through the thread-safe
/// `UNUserNotificationCenter`, and the routing constants need to be readable
/// from the (nonisolated) notification-center delegate.
enum NotificationService {
    /// Identifier for the repeating monthly recap request. Stable so re-scheduling
    /// replaces rather than stacks, and cancel can target it precisely.
    static let monthlyRecapID = "vo2max.monthlyRecap"
    /// Prefix for one-shot new-reading alerts (unique per fire so they don't coalesce).
    static let newReadingIDPrefix = "vo2max.newReading."

    /// userInfo key set on notifications so the app can route a tap to the right surface.
    static let routeKey = "route"
    static let recapRouteValue = "monthlyRecap"
    static let readingRouteValue = "today"

    /// Fire the recap on the 1st of the month, 18:00 — late enough that last
    /// month is "done", early enough to still be seen.
    static let recapDay = 1
    static let recapHour = 18

    private static let logger = Logger(subsystem: "com.jackwallner.vo2max", category: "Notifications")

    /// Requests notification permission. Returns true if authorized (or already
    /// authorized / provisional). Safe to call repeatedly — the system only
    /// prompts once.
    @discardableResult
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            logger.info("Notification authorization granted=\(granted, privacy: .public)")
            return granted
        } catch {
            logger.error("Notification authorization failed: \(String(describing: error), privacy: .public)")
            return false
        }
    }

    /// True when the user has authorized (or provisionally authorized) notifications.
    static func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    // MARK: - Monthly recap

    /// Schedules (or re-schedules) the repeating monthly recap notification.
    /// Requests authorization first; if denied, schedules nothing and returns false.
    @discardableResult
    static func scheduleMonthlyRecap() async -> Bool {
        guard await requestAuthorization() else {
            logger.info("Monthly recap not scheduled — notifications not authorized")
            return false
        }

        let content = UNMutableNotificationContent()
        content.title = "Your cardio fitness month"
        content.body = "See how your VO2 max trend and target progress stacked up."
        content.sound = .default
        content.userInfo = [routeKey: recapRouteValue]

        var components = DateComponents()
        components.day = recapDay
        components.hour = recapHour
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: monthlyRecapID, content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [monthlyRecapID])
        do {
            try await center.add(request)
            logger.info("Monthly recap scheduled for day=\(recapDay, privacy: .public) hour=\(recapHour, privacy: .public)")
            return true
        } catch {
            logger.error("Monthly recap scheduling failed: \(String(describing: error), privacy: .public)")
            return false
        }
    }

    /// Cancels the pending monthly recap notification (toggle off, or subscription lapsed).
    static func cancelMonthlyRecap() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [monthlyRecapID])
        logger.info("Monthly recap cancelled")
    }

    // MARK: - New-reading alert

    /// Posts a local notification announcing a new Apple Health VO2 max estimate.
    /// Fired at detection time so it can carry the live value and context. Only
    /// call when the user is entitled + opted in and notifications are authorized
    /// (caller decides); this method itself just checks authorization so a denied
    /// user is never spammed via the pending queue.
    static func scheduleNewReadingAlert(value: Double, context: String?) async {
        guard await isAuthorized() else {
            logger.info("New-reading alert skipped — notifications not authorized")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "New cardio fitness estimate"
        let rounded = value.formatted(.number.precision(.fractionLength(1)))
        if let context, !context.isEmpty {
            content.body = "Apple Health logged \(rounded) mL/kg/min. \(context)"
        } else {
            content.body = "Apple Health logged \(rounded) mL/kg/min."
        }
        content.sound = .default
        content.userInfo = [routeKey: readingRouteValue]

        // Fire almost immediately; a tiny delay keeps it a real notification even
        // when we're in the foreground handler.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let id = newReadingIDPrefix + UUID().uuidString
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        do {
            try await UNUserNotificationCenter.current().add(request)
            logger.info("New-reading alert scheduled value=\(rounded, privacy: .public)")
        } catch {
            logger.error("New-reading alert failed: \(String(describing: error), privacy: .public)")
        }
    }
}
