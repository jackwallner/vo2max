package com.jackwallner.vo2max

import android.app.Application
import android.content.Context

import com.jackwallner.vo2max.data.*
import com.jackwallner.vo2max.model.ConversionDiagnostics
import com.jackwallner.vo2max.model.ReviewTracker

class AppGraph(context: Context) {
    val values=Preferences(context)
    val settings=Settings(values)
    val review=ReviewTracker(values)
    val diagnostics=ConversionDiagnostics(values)
    val store=StoreService(context,diagnostics)
    val health=HealthService(context,settings,review){store.current.isPro}
    init { review.recordAppLaunch();diagnostics.recordAppOpen() }
}
class VO2Application: Application() {
    lateinit var graph: AppGraph;private set
    override fun onCreate() { super.onCreate();graph=AppGraph(this);BackgroundRefresh.schedule(this) }
}
