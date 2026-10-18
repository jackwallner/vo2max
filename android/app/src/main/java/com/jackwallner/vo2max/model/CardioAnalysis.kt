package com.jackwallner.vo2max.model

import java.time.Instant
import java.time.ZoneId
import java.time.temporal.ChronoUnit
import kotlin.math.ceil
import kotlin.math.roundToInt

fun Instant.daysBack(days: Int): Instant = atZone(ZoneId.systemDefault()).minusDays(days.toLong()).toInstant()
fun dayGap(start: Instant, end: Instant): Int = ChronoUnit.DAYS.between(start.atZone(ZoneId.systemDefault()), end.atZone(ZoneId.systemDefault())).toInt()
data class Point(val date: Instant, val value: Double, val id: String = "", val source: String = "Health Connect")
enum class Trend(val label: String) { improving("Improving"), stable("Stable"), declining("Declining"), insufficientData("Building trend") }
enum class TargetStatus(val label: String) { below("Below target"), inRange("In target range"), above("Above target") }
enum class ReferenceSex(val label: String) { unspecified("Not set"), female("Female reference"), male("Male reference") }
enum class MetricRange(val days: Int, val label: String, val phrase: String, val priorPhrase: String) {
    month(30, "30D", "last 30 days", "prior 30 days"), quarter(90, "90D", "last 90 days", "prior 90 days"),
    halfYear(180, "6M", "last 6 months", "prior 6 months"), year(365, "1Y", "last 12 months", "prior 12 months"),
    custom(0, "Custom", "selected range", "matching range before it");
    val fixedDays get() = days.takeIf { this != custom }
    val weeks get() = maxOf(days / 7, 4)
}
data class CardioRange(val selection: MetricRange, val start: Instant, val end: Instant, val days: Int) {
    val weeks get() = maxOf(days / 7, 4)
    val chartWeeks get() = if (selection == MetricRange.custom) maxOf(ceil(days / 7.0).toInt(), 1) else weeks
    val spanLabel get() = "${start.atZone(ZoneId.systemDefault()).format(java.time.format.DateTimeFormatter.ofPattern("MMM d"))} – ${end.atZone(ZoneId.systemDefault()).format(java.time.format.DateTimeFormatter.ofPattern("MMM d, yyyy"))}"
    fun priorSpanLabel() = CardioRange(selection, end.daysBack(days * 2), end.daysBack(days), days).spanLabel
    val priorPhrase get() = if (selection == MetricRange.custom) "previous $days ${if (days == 1) "day" else "days"}" else selection.priorPhrase
    fun contains(date: Instant) = date >= start && date <= end
    companion object {
        const val maximumCustomDays = 730
        fun fixed(selection: MetricRange, now: Instant = Instant.now()): CardioRange {
            val days = selection.fixedDays ?: 90
            return CardioRange(selection, now.daysBack(days), now, days)
        }
        fun trailing(days: Int, now: Instant = Instant.now()): CardioRange {
            val count = maxOf(days, 1)
            return CardioRange(MetricRange.entries.find { it.days == count } ?: MetricRange.custom, now.daysBack(count), now, count)
        }
        fun custom(start: Instant, end: Instant): CardioRange {
            val first = minOf(start, end); val last = maxOf(start, end)
            return CardioRange(MetricRange.custom, first, last, maxOf(dayGap(first, last), 1))
        }
    }
}
data class MetricSummary(val latest: Double, val latestDate: Instant, val average: Double, val minimum: Double, val maximum: Double, val count: Int, val previousAverage: Double?) {
    val change get() = previousAverage?.let { average - it }
}
data class MonthlyAverage(val monthStart: Instant, val average: Double, val count: Int)
data class PeriodComparison(val days: Int, val currentAverage: Double, val previousAverage: Double?, val currentCount: Int, val previousCount: Int) {
    val change get() = previousAverage?.let { currentAverage - it }
}
data class Projection(val slopePerMonth: Double, val monthsToTarget: Int?, val sampleCount: Int)
enum class HeartMetric(val title: String, val lowerIsBetter: Boolean) { restingHeartRate("Resting Heart Rate", true), heartRateRecovery("Heart Rate Recovery", false) }

object FitnessAnalysis {
    fun periodComparison(points: List<Point>, days: Int, now: Instant = Instant.now()): PeriodComparison? {
        val start = now.daysBack(days); val previousStart = now.daysBack(days * 2)
        val current = points.filter { it.date >= start && it.date <= now }
        val prior = points.filter { it.date >= previousStart && it.date < start }
        if (current.isEmpty()) return null
        return PeriodComparison(days, current.map { it.value }.average(), prior.map { it.value }.averageOrNull(), current.size, prior.size)
    }
    fun projection(points: List<Point>, targetLower: Double, now: Instant = Instant.now()): Projection? {
        val recent = points.filter { it.date >= now.daysBack(180) }.sortedBy { it.date }
        if (recent.size < 5) return null
        val xs = recent.map { (it.date.toEpochMilli() - recent.first().date.toEpochMilli()) / 86_400_000.0 }
        val ys = recent.map { it.value }; val n = recent.size.toDouble()
        val denominator = n * xs.sumOf { it * it } - xs.sum() * xs.sum()
        if (denominator == 0.0) return null
        val slope = (n * xs.zip(ys).sumOf { it.first * it.second } - xs.sum() * ys.sum()) / denominator * 30
        val gap = targetLower - recent.last().value
        val months = if (gap > 0 && slope > 0.05) ceil(gap / slope).toInt().takeIf { it <= 24 }?.coerceAtLeast(1) else null
        return Projection(slope, months, recent.size)
    }
    fun personalBest(points: List<Point>) = points.maxByOrNull { it.value }
    fun trend(points: List<Point>, now: Instant = Instant.now()): Trend {
        val recent = points.filter { it.date >= now.daysBack(90) }.sortedBy { it.date }
        if (recent.size < 4) return Trend.insufficientData
        val older = recent.take(recent.size / 2).map { it.value }.average()
        val newer = recent.drop(recent.size / 2).map { it.value }.average()
        val threshold = maxOf(0.5, older * 0.02)
        return when { newer - older > threshold -> Trend.improving; newer - older < -threshold -> Trend.declining; else -> Trend.stable }
    }
    fun targetStatus(value: Double, lower: Double, upper: Double) = when { value < lower -> TargetStatus.below; value > upper -> TargetStatus.above; else -> TargetStatus.inRange }
    fun change(points: List<Point>, days: Int, now: Instant = Instant.now()): Double? {
        val sorted = points.sortedBy { it.date }
        val latest = sorted.lastOrNull { it.date <= now } ?: return null
        val baseline = sorted.firstOrNull { it.date >= now.daysBack(days) } ?: return null
        return (latest.value - baseline.value).takeIf { baseline.date < latest.date }
    }
    private fun references(sex: ReferenceSex): List<Double>? = when (sex) {
        ReferenceSex.female -> listOf(41.0, 38.0, 35.0, 31.0, 27.0, 24.0)
        ReferenceSex.male -> listOf(49.0, 46.0, 42.0, 38.0, 34.0, 30.0)
        else -> null
    }
    fun referenceValue(age: Int, sex: ReferenceSex): Double? {
        val values = references(sex) ?: return null
        val clamped = age.coerceIn(20, 70); val index = minOf((clamped - 20) / 10, 4)
        return values[index] + ((clamped - 20) / 10.0 - index) * (values[index + 1] - values[index])
    }
    fun typicalRange(age: Int, sex: ReferenceSex): ClosedFloatingPointRange<Double> {
        val refs = if (sex == ReferenceSex.unspecified) listOf(referenceValue(age, ReferenceSex.female)!!, referenceValue(age, ReferenceSex.male)!!) else listOf(referenceValue(age, sex)!!)
        return refs.min() * 0.85..refs.max() * 1.15
    }
    fun fitnessBand(value: Double, age: Int, sex: ReferenceSex): String? {
        val ratio = value / (referenceValue(age, sex) ?: return null)
        return when { ratio < 0.85 -> "Below typical range"; ratio < 1 -> "Around typical range"; ratio < 1.15 -> "Above typical range"; else -> "Well above typical range" }
    }
    fun estimatedFitnessAge(value: Double, sex: ReferenceSex): Int? {
        val values = references(sex) ?: return null
        if (value >= values.first()) return 20
        if (value <= values.last()) return 70
        for (i in 0..4) if (value <= values[i] && value >= values[i + 1]) return (20 + i * 10 + (values[i] - value) / (values[i] - values[i + 1]) * 10).roundToInt()
        return null
    }
}
object MetricAnalysis {
    fun summarize(points: List<Point>, days: Int, now: Instant = Instant.now()): MetricSummary? {
        if (days <= 0) return null
        val start = now.daysBack(days)
        val window = points.filter { it.date >= start && it.date <= now }
        val latest = window.maxByOrNull { it.date } ?: return null
        val values = window.map { it.value }
        val previous = points.filter { it.date >= now.daysBack(days * 2) && it.date < start }.map { it.value }.averageOrNull()
        return MetricSummary(latest.value, latest.date, values.average(), values.min(), values.max(), values.size, previous)
    }
    fun monthlyAverages(points: List<Point>, days: Int, now: Instant = Instant.now()): List<MonthlyAverage> {
        if (days <= 0) return emptyList()
        return points.filter { it.date >= now.daysBack(days) && it.date <= now }.groupBy {
            it.date.atZone(ZoneId.systemDefault()).withDayOfMonth(1).toLocalDate().atStartOfDay(ZoneId.systemDefault()).toInstant()
        }.map { (date, samples) -> MonthlyAverage(date, samples.map { it.value }.average(), samples.size) }.sortedByDescending { it.monthStart }
    }
    fun downsample(points: List<Point>, limit: Int = 180): List<Point> {
        if (limit <= 0 || points.size <= limit) return points
        val step = ceil(points.size.toDouble() / limit).toInt(); val sorted = points.sortedBy { it.date }
        val thin = sorted.filterIndexed { index, _ -> index % step == 0 }.toMutableList()
        if (thin.last().date != sorted.last().date) thin.add(sorted.last())
        return thin
    }
}
fun List<Double>.averageOrNull(): Double? = if (isEmpty()) null else average()
