import Foundation
import Testing
@testable import VO2Max

struct VO2ConversionCopyTests {
    /// Apple 3.1.2(c) weighs pricing elements against each other, so no purchase
    /// button may carry trial or price wording that could outrank the billed
    /// amount rendered next to it. This is the regression guard for that.
    @Test func ctaCarriesNoPricingWordsInAnyEligibilityState() {
        let labels = [
            VO2ConversionCopy.ctaLabel(trialLabel: "7-day free trial", priceLabel: "$14.99 / year", eligibleForTrial: true),
            VO2ConversionCopy.ctaLabel(trialLabel: "7-day free trial", priceLabel: "$14.99 / year", eligibleForTrial: false),
            VO2ConversionCopy.ctaLabel(trialLabel: nil, priceLabel: "", eligibleForTrial: false),
            VO2ConversionCopy.shortCTALabel(eligibleForTrial: true),
            VO2ConversionCopy.shortCTALabel(eligibleForTrial: false),
        ]
        for label in labels {
            #expect(label == "Continue with VO2+")
            #expect(!label.lowercased().contains("trial"))
            #expect(!label.lowercased().contains("free"))
            #expect(!label.contains("$"))
        }
    }

    /// The billed amount leads the price line and the trial length trails it.
    @Test func billedAmountLeadsAndTrialTrails() {
        #expect(VO2ConversionCopy.billedAmount(priceLabel: "$14.99 / year") == "$14.99 per year")
        #expect(
            VO2ConversionCopy.billedNote(trialLabel: "7-day free trial", eligibleForTrial: true)
                == "after your 7-day free trial"
        )
        // Never promise a trial the Apple ID can't get.
        #expect(
            VO2ConversionCopy.billedNote(trialLabel: "7-day free trial", eligibleForTrial: false)
                == "Billed automatically until cancelled"
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
