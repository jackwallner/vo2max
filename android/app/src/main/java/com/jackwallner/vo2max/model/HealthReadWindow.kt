package com.jackwallner.vo2max.model

import java.time.Instant

object HealthReadWindow {
    fun initialStart(now: Instant): Instant = now.daysBack(29)
    fun queryStart(savedStart: Instant?,now: Instant,hasHistory: Boolean): Instant = if(hasHistory)Instant.EPOCH else savedStart ?: initialStart(now)
}
