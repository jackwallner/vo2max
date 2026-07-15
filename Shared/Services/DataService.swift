import Foundation
import os
import SwiftData

let vo2MaxAppGroupID = "group.com.jackwallner.vo2max"

@MainActor
enum DataService {
    static let appGroupID = vo2MaxAppGroupID

    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([CardioFitnessSample.self])
        let storeURL = containerURL.appendingPathComponent("VO2Max.store")
        let configuration = ModelConfiguration(
            "VO2Max",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            Logger(subsystem: "com.jackwallner.vo2max", category: "Data")
                .error("Persistent store failed: \(String(describing: error), privacy: .public)")
            let fallback = ModelConfiguration(
                "VO2MaxFallback",
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            do {
                return try ModelContainer(for: schema, configurations: [fallback])
            } catch {
                fatalError("Unable to initialize VO2 Max data store: \(error)")
            }
        }
    }()

    private static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
    }
}

