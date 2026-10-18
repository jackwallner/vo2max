package com.jackwallner.vo2max.ui.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

import com.jackwallner.vo2max.AppGraph
import com.jackwallner.vo2max.data.HealthState
import com.jackwallner.vo2max.model.*
import com.jackwallner.vo2max.ui.theme.*

@Composable fun RestingScreen(graph: AppGraph,health: HealthState,connect: ()->Unit) {
    val range=graph.settings.range();val summary=MetricAnalysis.summarize(health.resting,range.days,range.end)
    Page {
        RangePicker(graph,true,{})
        CardBlock {
            if(summary==null){Title("No readings in the ${range.selection.phrase}");Text("Resting heart rate is read directly from Health Connect, never written to.");Button(onClick=connect){Text("Allow supporting signals")}}else{
                Metric("Latest resting heart rate",summary.latest.fmt(0),"bpm at rest · ${summary.latestDate.date()}")
                Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween){Metric("Average",summary.average.fmt(0));Metric("Range","${summary.minimum.fmt(0)}–${summary.maximum.fmt(0)}")}
                Small("${summary.count} readings · Average vs. ${range.priorPhrase}: ${summary.change?.signed() ?: "No prior readings"}")
                LineChart(health.resting.filter{range.contains(it.date)},unit="bpm")
            }
        }
        val months=MetricAnalysis.monthlyAverages(health.resting,range.days,range.end)
        if(months.isNotEmpty())CardBlock{Title("Monthly averages");months.forEach{m->Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween){Text(m.monthStart.date("MMMM yyyy"));Text("${m.average.fmt(0)} bpm · ${m.count} readings")}}}
        CardBlock{Title("About this signal");Text("A lower resting heart rate can accompany improving cardio fitness. Many factors affect this signal, so it cannot establish a cause.");Small("A fitness-awareness signal, not a medical measurement. This app does not diagnose, treat, or monitor any condition. Discuss heart health concerns with a qualified clinician.")}
    }
}
@Composable fun RecoveryScreen() {
    Page {
        CardBlock{Title("One-minute recovery is unavailable");Text("Health Connect does not provide a direct one-minute heart rate recovery record. VO2 Max cannot read the Apple Health recovery series on Android.");Text("We do not substitute resting heart rate or infer a recovery value from unrelated samples.")}
        CardBlock{Title("About Heart Rate Recovery");Text("This is the fall in heart rate during the minute after a recorded workout ends. A larger drop is the direction associated with improving fitness, but many factors affect it.");Small("For fitness awareness only. This is not a medical assessment.")}
    }
}
@Composable fun LoadScreen(graph: AppGraph,health: HealthState,connect: ()->Unit) {
    val range=graph.settings.range();val load=DriverAnalysis.loadSummary(health.workouts,range.days,range.end)
    val selected=health.workouts.filter{range.contains(it.date)}
    val weeks=DriverAnalysis.weeklyLoad(selected,range.chartWeeks,range.end)
    Page {
        RangePicker(graph,true,{})
        CardBlock {
            if(load==null){Title("No cardio workouts in the ${range.selection.phrase}");Text("Walks, runs, hikes, rides, swims, rows, elliptical, and interval sessions recorded in Health Connect all count here.");Button(onClick=connect){Text("Allow supporting signals")}}else{
                Metric("Cardio Load",load.minutesPerWeek.fmt(0),"min/week over the ${range.selection.phrase}")
                Text("${load.sessionsPerWeek.fmt()} sessions/week · ${load.totalMinutes.fmt(0)} minutes total")
                Small("vs. ${range.priorPhrase}: ${load.change?.let{"${it.signed()} min/week"} ?: "No prior workouts"}")
                LoadChart(weeks)
                Small("Blue shows all cardio minutes. Teal shows walks, runs, and hikes, excluding explicitly indoor exercise types. Health Connect does not always identify indoor sessions. Whether a session produces an estimate depends on your fitness source.")
            }
        }
        ActivityTotals(selected,range.days,range.end)
        Small("Total recorded cardio minutes divided by the selected range's length in weeks. Empty weeks stay visible.")
    }
}
@Composable fun LoadChart(weeks: List<WeeklyLoad>) {
    val max=weeks.maxOfOrNull{it.minutes}?.coerceAtLeast(1.0) ?: 1.0
    Small("Minutes per week · highest week ${max.fmt(0)} min")
    Canvas(Modifier.fillMaxWidth().height(160.dp).semantics{contentDescription="${weeks.size} weeks of cardio, ${weeks.sumOf{it.minutes}.fmt(0)} total minutes, ${weeks.sumOf{it.qualifyingMinutes}.fmt(0)} walk, run, and hike minutes"}) {
        if(weeks.isEmpty())return@Canvas
        val unit=size.width/weeks.size;val width=unit*0.6f
        weeks.forEachIndexed{i,w->val height=(w.minutes/max*size.height).toFloat();val qualifying=(w.qualifyingMinutes/max*size.height).toFloat();drawRect(Blue,Offset(i*unit,size.height-height),Size(width,height));drawRect(Teal,Offset(i*unit,size.height-qualifying),Size(width,qualifying))}
    }
    if(weeks.isNotEmpty())Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) {
        Small(weeks.first().weekStart.date("MMM d"));Small(weeks.last().weekStart.date("MMM d"))
    }
}
@Composable fun ActivityTotals(workouts: List<Workout>,days: Int,end: java.time.Instant) {
    val totals=DriverAnalysis.activityTotals(workouts,days,end)
    if(totals.isEmpty())return
    CardBlock{Title("Activity mix");totals.forEach{total->Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween){Column{Text(total.kind.label);Small("${total.sessions} sessions")};Text("${total.minutes.fmt(0)} min",fontWeight=FontWeight.Bold)}}}
}
@Composable fun DriversScreen(graph: AppGraph,health: HealthState,connect: ()->Unit) {
    val range=graph.settings.range();val selected=health.points.filter{range.contains(it.date)}
    val workouts=health.workouts.filter{range.contains(it.date)};val windows=DriverAnalysis.windows(selected,workouts);val summary=DriverAnalysis.summary(windows)
    Page {
        RangePicker(graph,true,{})
        CardBlock {
            Title("What Moved It")
            if(summary==null){Text("This comparison needs at least six stretches between estimates, with at least two in each group. Keep recording workouts and it will fill in as your fitness source logs more estimates.");Small("${windows.size} of 6 usable stretches so far.")}else{
                Text(DriverAnalysis.headline(summary))
                Metric("When the estimate rose","${summary.risingMinutesPerWeek.fmt(0)} min/week","${summary.risingSessionsPerWeek.fmt()} sessions/week · ${summary.risingCount} stretches")
                HorizontalDivider()
                Metric("When it stayed flat or fell","${summary.otherMinutesPerWeek.fmt(0)} min/week","${summary.otherSessionsPerWeek.fmt()} sessions/week · ${summary.otherCount} stretches")
            }
            if(health.workouts.isEmpty())Button(onClick=connect){Text("Allow supporting signals")}
        }
        ActivityTotals(workouts,range.days,range.end)
        CardBlock{Title("How this comparison works");Text("Each pair of consecutive estimates forms a stretch of 3 to 60 days. The workouts inside it are converted to minutes per week, and the stretches where your estimate rose by more than 0.1 are averaged separately from the ones where it stayed flat or fell.");Small("This describes patterns in your own history. It does not establish cause, and it is not a training plan or medical advice.")}
    }
}
@Composable fun FreshnessScreen(health: HealthState) {
    val freshness=FreshnessAnalysis.assess(health.points)
    Page {
        CardBlock{Title(freshness.headline);freshness.daysSinceLatest?.let{Metric("Since latest estimate","$it days")};Text(freshness.detail);freshness.typicalGapDays?.let{Small("Your usual cadence: about $it days")}}
        CardBlock{Title("How freshness works");Text("Your usual cadence is the median gap between estimates over the last year, clamped to 5–30 days. It needs at least four readings. Without enough history, we use 10 days.");Text("Up to one usual gap is current. Up to two gaps is getting old. Longer gaps are stale.");Small(FreshnessAnalysis.refreshInstruction)}
        CardBlock{Title("Recent walks, runs, and hikes");val sessions=health.workouts.filter{it.refreshesEstimate}.sortedByDescending{it.date}.take(10);if(sessions.isEmpty())Text("No walks, runs, or hikes were read from Health Connect.");sessions.forEach{Text("${it.kind.label} · ${it.minutes.fmt(0)} min · ${it.date.date()}")};Small("Health Connect does not always identify indoor sessions. These sessions may support fitness. The connected source decides if and when it records a VO2 max estimate.")}
    }
}
@Composable fun RecapScreen(graph: AppGraph,health: HealthState) {
    val now=java.time.Instant.now();val points=health.points.filter{it.date>=now.daysBack(30)&&it.date<=now}
    val comparison=FitnessAnalysis.periodComparison(health.points,30,now)
    Page {
        Title(now.date("MMMM yyyy"))
        if(points.isEmpty())CardBlock{Title("No estimates this month");Text("Your monthly recap builds as Health Connect receives estimates.")}else{
            CardBlock{Metric("Last 30 days",comparison!!.currentAverage.fmt(),"mL/kg/min average · ${points.size} readings");comparison.previousAverage?.takeIf{it>0}?.let{Text("${((comparison.currentAverage-it)/it*100).signed()}% vs. previous 30 days")};Text(FitnessAnalysis.trend(health.points).label);LineChart(points,graph.settings.lower,graph.settings.upper)}
            val best=points.maxBy{it.value};CardBlock{Metric("Period best",best.value.fmt(),best.date.date());health.points.maxByOrNull{it.value}?.let{Metric("Personal best",it.value.fmt(),it.date.date())}}
            points.maxByOrNull{it.date}?.let{CardBlock{Title(FitnessAnalysis.targetStatus(it.value,graph.settings.lower,graph.settings.upper).label);Text("Target ${graph.settings.lower.fmt(0)}–${graph.settings.upper.fmt(0)} mL/kg/min")}}
        }
        Small("For fitness awareness. Estimates and broad reference context are not medical measurements.")
    }
}
