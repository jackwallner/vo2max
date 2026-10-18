package com.jackwallner.vo2max.ui

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import com.google.android.play.core.review.ReviewManagerFactory
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

import com.jackwallner.vo2max.AppGraph
import com.jackwallner.vo2max.ui.nav.*
import com.jackwallner.vo2max.ui.screens.*
import com.jackwallner.vo2max.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable fun RootScreen(graph: AppGraph) {
    val settings=graph.settings
    val dark=when(settings.appearance){"Dark"->true;"Light"->false;else->isSystemInDarkTheme()}
    val store by graph.store.state.collectAsState()
    val health by graph.health.state.collectAsState()
    val context=LocalContext.current
    SideEffect {
        (context as? android.app.Activity)?.window?.let { window->
            androidx.core.view.WindowCompat.getInsetsController(window,window.decorView).apply {
                isAppearanceLightStatusBars=!dark
                isAppearanceLightNavigationBars=!dark
            }
        }
    }
    val scope=rememberCoroutineScope()
    var tab by rememberSaveable{mutableIntStateOf(0)}
    val navigators=remember{List(3){Navigator()}}
    val navigator=navigators[tab]
    val permissionLauncher=rememberLauncherForActivityResult(PermissionController.createRequestPermissionResultContract()) { scope.launch{graph.health.refresh()} }
    val connect: (Boolean,Boolean)->Unit={includeContext,includeBackground->
        if(graph.health.sdkStatus==HealthConnectClient.SDK_AVAILABLE)permissionLauncher.launch(graph.health.permissions(includeContext,includeBackground))
        else runCatching{context.startActivity(graph.health.settingsIntent())}
    }
    LaunchedEffect(store.isPro) { if(store.isPro && navigator.top==Route.Paywall)navigator.pop()
        if(!store.isPro && settings.selection==com.jackwallner.vo2max.model.MetricRange.custom)settings.select(com.jackwallner.vo2max.model.MetricRange.quarter) }
    LaunchedEffect(health.points.isNotEmpty(),tab,navigator.depth,settings.hasCompletedSetup) {
        if(health.points.isNotEmpty()) { graph.review.hasSeenReading=true;graph.review.recordReturnWithReading() }
        if(health.points.isNotEmpty() && tab==0 && navigator.depth==1 && graph.review.shouldRequestAfterPositiveMoment(settings.hasCompletedSetup)) {
            delay(3000)
            if(navigator.depth==1 && graph.review.shouldRequestAfterPositiveMoment(settings.hasCompletedSetup)) {
                val activity=context as? androidx.activity.ComponentActivity
                if(activity!=null) {
                    val manager=ReviewManagerFactory.create(context)
                    manager.requestReviewFlow().addOnSuccessListener { info ->
                        if(tab==0 && navigator.depth==1 && activity.lifecycle.currentState.isAtLeast(androidx.lifecycle.Lifecycle.State.RESUMED)) { graph.review.markShown();manager.launchReviewFlow(activity,info) }
                    }
                }
            }
        }
    }
    VO2Theme(dark) {
        Surface(Modifier.fillMaxSize().semantics{testTagsAsResourceId=true},color=MaterialTheme.colorScheme.background) {
            if(!settings.hasCompletedSetup) {
                OnboardingScreen(graph,{connect(false,false)},{navigator.push(Route.Paywall)})
            } else {
                Scaffold(containerColor=MaterialTheme.colorScheme.background,topBar={
                    if(navigator.depth>1)TopAppBar(colors=TopAppBarDefaults.topAppBarColors(containerColor=MaterialTheme.colorScheme.background),title={Text(navigator.top.title)},navigationIcon={IconButton(onClick={navigator.pop()}){Icon(Icons.AutoMirrored.Filled.ArrowBack,"Back")}})
                },bottomBar={
                    NavigationBar(containerColor=MaterialTheme.colorScheme.background) {
                        listOf("Today","Trends","VO2+").forEachIndexed{index,label->NavigationBarItem(modifier=Modifier.testTag("tab-$index"),selected=tab==index,onClick={if(tab==index)navigator.popToRoot()else tab=index},icon={Icon(when(index){0->Icons.Default.Favorite;1->TrendIcon;else->Icons.Default.Star},null)},label={Text(label)})}
                    }
                }) { padding->
                    Box(Modifier.padding(padding)) {
                        NavStack(navigator) { route->
                            val push: (Route)->Unit={navigator.push(it)}
                            val gated: (Route)->Unit={route->navigator.paywallFocus=route;navigator.push(if(store.isPro || route==Route.Recovery)route else Route.Paywall)}
                            when(route) {
                                Route.Root->when(tab) {
                                    0->TodayScreen(graph,health,store.isPro,push,gated,{connect(false,false)})
                                    1->TrendsScreen(graph,health,store.isPro,push,gated)
                                    else->if(store.isPro)PlusScreen(graph,health,push)else PaywallScreen(graph,"vo2plus_tab")
                                }
                                Route.History->ReadingHistoryScreen(graph,health)
                                Route.Trend->TrendScreen(graph,health,store.isPro,gated)
                                Route.Age->FitnessAgeScreen(graph,health,store.isPro,push,gated)
                                Route.Settings->SettingsScreen(graph,health,store.isPro,push,gated,connect)
                                Route.Paywall->PaywallScreen(graph,"vo2plus_locked_feature",navigator.paywallFocus)
                                Route.Recovery->RecoveryScreen()
                                else->if(!store.isPro)PaywallScreen(graph,"vo2plus_locked_feature") else when(route) {
                                    Route.Resting->RestingScreen(graph,health,{connect(true,false)})
                                    Route.Load->LoadScreen(graph,health,{connect(true,false)})
                                    Route.Drivers->DriversScreen(graph,health,{connect(true,false)})
                                    Route.Freshness->FreshnessScreen(health)
                                    Route.Recap->RecapScreen(graph,health)
                                    Route.Report->ReportScreen(graph,health)
                                    else->Unit
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
