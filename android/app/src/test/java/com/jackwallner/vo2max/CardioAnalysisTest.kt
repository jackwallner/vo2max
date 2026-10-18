package com.jackwallner.vo2max

import java.time.Instant
import java.util.Locale
import java.util.TimeZone

import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

import com.jackwallner.vo2max.model.*

class CardioAnalysisTest {
    private val now = Instant.ofEpochSecond(1_760_000_000)
    private fun points(vararg values: Double) = values.mapIndexed { i, value -> Point(now.daysBack(40 - i * 10), value) }
    private fun dated(vararg entries: Pair<Int, Double>) = entries.map { (days, value) -> Point(now.daysBack(days), value) }
    private fun work(day: Int, kind: ActivityKind = ActivityKind.run, minutes: Double = 60.0, indoor: Boolean = false) = Workout("$day-$kind", now.daysBack(day), kind, minutes, indoor)
    private fun window(change: Double, minutes: Double = 100.0) = TrainingWindow(now.daysBack(30), now.daysBack(16), change, minutes, 3.0)
    private fun near(expected: Double, actual: Double?) = assertEquals(expected, actual ?: Double.NaN, 0.001)
    @Before fun calendar() { TimeZone.setDefault(TimeZone.getTimeZone("UTC")); Locale.setDefault(Locale.US) }
    @Test fun improvingTrendUsesRecentHalfComparison() { assertEquals(Trend.improving, FitnessAnalysis.trend(points(35.0,35.2,38.0,38.4),now)) }
    @Test fun smallChangesAreStable() { assertEquals(Trend.stable,FitnessAnalysis.trend(points(40.0,40.1,40.2,40.3),now)) }
    @Test fun fewerThanFourReadingsBuildsTrend() { assertEquals(Trend.insufficientData,FitnessAnalysis.trend(points(40.0,41.0,42.0),now)) }
    @Test fun targetRangeIncludesBounds() { assertEquals(TargetStatus.inRange,FitnessAnalysis.targetStatus(35.0,35.0,45.0)); assertEquals(TargetStatus.inRange,FitnessAnalysis.targetStatus(45.0,35.0,45.0)); assertEquals(TargetStatus.below,FitnessAnalysis.targetStatus(34.9,35.0,45.0)); assertEquals(TargetStatus.above,FitnessAnalysis.targetStatus(45.1,35.0,45.0)) }
    @Test fun fitnessAgeRequiresReferenceSex() { assertNull(FitnessAnalysis.estimatedFitnessAge(40.0,ReferenceSex.unspecified)); assertEquals(40,FitnessAnalysis.estimatedFitnessAge(42.0,ReferenceSex.male)); assertEquals(40,FitnessAnalysis.estimatedFitnessAge(35.0,ReferenceSex.female)) }
    @Test fun typicalRangeUsesAgeReference() { val r=FitnessAnalysis.typicalRange(40,ReferenceSex.male);near(35.7,r.start);near(48.3,r.endInclusive) }
    @Test fun typicalRangeUsesBroadEnvelopeWithoutReferenceSex() { val r=FitnessAnalysis.typicalRange(40,ReferenceSex.unspecified);near(29.75,r.start);near(48.3,r.endInclusive) }
    @Test fun typicalRangeClampsAgeToReferenceCurves() { near(34.85,FitnessAnalysis.typicalRange(12,ReferenceSex.female).start);near(27.6,FitnessAnalysis.typicalRange(90,ReferenceSex.female).endInclusive) }
    @Test fun fitnessBandTracksReferenceRatio() { assertNull(FitnessAnalysis.fitnessBand(40.0,35,ReferenceSex.unspecified)); listOf(30.0 to "Below typical range",42.0 to "Around typical range",46.0 to "Above typical range",55.0 to "Well above typical range").forEach { (v,s)->assertEquals(s,FitnessAnalysis.fitnessBand(v,35,ReferenceSex.male)) } }
    @Test fun fitnessBandClampsAgeOutsideCurve() { assertNotNull(FitnessAnalysis.fitnessBand(30.0,90,ReferenceSex.male));assertNotNull(FitnessAnalysis.fitnessBand(45.0,18,ReferenceSex.female)) }
    @Test fun periodComparisonSplitsWindows() { val c=FitnessAnalysis.periodComparison(dated(45 to 38.0,40 to 40.0,20 to 42.0,10 to 44.0),30,now)!!;near(43.0,c.currentAverage);near(39.0,c.previousAverage);near(4.0,c.change) }
    @Test fun periodComparisonNilWithoutCurrentData() { assertNull(FitnessAnalysis.periodComparison(dated(50 to 38.0),30,now)) }
    @Test fun projectionRequiresFiveReadings() { assertNull(FitnessAnalysis.projection(points(38.0,39.0,40.0,41.0),45.0,now)) }
    @Test fun projectionEstimatesMonthsToTarget() { val p=(0..5).map { Point(now.daysBack(50-it*10),35.0+it) };val projection=FitnessAnalysis.projection(p,45.0,now)!!;near(3.0,projection.slopePerMonth);assertEquals(2,projection.monthsToTarget) }
    @Test fun projectionNoTimeframeWhenDeclining() { val p=(0..5).map { Point(now.daysBack(50-it*10),40.0-it) };assertNull(FitnessAnalysis.projection(p,45.0,now)!!.monthsToTarget) }
    @Test fun personalBestFindsMaximum() { near(43.0,FitnessAnalysis.personalBest(points(40.0,43.0,41.0))?.value) }
    @Test fun changeIgnoresReadingsAfterNow() { near(4.0,FitnessAnalysis.change(dated(40 to 38.0,30 to 42.0,0 to 60.0),30,now.daysBack(30))) }
    @Test fun changeIsNilWhenNoReadingFallsAtOrBeforeNow() { assertNull(FitnessAnalysis.change(dated(0 to 50.0),30,now.daysBack(60))) }
    @Test fun summarizeCoversOnlyTheSelectedWindow() { val s=MetricAnalysis.summarize(dated(10 to 54.0,20 to 58.0,45 to 70.0),30,now)!!;assertEquals(2,s.count);near(54.0,s.latest);near(56.0,s.average);near(54.0,s.minimum);near(58.0,s.maximum) }
    @Test fun summarizeReturnsNilWhenTheWindowIsEmpty() { assertNull(MetricAnalysis.summarize(dated(120 to 54.0),30,now)) }
    @Test fun changeComparesAgainstTheEquivalentPriorWindow() { val s=MetricAnalysis.summarize(dated(10 to 50.0,20 to 52.0,100 to 60.0,150 to 64.0),90,now)!!;near(51.0,s.average);near(62.0,s.previousAverage);near(-11.0,s.change) }
    @Test fun changeIsNilWithoutAPriorWindow() { val s=MetricAnalysis.summarize(dated(10 to 50.0,20 to 52.0),90,now)!!;assertNull(s.previousAverage);assertNull(s.change) }
    @Test fun monthlyAveragesAreGroupedNewestFirst() { val n=Instant.ofEpochSecond(1_750_000_000);val p=listOf(5 to 50.0,9 to 54.0,45 to 60.0).map { Point(n.daysBack(it.first),it.second) };val m=MetricAnalysis.monthlyAverages(p,90,n);assertEquals(2,m.size);assertTrue(m[0].monthStart>m[1].monthStart);assertEquals(2,m[0].count);near(52.0,m[0].average) }
    @Test fun downsampleKeepsTheMostRecentPoint() { val p=(0..399).map { Point(now.plusSeconds(it*86400L),it.toDouble()) };val t=MetricAnalysis.downsample(p,50);assertTrue(t.size<=51);near(399.0,t.last().value) }
    @Test fun downsampleLeavesShortSeriesAlone() { assertEquals(2,MetricAnalysis.downsample(points(50.0,51.0),50).size) }
    @Test fun rangeWeeksCoverTheWindow() { assertEquals(4,MetricRange.month.weeks);assertEquals(12,MetricRange.quarter.weeks);assertEquals(52,MetricRange.year.weeks) }
    @Test fun heartMetricsDeclareTheirGoodDirection() { assertTrue(HeartMetric.restingHeartRate.lowerIsBetter);assertFalse(HeartMetric.heartRateRecovery.lowerIsBetter) }
    @Test fun fixedRangeEndsNowAndSpansItsOwnDayCount() { val r=CardioRange.fixed(MetricRange.quarter,now);assertEquals(90,r.days);assertEquals(now,r.end);assertEquals(now.daysBack(90),r.start);assertTrue(r.contains(now));assertTrue(r.contains(now.daysBack(89)));assertFalse(r.contains(now.daysBack(91))) }
    @Test fun customRangeHasNoFixedLength() { assertNull(MetricRange.custom.fixedDays);assertEquals(90,MetricRange.quarter.fixedDays) }
    @Test fun customRangeMeasuresTheGapBetweenTheChosenDates() { val r=CardioRange.custom(now.daysBack(47),now);assertEquals(MetricRange.custom,r.selection);assertEquals(47,r.days);assertEquals(now,r.end) }
    @Test fun customRangeOrdersReversedDates() { val r=CardioRange.custom(now,now.daysBack(30));assertEquals(now.daysBack(30),r.start);assertEquals(now,r.end);assertEquals(30,r.days) }
    @Test fun customRangeOfOneDayNeverCollapsesToZero() { assertEquals(1,CardioRange.custom(now,now).days) }
    @Test fun trailingRangeCoversAnArbitraryDayCount() { val r=CardioRange.trailing(45,now);assertEquals(45,r.days);assertEquals(now.daysBack(45),r.start) }
    @Test fun customPriorPhraseNamesItsOwnLength() { assertEquals("previous 47 days",CardioRange.custom(now.daysBack(47),now).priorPhrase);assertEquals("prior 90 days",CardioRange.fixed(MetricRange.quarter,now).priorPhrase) }
    @Test fun customPriorPhraseSingularizesOneDay() { assertEquals("previous 1 day",CardioRange.custom(now,now).priorPhrase) }
    @Test fun weeklyBarsNeverDropBelowFour() { assertEquals(4,CardioRange.trailing(7,now).weeks);assertEquals(52,CardioRange.fixed(MetricRange.year,now).weeks) }
    @Test fun chartWeeksDoesNotPadACustomRangePastItsOwnSpan() { assertEquals(1,CardioRange.custom(now.daysBack(3),now).chartWeeks);assertEquals(5,CardioRange.custom(now.daysBack(30),now).chartWeeks);assertEquals(4,CardioRange.fixed(MetricRange.month,now).chartWeeks);assertEquals(52,CardioRange.fixed(MetricRange.year,now).chartWeeks) }
    @Test fun spanLabelStatesBothEnds() { val r=CardioRange.fixed(MetricRange.month,now);assertTrue(r.spanLabel.contains("–"));assertNotEquals(r.spanLabel,r.priorSpanLabel()) }
    @Test fun windowsPairConsecutiveEstimates() { val w=DriverAnalysis.windows(dated(60 to 40.0,46 to 40.6,32 to 40.4),emptyList());assertEquals(2,w.size);assertTrue(w[0].isRising);assertFalse(w[1].isRising) }
    @Test fun windowsDropTooShortAndTooLongGaps() { assertTrue(DriverAnalysis.windows(dated(30 to 40.0,29 to 41.0),emptyList()).isEmpty());assertTrue(DriverAnalysis.windows(dated(200 to 40.0,30 to 41.0),emptyList()).isEmpty()) }
    @Test fun windowMinutesAreNormalizedPerWeek() { val w=DriverAnalysis.windows(dated(28 to 40.0,14 to 41.0),listOf(26,24,20,16).map { work(it) }).single();near(120.0,w.minutesPerWeek);near(2.0,w.sessionsPerWeek) }
    @Test fun workoutsOutsideAWindowAreExcluded() { val w=DriverAnalysis.windows(dated(28 to 40.0,14 to 41.0),listOf(work(40),work(5))).single();near(0.0,w.minutesPerWeek) }
    @Test fun summaryNeedsEnoughWindowsInBothBuckets() { val w=(0..5).map { window(if(it%2==0)1.0 else -1.0) };assertNull(DriverAnalysis.summary(w.take(5)));assertNull(DriverAnalysis.summary(List(8){window(1.0)}));assertNotNull(DriverAnalysis.summary(w)) }
    @Test fun summaryAveragesEachBucketSeparately() { val s=DriverAnalysis.summary(List(3){window(0.5,150.0)}+List(3){window(-0.5,50.0)})!!;assertEquals(3,s.risingCount);assertEquals(3,s.otherCount);near(150.0,s.risingMinutesPerWeek);near(50.0,s.otherMinutesPerWeek);near(100.0,s.minutesDifference) }
    @Test fun tinyChangesDoNotCountAsRising() { assertFalse(window(0.1).isRising);assertTrue(window(0.2).isRising) }
    @Test fun headlineReportsBothAveragesWithoutClaimingCause() { val s=DriverSummary(4,4,120.0,60.0,3.0,2.0);val h=DriverAnalysis.headline(s);assertTrue(h.contains("120"));assertTrue(h.contains("60")) }
    @Test fun activityTotalsGroupAndSortByMinutes() { val a=DriverAnalysis.activityTotals(listOf(work(5,ActivityKind.walk,30.0),work(6,ActivityKind.run,90.0),work(7,ActivityKind.walk,45.0),work(200,ActivityKind.run,500.0)),90,now);assertEquals(2,a.size);assertEquals(ActivityKind.run,a[0].kind);near(90.0,a[0].minutes);assertEquals(2,a[1].sessions) }
    @Test fun weeklyLoadSeparatesQualifyingMinutes() { val w=DriverAnalysis.weeklyLoad(listOf(work(2,minutes=40.0),work(2,ActivityKind.cycle,60.0),work(2,minutes=20.0,indoor=true)),4,now);assertEquals(4,w.size);near(120.0,w.sumOf{it.minutes});near(40.0,w.sumOf{it.qualifyingMinutes}) }
    @Test fun loadSummaryNormalizesTheSelectedRangeToWeeks() { val s=DriverAnalysis.loadSummary(listOf(work(3),work(10,ActivityKind.walk),work(25,ActivityKind.cycle)),30,now)!!;assertEquals(3,s.sessions);near(180.0,s.totalMinutes);near(42.0,s.minutesPerWeek);near(0.7,s.sessionsPerWeek);near(28.0,s.qualifyingMinutesPerWeek) }
    @Test fun loadSummaryComparesAgainstTheEquivalentPriorRange() { val s=DriverAnalysis.loadSummary(listOf(work(5,minutes=70.0),work(40,minutes=140.0)),30,now)!!;near(140/(30.0/7),s.previousMinutesPerWeek);assertTrue(s.change!!<0) }
    @Test fun loadSummaryWithholdsChangeWithoutPriorHistory() { val s=DriverAnalysis.loadSummary(listOf(work(5,minutes=70.0)),30,now)!!;assertNull(s.previousMinutesPerWeek);assertNull(s.change) }
    @Test fun loadSummaryIsNilWhenTheRangeHasNoWorkouts() { assertNull(DriverAnalysis.loadSummary(listOf(work(200)),90,now)) }
    @Test fun indoorSessionsNeverRefreshTheEstimate() { assertTrue(work(1).refreshesEstimate);assertFalse(work(1,indoor=true).refreshesEstimate);assertFalse(work(1,ActivityKind.cycle).refreshesEstimate) }
    private fun cadence(vararg days: Int) = days.map { Point(now.daysBack(it),40.0) }
    @Test fun noReadingsReportsNoReadings() { val f=FreshnessAnalysis.assess(emptyList(),now);assertEquals(FreshnessState.noReadings,f.state);assertNull(f.daysSinceLatest) }
    @Test fun recentReadingIsFresh() { val f=FreshnessAnalysis.assess(cadence(0,9,18,27),now);assertEquals(FreshnessState.fresh,f.state);assertEquals(0,f.daysSinceLatest) }
    @Test fun stalenessFollowsPersonalCadence() { assertEquals(FreshnessState.stale,FreshnessAnalysis.assess(cadence(20,27,34,41,48),now).state);assertEquals(FreshnessState.aging,FreshnessAnalysis.assess(cadence(35,63,91,119,147),now).state) }
    @Test fun typicalGapNeedsFourReadings() { assertNull(FreshnessAnalysis.typicalGapDays(cadence(1,8,15),now));assertEquals(7,FreshnessAnalysis.typicalGapDays(cadence(1,8,15,22),now)) }
    @Test fun typicalGapIsClamped() { assertEquals(5,FreshnessAnalysis.typicalGapDays(cadence(0,1,2,3,4,5),now));assertEquals(30,FreshnessAnalysis.typicalGapDays(cadence(0,60,120,180,240),now)) }
    @Test fun fallbackThresholdAppliesWithoutCadence() { val f=FreshnessAnalysis.assess(cadence(25,40),now);assertNull(f.typicalGapDays);assertEquals(FreshnessState.stale,f.state) }
    @Test fun staleDetailNamesTheRefreshAction() { val f=FreshnessAnalysis.assess(cadence(40,47,54,61),now);assertTrue(f.isStale);assertTrue(f.detail.contains(FreshnessAnalysis.refreshInstruction)) }
}
