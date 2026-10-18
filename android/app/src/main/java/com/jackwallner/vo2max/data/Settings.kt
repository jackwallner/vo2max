package com.jackwallner.vo2max.data

import android.content.Context
import java.time.Instant

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

import com.jackwallner.vo2max.model.*

class Preferences(context: Context) : Values {
    private val prefs = context.getSharedPreferences("vo2max",Context.MODE_PRIVATE)
    override fun string(key: String) = prefs.getString(key,null)
    override fun put(key: String,value: String) { prefs.edit().putString(key,value).apply() }
    override fun entries() = prefs.all.mapValues { it.value.toString() }
    fun clear() { prefs.edit().clear().commit() }
}
class Settings(val values: Values) {
    var revision by mutableIntStateOf(0); private set
    var hasCompletedSetup by mutableStateOf(values.bool("hasCompletedSetup")); private set
    var appearance by mutableStateOf(values.string("appearance") ?: "System"); private set
    var lower by mutableStateOf(values.string("targetLower")?.toDoubleOrNull() ?: 35.0); private set
    var upper by mutableStateOf(values.string("targetUpper")?.toDoubleOrNull() ?: 45.0); private set
    var age by mutableIntStateOf(values.int("chronologicalAge").takeIf { it>0 } ?: 35); private set
    var sex by mutableStateOf(ReferenceSex.entries.getOrElse(values.int("referenceSex")){ReferenceSex.unspecified}); private set
    var selection by mutableStateOf(values.string("cardioMetricRangeDays")?.toIntOrNull()?.let { days->MetricRange.entries.find { it.days==days } } ?: MetricRange.quarter); private set
    private fun save(key: String,value: Any) { values.put(key,value.toString());revision++ }
    fun completeSetup() { hasCompletedSetup=true;save("hasCompletedSetup",true) }
    fun updateAppearance(value: String) { appearance=value;save("appearance",value) }
    fun updateAge(value: Int) { age=value.coerceIn(18,100);save("chronologicalAge",age) }
    fun updateSex(value: ReferenceSex) { sex=value;save("referenceSex",value.ordinal) }
    fun updateLower(value: Double) { lower=value.coerceIn(10.0,89.0);if(lower>=upper)upper=lower+1;saveTargets() }
    fun updateUpper(value: Double) { upper=value.coerceIn(11.0,90.0);if(upper<=lower)lower=upper-1;saveTargets() }
    private fun saveTargets() { save("targetLower",lower);save("targetUpper",upper) }
    fun enabled(key: String, default: Boolean = true): Boolean { revision;return values.string(key)?.toBooleanStrictOrNull() ?: default }
    fun setEnabled(key: String,value: Boolean) = save(key,value)
    fun select(value: MetricRange) { selection=value;save("cardioMetricRangeDays",value.days) }
    fun custom(start: Instant,end: Instant,now: Instant = Instant.now()) {
        val range=DateSelection.boundedCustom(start,end,now)
        save("cardioMetricCustomStart",range.start.epochSecond);save("cardioMetricCustomEnd",range.end.epochSecond);select(MetricRange.custom)
    }
    fun range(): CardioRange = if(selection!=MetricRange.custom) CardioRange.fixed(selection) else CardioRange.custom(
        Instant.ofEpochSecond(values.long("cardioMetricCustomStart") ?: Instant.now().daysBack(90).epochSecond),
        Instant.ofEpochSecond(values.long("cardioMetricCustomEnd") ?: Instant.now().epochSecond))
}
