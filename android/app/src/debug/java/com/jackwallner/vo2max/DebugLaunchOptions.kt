package com.jackwallner.vo2max

import android.content.Intent
import java.time.Instant

import androidx.activity.ComponentActivity

import com.jackwallner.vo2max.model.*

object DebugLaunchOptions {
    fun apply(activity: ComponentActivity,graph: AppGraph,intent: Intent?) {
        val extras=intent?.extras ?: return
        if(extras.getBoolean("uiTest"))graph.review.isAutomationRun=true
        if(extras.getBoolean("skipOnboarding"))graph.settings.completeSetup()
        if(extras.getBoolean("forcePro"))graph.store.forceProForDebug()
        extras.getString("appearance")?.let{graph.settings.updateAppearance(it.replaceFirstChar{c->c.uppercase()})}
        if(extras.getBoolean("seedScreenshotData")) {
            val now=Instant.now()
            val points=(0..25).map{Point(now.daysBack(176-it*7),38.0+it*0.17+kotlin.math.sin(it*0.7)*0.55,"fixture-$it","Compatible fitness source")}
            val resting=(0..89).map{Point(now.daysBack(89-it),64.0-it*0.07+kotlin.math.sin(it.toDouble()),"rest-$it")}
            val workouts=(0..65).map{Workout("work-$it",now.daysBack(176-it*2),if(it%3==0)ActivityKind.cycle else ActivityKind.run,35.0+(it%4)*8)}
            graph.settings.updateSex(ReferenceSex.male);graph.settings.updateAge(35)
            graph.health.seedForDebug(points,resting,workouts)
        }
    }
}
