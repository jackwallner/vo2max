import CoreGraphics
import Testing
@testable import VO2Max

struct UnfoldedSplitTests {
    /// The unfolded iPhone Duo's inner display, held landscape.
    private let innerWidth: CGFloat = 951

    @Test func compactWidthNeverSplits() {
        #expect(UnfoldedSplit.make(width: 466, isRegularWidth: false, fold: nil) == nil)
        #expect(UnfoldedSplit.make(width: innerWidth, isRegularWidth: false, fold: 465...486) == nil)
    }

    @Test func portraitUnfoldStaysSingleColumn() {
        // 669 pt wide: two 360 pt panes do not fit.
        #expect(UnfoldedSplit.make(width: 669, isRegularWidth: true, fold: nil) == nil)
    }

    @Test func panesMeetTheFoldEdges() throws {
        let split = try #require(UnfoldedSplit.make(width: innerWidth, isRegularWidth: true, fold: 465...486))
        #expect(split.primaryWidth == 465)
        #expect(split.secondaryX == 486)
        #expect(split.secondaryWidth == innerWidth - 486)
    }

    @Test func zeroWidthFoldStillMeetsIt() throws {
        let split = try #require(UnfoldedSplit.make(width: innerWidth, isRegularWidth: true, fold: 475...475))
        #expect(split.primaryWidth == 475)
        #expect(split.secondaryX == 475)
        #expect(split.primaryWidth + split.secondaryWidth == innerWidth)
    }

    @Test func noFoldSplitsEvenly() throws {
        let split = try #require(UnfoldedSplit.make(width: innerWidth, isRegularWidth: true, fold: nil))
        #expect(split.primaryWidth == 475)
        #expect(split.secondaryX == 475)
        #expect(split.secondaryWidth == 476)
    }

    @Test func offCentreFoldFallsBackToAnEvenSplit() throws {
        // A fold that would leave the trailing pane under 360 pt is ignored.
        let split = try #require(UnfoldedSplit.make(width: 800, isRegularWidth: true, fold: 500...510))
        #expect(split.primaryWidth == 400)
        #expect(split.secondaryX == 400)
    }

    @Test func everySplitKeepsBothPanesUsableAndCoversTheWidth() {
        for width in stride(from: CGFloat(600), through: 1400, by: 7) {
            guard let split = UnfoldedSplit.make(width: width, isRegularWidth: true, fold: nil) else {
                #expect(width < UnfoldedSplit.minimumPaneWidth * 2)
                continue
            }
            #expect(split.primaryWidth >= UnfoldedSplit.minimumPaneWidth)
            #expect(split.secondaryWidth >= UnfoldedSplit.minimumPaneWidth)
            #expect(split.secondaryX + split.secondaryWidth == width)
        }
    }

    @Test func tabBarBandEndsTheContentAGapAboveTheBar() {
        // The 55 pt bar measured on the gh-sim iPhone Duo, in a 669 pt pane.
        let band = UnfoldedSplit.tabBarBandHeight(barHeight: 55)
        let barTop = 669 - UnfoldedSplit.tabBarBottomPadding - 55
        #expect(band == 77)
        #expect(barTop - (669 - band) == UnfoldedSplit.tabBarGap)
    }

    @Test func unmeasuredTabBarStillKeepsItsMargins() {
        #expect(UnfoldedSplit.tabBarBandHeight(barHeight: 0) == UnfoldedSplit.tabBarBottomPadding + UnfoldedSplit.tabBarGap)
        #expect(UnfoldedSplit.tabBarBandHeight(barHeight: -4) == UnfoldedSplit.tabBarBandHeight(barHeight: 0))
    }

    @Test func cardsThatFitKeepTheirStackPositions() {
        let tops = UnfoldedSplit.restingTops(heights: [100, 120, 80], spacing: 20, restHeight: 500)
        #expect(tops == [0, 120, 260])
    }

    @Test func theFirstCutCardStartsAtTheRestEdge() {
        // VO2+ in the leading Duo pane: figures and signals fit, the estimate
        // section would show its title above the band, so it starts at the band.
        let tops = UnfoldedSplit.restingTops(heights: [187, 261, 260, 180], spacing: 22, restHeight: 501)
        #expect(tops == [0, 209, 501, 783])
    }

    @Test func aCardAlreadyBelowTheEdgeIsNotMoved() {
        let tops = UnfoldedSplit.restingTops(heights: [480, 100], spacing: 22, restHeight: 500)
        #expect(tops == [0, 502])
    }

    @Test func aCardEndingExactlyAtTheEdgeStays() {
        let tops = UnfoldedSplit.restingTops(heights: [300, 180, 50], spacing: 10, restHeight: 490)
        #expect(tops == [0, 310, 500])
    }

    @Test func theFirstCardNeverMoves() {
        let tops = UnfoldedSplit.restingTops(heights: [700, 100], spacing: 16, restHeight: 500)
        #expect(tops == [0, 716])
        #expect(UnfoldedSplit.restingTops(heights: [], spacing: 16, restHeight: 500).isEmpty)
    }

    @Test func everyVisibleCardEndsAboveTheEdge() {
        let heights: [CGFloat] = [154, 138, 160, 48, 90, 200]
        for rest in stride(from: CGFloat(150), through: 900, by: 3) {
            let tops = UnfoldedSplit.restingTops(heights: heights, spacing: 12, restHeight: rest)
            for (top, height) in zip(tops.dropFirst(), heights.dropFirst()) where top < rest {
                #expect(top + height <= rest)
            }
        }
    }

    @Test func restTopKeepsTheTopOfTheScrollWhileIdle() {
        var rest = PaneRestTop()
        #expect(rest.restHeight(edge: 592) == nil)
        rest.observe(CGRect(x: 20, y: 92, width: 415, height: 900))
        #expect(rest.restHeight(edge: 592) == 500)
        // Scrolled down and settled: the top of the scroll still counts.
        rest.observe(CGRect(x: 20, y: -140, width: 415, height: 900))
        #expect(rest.restHeight(edge: 592) == 500)
        #expect(rest.restHeight(edge: nil) == nil)
    }

    @Test func restTopIgnoresAnOverscrollWhileScrolling() {
        var rest = PaneRestTop()
        rest.observe(CGRect(x: 20, y: 92, width: 415, height: 900))
        rest.isIdle = false
        rest.observe(CGRect(x: 20, y: 160, width: 415, height: 900))
        rest.isIdle = true
        #expect(rest.restHeight(edge: 592) == 500)
    }

    @Test func restTopMeasuresAgainWhenThePaneResizes() {
        var rest = PaneRestTop()
        rest.observe(CGRect(x: 20, y: 120, width: 342, height: 900))
        rest.observe(CGRect(x: 20, y: 92, width: 415, height: 900))
        #expect(rest.restHeight(edge: 592) == 500)
    }

    /// The stroke straddles the ring's frame, so the open centre is the frame
    /// less one line width across, narrowing away from the middle.
    @Test func ringInnerChordFollowsTheStrokesInnerEdge() {
        #expect(ProgressRing.innerChord(size: 140, lineWidth: 14, offset: 0) == 126)
        #expect(ProgressRing.innerChord(size: 140, lineWidth: 14, offset: 63) == 0)
        #expect(ProgressRing.innerChord(size: 140, lineWidth: 14, offset: -80) == 0)
        let chord = ProgressRing.innerChord(size: 140, lineWidth: 14, offset: 28)
        #expect(abs(chord - 112.87) < 0.01)
    }

    /// Today's caption on the 140 pt floor ring (the Duo pane) gets the chord
    /// less 12 pt a side, under "In target range"'s ~105 pt natural width, so
    /// it scales down instead of touching the stroke. Full-size rings keep it.
    @Test func ringCaptionScalesOnlyOnTheFloorRing() {
        let floor = ProgressRing.innerChord(size: 140, lineWidth: 14, offset: 28) - 24
        let full = ProgressRing.innerChord(size: 260, lineWidth: 18, offset: 52) - 24
        #expect(floor < 105)
        #expect(floor >= 105 * 0.7)
        #expect(full > 105)
    }
}
