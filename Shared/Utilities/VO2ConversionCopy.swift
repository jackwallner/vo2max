import Foundation

/// Pure copy helpers for VO2+ conversion CTAs. StoreKit always purchases the
/// same yearly package — trial vs paid is eligibility, not a different product.
/// These helpers keep every pitch surface (trial sheet, paywall, locked rows)
/// honest when the user already used their free trial.
enum VO2ConversionCopy {
    /// Primary button. Deliberately carries no pricing words at all: not the
    /// trial, not the price. Apple 3.1.2(c) weighs pricing elements against each
    /// other, and a bold button reading "Start 7-day free trial" would outshout
    /// the calm price line above it. With a neutral button, the billed amount in
    /// `BilledAmountBlock` is the leading pricing text on the surface.
    ///
    /// The parameters are retained so callers keep passing the real offer, and
    /// so re-introducing price wording here stays a one-line change that is
    /// obviously coupled to the block's sizing.
    static func ctaLabel(trialLabel: String?, priceLabel: String, eligibleForTrial: Bool) -> String {
        "Continue with VO2+"
    }

    /// Short capsule CTA on locked cards. These sit far from any price and only
    /// route to a purchase surface, so they stay neutral for the same reason.
    static func shortCTALabel(eligibleForTrial: Bool) -> String {
        "Continue with VO2+"
    }

    /// Apple 3.1.2(c): the amount the user will actually be billed, phrased as a
    /// commitment rather than a rate ("$29.99 / year" -> "$29.99 per year"). Every
    /// purchase surface renders this as its largest pricing element.
    static func billedAmount(priceLabel: String) -> String {
        priceLabel.replacingOccurrences(of: " / ", with: " per ")
    }

    /// Subordinate line under the billed amount: how long the free trial lasts
    /// when the Apple ID is eligible, otherwise the renewal commitment.
    static func billedNote(trialLabel: String?, eligibleForTrial: Bool) -> String {
        if eligibleForTrial, let trialLabel, !trialLabel.isEmpty {
            return "after your \(trialLabel.lowercased())"
        }
        return "Billed automatically until cancelled"
    }

    /// Apple 3.1.2 disclosure adjacent to the purchase button.
    static func disclosure(
        trialLabel: String?,
        priceLabel: String,
        eligibleForTrial: Bool,
        renewClause: String = "Auto-renews unless cancelled at least 24 hours before the end of the current period. Manage or cancel in Settings › Apple ID › Subscriptions."
    ) -> String {
        if eligibleForTrial, let trialLabel, !trialLabel.isEmpty {
            return "\(trialLabel.capitalized), then \(priceLabel). \(renewClause)"
        }
        return "\(priceLabel). \(renewClause)"
    }

    /// Compact disclosure for the trial offer sheet footer.
    static func sheetDisclosure(trialLabel: String?, priceLabel: String, eligibleForTrial: Bool) -> String {
        if eligibleForTrial, let trialLabel, !trialLabel.isEmpty {
            return "Free during trial, then \(priceLabel). Auto-renews unless cancelled 24h before trial ends."
        }
        return "\(priceLabel). Auto-renews unless cancelled 24h before the period ends."
    }

    /// Cancel / failure copy — never blames a "trial" the user wasn't eligible for.
    static func purchaseCancelledMessage(eligibleForTrial: Bool) -> String {
        eligibleForTrial
            ? "Trial wasn't started. Tap again to continue."
            : "Purchase wasn't completed. Tap again to continue."
    }

    static func purchaseFailedMessage(eligibleForTrial: Bool) -> String {
        eligibleForTrial
            ? "Couldn't start your trial. Please try again."
            : "Couldn't complete the purchase. Please try again."
    }
}
