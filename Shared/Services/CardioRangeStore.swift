import Combine
import Foundation

/// One shared range across Trends, the VO2+ tab, and every metric detail screen,
/// so the window a user picks anywhere is the window they land in everywhere.
///
/// Was four separate `@AppStorage` reads of a day count. A custom range needs a
/// start and an end as well, and all three have to move together, so they live
/// here instead.
@MainActor
final class CardioRangeStore: ObservableObject {
    static let shared = CardioRangeStore()

    /// Kept as the original key so an existing pick survives the upgrade.
    static let selectionKey = "cardioMetricRangeDays"
    private static let customStartKey = "cardioMetricCustomStart"
    private static let customEndKey = "cardioMetricCustomEnd"

    @Published private(set) var selection: MetricRange
    @Published private(set) var customStart: Date
    @Published private(set) var customEnd: Date

    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.object(forKey: Self.selectionKey) as? Int
        selection = stored.flatMap(MetricRange.init(rawValue:)) ?? .quarter

        let now = Date.now
        let storedEnd = defaults.object(forKey: Self.customEndKey) as? Double
        let storedStart = defaults.object(forKey: Self.customStartKey) as? Double
        customEnd = storedEnd.map(Date.init(timeIntervalSince1970:)) ?? now
        customStart = storedStart.map(Date.init(timeIntervalSince1970:))
            ?? Calendar.current.date(byAdding: .day, value: -MetricRange.quarter.days, to: now)
            ?? now
    }

    /// The current selection resolved into real dates. Recomputed on read so the
    /// fixed windows always end today.
    var resolved: CardioRange {
        selection == .custom
            ? .custom(start: customStart, end: customEnd)
            : .fixed(selection)
    }

    func select(_ range: MetricRange) {
        guard range != selection else { return }
        selection = range
        defaults.set(range.rawValue, forKey: Self.selectionKey)
    }

    /// Applies a hand-picked window and switches to it. Dates are ordered and
    /// clamped here so no caller can install a backwards or oversized range.
    func applyCustom(start: Date, end: Date, now: Date = .now, calendar: Calendar = .current) {
        let cappedEnd = min(max(start, end), now)
        let earliest = calendar.date(
            byAdding: .day,
            value: -CardioRange.maximumCustomDays,
            to: cappedEnd
        ) ?? cappedEnd
        let cappedStart = max(min(start, cappedEnd), earliest)

        customStart = cappedStart
        customEnd = cappedEnd
        selection = .custom
        defaults.set(cappedStart.timeIntervalSince1970, forKey: Self.customStartKey)
        defaults.set(cappedEnd.timeIntervalSince1970, forKey: Self.customEndKey)
        defaults.set(MetricRange.custom.rawValue, forKey: Self.selectionKey)
    }

    /// Custom ranges are VO2+. If entitlement lapses while one is selected, drop
    /// back to the default window rather than leaving a locked screen running on
    /// a range the user can no longer change.
    func revertCustomIfLocked(isPro: Bool) {
        guard !isPro, selection == .custom else { return }
        select(.quarter)
    }
}
