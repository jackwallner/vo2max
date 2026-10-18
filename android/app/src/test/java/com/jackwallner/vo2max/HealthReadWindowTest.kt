package com.jackwallner.vo2max

import java.time.Instant

import com.jackwallner.vo2max.model.HealthReadWindow
import com.jackwallner.vo2max.model.daysBack
import org.junit.Assert.assertEquals
import org.junit.Test

class HealthReadWindowTest {
    private val grant=Instant.parse("2026-06-01T12:00:00Z")
    @Test fun firstReadStaysInsideDefaultGrantWindow() {
        assertEquals(grant.daysBack(29),HealthReadWindow.queryStart(null,grant,false))
    }
    @Test fun historyPermissionReadsFullSourceHistory() {
        assertEquals(Instant.EPOCH,HealthReadWindow.queryStart(grant.daysBack(29),grant,true))
    }
    @Test fun olderAuthorizedRecordsRemainReadableAsTheAppAges() {
        val saved=HealthReadWindow.initialStart(grant)
        val threeMonthsLater=grant.plusSeconds(90L*86400)
        assertEquals(saved,HealthReadWindow.queryStart(saved,threeMonthsLater,false))
    }
}
