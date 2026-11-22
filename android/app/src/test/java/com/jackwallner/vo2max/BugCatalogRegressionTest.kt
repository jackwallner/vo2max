package com.jackwallner.vo2max

import java.time.Instant
import java.time.ZoneId
import java.util.Locale
import java.util.TimeZone

import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

import com.revenuecat.purchases.PurchasesErrorCode

import com.jackwallner.vo2max.data.PurchaseOutcome
import com.jackwallner.vo2max.model.*

/** Android side of the 2026-11-20 iOS bug catalog (project-docs/audits/2026-11-21-android-bug-port.md). */
class BugCatalogRegressionTest {
    private val zone = ZoneId.of("America/Los_Angeles")
    private val saved = TimeZone.getDefault()
    private fun at(text: String) = java.time.LocalDateTime.parse(text).atZone(zone).toInstant()
    private fun millis(day: String) = Instant.parse("${day}T00:00:00Z").toEpochMilli()
    @Before fun calendar() { TimeZone.setDefault(TimeZone.getTimeZone(zone)); Locale.setDefault(Locale.US) }
    @After fun restore() { TimeZone.setDefault(saved) }

    // B4: a purchase waiting for payment or approval is pending, never a failure.
    @Test fun b4_pendingPurchaseIsPending() {
        assertEquals(PurchaseOutcome.PENDING, PurchaseOutcome.forFailure(false, PurchasesErrorCode.PaymentPendingError))
        assertEquals(PurchaseOutcome.CANCELLED, PurchaseOutcome.forFailure(true, PurchasesErrorCode.PurchaseCancelledError))
        assertEquals(PurchaseOutcome.CANCELLED, PurchaseOutcome.forFailure(false, PurchasesErrorCode.PurchaseCancelledError))
        assertNull(PurchaseOutcome.forFailure(false, PurchasesErrorCode.NetworkError))
        assertNull(PurchaseOutcome.forFailure(false, PurchasesErrorCode.StoreProblemError))
    }
}
