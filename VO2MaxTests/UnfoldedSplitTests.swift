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
}
