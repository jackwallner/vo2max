import SwiftData
import SwiftUI
import WidgetKit

struct CardioEntry: TimelineEntry {
    let date: Date
    let value: Double?
    let readingDate: Date?
    let trend: CardioTrend
    let targetLower: Double
    let targetUpper: Double
}

struct CardioProvider: TimelineProvider {
    func placeholder(in context: Context) -> CardioEntry {
        CardioEntry(date: .now, value: 42.6, readingDate: .now, trend: .improving, targetLower: 35, targetUpper: 45)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (CardioEntry) -> Void) {
        let isPreview = context.isPreview
        Task { @MainActor in
            completion(isPreview ? CardioEntry(date: .now, value: 42.6, readingDate: .now, trend: .improving, targetLower: 35, targetUpper: 45) : loadEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<CardioEntry>) -> Void) {
        Task { @MainActor in
            let entry = loadEntry()
            let next = Calendar.current.date(byAdding: .hour, value: 6, to: .now) ?? .now.addingTimeInterval(21_600)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    @MainActor
    private func loadEntry() -> CardioEntry {
        var descriptor = FetchDescriptor<CardioFitnessSample>(sortBy: [SortDescriptor(\CardioFitnessSample.date, order: .reverse)])
        descriptor.fetchLimit = 30
        let samples = (try? DataService.sharedModelContainer.mainContext.fetch(descriptor)) ?? []
        let defaults = UserDefaults(suiteName: vo2MaxAppGroupID) ?? .standard
        let lower = defaults.object(forKey: "targetLower") as? Double ?? 35
        let upper = defaults.object(forKey: "targetUpper") as? Double ?? 45
        let points = samples.map { CardioFitnessPoint(date: $0.date, value: $0.value) }
        return CardioEntry(
            date: .now,
            value: samples.first?.value,
            readingDate: samples.first?.date,
            trend: CardioFitnessAnalysis.trend(points: points),
            targetLower: lower,
            targetUpper: upper
        )
    }
}

struct VO2MaxWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CardioEntry

    var body: some View {
        if let value = entry.value {
            switch family {
            case .systemMedium:
                medium(value)
            case .accessoryCircular:
                circular(value)
            case .accessoryRectangular:
                rectangular(value)
            case .accessoryInline:
                Text("VO2 max \(value, format: .number.precision(.fractionLength(1))) · \(entry.trend.label)")
            default:
                small(value)
            }
        } else {
            ContentUnavailableView("No VO2 max", systemImage: "heart.text.square", description: Text("Open the app to sync"))
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }

    private func small(_ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("VO2 MAX", systemImage: "heart.fill")
                .font(.caption2.bold())
                .foregroundStyle(Theme.cardio)
            Spacer()
            Text(value, format: .number.precision(.fractionLength(1)))
                .font(Theme.numberFont(40))
                .minimumScaleFactor(0.7)
            Text("mL/kg/min").font(.caption2).foregroundStyle(.secondary)
            Label(entry.trend.label, systemImage: entry.trend.symbol)
                .font(.caption.bold())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("VO2 max \(value.formatted(.number.precision(.fractionLength(1)))) milliliters per kilogram per minute, trend \(entry.trend.label)")
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func medium(_ value: Double) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Label("Cardio Fitness", systemImage: "heart.fill")
                    .font(.caption.bold()).foregroundStyle(Theme.cardio)
                Spacer()
                Text(value, format: .number.precision(.fractionLength(1)))
                    .font(Theme.numberFont(46))
                Text("mL/kg/min").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Image(systemName: entry.trend.symbol)
                    .font(.title.bold()).foregroundStyle(Theme.cardio)
                Text(entry.trend.label).font(.headline)
                Text("Target \(entry.targetLower.formatted(.number.precision(.fractionLength(0))))–\(entry.targetUpper.formatted(.number.precision(.fractionLength(0))))")
                    .font(.caption).foregroundStyle(.secondary)
                if let readingDate = entry.readingDate {
                    Text(readingDate, format: .dateTime.month(.abbreviated).day())
                        .font(.caption2).foregroundStyle(.tertiary)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func circular(_ value: Double) -> some View {
        Gauge(value: value, in: 10...70) {
            Image(systemName: "heart.fill")
        } currentValueLabel: {
            Text(value, format: .number.precision(.fractionLength(0)))
                .font(.headline.bold()).minimumScaleFactor(0.7)
        }
        .gaugeStyle(.accessoryCircular)
        .tint(Theme.cardio)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func rectangular(_ value: Double) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("VO2 max").font(.caption)
                Text(value, format: .number.precision(.fractionLength(1))).font(.title2.bold())
            }
            Spacer()
            Label(entry.trend.label, systemImage: entry.trend.symbol).font(.caption.bold())
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct VO2MaxWidgetBundle: WidgetBundle {
    var body: some Widget { VO2MaxWidget() }
}

struct VO2MaxWidget: Widget {
    let kind = "VO2MaxWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CardioProvider()) { entry in
            VO2MaxWidgetView(entry: entry)
        }
        .configurationDisplayName("VO2 Max")
        .description("Your latest cardio fitness estimate and trend.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

#Preview(as: .systemSmall) {
    VO2MaxWidget()
} timeline: {
    CardioEntry(date: .now, value: 42.6, readingDate: .now, trend: .improving, targetLower: 35, targetUpper: 45)
}
