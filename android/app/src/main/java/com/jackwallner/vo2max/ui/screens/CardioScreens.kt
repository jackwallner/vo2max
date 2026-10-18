package com.jackwallner.vo2max.ui.screens

import java.time.Instant

import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch

import com.jackwallner.vo2max.AppGraph
import com.jackwallner.vo2max.data.HealthState
import com.jackwallner.vo2max.model.*
import com.jackwallner.vo2max.ui.nav.Route
import com.jackwallner.vo2max.ui.theme.*

@Composable fun TodayScreen(graph: AppGraph,health: HealthState,isPro: Boolean,push: (Route)->Unit,gated: (Route)->Unit,connect: ()->Unit) {
    val settings=graph.settings
    Page {
        Row(Modifier.fillMaxWidth(),verticalAlignment=Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) { Text(Instant.now().date("EEEE, MMMM d"),fontSize=20.sp,fontWeight=FontWeight.Bold);Small(if(health.refreshing)"Refreshing…" else health.points.lastOrNull()?.let{"Latest estimate ${it.date.date("MMM d")}"} ?: "Waiting for your first Health Connect estimate") }
            IconButton(onClick={push(Route.Settings)}){Icon(Icons.Default.Settings,"Settings")}
        }
        val latest=health.points.maxByOrNull{it.date}
        if(latest==null)EmptyHealth(graph,health,connect) else {
            Ring(latest.value,settings.lower,settings.upper,{push(Route.History)})
            LinkCard("Cardio fitness trend",FitnessAnalysis.trend(health.points).label,FitnessAnalysis.change(health.points,90)?.let{"${it.signed()} over 90 days"} ?: "Four readings within 90 days build a trend",{push(Route.Trend)})
            val age=FitnessAnalysis.estimatedFitnessAge(latest.value,settings.sex)
            LinkCard("Fitness age estimate",age?.let{"About $it"} ?: "Add a reference profile",if(age==null)"Used to calculate this broad estimate" else "Chronological age ${settings.age}",{push(Route.Age)})
            Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.spacedBy(8.dp)) {
                SignalTile("RHR","Resting Heart Rate",if(isPro)health.resting.maxByOrNull{it.date}?.value?.fmt(0) ?: "No data" else "VO2+",Modifier.weight(1f),{gated(Route.Resting)})
                SignalTile("HRR","Heart Rate Recovery","Unavailable",Modifier.weight(1f),{gated(Route.Recovery)})
                SignalTile("Cardio","Cardio Load",if(isPro)DriverAnalysis.loadSummary(health.workouts,90)?.let{"${it.minutesPerWeek.fmt(0)} min/wk"} ?: "No data" else "VO2+",Modifier.weight(1f),{gated(Route.Load)})
            }
        }
        health.error?.let{Text(it,color=MaterialTheme.colorScheme.error)}
    }
}
@Composable fun EmptyHealth(graph: AppGraph,health: HealthState,connect: ()->Unit) {
    val scope=rememberCoroutineScope()
    val connected=health.granted.containsAll(graph.health.corePermissions)
    val context=androidx.compose.ui.platform.LocalContext.current
    CardBlock {
        Spacer(Modifier.height(12.dp));Title(if(connected)"Your first estimate will appear here" else "Connect Health Connect")
        Text(if(connected)FreshnessAnalysis.refreshInstruction else "Allow read-only access to VO2 max. A compatible fitness app or wearable must share estimates with Health Connect first.")
        Button(onClick={if(connected)scope.launch{graph.health.refresh()}else connect()},Modifier.fillMaxWidth().heightIn(min=48.dp)){Text(if(connected)"Refresh Health Connect" else "Connect Health Connect")}
        TextButton(onClick={runCatching{context.startActivity(graph.health.settingsIntent())}}){Text("Open Health Connect")}
        Small("Health Connect estimates are for fitness awareness. This app does not diagnose or treat health conditions.")
    }
}
@Composable fun RangePicker(graph: AppGraph,isPro: Boolean,gated: (Route)->Unit) {
    val settings=graph.settings
    var custom by remember{mutableStateOf(false)}
    Row(Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),horizontalArrangement=Arrangement.spacedBy(6.dp)) {
        MetricRange.entries.forEach{range->FilterChip(selected=settings.selection==range,onClick={if(range==MetricRange.custom){if(isPro)custom=true else gated(Route.Paywall)}else settings.select(range)},label={Text(range.label)})}
    }
    val range=settings.range();Small("${range.start.date("MMM d")} – ${range.end.date()}")
    if(custom)CustomRangeDialog(graph,{custom=false})
}
@OptIn(ExperimentalMaterial3Api::class)
@Composable fun CustomRangeDialog(graph: AppGraph,onDismiss: ()->Unit) {
    val picker=rememberDateRangePickerState(initialSelectedStartDateMillis=DateSelection.pickerMillis(graph.settings.range().start),initialSelectedEndDateMillis=DateSelection.pickerMillis(graph.settings.range().end),selectableDates=object: SelectableDates { override fun isSelectableDate(utcTimeMillis: Long)=utcTimeMillis<=System.currentTimeMillis() })
    DatePickerDialog(onDismissRequest=onDismiss,confirmButton={TextButton(onClick={val start=picker.selectedStartDateMillis;val end=picker.selectedEndDateMillis;if(start!=null&&end!=null){graph.settings.custom(DateSelection.localStart(start),DateSelection.localEnd(end));onDismiss()}},enabled=picker.selectedStartDateMillis!=null&&picker.selectedEndDateMillis!=null){Text("Apply")}},dismissButton={TextButton(onClick=onDismiss){Text("Cancel")}}) {
        DateRangePicker(picker,modifier=Modifier.height(480.dp),title={Text("Choose up to two years",Modifier.padding(16.dp))})
    }
}
@Composable fun TrendsScreen(graph: AppGraph,health: HealthState,isPro: Boolean,push: (Route)->Unit,gated: (Route)->Unit) {
    val settings=graph.settings;val range=settings.range();val selected=health.points.filter{range.contains(it.date)}
    Page {
        Text("Trends",fontSize=30.sp,fontWeight=FontWeight.Bold)
        RangePicker(graph,isPro,gated)
        CardBlock { Title("Cardio fitness trend");Small("Health Connect estimates");LineChart(selected,settings.lower,settings.upper);if(selected.isEmpty())Small("Choose a longer window, or return after your connected fitness source records another estimate.") }
        LinkCard("All Readings","View every estimate","Read-only history and source dates",{push(Route.History)})
        if(isPro && settings.enabled("showDeepTrends"))DeepTrends(health.points) else if(!isPro)LockedCard("Compare every period","See matching-window averages, direction toward target, broad age-reference context, and personal bests.",{gated(Route.Paywall)})
        LinkCard("Heart Signals","Resting Heart Rate",if(isPro)MetricAnalysis.summarize(health.resting,range.days,range.end)?.let{"${it.average.fmt(0)} bpm average"} ?: "No readings in this range" else "VO2+",{gated(Route.Resting)})
        LinkCard("Heart Signals","Heart Rate Recovery","One-minute recovery context",{gated(Route.Recovery)})
        LinkCard("Cardio Load","Your recorded training","Minutes and sessions per week",{gated(Route.Load)})
        LinkCard("What Moved It","Compare your own history","Training between consecutive estimates",{gated(Route.Drivers)})
        LinkCard("Estimate Freshness",FreshnessAnalysis.assess(health.points).headline,"Your personal recording cadence",{gated(Route.Freshness)})
        if(isPro && settings.enabled("showPersonalBest"))health.points.maxByOrNull{it.value}?.let{CardBlock{Metric("Personal best",it.value.fmt(),it.date.date())}}
    }
}
@Composable fun LockedCard(title: String,detail: String,onClick: ()->Unit) {
    CardBlock { Title(title);Text(detail);Button(onClick=onClick){Text(ConversionCopy.ctaLabel)} }
}
@Composable fun DeepTrends(points: List<Point>) {
    CardBlock {
        Title("Deep Trends")
        listOf(30,90,180,365).forEach{days->
            val comparison=FitnessAnalysis.periodComparison(points,days)
            Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) { Column{Text("Last $days days");Small("vs. previous $days days")};Column(horizontalAlignment=Alignment.End){Text(comparison?.currentAverage?.fmt() ?: "No data",fontWeight=FontWeight.Bold);Small(comparison?.change?.signed() ?: "No prior readings")} }
            if(days!=365)HorizontalDivider()
        }
        Small("Deep Trends compare each period with the matching one before it once both windows contain estimates.")
    }
}
@Composable fun ReadingHistoryScreen(graph: AppGraph,health: HealthState) {
    Page {
        health.points.maxByOrNull{it.date}?.let{CardBlock{Metric("Latest Health Connect estimate",it.value.fmt(),"mL/kg/min · ${it.date.date()}")}}
        Title("Reading history")
        Small("Every cached estimate, shown read-only. To change or remove source health data, use Health Connect.")
        if(health.points.isEmpty())CardBlock{Text("No estimates yet")}
        health.points.sortedByDescending{it.date}.forEach{point->CardBlock{Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween){Column(Modifier.weight(1f)){Text(point.date.date());Small(point.source);Small(FitnessAnalysis.targetStatus(point.value,graph.settings.lower,graph.settings.upper).label)};Column(horizontalAlignment=Alignment.End){Text(point.value.fmt(),fontSize=24.sp,fontWeight=FontWeight.Bold);Small("mL/kg/min")}}}}
    }
}
@Composable fun TrendScreen(graph: AppGraph,health: HealthState,isPro: Boolean,gated: (Route)->Unit) {
    Page {
        CardBlock{Metric("Cardio fitness trend",FitnessAnalysis.trend(health.points).label);LineChart(health.points.filter{it.date>=Instant.now().daysBack(90)},graph.settings.lower,graph.settings.upper)}
        CardBlock{Title("Change by window");listOf(30,90,180).forEach{days->Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween){Text("Last $days days");Text(FitnessAnalysis.change(health.points,days)?.signed() ?: "Not enough data")}}}
        if(isPro && graph.settings.enabled("showProjection"))ProjectionCard(graph,health) else if(!isPro)LockedCard("Target outlook","See whether recent estimates are moving toward your target range and get a broad timeframe when the data supports one.",{gated(Route.Paywall)})
        CardBlock{Title("How trend works");Text("The main trend compares averages from the older and newer halves of the last 90 days. It needs at least four readings and ignores small changes that are likely normal estimate-to-estimate variation.");Small("A cardio fitness trend is motivational context, not a medical assessment.")}
    }
}
@Composable fun ProjectionCard(graph: AppGraph,health: HealthState) {
    val projection=FitnessAnalysis.projection(health.points,graph.settings.lower)
    CardBlock{Title("Target outlook");if(projection==null)Text("Target outlook needs at least five readings across the last 180 days.")else{Text("${projection.slopePerMonth.signed()} mL/kg/min per month",fontWeight=FontWeight.Bold);Text(projection.monthsToTarget?.let{"About $it months to the lower target"} ?: "No supported timeframe to target");Small("Broad extrapolation from recent estimates, not a prediction or guarantee.")}}
}
@Composable fun FitnessAgeScreen(graph: AppGraph,health: HealthState,isPro: Boolean,push: (Route)->Unit,gated: (Route)->Unit) {
    val settings=graph.settings;val latest=health.points.maxByOrNull{it.date};val estimate=latest?.let{FitnessAnalysis.estimatedFitnessAge(it.value,settings.sex)}
    Page {
        CardBlock{Metric("Fitness age estimate",estimate?.let{"About $it"} ?: "Set a reference profile","Chronological age: ${settings.age}");if(estimate==null){Text("Fitness age needs a reference option plus at least one Health Connect estimate.");TextButton(onClick={push(Route.Settings)}){Text("Edit reference profile")}}}
        if(isPro && settings.enabled("showFitnessBand"))CardBlock{Title("Age reference");Text(latest?.let{FitnessAnalysis.fitnessBand(it.value,settings.age,settings.sex)} ?: "Choose a reference option in Settings to see this context.")}else if(!isPro)LockedCard("Age reference","See how your latest estimate sits within broad age-reference context, alongside the fitness age methodology.",{gated(Route.Paywall)})
        CardBlock{Title("How fitness age works");Text("Your latest cardio fitness estimate is compared with broad age and sex reference curves to find the age whose typical value most closely matches your number. Higher relative cardio fitness maps to a younger estimate.");Text("Female reference: age 20/30/40/50/60/70 maps to 41/38/35/31/27/24 mL/kg/min. Male reference maps to 49/46/42/38/34/30. Values are interpolated and age is clamped from 20 to 70.");Small("Fitness age is a broad motivational estimate. It is not clinically validated, does not diagnose anything, and does not predict longevity or health outcomes.")}
    }
}
@Composable fun PlusScreen(graph: AppGraph,health: HealthState,push: (Route)->Unit) {
    Page {
        Text("VO2+",fontSize=30.sp,fontWeight=FontWeight.Bold)
        CardBlock{Title("VO2+ active");Text("Every screen below is unlocked, and reads the range you pick.")}
        RangePicker(graph,true,push)
        health.points.maxByOrNull{it.value}?.let{CardBlock{Metric("Personal best",it.value.fmt(),it.date.date())}}
        CardBlock {
            Title("Heart Signals")
            ActionRow("Resting Heart Rate",health.resting.maxByOrNull{it.date}?.let{"${it.value.fmt(0)} bpm"} ?: "No readings",{push(Route.Resting)})
            HorizontalDivider()
            ActionRow("Heart Rate Recovery","Unavailable",{push(Route.Recovery)})
            HorizontalDivider()
            ActionRow("Cardio Load",DriverAnalysis.loadSummary(health.workouts,graph.settings.range().days,graph.settings.range().end)?.let{"${it.minutesPerWeek.fmt(0)} min/week"} ?: "No workouts",{push(Route.Load)})
        }
        CardBlock {
            Title("Your estimate")
            ActionRow("What Moved It",onClick={push(Route.Drivers)})
            HorizontalDivider()
            ActionRow("Estimate Freshness",onClick={push(Route.Freshness)})
            HorizontalDivider()
            ActionRow("Target outlook",onClick={push(Route.Trend)})
        }
        CardBlock {
            Title("Your context")
            ActionRow("Age reference",onClick={push(Route.Age)})
            HorizontalDivider()
            ActionRow("Monthly Recap",onClick={push(Route.Recap)})
            HorizontalDivider()
            ActionRow("Export fitness report",onClick={push(Route.Report)})
            HorizontalDivider()
            ActionRow("Manage VO2+",onClick={push(Route.Settings)})
        }
        Small("Your estimate, basic trend, and fitness age remain free. Health data stays on this device.")
    }
}

@Composable private fun SignalTile(label: String,accessibilityLabel: String,value: String,modifier: Modifier,onClick: ()->Unit) {
    Surface(modifier.clickable(onClick=onClick).semantics(mergeDescendants=true){contentDescription=accessibilityLabel},shape=RoundedCornerShape(16.dp),color=MaterialTheme.colorScheme.surface) {
        Column(Modifier.padding(12.dp).heightIn(min=64.dp),verticalArrangement=Arrangement.spacedBy(5.dp)) { Small(label);Text(value,fontWeight=FontWeight.SemiBold,fontSize=14.sp) }
    }
}
