package com.jackwallner.vo2max

import java.time.Instant
import java.time.ZoneId

import org.junit.Assert.*
import org.junit.Test

import com.jackwallner.vo2max.model.*

class DateSelectionTest {
    private val zone=ZoneId.of("America/Los_Angeles")
    @Test fun calendarSelectionKeepsLocalDayAcrossUtcBoundary() {
        val reading=Instant.parse("2026-10-18T15:00:00Z")
        val selected=DateSelection.pickerMillis(reading,zone)
        assertEquals(Instant.parse("2026-10-18T00:00:00Z").toEpochMilli(),selected)
        assertEquals(Instant.parse("2026-10-18T07:00:00Z"),DateSelection.localStart(selected,zone))
        assertEquals(Instant.parse("2026-10-19T06:59:59.999Z"),DateSelection.localEnd(selected,zone))
    }
    @Test fun dateEndHandlesDaylightSavingTransition() {
        val selected=Instant.parse("2026-11-01T00:00:00Z").toEpochMilli()
        assertEquals(Instant.parse("2026-11-02T07:59:59.999Z"),DateSelection.localEnd(selected,zone))
    }
    @Test fun customSettingOrdersBothInputsAndCapsFuture() {
        val now=Instant.parse("2026-10-18T15:00:00Z");val earlier=now.minusSeconds(40L*86400)
        val range=DateSelection.boundedCustom(now.plusSeconds(86400),earlier,now)
        assertEquals(earlier,range.start);assertEquals(now,range.end);assertEquals(40,range.days)
    }
    @Test fun customSettingCapsLongSpanAtTwoYears() {
        val now=Instant.parse("2026-10-18T15:00:00Z")
        val range=DateSelection.boundedCustom(now.daysBack(1000),now,now)
        assertEquals(730,range.days);assertEquals(now.daysBack(730),range.start)
    }
    @Test fun eligibleTrialUsesReadableStorePeriod() {
        assertEquals("7-day free trial",ConversionCopy.trialLabel("P7D"));assertEquals("1-month free trial",ConversionCopy.trialLabel("P1M"));assertNull(ConversionCopy.trialLabel("P0D"));assertNull(ConversionCopy.trialLabel("invalid"))
    }
}
