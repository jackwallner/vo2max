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
        String(localized: "Continue with VO2+")
    }

    /// Short capsule CTA on locked cards. These sit far from any price and only
    /// route to a purchase surface, so they stay neutral for the same reason.
    static func shortCTALabel(eligibleForTrial: Bool) -> String {
        String(localized: "Continue with VO2+")
    }

    /// Apple 3.1.2(c): the amount the user will actually be billed, phrased as a
    /// commitment rather than a rate ("$29.99 / year" -> "$29.99 per year"). Every
    /// purchase surface renders this as its largest pricing element.
    static func billedAmount(priceLabel: String) -> String {
        guard let separator = priceLabel.range(of: " / ") else { return priceLabel }
        let amount = String(priceLabel[..<separator.lowerBound])
        let period = String(priceLabel[separator.upperBound...])
        return switch period {
        case "day": String(localized: "\(amount) per day")
        case "week": String(localized: "\(amount) per week")
        case "month": String(localized: "\(amount) per month")
        case "year": String(localized: "\(amount) per year")
        default: priceLabel
        }
    }

    /// Subordinate line under the billed amount. The trial remains a visible
    /// conversion hook, but the price always leads and receives stronger type.
    static func billedNote(trialLabel: String?, eligibleForTrial: Bool) -> String {
        if eligibleForTrial, let trialLabel, !trialLabel.isEmpty {
            return String(localized: "\(trialLabel). Cancel anytime.")
        }
        return String(localized: "Billed automatically. Cancel anytime.")
    }

    /// Apple 3.1.2 disclosure adjacent to the purchase button.
    static func disclosure(
        trialLabel: String?,
        priceLabel: String,
        eligibleForTrial: Bool
    ) -> String {
        if eligibleForTrial, let trialLabel, !trialLabel.isEmpty {
            return String(localized: "\(priceLabel) is charged after the free trial. It renews automatically unless you cancel at least 24 hours before renewal. Manage or cancel in Settings > Apple ID > Subscriptions.")
        }
        return String(localized: "\(priceLabel) is charged now. It renews automatically unless you cancel at least 24 hours before this period ends. Manage or cancel in Settings > Apple ID > Subscriptions.")
    }

    /// Compact disclosure for the trial offer sheet footer.
    static func sheetDisclosure(trialLabel: String?, priceLabel: String, eligibleForTrial: Bool) -> String {
        if eligibleForTrial, let trialLabel, !trialLabel.isEmpty {
            return String(localized: "\(priceLabel) is charged after the free trial. It renews automatically unless you cancel at least 24 hours before renewal.")
        }
        return String(localized: "\(priceLabel) is charged now. It renews automatically unless you cancel at least 24 hours before this period ends.")
    }

    /// Cancel / failure copy — never blames a "trial" the user wasn't eligible for.
    static func purchaseCancelledMessage(eligibleForTrial: Bool) -> String {
        eligibleForTrial
            ? String(localized: "Trial wasn't started. Tap again to continue.")
            : String(localized: "Purchase wasn't completed. Tap again to continue.")
    }

    static func purchaseFailedMessage(eligibleForTrial: Bool) -> String {
        eligibleForTrial
            ? String(localized: "Couldn't start your trial. Please try again.")
            : String(localized: "Couldn't complete the purchase. Please try again.")
    }
}
