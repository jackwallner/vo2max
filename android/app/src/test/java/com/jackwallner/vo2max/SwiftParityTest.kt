package com.jackwallner.vo2max

import java.time.Instant
import java.util.TimeZone

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

import com.jackwallner.vo2max.model.*

@RunWith(Parameterized::class)
class SwiftParityTest(private val name: String,private val fixture: JSONObject) {
    companion object {
        @JvmStatic @Parameterized.Parameters(name="{0}") fun cases(): List<Array<Any>> {
            val json=SwiftParityTest::class.java.getResource("/swift-parity.json")!!.readText()
            val array=JSONArray(json)
            return (0 until array.length()).map { val row=array.getJSONObject(it);arrayOf(row.getString("name"),row) }
        }
    }
    private fun compare(expected: Any?,actual: Any?) {
        if(expected==JSONObject.NULL || expected==null){assertNull(actual);return}
        if(expected is Number && actual is Number)assertEquals(expected.toDouble(),actual.toDouble(),0.00001)else assertEquals(expected,actual)
    }
    @Test fun matchesSwiftAnalysis() {
        TimeZone.setDefault(TimeZone.getTimeZone("UTC"))
        val now=Instant.ofEpochSecond(fixture.getLong("now"));val days=fixture.getInt("days")
        val array=fixture.getJSONArray("points");val points=(0 until array.length()).map{val p=array.getJSONObject(it);Point(Instant.ofEpochSecond(p.getLong("date")),p.getDouble("value"))}
        val sex=ReferenceSex.entries[fixture.getInt("sex")];val age=fixture.getInt("age");val scenario=name.substringAfterLast('-').toInt()
        compare(fixture.getString("trend"),FitnessAnalysis.trend(points,now).name)
        compare(fixture.get("change"),FitnessAnalysis.change(points,days,now))
        compare(fixture.get("fitnessAge"),FitnessAnalysis.estimatedFitnessAge(31.0+scenario,sex))
        compare(fixture.get("band"),FitnessAnalysis.fitnessBand(31.0+scenario,age,sex))
        val typical=FitnessAnalysis.typicalRange(age,sex);compare(fixture.getDouble("typicalLower"),typical.start);compare(fixture.getDouble("typicalUpper"),typical.endInclusive)
        val summary=MetricAnalysis.summarize(points,days,now)
        if(fixture.isNull("summary"))assertNull(summary)else{val s=fixture.getJSONObject("summary");requireNotNull(summary);compare(s.get("latest"),summary.latest);compare(s.get("average"),summary.average);compare(s.get("minimum"),summary.minimum);compare(s.get("maximum"),summary.maximum);compare(s.get("count"),summary.count);compare(s.get("previous"),summary.previousAverage)}
        val projection=FitnessAnalysis.projection(points,45.0,now)
        if(fixture.isNull("projection"))assertNull(projection)else{val p=fixture.getJSONObject("projection");requireNotNull(projection);compare(p.get("slope"),projection.slopePerMonth);compare(p.get("months"),projection.monthsToTarget);compare(p.get("count"),projection.sampleCount)}
        val freshness=FreshnessAnalysis.assess(points,now);val f=fixture.getJSONObject("freshness");compare(f.get("state"),freshness.state.name);compare(f.get("days"),freshness.daysSinceLatest);compare(f.get("gap"),freshness.typicalGapDays)
        val comparison=FitnessAnalysis.periodComparison(points,days,now)
        if(fixture.isNull("comparison"))assertNull(comparison)else{val c=fixture.getJSONObject("comparison");requireNotNull(comparison);compare(c.get("current"),comparison.currentAverage);compare(c.get("previous"),comparison.previousAverage);compare(c.get("count"),comparison.currentCount);compare(c.get("priorCount"),comparison.previousCount)}
    }
}
