package com.jackwallner.vo2max.model

import java.time.Instant
import java.time.ZoneId
import java.time.ZoneOffset

object DateSelection {
    fun pickerMillis(instant: Instant,zone: ZoneId = ZoneId.systemDefault()): Long = instant.atZone(zone).toLocalDate().atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli()
    fun localStart(millis: Long,zone: ZoneId = ZoneId.systemDefault()): Instant = Instant.ofEpochMilli(millis).atZone(ZoneOffset.UTC).toLocalDate().atStartOfDay(zone).toInstant()
    fun localEnd(millis: Long,zone: ZoneId = ZoneId.systemDefault()): Instant = Instant.ofEpochMilli(millis).atZone(ZoneOffset.UTC).toLocalDate().plusDays(1).atStartOfDay(zone).toInstant().minusMillis(1)
    fun boundedCustom(start: Instant,end: Instant,now: Instant = Instant.now()): CardioRange {
        val last=minOf(maxOf(start,end),now)
        val first=maxOf(minOf(start,end,last),last.daysBack(CardioRange.maximumCustomDays))
        return CardioRange.custom(first,last)
    }
}
