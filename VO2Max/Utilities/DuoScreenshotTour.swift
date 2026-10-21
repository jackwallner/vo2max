#if DEBUG
import Foundation
import SwiftUI

/// Unattended iPhone Duo capture (`gh-sim launch --device 'iPhone Duo'`).
/// DEBUG only, so none of it ships.
///
/// `-DuoTour` walks the main screens on a timer, because `simctl openurl`
/// raises a confirmation alert and the capture job cannot tap. `-DuoRoutes a,b`
/// is the walk while folded and `-DuoRoutesRegular a,b` while split (the inner
/// display). `-DuoTourFirst <s>` is the delay before the first route and
/// `-DuoTourStep <s>` the dwell on each. The walk restarts when the panes split
/// or join, so each display gets all of it. Every step is logged as a
/// `DUOTOUR` line, which maps the captures to routes.
///
/// Routes: today, trends, plus, settings, and pushes onto Today's stack
/// (fitness-age, trend, readings, resting, recovery, load) or, with a
/// `trends/` prefix, onto the Trends stack.
enum DuoScreenshotTour {
    private static let arguments = ProcessInfo.processInfo.arguments

    static var isEnabled: Bool { arguments.contains("-DuoTour") }

    static func routes(split: Bool) -> [String] {
        let list = value(split ? "-DuoRoutesRegular" : "-DuoRoutes")
            ?? (split ? "today,fitness-age,trends/resting,plus,settings" : "today,trends,fitness-age,plus,settings")
        return list.split(separator: ",").map(String.init)
    }

    static var firstDelay: Double { value("-DuoTourFirst").flatMap(Double.init) ?? 2 }
    static var step: Double { value("-DuoTourStep").flatMap(Double.init) ?? 10 }

    private static func value(_ key: String) -> String? {
        guard let i = arguments.firstIndex(of: key), i + 1 < arguments.count else { return nil }
        return arguments[i + 1]
    }

    /// A detail screen the tour pushes onto Today's or Trends' stack.
    enum Screen: String, Hashable, Identifiable {
        case fitnessAge = "fitness-age"
        case trend
        case readings
        case resting
        case recovery
        case load

        var id: String { rawValue }

        @MainActor @ViewBuilder
        var view: some View {
            switch self {
            case .fitnessAge: FitnessAgeDetailView()
            case .trend: TrendDetailView()
            case .readings: ReadingHistoryDetailView()
            case .resting: HeartMetricDetailView(metric: .restingHeartRate)
            case .recovery: HeartMetricDetailView(metric: .heartRateRecovery)
            case .load: CardioLoadDetailView()
            }
        }
    }
}
#endif
