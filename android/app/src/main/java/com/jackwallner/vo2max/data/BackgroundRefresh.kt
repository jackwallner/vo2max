package com.jackwallner.vo2max.data

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import java.time.LocalDate
import java.time.YearMonth
import java.util.concurrent.TimeUnit

import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters

import com.jackwallner.vo2max.MainActivity
import com.jackwallner.vo2max.R
import com.jackwallner.vo2max.VO2Application
import com.jackwallner.vo2max.model.FreshnessAnalysis

class HealthNotifications(private val context: Context) {
    fun send(title: String,body: String,id: Int) {
        if(android.os.Build.VERSION.SDK_INT>=33 && ContextCompat.checkSelfPermission(context,Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED)return
        val manager=context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel("cardio","Cardio fitness updates",NotificationManager.IMPORTANCE_DEFAULT))
        val pending=PendingIntent.getActivity(context,id,Intent(context,MainActivity::class.java),PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val notification=NotificationCompat.Builder(context,"cardio").setSmallIcon(R.drawable.ic_stat).setContentTitle(title).setContentText(body).setContentIntent(pending).setAutoCancel(true).setVisibility(NotificationCompat.VISIBILITY_PRIVATE).build()
        NotificationManagerCompat.from(context).notify(id,notification)
    }
}
class BackgroundRefresh(context: Context,parameters: WorkerParameters): CoroutineWorker(context,parameters) {
    override suspend fun doWork(): Result {
        val graph=(applicationContext as VO2Application).graph
        // Recheck the entitlement, permission and opt-ins before every background read.
        graph.store.start()
        if(!graph.store.current.isPro)return Result.success()
        graph.health.refresh(background=true)
        return if(graph.health.state.value.error==null)Result.success() else Result.retry()
    }
    companion object {
        fun schedule(context: Context) = WorkManager.getInstance(context).enqueueUniquePeriodicWork("cardio-refresh",ExistingPeriodicWorkPolicy.KEEP,PeriodicWorkRequestBuilder<BackgroundRefresh>(6,TimeUnit.HOURS).build())
        fun notifyRetention(context: Context,settings: Settings,state: HealthState) {
            val values=settings.values;val notifications=HealthNotifications(context)
            val month=YearMonth.now().toString()
            if(settings.enabled("monthlyRecapEnabled",false) && LocalDate.now().dayOfMonth<=3 && values.string("lastMonthlyRecap")!=month && state.points.any { it.date>=java.time.Instant.now().minusSeconds(30L*86400) }) {
                notifications.send("Your monthly cardio recap","Your latest month of estimates is ready to review.",2);values.put("lastMonthlyRecap",month)
            }
            val freshness=FreshnessAnalysis.assess(state.points)
            val last=values.long("lastFreshnessNudge") ?: 0
            if(settings.enabled("freshnessNudgesEnabled",false) && freshness.isStale && System.currentTimeMillis()-last>=7L*86400000) {
                notifications.send("Check your estimate source","Your estimate is older than your usual cadence. Check your connected fitness app.",3);values.put("lastFreshnessNudge",System.currentTimeMillis().toString())
            }
        }
    }
}
