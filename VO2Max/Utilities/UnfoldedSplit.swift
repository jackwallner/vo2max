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

    /// Tops for a pane's stacked cards, so the pane comes to rest on whole
    /// cards: the first card that `restHeight` (the bottom of the visible
    /// area, from the stack's top) would cut starts at that edge instead, and
    /// the cards after it keep their spacing. The first card never moves.
    static func restingTops(heights: [CGFloat], spacing: CGFloat, restHeight: CGFloat) -> [CGFloat] {
        var tops: [CGFloat] = []
        var y: CGFloat = 0
        for height in heights {
            if !tops.isEmpty {
                y += spacing
                if y < restHeight, y + height > restHeight { y = restHeight }
            }
            tops.append(y)
            y += height
        }
        return tops
    }

    /// The stack for a pane's scroll content: `PaneRestStack` while split,
    /// once the visible height is known, else a plain `VStack`. One
    /// `AnyLayout`, so folding keeps every card's state.
    @MainActor
    static func contentLayout(spacing: CGFloat, restHeight: CGFloat?) -> AnyLayout {
        guard let restHeight, restHeight > 0 else { return AnyLayout(VStackLayout(spacing: spacing)) }
        return AnyLayout(PaneRestStack(spacing: spacing, restHeight: restHeight))
    }
}

/// A centred `VStack` that rests on whole cards (`UnfoldedSplit.restingTops`).
/// Split, the leading pane's content stops at the opaque tab bar band, and a
/// card cut by its edge read as chopped off; the screen edge under the
/// trailing pane doesn't have that problem, so only pane content uses this.
struct PaneRestStack: Layout {
    var spacing: CGFloat
    var restHeight: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil)) }
        guard let last = sizes.last else { return .zero }
        let tops = UnfoldedSplit.restingTops(heights: sizes.map(\.height), spacing: spacing, restHeight: restHeight)
        return CGSize(width: sizes.map(\.width).max() ?? 0, height: tops[tops.count - 1] + last.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let childProposal = ProposedViewSize(width: proposal.width, height: nil)
        let heights = subviews.map { $0.sizeThatFits(childProposal).height }
        let tops = UnfoldedSplit.restingTops(heights: heights, spacing: spacing, restHeight: restHeight)
        for (subview, top) in zip(subviews, tops) {
            subview.place(at: CGPoint(x: bounds.midX, y: bounds.minY + top), anchor: .top, proposal: childProposal)
        }
    }
}

extension View {
    /// Reports the height a scroll view shows between its bars and insets
    /// (the tab bar band included): its frame less its safe area, which holds
    /// whether or not the frame runs under the bars. `ScrollGeometry`'s
    /// container size less its content insets came out about 74 pt short on
    /// the Duo and pushed cards that fit.
    func onScrollVisibleHeightChange(_ action: @escaping (CGFloat) -> Void) -> some View {
        onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom
        } action: { height in
            action(height)
        }
    }
}
