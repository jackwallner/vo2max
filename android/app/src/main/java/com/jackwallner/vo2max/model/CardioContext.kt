package com.jackwallner.vo2max.model

import java.time.DayOfWeek
import java.time.Instant
import java.time.ZoneId
import java.time.temporal.TemporalAdjusters
import kotlin.math.roundToInt

enum class ActivityKind(val label: String) {
    walk("Walking"), run("Running"), hike("Hiking"), cycle("Cycling"), swim("Swimming"), elliptical("Elliptical"), rowing("Rowing"), intervals("Intervals");
    val canRefreshEstimate get() = this in setOf(walk, run, hike)
}
data class Workout(val id: String, val date: Instant, val kind: ActivityKind, val minutes: Double, val isIndoor: Boolean = false) {
    // Keep the iOS comparison group. Unmarked Android sessions are not guaranteed to be outdoors.
    val refreshesEstimate get() = kind.canRefreshEstimate && !isIndoor
}
data class TrainingWindow(val start: Instant, val end: Instant, val change: Double, val minutesPerWeek: Double, val sessionsPerWeek: Double) {
    val isRising get() = change > 0.1
}
data class DriverSummary(val risingCount: Int, val otherCount: Int, val risingMinutesPerWeek: Double, val otherMinutesPerWeek: Double, val risingSessionsPerWeek: Double, val otherSessionsPerWeek: Double) {
    val minutesDifference get() = risingMinutesPerWeek - otherMinutesPerWeek
    val windowCount get() = risingCount + otherCount
}
data class ActivityTotal(val kind: ActivityKind, val minutes: Double, val sessions: Int)
data class LoadSummary(val minutesPerWeek: Double, val sessionsPerWeek: Double, val qualifyingMinutesPerWeek: Double, val totalMinutes: Double, val sessions: Int, val previousMinutesPerWeek: Double?) {
    val change get() = previousMinutesPerWeek?.let { minutesPerWeek - it }
}
data class WeeklyLoad(val weekStart: Instant, val minutes: Double, val qualifyingMinutes: Double)
object DriverAnalysis {
    const val minimumWindowDays = 3
    const val maximumWindowDays = 60
    const val minimumWindows = 6
    const val minimumPerBucket = 2
    fun windows(points: List<Point>, workouts: List<Workout>): List<TrainingWindow> = points.sortedBy { it.date }.zipWithNext().mapNotNull { (earlier, later) ->
        val days = (later.date.toEpochMilli() - earlier.date.toEpochMilli()) / 86_400_000.0
        if (days < minimumWindowDays || days > maximumWindowDays) return@mapNotNull null
        val selected = workouts.filter { it.date > earlier.date && it.date <= later.date }
        TrainingWindow(earlier.date, later.date, later.value - earlier.value, selected.sumOf { it.minutes } / (days / 7), selected.size / (days / 7))
    }
    fun summary(windows: List<TrainingWindow>): DriverSummary? {
        if (windows.size < minimumWindows) return null
        val rising = windows.filter { it.isRising }; val other = windows.filter { !it.isRising }
        if (rising.size < minimumPerBucket || other.size < minimumPerBucket) return null
        return DriverSummary(rising.size, other.size, rising.map { it.minutesPerWeek }.average(), other.map { it.minutesPerWeek }.average(), rising.map { it.sessionsPerWeek }.average(), other.map { it.sessionsPerWeek }.average())
    }
    fun headline(summary: DriverSummary): String {
        val rising = summary.risingMinutesPerWeek.roundToInt(); val other = summary.otherMinutesPerWeek.roundToInt()
        return when {
            summary.minutesDifference >= 10 -> "In the stretches where your estimate rose, you averaged $rising min/week of cardio versus $other in the stretches where it didn't."
            summary.minutesDifference <= -10 -> "Your estimate rose on $rising min/week of cardio and stalled on $other. More volume alone hasn't been what moved it."
            else -> "Your training volume looks similar whether the estimate rose ($rising min/week) or not ($other min/week)."
        }
    }
    fun activityTotals(workouts: List<Workout>, days: Int, now: Instant = Instant.now()) = workouts.filter { it.date >= now.daysBack(days) }.groupBy { it.kind }
        .map { (kind, entries) -> ActivityTotal(kind, entries.sumOf { it.minutes }, entries.size) }.sortedByDescending { it.minutes }
    fun loadSummary(workouts: List<Workout>, days: Int, now: Instant = Instant.now()): LoadSummary? {
        if (days <= 0) return null
        val start = now.daysBack(days); val selected = workouts.filter { it.date >= start && it.date <= now }
        if (selected.isEmpty()) return null
        val prior = workouts.filter { it.date >= now.daysBack(days * 2) && it.date < start }
        val weeks = days / 7.0; val total = selected.sumOf { it.minutes }
        return LoadSummary(total / weeks, selected.size / weeks, selected.filter { it.refreshesEstimate }.sumOf { it.minutes } / weeks, total, selected.size, if (prior.isEmpty()) null else prior.sumOf { it.minutes } / weeks)
    }
    fun weeklyLoad(workouts: List<Workout>, weeks: Int, now: Instant = Instant.now()): List<WeeklyLoad> {
        if (weeks <= 0) return emptyList()
        val localeFirstDay = java.time.temporal.WeekFields.of(java.util.Locale.getDefault()).firstDayOfWeek
        val start = now.atZone(ZoneId.systemDefault()).toLocalDate().with(TemporalAdjusters.previousOrSame(localeFirstDay))
        return (weeks - 1 downTo 0).map { offset ->
            val date = start.minusWeeks(offset.toLong()).atStartOfDay(ZoneId.systemDefault()).toInstant()
            val end = start.minusWeeks(offset.toLong() - 1).atStartOfDay(ZoneId.systemDefault()).toInstant()
            val selected = workouts.filter { it.date >= date && it.date < end }
            WeeklyLoad(date, selected.sumOf { it.minutes }, selected.filter { it.refreshesEstimate }.sumOf { it.minutes })
        }
    }
}
enum class FreshnessState { noReadings, fresh, aging, stale }
data class Freshness(val state: FreshnessState, val daysSinceLatest: Int?, val typicalGapDays: Int?) {
    val isStale get() = state == FreshnessState.stale
    val headline get() = when(state) { FreshnessState.noReadings -> "No estimate yet"; FreshnessState.fresh -> "Estimate is current"; FreshnessState.aging -> "Estimate is getting old"; FreshnessState.stale -> "Time to refresh your estimate" }
    val detail get(): String {
        val days = daysSinceLatest ?: return "No VO2 max estimate has been read from Health Connect. ${FreshnessAnalysis.refreshInstruction}"
        val cadence = typicalGapDays?.let { " You usually get one about every $it days." }.orEmpty()
        val action = if (state == FreshnessState.aging || state == FreshnessState.stale) " ${FreshnessAnalysis.refreshInstruction}" else ""
        return "Your last estimate landed ${FreshnessAnalysis.dayPhrase(days)}.$cadence$action"
    }
}
object FreshnessAnalysis {
    const val defaultGapDays = 10
    const val minimumGapDays = 5
    const val maximumGapDays = 30
    const val refreshInstruction = "Check that your compatible fitness app or wearable shares VO2 max with Health Connect. Recording requirements depend on that source."
    fun assess(points: List<Point>, now: Instant = Instant.now()): Freshness {
        val latest = points.maxByOrNull { it.date } ?: return Freshness(FreshnessState.noReadings, null, null)
        val days = maxOf(dayGap(latest.date, now), 0); val typical = typicalGapDays(points, now); val reference = typical ?: defaultGapDays
        val state = when { days <= reference -> FreshnessState.fresh; days <= reference * 2 -> FreshnessState.aging; else -> FreshnessState.stale }
        return Freshness(state, days, typical)
    }
    fun typicalGapDays(points: List<Point>, now: Instant = Instant.now()): Int? {
        val recent = points.filter { it.date >= now.daysBack(365) }.sortedBy { it.date }
        if (recent.size < 4) return null
        val gaps = recent.zipWithNext().map { (a,b) -> (b.date.toEpochMilli() - a.date.toEpochMilli()) / 86_400_000.0 }.sorted()
        val median = if (gaps.size % 2 == 0) (gaps[gaps.size / 2 - 1] + gaps[gaps.size / 2]) / 2 else gaps[gaps.size / 2]
        return median.roundToInt().coerceIn(minimumGapDays, maximumGapDays)
    }
    fun dayPhrase(days: Int) = when { days < 1 -> "today"; days == 1 -> "yesterday"; else -> "$days days ago" }
}
