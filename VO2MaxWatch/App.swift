import SwiftData
import SwiftUI

@main
struct VO2MaxWatchApp: App {
    init() {
        // Re-execute the observer query on every launch, including the
        // background ones HealthKit delivery causes, so a new estimate refreshes
        // the cache and the complication without opening the app. Needs the
        // background-delivery entitlement. See
        // `HealthKitService.enableBackgroundDelivery`.
        HealthKitService.shared.enableBackgroundDelivery()
    }

    var body: some Scene {
        WindowGroup { WatchTodayView() }
            .modelContainer(DataService.sharedModelContainer)
    }
}
