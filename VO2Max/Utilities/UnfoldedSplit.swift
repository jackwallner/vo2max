import CoreGraphics
import SwiftUI

/// Pane frames for the unfolded iPhone Duo: Today (or VO2+, with the tab bar)
/// on the leading side of the fold, Trends on the trailing side, so no card
/// straddles the crease. `nil` keeps the single-column layout (every ordinary
/// iPhone, the folded Duo, and the unfolded Duo held in portrait, where each
/// half would be too narrow).
struct UnfoldedSplit: Equatable, Sendable {
    var primaryWidth: CGFloat
    var secondaryX: CGFloat
    var secondaryWidth: CGFloat

    /// Narrowest pane that still fits the compact Today and Trends layouts.
    static let minimumPaneWidth: CGFloat = 360

    /// - Parameters:
    ///   - width: the container's width.
    ///   - fold: the vertical fold's leading and trailing edge in the same
    ///     coordinate space, or `nil` when the system reports none.
    static func make(width: CGFloat, isRegularWidth: Bool, fold: ClosedRange<CGFloat>?) -> UnfoldedSplit? {
        guard isRegularWidth, width >= minimumPaneWidth * 2 else { return nil }
        if let fold,
           fold.lowerBound >= minimumPaneWidth,
           width - fold.upperBound >= minimumPaneWidth {
            return UnfoldedSplit(
                primaryWidth: fold.lowerBound,
                secondaryX: fold.upperBound,
                secondaryWidth: width - fold.upperBound
            )
        }
        let half = (width / 2).rounded(.down)
        return UnfoldedSplit(primaryWidth: half, secondaryX: half, secondaryWidth: width - half)
    }

    /// The tab bar's margin above the bottom edge.
    static let tabBarBottomPadding: CGFloat = 12
    /// Clear page between the leading pane's content and the top of its tab bar.
    static let tabBarGap: CGFloat = 10

    /// Room the leading pane keeps under its content for the tab bar, which
    /// sits on an opaque band: the bar, its bottom margin and the gap above
    /// it. The content ends at a hard edge at the band's top, so no row fades
    /// or shows under the bar, and the last row scrolls fully clear of it.
    static func tabBarBandHeight(barHeight: CGFloat) -> CGFloat {
        max(barHeight, 0) + tabBarBottomPadding + tabBarGap
    }
}

extension GeometryProxy {
    /// The vertical fold's horizontal extent in this proxy's space. Inactive
    /// folds count too, so the panes don't jump while the device opens.
    func verticalFold() -> ClosedRange<CGFloat>? {
        guard #available(iOS 27.1, *) else { return nil }
        let fold = reservedRegions(kind: .division, options: .includeInactive)
            .map(\.frame)
            .first { $0.height > $0.width && $0.minX > 0 && $0.maxX < size.width }
        guard let fold else { return nil }
        return fold.minX...fold.maxX
    }
}
