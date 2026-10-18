package com.jackwallner.vo2max

import com.jackwallner.vo2max.data.Settings
import com.jackwallner.vo2max.model.MetricRange
import org.junit.Assert.assertEquals
import org.junit.Test

class SettingsDefaultsTest {
    @Test fun absentPreferenceStartsWithNinetyDays() {
        assertEquals(MetricRange.quarter,Settings(MemoryValues()).selection)
    }
    @Test fun anExplicitZeroRestoresACustomRange() {
        val values=MemoryValues().apply{put("cardioMetricRangeDays","0")}
        assertEquals(MetricRange.custom,Settings(values).selection)
    }
}
