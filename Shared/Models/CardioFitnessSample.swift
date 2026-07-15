import Foundation
import SwiftData

@Model
final class CardioFitnessSample {
    @Attribute(.unique) var healthKitID: String
    var date: Date
    var value: Double
    var sourceName: String
    var lastUpdated: Date

    init(
        healthKitID: String,
        date: Date,
        value: Double,
        sourceName: String = "Apple Health"
    ) {
        self.healthKitID = healthKitID
        self.date = date
        self.value = value
        self.sourceName = sourceName
        self.lastUpdated = .now
    }
}

struct CardioFitnessReading: Sendable, Equatable {
    let id: String
    let date: Date
    let value: Double
    let sourceName: String
}

