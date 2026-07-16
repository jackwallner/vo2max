import Foundation
import Testing
@testable import VO2Max

struct VO2ConversionCopyTests {
    @Test func ctaUsesTrialOnlyWhenEligible() {
        #expect(
            VO2ConversionCopy.ctaLabel(trialLabel: "7-day free trial", priceLabel: "$14.99 / year", eligibleForTrial: true)
                == "Start 7-day free trial"
        )
        #expect(
            VO2ConversionCopy.ctaLabel(trialLabel: "7-day free trial", priceLabel: "$14.99 / year", eligibleForTrial: false)
                == "Continue with VO2+ for $14.99 / year"
        )
        #expect(
            VO2ConversionCopy.ctaLabel(trialLabel: nil, priceLabel: "", eligibleForTrial: false)
                == "Continue with VO2+"
        )
    }

    @Test func disclosureMentionsTrialOnlyWhenEligible() {
        let eligible = VO2ConversionCopy.disclosure(
            trialLabel: "7-day free trial",
            priceLabel: "$14.99 / year",
            eligibleForTrial: true
        )
        #expect(eligible.hasPrefix("7-Day Free Trial, then $14.99 / year."))

        let ineligible = VO2ConversionCopy.disclosure(
            trialLabel: "7-day free trial",
            priceLabel: "$14.99 / year",
            eligibleForTrial: false
        )
        #expect(ineligible.hasPrefix("$14.99 / year."))
        #expect(!ineligible.lowercased().contains("trial"))
    }

    @Test func failureCopyNeverBlamesIneligibleTrial() {
        #expect(VO2ConversionCopy.purchaseCancelledMessage(eligibleForTrial: false) == "Purchase wasn't completed. Tap again to continue.")
        #expect(VO2ConversionCopy.purchaseFailedMessage(eligibleForTrial: true) == "Couldn't start your trial. Please try again.")
    }
}
