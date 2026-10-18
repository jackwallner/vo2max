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
        let pending = ReviewPromptTracker.hasPendingPositiveMoment
        let seenReading = ReviewPromptTracker.hasSeenReading
        defer {
            ReviewPromptTracker.appLaunchCount = launches
            ReviewPromptTracker.firstAppOpenDate = firstOpen
            ReviewPromptTracker.lastShownDate = lastShown
            ReviewPromptTracker.outcome = outcome
            ReviewPromptTracker.positiveMomentCount = moments
            ReviewPromptTracker.hasPendingPositiveMoment = pending
            ReviewPromptTracker.hasSeenReading = seenReading
        }
        ReviewPromptTracker.appLaunchCount = 9
        ReviewPromptTracker.firstAppOpenDate = .now
        ReviewPromptTracker.lastShownDate = nil
        ReviewPromptTracker.outcome = nil
        ReviewPromptTracker.hasPendingPositiveMoment = false
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

    /// The return-visit moment never fires in the first session, even with an
    /// estimate on screen.
    @Test func returnVisitMomentWaitsForTheSecondLaunch() {
        withCleanTracker {
            ReviewPromptTracker.appLaunchCount = 1
            ReviewPromptTracker.hasSeenReading = true
            #expect(!ReviewPromptTracker.recordReturnWithReading())
            #expect(!ReviewPromptTracker.hasPendingPositiveMoment)
        }
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
