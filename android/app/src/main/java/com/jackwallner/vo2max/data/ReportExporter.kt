package com.jackwallner.vo2max.data

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.pdf.PdfDocument
import java.io.File

import androidx.core.content.FileProvider

import com.jackwallner.vo2max.model.*
import com.jackwallner.vo2max.ui.theme.date
import com.jackwallner.vo2max.ui.theme.fmt

class ReportExporter(private val context: Context) {
    fun pdf(points: List<Point>,range: CardioRange,lower: Double,upper: Double,age: Int,sex: ReferenceSex): File {
        val selected=points.filter{range.contains(it.date)}.sortedBy{it.date}
        require(selected.isNotEmpty()){ "No estimates in the selected range." }
        val summary=MetricAnalysis.summarize(points,range.days,range.end)!!
        val document=PdfDocument()
        try {
            val page=document.startPage(PdfDocument.PageInfo.Builder(612,792,1).create())
            val canvas=page.canvas;val paint=Paint(Paint.ANTI_ALIAS_FLAG)
            fun text(value: String,x: Float,y: Float,size: Float=13f,bold: Boolean=false,color: Int=Color.BLACK) {
                paint.color=color;paint.textSize=size;paint.typeface=if(bold)android.graphics.Typeface.DEFAULT_BOLD else android.graphics.Typeface.DEFAULT;canvas.drawText(value,x,y,paint)
            }
            canvas.drawColor(Color.WHITE)
            text("VO2+",36f,46f,14f,true,Color.rgb(0,130,140));text("Cardio Fitness Report",36f,80f,26f,true)
            text("${range.start.date()} to ${range.end.date()}",36f,104f,12f)
            text("AVERAGE",36f,146f,11f,true);text(summary.average.fmt(),36f,181f,30f,true)
            text("LATEST",310f,146f,11f,true);text(summary.latest.fmt(),310f,181f,30f,true)
            text("mL/kg/min",36f,201f,12f);text("mL/kg/min",310f,201f,12f)
            text("RANGE",36f,239f,11f,true);text("${summary.minimum.fmt()} to ${summary.maximum.fmt()}",36f,268f,22f,true)
            text("IN TARGET",310f,239f,11f,true);text("${selected.count{it.value in lower..upper}} / ${selected.size}",310f,268f,22f,true)
            text("Target ${lower.fmt(0)} to ${upper.fmt(0)} mL/kg/min",310f,289f,11f)
            val low=minOf(summary.minimum,lower)-1;val high=maxOf(summary.maximum,upper)+1
            fun y(value: Double)=480f-((value-low)/(high-low)*150).toFloat()
            paint.color=Color.rgb(234,245,237);canvas.drawRect(36f,y(upper),576f,y(lower),paint)
            paint.color=Color.LTGRAY;paint.strokeWidth=1f
            repeat(4){ val yy=330f+it*50;canvas.drawLine(36f,yy,576f,yy,paint) }
            val first=selected.first().date.toEpochMilli();val span=(selected.last().date.toEpochMilli()-first).coerceAtLeast(1)
            val path=Path();selected.forEachIndexed{i,p->val x=36+((p.date.toEpochMilli()-first).toDouble()/span*540).toFloat();if(i==0)path.moveTo(x,y(p.value))else path.lineTo(x,y(p.value))}
            paint.style=Paint.Style.STROKE;paint.strokeWidth=2.5f;paint.color=Color.rgb(0,150,160);canvas.drawPath(path,paint);paint.style=Paint.Style.FILL
            selected.forEach{p->canvas.drawCircle(36+((p.date.toEpochMilli()-first).toDouble()/span*540).toFloat(),y(p.value),3f,paint)}
            text(selected.first().date.date(),36f,502f,10f);text(selected.last().date.date(),450f,502f,10f)
            text("${selected.size} Health Connect estimates",36f,540f,13f,true)
            text("Trend: ${FitnessAnalysis.trend(points.filter{it.date<=range.end},range.end).label}",36f,568f)
            summary.previousAverage?.takeIf{it>0}?.let{text("Average change: ${((summary.average-it)/it*100).fmt()}% vs. ${range.priorPhrase}",36f,594f)}
            val peak=selected.maxBy{it.value}
            text("Best estimate: ${peak.value.fmt()} on ${peak.date.date()}",36f,620f)
            val fitnessAge=FitnessAnalysis.estimatedFitnessAge(selected.last().value,sex)
            text(fitnessAge?.let{"Fitness age: about $it (chronological age $age)"} ?: "Fitness age: reference profile not set",36f,646f)
            val band=FitnessAnalysis.fitnessBand(selected.last().value,age,sex)
            text("Age reference: ${band ?: "reference profile not set"}",36f,672f)
            text("For fitness awareness only. Estimates and reference context are not",36f,702f,10f)
            text("medical measurements. This app does not diagnose or treat any condition.",36f,718f,10f)
            text("Health data stays on your device until you choose to share this report.",36f,740f,10f)
            document.finishPage(page)
            val target=directory().resolve("VO2-Max-Report.pdf");target.outputStream().use{document.writeTo(it)};return target
        } finally { document.close() }
    }
    fun share(file: File,mime: String) {
        val uri=FileProvider.getUriForFile(context,"com.jackwallner.vo2max.files",file)
        val send=Intent(Intent.ACTION_SEND).setType(mime).putExtra(Intent.EXTRA_STREAM,uri).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        context.startActivity(Intent.createChooser(send,"Share fitness report"))
    }
    private fun directory()=File(context.cacheDir,"reports").apply{mkdirs()}
}
