import SwiftData
import SwiftUI

@main
struct VO2MaxWatchApp: App {
    var body: some Scene {
        WindowGroup { WatchTodayView() }
            .modelContainer(DataService.sharedModelContainer)
    }
}

