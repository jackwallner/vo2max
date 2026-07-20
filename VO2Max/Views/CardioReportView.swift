import SwiftUI
import Charts
import CoreGraphics
import PDFKit

/// Print-friendly SwiftUI page rendered to PDF via `ImageRenderer`.
/// Designed at US Letter size (612×792 points). Uses light-mode colors only —
/// reports must look right when printed regardless of in-app appearance.
struct CardioReportView: View {
    let report: CardioReport

    private let pageWidth: CGFloat = 612
    private let pageHeight: CGFloat = 792
    private let margin: CGFloat = 36

    private var reportColor: Color { Color(red: 0.06, green: 0.70, blue: 0.74) }
    private var targetColor: Color { Color(red: 0.20, green: 0.68, blue: 0.45) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            keyMetricsGrid
            trendChart
            highlightsRow
            Spacer(minLength: 0)
            footer
        }
        .padding(margin)
        .frame(width: pageWidth, height: pageHeight, alignment: .topLeading)
        .background(Color.white)
        .environment(\.colorScheme, .light)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("VO2+")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(reportColor)
                    Text(report.title)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(report.calendarLabel)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.gray)
                    Text("\(report.readingCount) estimate\(report.readingCount == 1 ? "" : "s")")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.gray)
                }
            }
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 1)
                .padding(.top, 4)
        }
    }

    private var keyMetricsGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                MetricTile(
                    label: "AVG VO2 MAX",
                    value: formatValue(report.average),
                    sub: "mL/kg/min",
                    accent: reportColor,
                    trendPct: report.changePct
                )
                MetricTile(
                    label: "LATEST",
                    value: report.latest.map { formatValue($0.value) } ?? "—",
                    sub: "mL/kg/min",
                    accent: reportColor,
                    trendPct: nil
                )
            }
            HStack(spacing: 10) {
                MetricTile(
                    label: "RANGE",
                    value: "\(formatValue(report.minValue))–\(formatValue(report.maxValue))",
                    sub: "min–max",
                    accent: reportColor,
                    trendPct: nil
                )
                MetricTile(
                    label: "IN TARGET",
                    value: "\(report.readingsInTarget) / \(report.readingCount)",
                    sub: "\(Int(report.targetLower))–\(Int(report.targetUpper)) mL/kg/min",
                    accent: targetColor,
                    trendPct: nil
                )
            }
        }
    }

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(reportColor).frame(width: 8, height: 8)
                Text("Cardio fitness estimates")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black)
            }
            Chart {
                RectangleMark(
                    yStart: .value("Lower", report.targetLower),
                    yEnd: .value("Upper", report.targetUpper)
                )
                .foregroundStyle(targetColor.opacity(0.10))

                ForEach(report.readings) { reading in
                    LineMark(
                        x: .value("Date", reading.date, unit: .day),
                        y: .value("VO2 max", reading.value)
                    )
                    .foregroundStyle(reportColor)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", reading.date, unit: .day),
                        y: .value("VO2 max", reading.value)
                    )
                    .foregroundStyle(reportColor)
                    .symbolSize(18)
                }
            }
            .chartXAxis { axisMarks }
            .chartYAxis { yAxisMarks }
            .frame(height: 150)
        }
        .padding(12)
        .background(Color(white: 0.97), in: RoundedRectangle(cornerRadius: 10))
    }

    /// Stride by a fraction of the *date span*, not the reading count — VO2 max
    /// readings are sparse (a handful over months), so striding by reading count
    /// drew a label per day across the whole range and scribbled the axis.
    private var axisStrideDays: Int {
        let span = Calendar.current.dateComponents([.day], from: report.periodStart, to: report.periodEnd).day ?? 0
        return max(1, Int((Double(max(span, 1)) / 6).rounded()))
    }

    private var axisMarks: some AxisContent {
        AxisMarks(values: .stride(by: .day, count: axisStrideDays)) { value in
            AxisValueLabel {
                if let date = value.as(Date.self) {
                    Text(Self.dateFmt.string(from: date))
                        .font(.system(size: 8))
                        .foregroundStyle(.gray)
                }
            }
            AxisGridLine().foregroundStyle(Color.black.opacity(0.06))
        }
    }

    private var yAxisMarks: some AxisContent {
        AxisMarks { value in
            AxisGridLine().foregroundStyle(Color.black.opacity(0.06))
            AxisValueLabel {
                if let v = value.as(Double.self) {
                    Text(v.formatted(.number.precision(.fractionLength(0))))
                        .font(.system(size: 8))
                        .foregroundStyle(.gray)
                }
            }
        }
    }

    private var highlightsRow: some View {
        HStack(spacing: 8) {
            if let peak = report.peak {
                HighlightTile(
                    label: "BEST ESTIMATE",
                    value: formatValue(peak.value),
                    date: peak.date,
                    accent: reportColor
                )
            }
            HighlightTile(
                label: "TREND",
                value: report.trend.label,
                date: nil,
                sub: "last 90 days",
                accent: reportColor
            )
            if let age = report.fitnessAge {
                HighlightTile(
                    label: "FITNESS AGE",
                    value: "\(age)",
                    date: nil,
                    sub: "vs. age \(report.chronologicalAge)",
                    accent: targetColor
                )
            } else if let band = report.fitnessBand {
                HighlightTile(
                    label: "CONTEXT",
                    value: band,
                    date: nil,
                    accent: targetColor
                )
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("A broad fitness-awareness summary of Apple Health estimates. Not a medical measurement, diagnosis, or clinical result.")
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(.gray)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 1)
            HStack {
                Text("Generated by VO2 Max Daily Tracker on \(generatedAt)")
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(.gray)
                Spacer()
                Text("Data from Apple Health · stays on your device")
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(.gray)
            }
        }
    }

    private var generatedAt: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: Date.now)
    }

    private func formatValue(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()
}

// MARK: - Subcomponents

private struct MetricTile: View {
    let label: String
    let value: String
    var sub: String? = nil
    let accent: Color
    let trendPct: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.gray)
                    .tracking(0.6)
                Spacer()
                if let pct = trendPct {
                    TrendBadge(pct: pct)
                }
            }
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let sub {
                Text(sub)
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(white: 0.97), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct TrendBadge: View {
    let pct: Double

    var body: some View {
        let isUp = pct >= 0
        let color = isUp ? Color(red: 0.20, green: 0.68, blue: 0.45) : Color(red: 0.85, green: 0.42, blue: 0.40)
        HStack(spacing: 2) {
            Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 8, weight: .bold))
            Text("\(abs(pct).formatted(.number.precision(.fractionLength(1))))%")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.12), in: Capsule())
    }
}

private struct HighlightTile: View {
    let label: String
    let value: String
    let date: Date?
    var sub: String? = nil
    let accent: Color

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.gray)
                .tracking(0.6)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let date {
                Text(Self.dateFmt.string(from: date))
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(.gray)
            } else if let sub {
                Text(sub)
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(white: 0.97), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - PDF Rendering

@MainActor
enum CardioReportPDF {
    /// Renders a `CardioReport` to a PDF on disk and returns the file URL.
    /// Caller is responsible for cleaning up the file (typically after the share sheet dismisses).
    static func render(_ report: CardioReport) throws -> URL {
        let view = CardioReportView(report: report)
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(width: 612, height: 792)
        renderer.scale = 2.0

        let safeTitle = report.title.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("VO2Max_\(safeTitle)_\(Int(Date.now.timeIntervalSince1970)).pdf")

        var pageBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let context = CGContext(url as CFURL, mediaBox: &pageBox, nil) else {
            throw NSError(domain: "VO2Max.PDF", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create PDF context."])
        }

        renderer.render { _, renderAction in
            context.beginPDFPage(nil)
            renderAction(context)
            context.endPDFPage()
        }
        context.closePDF()

        return url
    }
}

enum CardioReportShareText {
    static func make(report: CardioReport) -> String {
        let trend = trendLine(report.changePct)
        return """
        VO2+ \(report.title) 💙
        ❤️ Avg cardio fitness: \(report.average.formatted(.number.precision(.fractionLength(1)))) mL/kg/min
        🎯 In target: \(report.readingsInTarget)/\(report.readingCount) estimates
        📈 Trend: \(report.trend.label)
        \(trend)

        Tracked with VO2 Max Daily Tracker — Apple Health estimates, private on your device.
        """
    }

    private static func trendLine(_ percent: Double?) -> String {
        guard let percent else { return "⬜️ Change: more data needed" }
        let arrow = percent >= 0 ? "↗️" : "↘️"
        return "\(arrow) Change: \(abs(percent).formatted(.number.precision(.fractionLength(1))))% vs. prior period"
    }
}

struct PDFPreviewSheet: View {
    let title: String
    let url: URL
    let shareText: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PDFKitPreview(url: url)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            ShareLink(item: shareText) {
                                Image(systemName: "message.fill")
                            }
                            .accessibilityLabel("Share summary")
                            ShareLink(item: url) {
                                Image(systemName: "square.and.arrow.up")
                            }
                            .accessibilityLabel("Share PDF")
                        }
                    }
                }
        }
    }
}

private struct PDFKitPreview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .systemBackground
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
        }
    }
}
