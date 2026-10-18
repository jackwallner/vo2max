package com.jackwallner.vo2max

import org.junit.Assert.*
import org.junit.Test

import com.jackwallner.vo2max.model.*

class MemoryValues : Values {
    private val map = mutableMapOf<String,String>()
    override fun string(key: String) = map[key]
    override fun put(key: String,value: String) { map[key]=value }
    override fun entries() = map.toMap()
}
class FunnelTest {
    private val now=1_760_000_000_000L
    private val values=MemoryValues()
    private val diagnostics=ConversionDiagnostics(values){now}
    private val review=ReviewTracker(values){now}.also{it.appLaunchCount=9}
    private fun attributes()=diagnostics.subscriberAttributes
    @Test fun countsPitchesPerSurfaceAndInTotal() { diagnostics.recordPitchView("vo2plus_tab");diagnostics.recordPitchView("vo2plus_tab");diagnostics.recordPitchView("vo2plus_onboarding_trial");assertEquals("3",attributes()["pitch_views_total"]);assertEquals("2",attributes()["pitch_views_tab"]);assertEquals("onboarding_trial",attributes()["pitch_last"]) }
    @Test fun noAttributesBeforeAnyPitchIsSeen() { diagnostics.recordAppOpen();assertTrue(attributes().isEmpty()) }
    @Test fun recordsHowEarlyTheFirstPitchArrived() { repeat(2){diagnostics.recordAppOpen()};diagnostics.recordPitchView("vo2plus_tab");assertEquals("2",attributes()["opens_before_first_pitch"]);assertEquals("0",attributes()["days_since_install"]) }
    @Test fun theEarlinessPairIsFrozenOnTheFirstPitchOnly() { diagnostics.recordAppOpen();diagnostics.recordPitchView("vo2plus_tab");diagnostics.recordAppOpen();diagnostics.recordPitchView("vo2plus_onboarding_trial");assertEquals("1",attributes()["opens_before_first_pitch"]) }
    @Test fun anInstallThatPredatesThisCodeReportsNoAge() { diagnostics.recordPitchView("vo2plus_tab");assertNull(attributes()["days_since_install"]);assertEquals("1",attributes()["pitch_views_total"]) }
    @Test fun conversionFreezesTheSurfaceAndCountAtTheMomentOfSale() { diagnostics.recordPitchView("vo2plus_tab");diagnostics.recordPitchView("vo2plus_onboarding_trial");diagnostics.recordConversion("yearly",true,"default");diagnostics.recordPitchView("vo2plus_tab");assertEquals("onboarding_trial",attributes()["converted_surface"]);assertEquals("2",attributes()["pitch_views_at_convert"]);assertEquals("true",attributes()["converted_with_trial"]);assertEquals("default",attributes()["converted_offering"]) }
    @Test fun onlyTheFirstConversionIsRecorded() { diagnostics.recordPitchView("vo2plus_tab");diagnostics.recordConversion("monthly",true);diagnostics.recordConversion("yearly",false);assertEquals("monthly",attributes()["converted_plan"]);assertEquals("true",attributes()["converted_with_trial"]) }
    @Test fun attributeKeysStayInsideRevenueCatsLimit() { diagnostics.recordPitchView("vo2plus_"+"a".repeat(80));assertTrue(attributes().keys.all{it.length<=40}) }
    @Test fun noAttributeCarriesFreeTextOrHealthData() { diagnostics.recordAppOpen();diagnostics.recordPitchView("vo2plus_tab");diagnostics.recordConversion("monthly",false);assertTrue(attributes().values.all{!it.contains(" ")&&it.length<=64}) }
    @Test fun ctaCarriesNoPricingWordsInAnyEligibilityState() { assertEquals("Continue with VO2+",ConversionCopy.ctaLabel) }
    @Test fun billedAmountLeadsAndTrialTrails() { assertEquals("$14.99 per year",ConversionCopy.billedAmount("$14.99 / year"));assertEquals("7-day free trial included · Cancel anytime",ConversionCopy.billedNote("7-day free trial",true));assertEquals("Billed automatically · Cancel anytime",ConversionCopy.billedNote("7-day free trial",false)) }
    @Test fun disclosureMentionsTrialOnlyWhenEligible() { assertTrue(ConversionCopy.disclosure("7-day free trial","$14.99 / year",true).startsWith("$14.99 / year after the 7-day free trial."));val d=ConversionCopy.disclosure("7-day free trial","$14.99 / year",false);assertTrue(d.startsWith("$14.99 / year."));assertFalse(d.contains("trial")) }
    @Test fun sheetDisclosureLeadsWithPrice() { assertTrue(ConversionCopy.disclosure("7-day free trial","$14.99 / year",true).startsWith("$14.99")) }
    @Test fun failureCopyNeverBlamesIneligibleTrial() { assertEquals("Purchase wasn't completed. Tap again to continue.",ConversionCopy.purchaseCancelledMessage(false));assertEquals("Couldn't start your trial. Please try again.",ConversionCopy.purchaseFailedMessage(true)) }
    @Test fun asksFromTheSecondLaunch() { review.appLaunchCount=2;assertTrue(review.canRequestReview(true)) }
    @Test fun neverAsksInTheFirstSession() { review.appLaunchCount=1;assertFalse(review.canRequestReview(true)) }
    @Test fun requiresFinishedSetup() { assertFalse(review.canRequestReview(false)) }
    @Test fun waitsOutTheCooldown() { review.markShown();assertFalse(review.canRequestReview(true,now+29L*86_400_000));assertTrue(review.canRequestReview(true,now+31L*86_400_000)) }
    @Test fun openingTheReviewPageEndsTheAsks() { review.markOpenedWriteReview();assertFalse(review.canRequestReview(true,now+400L*86_400_000)) }
    @Test fun feedbackDoesNotStopTheAsks() { review.markFeedbackSubmitted();assertTrue(review.canRequestReview(true)) }
    @Test fun feedbackAfterTheReviewPageKeepsTheAsksEnded() { review.markOpenedWriteReview();review.markFeedbackSubmitted();assertEquals("openedWriteReview",review.outcome);assertFalse(review.canRequestReview(true,now+400L*86_400_000)) }
    @Test fun blockedAskKeepsTheMomentPending() { review.recordPositiveMoment();assertTrue(review.shouldRequestAfterPositiveMoment(true));assertTrue(review.shouldRequestAfterPositiveMoment(true));review.markShown();assertFalse(review.shouldRequestAfterPositiveMoment(true)) }
    @Test fun returnVisitMomentWaitsForTheSecondLaunch() { review.appLaunchCount=1;review.hasSeenReading=true;assertFalse(review.recordReturnWithReading());assertFalse(review.hasPendingPositiveMoment) }
    @Test fun clearWhenNoSheetIsReported() { assertTrue(ReviewSheetGuard().noSheetIsPresented) }
    @Test fun detailPaywallBlocksTheAsk() { val guard=ReviewSheetGuard();guard.setSheet("paywall",true);assertFalse(guard.noSheetIsPresented);guard.setSheet("paywall",false);assertTrue(guard.noSheetIsPresented) }
    @Test fun staysBlockedUntilEverySheetCloses() { val guard=ReviewSheetGuard();guard.setSheet("settings",true);guard.setSheet("paywall",true);guard.setSheet("paywall",false);assertFalse(guard.noSheetIsPresented);guard.setSheet("settings",false);assertTrue(guard.noSheetIsPresented) }
    @Test fun closingAnUnreportedSheetIsHarmless() { val guard=ReviewSheetGuard();guard.setSheet("unknown",false);assertTrue(guard.noSheetIsPresented) }
}
