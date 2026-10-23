import SwiftUI

struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0+
    let gradient: LinearGradient
    let glowColor: Color
    let lineWidth: CGFloat
    let size: CGFloat

    init(
        progress: Double,
        gradient: LinearGradient,
        glowColor: Color,
        lineWidth: CGFloat = 14,
        size: CGFloat = 180
    ) {
        self.progress = progress
        self.gradient = gradient
        self.glowColor = glowColor
        self.lineWidth = lineWidth
        self.size = size
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(
                    Theme.ringTrack,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // Progress arc
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: glowColor, radius: 8, x: 0, y: 0)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    /// Width of the ring's open centre along a horizontal line `offset` points
    /// above or below its middle. The stroke straddles the frame's circle, so
    /// the inner edge sits half a line width inside it.
    nonisolated static func innerChord(size: CGFloat, lineWidth: CGFloat, offset: CGFloat) -> CGFloat {
        let radius = size / 2 - lineWidth / 2
        guard abs(offset) < radius else { return 0 }
        return 2 * (radius * radius - offset * offset).squareRoot()
    }
}
