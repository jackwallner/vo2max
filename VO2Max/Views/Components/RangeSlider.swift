import SwiftUI

/// A two-thumb range control for the VO2+ target band. Replaces the paired
/// +/- Steppers: drag the whole range at a glance instead of tapping a number
/// up one unit at a time. Snaps to `step` and keeps a one-step minimum gap
/// between the handles. Reused by onboarding and Settings so the target-range
/// interaction is identical everywhere it's edited.
struct RangeSlider: View {
    @Binding var lowerValue: Double
    @Binding var upperValue: Double
    let bounds: ClosedRange<Double>
    var step: Double = 1
    var tint: Color = Theme.cardio
    /// Knob fill. Defaults to the adaptive system background for Settings;
    /// onboarding passes white for its fixed light input cards.
    var handleColor: Color = Color(.systemBackground)
    var referenceRange: ClosedRange<Double>? = nil

    private let thumb: CGFloat = 30
    private let trackHeight: CGFloat = 7

    private enum Handle { case lower, upper }

    var body: some View {
        GeometryReader { geo in
            let usable = max(geo.size.width - thumb, 1)
            let span = bounds.upperBound - bounds.lowerBound
            let lowerX = position(lowerValue, usable: usable, span: span)
            let upperX = position(upperValue, usable: usable, span: span)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(tint.opacity(0.16))
                    .frame(height: trackHeight)

                if let referenceRange {
                    let referenceStart = position(referenceRange.lowerBound, usable: usable, span: span)
                    let referenceEnd = position(referenceRange.upperBound, usable: usable, span: span)
                    Capsule()
                        .fill(Theme.cardio.opacity(0.24))
                        .frame(width: max(referenceEnd - referenceStart, 0), height: 16)
                        .offset(x: referenceStart + thumb / 2)
                }

                Capsule()
                    .fill(tint)
                    .frame(width: max(upperX - lowerX, 0), height: trackHeight)
                    .offset(x: lowerX + thumb / 2)

                handle.offset(x: lowerX)
                    .gesture(drag(.lower, usable: usable, span: span))
                handle.offset(x: upperX)
                    .gesture(drag(.upper, usable: usable, span: span))
            }
            .frame(height: thumb)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 40)
        .accessibilityElement()
        .accessibilityLabel("Target range")
        .accessibilityValue("\(Int(lowerValue)) to \(Int(upperValue))")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: upperValue = min(upperValue + step, bounds.upperBound)
            case .decrement: lowerValue = max(lowerValue - step, bounds.lowerBound)
            default: break
            }
        }
    }

    private var handle: some View {
        Circle()
            .fill(handleColor)
            .frame(width: thumb, height: thumb)
            .overlay(Circle().stroke(tint, lineWidth: 3))
            .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
    }

    private func position(_ value: Double, usable: CGFloat, span: Double) -> CGFloat {
        CGFloat((value - bounds.lowerBound) / span) * usable
    }

    private func value(atX x: CGFloat, usable: CGFloat, span: Double) -> Double {
        let raw = bounds.lowerBound + Double(min(max(x, 0), usable) / usable) * span
        return (raw / step).rounded() * step
    }

    private func drag(_ handle: Handle, usable: CGFloat, span: Double) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                let v = value(atX: g.location.x - thumb / 2, usable: usable, span: span)
                switch handle {
                case .lower:
                    lowerValue = min(max(v, bounds.lowerBound), upperValue - step)
                case .upper:
                    upperValue = max(min(v, bounds.upperBound), lowerValue + step)
                }
            }
    }
}
