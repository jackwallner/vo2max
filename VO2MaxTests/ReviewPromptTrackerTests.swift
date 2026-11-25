import Foundation
import Testing
@testable import VO2Max

/// The rating-ask rules from the fleet policy: ask from the second launch, wait
/// out a 30-day cooldown, stop only when the user opened the review page, and
/// never let feedback stop or restart the asks.
@Suite("Review prompt gates", .serialized)
@MainActor
struct ReviewPromptTrackerTests {
    /// Snapshots and restores the shared app-group state the tracker persists,
    /// so running the suite doesn't leave a simulator install mid-ask.
    private func withCleanTracker(_ body: () -> Void) {
        let launches = ReviewPromptTracker.appLaunchCount
        let firstOpen = ReviewPromptTracker.firstAppOpenDate
        let lastShown = ReviewPromptTracker.lastShownDate
        let outcome = ReviewPromptTracker.outcome
        let moments = ReviewPromptTracker.positiveMomentCount
        defer {
            ReviewPromptTracker.consumePendingPositiveMoment()
            ReviewPromptTracker.appLaunchCount = launches
            ReviewPromptTracker.firstAppOpenDate = firstOpen
            ReviewPromptTracker.lastShownDate = lastShown
            ReviewPromptTracker.outcome = outcome
            ReviewPromptTracker.positiveMomentCount = moments
        }
        ReviewPromptTracker.appLaunchCount = 9
        ReviewPromptTracker.firstAppOpenDate = .now
        ReviewPromptTracker.lastShownDate = nil
        ReviewPromptTracker.outcome = nil
        ReviewPromptTracker.consumePendingPositiveMoment()
        body()
    }

    private func days(_ n: Double) -> Date { Date.now.addingTimeInterval(n * 86_400) }

    @Test func asksFromTheSecondLaunch() {
        withCleanTracker {
            ReviewPromptTracker.appLaunchCount = 2
            #expect(ReviewPromptTracker.canRequestReview(hasCompletedSetup: true))
        }
    }

    @Test func neverAsksInTheFirstSession() {
        withCleanTracker {
            ReviewPromptTracker.appLaunchCount = 1
            #expect(!ReviewPromptTracker.canRequestReview(hasCompletedSetup: true))
        }
    }

    @Test func requiresFinishedSetup() {
        withCleanTracker {
            #expect(!ReviewPromptTracker.canRequestReview(hasCompletedSetup: false))
        }
    }

    @Test func waitsOutTheCooldown() {
        withCleanTracker {
            ReviewPromptTracker.markShown()
            #expect(!ReviewPromptTracker.canRequestReview(hasCompletedSetup: true, now: days(29)))
            #expect(ReviewPromptTracker.canRequestReview(hasCompletedSetup: true, now: days(31)))
        }
    }

    @Test func openingTheReviewPageEndsTheAsks() {
        withCleanTracker {
            ReviewPromptTracker.markOpenedWriteReview()
            #expect(!ReviewPromptTracker.canRequestReview(hasCompletedSetup: true, now: days(400)))
        }
    }

    @Test func feedbackDoesNotStopTheAsks() {
        withCleanTracker {
            ReviewPromptTracker.markFeedbackSubmitted()
            #expect(ReviewPromptTracker.canRequestReview(hasCompletedSetup: true))
        }
    }

    @Test func feedbackAfterTheReviewPageKeepsTheAsksEnded() {
        withCleanTracker {
            ReviewPromptTracker.markOpenedWriteReview()
            ReviewPromptTracker.markFeedbackSubmitted()
            #expect(ReviewPromptTracker.outcome == .openedWriteReview)
            #expect(!ReviewPromptTracker.canRequestReview(hasCompletedSetup: true, now: days(400)))
        }
    }

    @Test func blockedAskKeepsTheMomentPending() {
        withCleanTracker {
            ReviewPromptTracker.recordPositiveMoment()
            #expect(ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: true))
            #expect(ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: true))
            ReviewPromptTracker.markShown()
            #expect(!ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: true))
        }
    }

    /// A good result from this launch asks; a stale one never does.
    @Test func goodResultFromThisLaunchAsks() {
        withCleanTracker {
            ReviewPromptTracker.recordPositiveMoment()
            #expect(ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: true))
        }
    }

    @Test func staleResultNoLongerAsks() {
        withCleanTracker {
            ReviewPromptTracker.recordPositiveMoment()
            #expect(!ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: true, now: days(4)))
        }
    }

    @Test func noResultNoAsk() {
        withCleanTracker {
            #expect(!ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: true))
        }
    }

    /// Launch 1 is blocked even with a good result, launch 2 is allowed.
    @Test func goodResultStillWaitsForTheSecondLaunch() {
        withCleanTracker {
            ReviewPromptTracker.recordPositiveMoment()
            ReviewPromptTracker.appLaunchCount = 1
            #expect(!ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: true))
            ReviewPromptTracker.appLaunchCount = 2
            #expect(ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: true))
        }
    }

    @Test func goodResultNeverAsksInOnboarding() {
        withCleanTracker {
            ReviewPromptTracker.recordPositiveMoment()
            #expect(!ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: false))
        }
    }

    @Test func goodResultHonoursCooldownAndWriteReviewStop() {
        withCleanTracker {
            ReviewPromptTracker.markShown()
            ReviewPromptTracker.recordPositiveMoment()
            #expect(!ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: true, now: days(2)))
        }
        withCleanTracker {
            ReviewPromptTracker.markOpenedWriteReview()
            ReviewPromptTracker.recordPositiveMoment()
            #expect(!ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: true, now: days(2)))
        }
    }
}

/// Which readings count as a good result (the only automatic ask trigger).
@Suite("Review moment")
struct ReviewMomentTests {
    private func good(_ newest: Double, prior: Double, best: Double?, lower: Double = 35, upper: Double = 45) -> Bool {
        ReviewMoment.isGoodResult(newest: newest, priorLatest: prior, priorBest: best, targetLower: lower, targetUpper: upper)
    }

    @Test func newPersonalBestAsks() {
        #expect(good(47, prior: 44, best: 46))
    }

    @Test func enteringTheTargetRangeAsks() {
        #expect(good(36, prior: 33, best: 40))
    }

    @Test func slipOutOfRangeDoesNotAsk() {
        #expect(!good(33, prior: 36, best: 40))
    }

    @Test func lowerReadingInsideRangeDoesNotAsk() {
        #expect(!good(38, prior: 40, best: 41))
    }

    @Test func smallRiseBelowTheBestAndOutsideTheRangeAsks() {
        // The frequent moment: the workout's new estimate is higher than the last.
        #expect(good(46, prior: 44, best: 48, lower: 50, upper: 60))
    }

    @Test func steadyEstimateAsks() {
        #expect(good(40, prior: 40, best: 42))
        #expect(good(39.995, prior: 40, best: 42))
    }

    @Test func anyDropDoesNotAsk() {
        #expect(!good(39.9, prior: 40, best: 42))
        #expect(!good(30, prior: 31, best: 31, lower: 50, upper: 60))
    }

    @Test func holdsOrImprovesRule() {
        #expect(ReviewMoment.holdsOrImproves(newest: 41, priorLatest: 40))
        #expect(ReviewMoment.holdsOrImproves(newest: 40, priorLatest: 40))
        #expect(!ReviewMoment.holdsOrImproves(newest: 39.5, priorLatest: 40))
    }
}

/// The clear-screen check behind the rating ask: any sheet opened below the
/// tab root (a locked-feature paywall on a Today card or pushed detail screen)
/// holds the ask until it closes.
@Suite("Review prompt sheet guard", .serialized)
@MainActor
struct ReviewPromptSheetGuardTests {
    private let coordinator = ReviewPromptCoordinator.shared

    @Test func clearWhenNoSheetIsReported() {
        #expect(coordinator.noSheetIsPresented)
    }

    @Test func detailPaywallBlocksTheAsk() {
        let paywall = UUID()
        coordinator.setSheet(paywall, isPresented: true)
        #expect(!coordinator.noSheetIsPresented)
        coordinator.setSheet(paywall, isPresented: false)
        #expect(coordinator.noSheetIsPresented)
    }

    @Test func staysBlockedUntilEverySheetCloses() {
        let settings = UUID()
        let paywall = UUID()
        coordinator.setSheet(settings, isPresented: true)
        coordinator.setSheet(paywall, isPresented: true)
        coordinator.setSheet(paywall, isPresented: false)
        #expect(!coordinator.noSheetIsPresented)
        coordinator.setSheet(settings, isPresented: false)
        #expect(coordinator.noSheetIsPresented)
    }

    @Test func closingAnUnreportedSheetIsHarmless() {
        coordinator.setSheet(UUID(), isPresented: false)
        #expect(coordinator.noSheetIsPresented)
    }
}
