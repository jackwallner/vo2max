package com.jackwallner.vo2max.ui.theme

import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

import com.jackwallner.vo2max.model.Point

val Teal=Color(0xFF0FC2C7)
val Blue=Color(0xFF147AF2)
val Positive=Color(0xFF339B65)
val Negative=Color(0xFFEB5C61)
fun Double.fmt(digits: Int=1)=String.format(Locale.getDefault(),"%.${digits}f",this)
fun Double.signed()=String.format(Locale.getDefault(),"%+.1f",this)
fun Instant.date(pattern: String="MMM d, yyyy"): String = DateTimeFormatter.ofPattern(pattern).withZone(ZoneId.systemDefault()).format(this)
@Composable fun VO2Theme(dark: Boolean,content: @Composable ()->Unit) {
    val colors=if(dark) darkColorScheme(primary=Teal,onPrimary=Color(0xFF002B30),secondary=Teal,secondaryContainer=Color(0xFF123C3D),onSecondaryContainer=Teal,background=Color.Black,surface=Color(0xFF1C1C1E),surfaceContainer=Color(0xFF1C1C1E),onBackground=Color.White,onSurface=Color.White) else lightColorScheme(primary=Color(0xFF007C83),onPrimary=Color.White,secondary=Color(0xFF007C83),secondaryContainer=Color(0xFFDFF5F4),onSecondaryContainer=Color(0xFF00565D),background=Color.White,surface=Color(0xFFF2F2F7),surfaceContainer=Color(0xFFF2F2F7),onBackground=Color(0xFF141417),onSurface=Color(0xFF141417))
    MaterialTheme(colorScheme=colors,content=content)
}
@Composable fun Page(content: @Composable ColumnScope.()->Unit) { Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal=24.dp).padding(top=12.dp,bottom=28.dp),verticalArrangement=Arrangement.spacedBy(16.dp),content=content) }
@Composable fun CardBlock(modifier: Modifier=Modifier,content: @Composable ColumnScope.()->Unit) {
    Surface(modifier.fillMaxWidth(),shape=RoundedCornerShape(20.dp),color=MaterialTheme.colorScheme.surface) { Column(Modifier.padding(20.dp),verticalArrangement=Arrangement.spacedBy(10.dp),content=content) }
}
@Composable fun Small(text: String) { Text(text,style=MaterialTheme.typography.bodySmall,color=MaterialTheme.colorScheme.onSurfaceVariant) }
@Composable fun Title(text: String) { Text(text,fontSize=20.sp,fontWeight=FontWeight.Bold) }
@Composable fun Metric(label: String,value: String,detail: String?=null) {
    Column(verticalArrangement=Arrangement.spacedBy(3.dp)) { Small(label);Text(value,fontSize=28.sp,fontWeight=FontWeight.Bold);detail?.let{Small(it)} }
}
@Composable fun LinkCard(title: String,value: String,detail: String?=null,onClick: ()->Unit) {
    CardBlock(Modifier.clickable(onClick=onClick).semantics(mergeDescendants=true){}) {
        Row(verticalAlignment=Alignment.CenterVertically) { Column(Modifier.weight(1f),verticalArrangement=Arrangement.spacedBy(3.dp)) { Small(title);Text(value,fontSize=18.sp,fontWeight=FontWeight.SemiBold);detail?.let { Small(it) } };Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight,contentDescription=null,modifier=Modifier.size(20.dp)) }
    }
}
@Composable fun ActionRow(title: String,value: String="",onClick: ()->Unit) {
    Row(Modifier.fillMaxWidth().clickable(onClick=onClick).heightIn(min=52.dp).padding(vertical=10.dp).semantics(mergeDescendants=true){},verticalAlignment=Alignment.CenterVertically) {
        Text(title,Modifier.weight(1f));if(value.isNotEmpty())Text(value,color=MaterialTheme.colorScheme.onSurfaceVariant);Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight,null,Modifier.size(20.dp))
    }
}
@Composable fun Ring(value: Double,lower: Double,upper: Double,onClick: ()->Unit) {
    val floor=lower-(upper-lower).coerceAtLeast(1.0)
    val progress=((value-floor)/(upper-floor)).coerceIn(0.02,1.0).toFloat()
    val track=MaterialTheme.colorScheme.outlineVariant
    Box(Modifier.fillMaxWidth().padding(vertical=8.dp),contentAlignment=Alignment.Center) {
        Box(Modifier.size(230.dp).clickable(onClick=onClick).semantics(mergeDescendants=true){contentDescription="Latest Health Connect estimate, ${value.fmt()} milliliters per kilogram per minute"},contentAlignment=Alignment.Center) {
            Canvas(Modifier.fillMaxSize()) { val stroke=17.dp.toPx();val inset=stroke/2;drawArc(track,0f,360f,false,Offset(inset,inset),Size(size.width-stroke,size.height-stroke),style=Stroke(stroke));drawArc(Brush.sweepGradient(listOf(Blue,Teal,Blue)),-90f,360*progress,false,Offset(inset,inset),Size(size.width-stroke,size.height-stroke),style=Stroke(stroke,cap=StrokeCap.Round)) }
            Column(horizontalAlignment=Alignment.CenterHorizontally,verticalArrangement=Arrangement.spacedBy(3.dp)) { Text(value.fmt(),fontSize=54.sp,fontWeight=FontWeight.Bold);Small("mL/kg/min");Text(com.jackwallner.vo2max.model.FitnessAnalysis.targetStatus(value,lower,upper).label,fontWeight=FontWeight.Bold,color=if(value<lower)Color(0xFFFF7366)else Positive);Small("Target ${lower.fmt(0)}–${upper.fmt(0)}") }
        }
    }
}
@Composable fun LineChart(points: List<Point>,lower: Double?=null,upper: Double?=null,unit: String="mL/kg/min") {
    if(points.isEmpty()) { Small("No estimates in this period");return }
    val sorted=com.jackwallner.vo2max.model.MetricAnalysis.downsample(points.sortedBy{it.date})
    val min=minOf(sorted.minOf{it.value},lower ?: Double.MAX_VALUE)-1;val max=maxOf(sorted.maxOf{it.value},upper ?: -Double.MAX_VALUE)+1
    val first=sorted.first().date.toEpochMilli();val span=(sorted.last().date.toEpochMilli()-first).coerceAtLeast(1)
    val grid=MaterialTheme.colorScheme.outlineVariant
    Column(verticalArrangement=Arrangement.spacedBy(8.dp)) {
        Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) { Small(max.fmt());Small(unit) }
        Canvas(Modifier.fillMaxWidth().height(150.dp).semantics{contentDescription="${points.size} estimates from ${sorted.first().date.date()} to ${sorted.last().date.date()}, range ${points.minOf{it.value}.fmt()} to ${points.maxOf{it.value}.fmt()} $unit"}) {
            fun y(v: Double)=size.height-((v-min)/(max-min)).toFloat()*size.height
            if(lower!=null && upper!=null)drawRect(Positive.copy(alpha=0.12f),Offset(0f,y(upper)),Size(size.width,y(lower)-y(upper)))
            repeat(4){ val yy=size.height*it/3;drawLine(grid,Offset(0f,yy),Offset(size.width,yy),1.dp.toPx()) }
            val path=Path();sorted.forEachIndexed{index,point->val x=((point.date.toEpochMilli()-first).toDouble()/span*size.width).toFloat();val yy=y(point.value);if(index==0)path.moveTo(x,yy)else path.lineTo(x,yy);drawCircle(Teal,3.dp.toPx(),Offset(x,yy))};drawPath(path,Teal,style=Stroke(2.5.dp.toPx(),cap=StrokeCap.Round))
        }
        Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) { Small(sorted.first().date.date("MMM d"));Small(sorted.last().date.date("MMM d")) }
    }
}

val TrendIcon: androidx.compose.ui.graphics.vector.ImageVector by lazy {
    androidx.compose.ui.graphics.vector.ImageVector.Builder("Cardio trend",24.dp,24.dp,24f,24f).apply {
        path(fill=null,stroke=androidx.compose.ui.graphics.SolidColor(Color.Black),strokeLineWidth=2f,strokeLineCap=StrokeCap.Round,strokeLineJoin=androidx.compose.ui.graphics.StrokeJoin.Round) {
            moveTo(3f,17f);lineTo(9f,11f);lineTo(13f,14f);lineTo(21f,5f)
        }
    }.build()
}
