package com.jackwallner.vo2max.ui.screens

import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

import com.jackwallner.vo2max.AppGraph
import com.jackwallner.vo2max.data.HealthState
import com.jackwallner.vo2max.data.ReportExporter
import com.jackwallner.vo2max.model.*
import com.jackwallner.vo2max.ui.theme.*

@Composable fun ReportScreen(graph: AppGraph,health: HealthState) {
    val range=graph.settings.range();val summary=MetricAnalysis.summarize(health.points,range.days,range.end)
    val context=LocalContext.current;val scope=rememberCoroutineScope();var busy by remember{mutableStateOf(false)};var error by remember{mutableStateOf<String?>(null)}
    fun export() { scope.launch{busy=true;error=null;try{val exporter=ReportExporter(context);val file=withContext(Dispatchers.IO){exporter.pdf(health.points,range,graph.settings.lower,graph.settings.upper,graph.settings.age,graph.settings.sex)};exporter.share(file,"application/pdf")}catch(failure: Exception){error=failure.message ?: "Couldn't create report. Please try again."}finally{busy=false}} }
    Page {
        RangePicker(graph,true,{})
        if(summary==null)CardBlock{Title("No estimates in this period");Text("Choose a longer range before exporting.")}else{
            CardBlock{Title("Cardio Fitness Report");Metric("Average",summary.average.fmt(),"mL/kg/min · ${summary.count} estimates");Metric("Latest",summary.latest.fmt(),summary.latestDate.date());LineChart(health.points.filter{range.contains(it.date)},graph.settings.lower,graph.settings.upper)}
            Button(onClick={export()},enabled=!busy){Text(if(busy)"Creating report…" else "Share PDF report")}
        }
        error?.let{Text(it,color=MaterialTheme.colorScheme.error)}
        Small("Sharing sends only the report you choose to the app or person you select. Your source data stays in Health Connect.")
    }
}
