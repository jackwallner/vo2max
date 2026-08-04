import Foundation
import Testing
@testable import VO2Max

struct ReviewPromptEligibilityTests {
    @Test func aPositiveMomentOpensTheFunnelEarly() {
        let eligibility = ReviewPromptEligibility(
            positiveMomentCount: 1,
            appLaunchCount: 3,
            daysSinceFirstOpen: 3,
            hasSeenReading: true
        )
        #expect(eligibility.trigger == .positiveMoment)
    }

    @Test func aPositiveMomentStillNeedsThreeLaunchesAndThreeDays() {
        let tooNew = ReviewPromptEligibility(
            positiveMomentCount: 1,
            appLaunchCount: 3,
            daysSinceFirstOpen: 2,
            hasSeenReading: true
        )
        #expect(tooNew.trigger == nil)

        let tooFewLaunches = ReviewPromptEligibility(
            positiveMomentCount: 1,
            appLaunchCount: 2,
            daysSinceFirstOpen: 3,
            hasSeenReading: true
        )
        #expect(tooFewLaunches.trigger == nil)
    }

    /// The whole point of the second path: a user whose estimate never moves
    /// enough to trip a personal best can still be asked.
    @Test func steadyReturnsOpenTheFunnelWithoutAnyPositiveMoment() {
        let eligibility = ReviewPromptEligibility(
            positiveMomentCount: 0,
            appLaunchCount: 5,
            daysSinceFirstOpen: 7,
            hasSeenReading: true
        )
        #expect(eligibility.trigger == .engagedUse)
    }

    @Test func engagedPathWaitsLongerThanThePositiveOne() {
        let fourLaunches = ReviewPromptEligibility(
            positiveMomentCount: 0,
            appLaunchCount: 4,
            daysSinceFirstOpen: 7,
            hasSeenReading: true
        )
        #expect(fourLaunches.trigger == nil)

        let sixDays = ReviewPromptEligibility(
            positiveMomentCount: 0,
            appLaunchCount: 5,
            daysSinceFirstOpen: 6,
            hasSeenReading: true
        )
        #expect(sixDays.trigger == nil)
    }

    /// Asking someone who has never seen an estimate whether they enjoy an
    /// estimate viewer is how you earn a one-star review.
    @Test func engagedPathRequiresRealDataOnScreen() {
        let noData = ReviewPromptEligibility(
            positiveMomentCount: 0,
            appLaunchCount: 40,
            daysSinceFirstOpen: 90,
            hasSeenReading: false
        )
        #expect(noData.trigger == nil)
    }

    /// A positive moment is the stronger signal, so it wins the tie and the host
    /// consumes the pending token instead of burning the cooldown.
    @Test func positiveMomentWinsWhenBothPathsQualify() {
        let eligibility = ReviewPromptEligibility(
            positiveMomentCount: 2,
            appLaunchCount: 12,
            daysSinceFirstOpen: 30,
            hasSeenReading: true
        )
        #expect(eligibility.trigger == .positiveMoment)
    }

    @Test func aBrandNewInstallIsNeverAsked() {
        let firstLaunch = ReviewPromptEligibility(
            positiveMomentCount: 0,
            appLaunchCount: 1,
            daysSinceFirstOpen: 0,
            hasSeenReading: true
        )
        #expect(firstLaunch.trigger == nil)
    }
}
