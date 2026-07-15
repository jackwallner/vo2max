import SwiftData
import SwiftUI
import WidgetKit

struct WatchCardioEntry: TimelineEntry {
    let date: Date
    let value: Double?
    let trend: CardioTrend
}

struct WatchCardioProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchCardioEntry {
        WatchCardioEntry(date: .now, value: 42.6, trend: .improving)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (WatchCardioEntry) -> Void) {
        Task { @MainActor in completion(loadEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<WatchCardioEntry>) -> Void) {
        Task { @MainActor in
            let entry = loadEntry()
            let next = Calendar.current.date(byAdding: .hour, value: 6, to: .now) ?? .now.addingTimeInterval(21_600)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    @MainActor
    private func loadEntry() -> WatchCardioEntry {
        var descriptor = FetchDescriptor<CardioFitnessSample>(sortBy: [SortDescriptor(\CardioFitnessSample.date, order: .reverse)])
        descriptor.fetchLimit = 30
        let samples = (try? DataService.sharedModelContainer.mainContext.fetch(descriptor)) ?? []
        let points = samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
        return WatchCardioEntry(date: .now, value: samples.first?.value, trend: CardioFitnessAnalysis.trend(points: points))
    }
}

struct WatchCardioView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WatchCardioEntry

    var body: some View {
        if let value = entry.value {
            switch family {
            case .accessoryCircular:
                Gauge(value: value, in: 10...70) {
                    Image(systemName: "heart.fill")
                } currentValueLabel: {
                    Text(value, format: .number.precision(.fractionLength(0))).font(.headline.bold())
                }
                .gaugeStyle(.accessoryCircular).tint(Theme.cardio)
            case .accessoryRectangular:
                HStack {
                    VStack(alignment: .leading) {
                        Text("VO2 MAX").font(.caption2)
                        Text(value, format: .number.precision(.fractionLength(1))).font(.title3.bold())
                    }
                    Spacer()
                    Image(systemName: entry.trend.symbol).foregroundStyle(Theme.cardio)
                }
            case .accessoryInline:
                Label("VO2 \(value.formatted(.number.precision(.fractionLength(1)))) · \(entry.trend.label)", systemImage: "heart.fill")
            case .accessoryCorner:
                Text(value, format: .number.precision(.fractionLength(0)))
                    .font(.headline.bold())
                    .widgetLabel { Label("VO2 Max", systemImage: "heart.fill") }
            default:
                Text(value, format: .number.precision(.fractionLength(1)))
            }
        } else {
            Image(systemName: "heart.slash").foregroundStyle(.secondary)
        }
    }
}

@main
struct VO2MaxWatchWidgetBundle: WidgetBundle {
    var body: some Widget { VO2MaxWatchWidget() }
}

struct VO2MaxWatchWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "VO2MaxWatchWidget", provider: WatchCardioProvider()) { entry in
            WatchCardioView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("VO2 Max")
        .description("Your latest cardio fitness estimate and trend.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}
