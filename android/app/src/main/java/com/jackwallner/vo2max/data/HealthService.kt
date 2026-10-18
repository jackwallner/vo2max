package com.jackwallner.vo2max.data

import android.content.Context
import android.content.Intent
import android.net.Uri
import java.time.Duration
import java.time.Instant
import kotlin.reflect.KClass

import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.HealthConnectFeatures
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.Record
import androidx.health.connect.client.records.RestingHeartRateRecord
import androidx.health.connect.client.records.Vo2MaxRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject

import com.jackwallner.vo2max.model.*

data class HealthState(val points: List<Point> = emptyList(),val resting: List<Point> = emptyList(),val workouts: List<Workout> = emptyList(),val refreshing: Boolean = false,val status: String = "Connect Health Connect",val error: String? = null,val granted: Set<String> = emptySet(),val updated: Instant? = null)
class HealthService(private val context: Context,private val settings: Settings,private val review: ReviewTracker,private val isPro: ()->Boolean = {false}) {
    private val mutex=Mutex()
    private val cache=context.getFileStreamPath("cardio-cache.json")
    private val mutable=MutableStateFlow(HealthState())
    val state=mutable.asStateFlow()
    private var automation=false
    val sdkStatus get() = HealthConnectClient.getSdkStatus(context)
    private fun client()=HealthConnectClient.getOrCreate(context)
    val corePermissions=setOf(HealthPermission.getReadPermission(Vo2MaxRecord::class))
    val contextPermissions=setOf(HealthPermission.getReadPermission(RestingHeartRateRecord::class),HealthPermission.getReadPermission(ExerciseSessionRecord::class))
    fun availableFeature(feature: Int) = sdkStatus==HealthConnectClient.SDK_AVAILABLE && client().features.getFeatureStatus(feature)==HealthConnectFeatures.FEATURE_STATUS_AVAILABLE
    fun permissions(includeContext: Boolean = false,includeBackground: Boolean = false): Set<String> = buildSet {
        addAll(corePermissions);if(includeContext)addAll(contextPermissions)
        if(availableFeature(HealthConnectFeatures.FEATURE_READ_HEALTH_DATA_HISTORY))add(HealthPermission.PERMISSION_READ_HEALTH_DATA_HISTORY)
        if(includeBackground && availableFeature(HealthConnectFeatures.FEATURE_READ_HEALTH_DATA_IN_BACKGROUND))add(HealthPermission.PERMISSION_READ_HEALTH_DATA_IN_BACKGROUND)
    }
    fun settingsIntent(): Intent = if(sdkStatus==HealthConnectClient.SDK_AVAILABLE) Intent(HealthConnectClient.ACTION_HEALTH_CONNECT_SETTINGS) else Intent(Intent.ACTION_VIEW,Uri.parse("market://details?id=com.google.android.apps.healthdata"))
    private suspend fun <T:Record> readAll(type: KClass<T>,start: Instant,end: Instant): List<T> {
        val records=mutableListOf<T>();var token: String?=null
        do {
            val response=client().readRecords(ReadRecordsRequest(type,TimeRangeFilter.between(start,end),pageSize=1000,pageToken=token))
            records.addAll(response.records);token=response.pageToken
        } while(token!=null)
        return records
    }
    suspend fun refresh(background: Boolean = false): Unit = mutex.withLock {
        if(automation)return@withLock
        if(sdkStatus!=HealthConnectClient.SDK_AVAILABLE) { clear("Health Connect needs to be installed or updated");return@withLock }
        mutable.value=mutable.value.copy(refreshing=true,error=null)
        try {
            val granted=client().permissionController.getGrantedPermissions()
            if(!granted.containsAll(corePermissions)) { clear("VO2 max permission is not granted",granted);return@withLock }
            if(background && HealthPermission.PERMISSION_READ_HEALTH_DATA_IN_BACKGROUND !in granted) { mutable.value=mutable.value.copy(refreshing=false,granted=granted);return@withLock }
            mutable.value=mutable.value.copy(
                resting=if(HealthPermission.getReadPermission(RestingHeartRateRecord::class) in granted)mutable.value.resting else emptyList(),
                workouts=if(HealthPermission.getReadPermission(ExerciseSessionRecord::class) in granted)mutable.value.workouts else emptyList(),granted=granted)
            val now=Instant.now();val history=HealthPermission.PERMISSION_READ_HEALTH_DATA_HISTORY in granted
            // The provider enforces its grant date on older history. A denied history grant still permits the recent window.
            val savedStart=settings.values.long("healthReadWindowStart")?.let(Instant::ofEpochSecond)
            val recentStart=savedStart ?: HealthReadWindow.initialStart(now)
            val start=HealthReadWindow.queryStart(savedStart,now,history)
            if(mutable.value.points.isEmpty()) {
                val restored=withContext(Dispatchers.IO){restore(granted,start)}
                if(restored!=null)mutable.value=restored.copy(refreshing=true)
            }
            val old=mutable.value.points
            val estimates=readAll(Vo2MaxRecord::class,start,now).map { Point(it.time,it.vo2MillilitersPerMinuteKilogram,it.metadata.id,it.metadata.dataOrigin.packageName) }.sortedBy { it.date }
            val resting=if(HealthPermission.getReadPermission(RestingHeartRateRecord::class) in granted) readAll(RestingHeartRateRecord::class,start,now).map { Point(it.time,it.beatsPerMinute.toDouble(),it.metadata.id,it.metadata.dataOrigin.packageName) } else emptyList()
            val workouts=if(HealthPermission.getReadPermission(ExerciseSessionRecord::class) in granted) readAll(ExerciseSessionRecord::class,start,now).mapNotNull { record ->
                val kind=kind(record.exerciseType) ?: return@mapNotNull null
                Workout(record.metadata.id,record.startTime,kind,Duration.between(record.startTime,record.endTime).seconds/60.0,record.exerciseType in indoorTypes)
            } else emptyList()
            val next=HealthState(estimates,resting,workouts,false,if(estimates.isEmpty())"Connected, no VO2 max records" else "Connected",granted=granted,updated=now)
            mutable.value=next
            withContext(Dispatchers.IO) { save(next) }
            settings.values.put("healthReadWindowStart",recentStart.epochSecond.toString())
            if(estimates.isNotEmpty()) {
                review.hasSeenReading=true
                val latest=estimates.last();val previous=old.lastOrNull()
                if(previous!=null && latest.id!=previous.id && (latest.value>(old.maxOfOrNull{it.value} ?: latest.value) || (FitnessAnalysis.targetStatus(previous.value,settings.lower,settings.upper)!=TargetStatus.inRange && FitnessAnalysis.targetStatus(latest.value,settings.lower,settings.upper)==TargetStatus.inRange))) review.recordPositiveMoment()
                if(isPro() && previous!=null && latest.id!=previous.id && settings.enabled("readingAlertsEnabled",false)) HealthNotifications(context).send("New VO2 max estimate","A new estimate is ready in VO2 Max.",1)
            }
            if(background) BackgroundRefresh.notifyRetention(context,settings,next)
        } catch(error: Exception) {
            if(error is CancellationException)throw error
            if(error is SecurityException) clear("Health permissions changed. Reconnect to refresh.")
            else mutable.value=mutable.value.copy(refreshing=false,error="Couldn't refresh Health Connect. Check permissions and try again.")
        }
    }
    private suspend fun clear(status: String,granted: Set<String> = emptySet()) {
        mutable.value=HealthState(status=status,granted=granted)
        settings.values.put("healthReadWindowStart","")
        withContext(Dispatchers.IO){cache.delete()}
    }
    private fun save(state: HealthState) {
        fun points(list: List<Point>)=JSONArray().apply { list.forEach { put(JSONObject().put("id",it.id).put("date",it.date.epochSecond).put("value",it.value).put("source",it.source)) } }
        val workouts=JSONArray().apply { state.workouts.forEach { put(JSONObject().put("id",it.id).put("date",it.date.epochSecond).put("kind",it.kind.name).put("minutes",it.minutes).put("indoor",it.isIndoor)) } }
        val temporary=java.io.File(cache.parentFile,"cardio-cache.tmp")
        temporary.writeText(JSONObject().put("points",points(state.points)).put("resting",points(state.resting)).put("workouts",workouts).put("updated",state.updated?.epochSecond).toString())
        check(temporary.renameTo(cache)){"Could not persist display cache"}
    }
    private fun restore(granted: Set<String>,start: Instant): HealthState? = runCatching {
        if(!cache.exists())return@runCatching null
        val json=JSONObject(cache.readText())
        fun points(key: String): List<Point> {
            val array=json.optJSONArray(key) ?: return emptyList()
            return (0 until array.length()).map { val p=array.getJSONObject(it);Point(Instant.ofEpochSecond(p.getLong("date")),p.getDouble("value"),p.getString("id"),p.getString("source")) }.filter { it.date>=start }
        }
        val array=json.optJSONArray("workouts") ?: JSONArray()
        val workouts=if(HealthPermission.getReadPermission(ExerciseSessionRecord::class) in granted)(0 until array.length()).map { val w=array.getJSONObject(it);Workout(w.getString("id"),Instant.ofEpochSecond(w.getLong("date")),ActivityKind.valueOf(w.getString("kind")),w.getDouble("minutes"),w.getBoolean("indoor")) }.filter { it.date>=start }else emptyList()
        HealthState(points("points"),if(HealthPermission.getReadPermission(RestingHeartRateRecord::class) in granted)points("resting")else emptyList(),workouts,status="Cached estimates",granted=granted,updated=json.optLong("updated").takeIf{it>0}?.let(Instant::ofEpochSecond))
    }.getOrNull()
    fun seedForDebug(points: List<Point>,resting: List<Point>,workouts: List<Workout>) {
        check(com.jackwallner.vo2max.BuildConfig.DEBUG)
        automation=true;mutable.value=HealthState(points,resting,workouts,status="Local test data",updated=Instant.now())
    }
    companion object {
        private val indoorTypes=setOf(ExerciseSessionRecord.EXERCISE_TYPE_BIKING_STATIONARY,ExerciseSessionRecord.EXERCISE_TYPE_ELLIPTICAL,ExerciseSessionRecord.EXERCISE_TYPE_ROWING_MACHINE,ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_POOL,ExerciseSessionRecord.EXERCISE_TYPE_RUNNING_TREADMILL)
        fun kind(type: Int): ActivityKind? = when(type) {
            ExerciseSessionRecord.EXERCISE_TYPE_WALKING -> ActivityKind.walk
            ExerciseSessionRecord.EXERCISE_TYPE_RUNNING,ExerciseSessionRecord.EXERCISE_TYPE_RUNNING_TREADMILL -> ActivityKind.run
            ExerciseSessionRecord.EXERCISE_TYPE_HIKING -> ActivityKind.hike
            ExerciseSessionRecord.EXERCISE_TYPE_BIKING,ExerciseSessionRecord.EXERCISE_TYPE_BIKING_STATIONARY -> ActivityKind.cycle
            ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_POOL,ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_OPEN_WATER -> ActivityKind.swim
            ExerciseSessionRecord.EXERCISE_TYPE_ELLIPTICAL -> ActivityKind.elliptical
            ExerciseSessionRecord.EXERCISE_TYPE_ROWING,ExerciseSessionRecord.EXERCISE_TYPE_ROWING_MACHINE -> ActivityKind.rowing
            ExerciseSessionRecord.EXERCISE_TYPE_HIGH_INTENSITY_INTERVAL_TRAINING -> ActivityKind.intervals
            else -> null
        }
    }
}
