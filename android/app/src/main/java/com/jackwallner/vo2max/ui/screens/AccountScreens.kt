package com.jackwallner.vo2max.ui.screens

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.net.Uri

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch

import com.jackwallner.vo2max.AppGraph
import com.jackwallner.vo2max.data.*
import com.jackwallner.vo2max.model.*
import com.jackwallner.vo2max.ui.nav.Route
import com.jackwallner.vo2max.ui.theme.*

fun openLink(context: android.content.Context,url: String): Boolean = runCatching { context.startActivity(Intent(Intent.ACTION_VIEW,Uri.parse(url)));true }.getOrDefault(false)
const val DISCLAIMER="VO2 Max Daily Tracker is for fitness awareness. Health Connect estimates and broad reference context are not medical measurements. This app does not diagnose, treat, cure, or prevent any condition. Discuss health concerns with a qualified clinician."
@Composable fun OnboardingScreen(graph: AppGraph,connect: ()->Unit,plans: ()->Unit) {
    var step by rememberSaveable{mutableIntStateOf(0)}
    val health by graph.health.state.collectAsState()
    Page {
        Small("${step+1} of 5")
        Spacer(Modifier.height(20.dp))
        when(step) {
            0->{Text("Welcome to VO2 Max",fontSize=34.sp,fontWeight=FontWeight.Bold);Text("See your cardio fitness from Health Connect in one simple view.",fontSize=20.sp);CardBlock{Title("Your number. Your trend.");Text("Keep your latest estimate, personal target, and broad fitness age estimate together.");Text("Read-only. Stays on your device. No account.")}}
            1->{Title("Connect Health Connect");Text("VO2 Max reads VO2 max estimates from compatible fitness apps and wearables through Health Connect.");CardBlock{Text("Your fitness source must share VO2 max first. Health Connect does not calculate VO2 max itself.");Small(FreshnessAnalysis.refreshInstruction)};Button(onClick=connect,Modifier.fillMaxWidth()){Text("Connect Health Connect")};Small(health.status);health.error?.let{Text(it,color=MaterialTheme.colorScheme.error)}}
            2->{Title("About you");Text("Optional. Your age and reference power the fitness age estimate and set a target range tuned to you. Change both later in Settings.");ProfileEditor(graph);TextButton(onClick={step++}){Text("Skip profile")}}
            3->{Title("Your target range");TargetEditor(graph);Small("A personal fitness target, not a medical threshold.")}
            else->{Title("Go further with VO2+");Text("Your number, trend, and fitness age stay free. VO2+ adds deeper context on top:");CardBlock{Text("What moved your estimate");Text("Resting heart rate and cardio load");Text("Deep trends and custom date ranges");Text("Target outlook and personal bests");Text("Freshness nudges, monthly recap, and shareable reports")};Button(onClick={graph.settings.completeSetup();plans()},Modifier.fillMaxWidth()){Text("See VO2+ plans")};Small("One-minute heart rate recovery is unavailable through Health Connect.")}
        }
        Spacer(Modifier.height(12.dp))
        Button(onClick={if(step==4)graph.settings.completeSetup()else{if(step==2){val range=FitnessAnalysis.typicalRange(graph.settings.age,graph.settings.sex);graph.settings.updateLower(range.start);graph.settings.updateUpper(range.endInclusive)};step++}},Modifier.fillMaxWidth().heightIn(min=48.dp)){Text(if(step==0)"Get Started" else if(step==4)"Continue free" else "Continue")}
        if(step>0)TextButton(onClick={step--}){Text("Back")}
        Small(DISCLAIMER)
    }
}
@Composable fun ProfileEditor(graph: AppGraph) {
    val settings=graph.settings
    var ages by remember{mutableStateOf(false)}
    CardBlock {
        ActionRow("Age",settings.age.toString(),{ages=true})
        Text("Reference",fontWeight=FontWeight.SemiBold)
        ReferenceSex.entries.forEach{sex->Row(verticalAlignment=Alignment.CenterVertically){RadioButton(selected=settings.sex==sex,onClick={settings.updateSex(sex)});Text(sex.label)}}
        Small("Used for a broad motivational estimate, not a clinical result.")
    }
    if(ages)AlertDialog(onDismissRequest={ages=false},title={Text("Age")},text={androidx.compose.foundation.lazy.LazyColumn(Modifier.height(360.dp)){items(73){index->val age=index+18;TextButton(onClick={settings.updateAge(age);ages=false},Modifier.fillMaxWidth()){Text(age.toString())}}}},confirmButton={TextButton(onClick={ages=false}){Text("Done")}})
}
@Composable fun TargetEditor(graph: AppGraph) {
    val settings=graph.settings;val typical=FitnessAnalysis.typicalRange(settings.age,settings.sex)
    CardBlock {
        Metric("Target range","${settings.lower.fmt(0)}–${settings.upper.fmt(0)}","mL/kg/min")
        RangeSlider(value=settings.lower.toFloat().coerceIn(20f,69f)..settings.upper.toFloat().coerceIn(21f,70f),onValueChange={range->if(range.endInclusive-range.start>=1){settings.updateLower(range.start.toDouble());settings.updateUpper(range.endInclusive.toDouble())}},valueRange=20f..70f,steps=49)
        Small("Broad typical range for your current profile: ${typical.start.fmt(0)}–${typical.endInclusive.fmt(0)} mL/kg/min")
    }
}
@Composable fun PaywallScreen(graph: AppGraph,impressionId: String,focus: Route?=null) {
    val state by graph.store.state.collectAsState();val scope=rememberCoroutineScope();val context=LocalContext.current
    var selected by rememberSaveable{mutableStateOf<String?>(null)};var busy by remember{mutableStateOf(false)};var message by remember{mutableStateOf<String?>(null)}
    val plan=state.planOptions.find{it.id==selected} ?: state.planOptions.find{it.displayName=="Yearly"} ?: state.planOptions.firstOrNull()
    LaunchedEffect(impressionId){graph.store.trackPaywallImpression(impressionId);graph.store.fetchProducts()}
    Page {
        Text("VO2+",fontSize=34.sp,fontWeight=FontWeight.Bold)
        Text(when(focus){Route.Resting->"Follow your resting heart rate";Route.Load,Route.Drivers->"See your cardio load";Route.Freshness->"Never wonder why it hasn't updated";Route.Recap->"Your month in review";Route.Report->"Export your cardio fitness";else->"Go further with VO2+"},fontSize=24.sp,fontWeight=FontWeight.SemiBold)
        Small("Extras that sit on top of your Health Connect estimates.")
        CardBlock{Text("Track resting heart rate (RHR)");Text("Track cardio load in min/week");Text("See your cardio fitness month in review");Text("Compare every period with the one before")}
        Small("One-minute heart rate recovery is unavailable through Health Connect.")
        if(state.isLoadingProducts)CircularProgressIndicator()else if(state.planOptions.isEmpty())CardBlock {
            Title("VO2+ Plans Unavailable");Text("Purchases are temporarily unavailable. Your free features are still ready to use.")
            Button(onClick={scope.launch{graph.store.fetchProducts()}}){Text("Try again")}
        }else{
            state.planOptions.forEach{option->CardBlock{Row(verticalAlignment=Alignment.CenterVertically){RadioButton(selected=option.id==plan?.id,onClick={selected=option.id},enabled=!busy);Column(Modifier.weight(1f)){Text(option.displayName,fontWeight=FontWeight.Bold);Text(ConversionCopy.billedAmount(option.priceLabel),fontSize=22.sp,fontWeight=FontWeight.Bold);option.trialLabel?.let{Small("$it, then the price shown")}}}}}
            plan?.let{option->
                Text(ConversionCopy.billedAmount(option.priceLabel),fontSize=26.sp,fontWeight=FontWeight.Bold)
                Small(if(option.recurring)ConversionCopy.billedNote(option.trialLabel,option.trialLabel!=null)else "One-time purchase. No subscription.")
                Button(onClick={val activity=context as? Activity ?: return@Button;scope.launch{busy=true;message=null;try{message=when(graph.store.purchase(activity,option)){PurchaseOutcome.PURCHASED->"VO2+ is active";PurchaseOutcome.PENDING->"Purchase pending. VO2+ unlocks when payment is confirmed.";PurchaseOutcome.CANCELLED->ConversionCopy.purchaseCancelledMessage(option.trialLabel!=null)}}catch(error: Exception){message=error.message ?: "Couldn't complete the purchase. Please try again."}finally{busy=false}}},enabled=!busy && option.isPurchasable,modifier=Modifier.fillMaxWidth().heightIn(min=50.dp)){Text(if(busy)"Please wait…"else ConversionCopy.ctaLabel)}
                Small(if(option.recurring)ConversionCopy.disclosure(option.trialLabel,option.priceLabel,option.trialLabel!=null)else "${option.priceLabel}. One-time purchase for lifetime access.")
            }
        }
        if(state.isPro)Text("VO2+ active",color=Positive,fontWeight=FontWeight.Bold)
        message?.let{Text(it)};state.lastError?.let{Small(it)};state.restoreError?.let{Text(it)}
        TextButton(onClick={scope.launch{graph.store.restorePurchases()}},enabled=!busy){Text("Restore Purchases")}
        Row(horizontalArrangement=Arrangement.spacedBy(12.dp)){TextButton(onClick={openLink(context,Legal.TERMS_URL)}){Text("Terms")};TextButton(onClick={openLink(context,Legal.PRIVACY_URL)}){Text("Privacy")}}
        Small("Your latest estimate, basic cardio fitness trend, and fitness age remain free.")
    }
}
@Composable fun SettingsScreen(graph: AppGraph,health: HealthState,isPro: Boolean,push: (Route)->Unit,gated: (Route)->Unit,connect: (Boolean,Boolean)->Unit) {
    val settings=graph.settings;val scope=rememberCoroutineScope();val context=LocalContext.current
    val notifyLauncher=rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()){}
    fun enableAlerts(key: String,value: Boolean) {
        settings.setEnabled(key,value)
        if(value){if(android.os.Build.VERSION.SDK_INT>=33)notifyLauncher.launch(Manifest.permission.POST_NOTIFICATIONS);connect(false,true)}
    }
    var reviewer by remember{mutableStateOf(false)}
    var appearance by remember{mutableStateOf(false)};var showPrivacy by remember{mutableStateOf(false)};var linkError by remember{mutableStateOf<String?>(null)}
    Page {
        CardBlock{Title("Health Connect");Text(health.status);Button(onClick={connect(false,false)}){Text("Connect Health Connect")};TextButton(onClick={scope.launch{graph.health.refresh()}}){Text("Refresh Health Connect")};TextButton(onClick={runCatching{context.startActivity(graph.health.settingsIntent())}}){Text("Open Health Connect")};Small("VO2 Max reads estimates on this device. Allow history access for older trends. You can revoke individual permissions in Health Connect.");if(isPro)TextButton(onClick={connect(true,false)}){Text("Allow supporting signals")}}
        Title("Your target");TargetEditor(graph)
        Title("Reference profile");ProfileEditor(graph)
        CardBlock{ActionRow("Appearance",settings.appearance,{appearance=true})}
        CardBlock {
            Title("VO2+");if(isPro)Text("VO2+ active",color=Positive)else Button(onClick={gated(Route.Paywall)}){Text(ConversionCopy.ctaLabel)}
            listOf("showDeepTrends" to "Deep Trends","showProjection" to "Target outlook","showFitnessBand" to "Age reference","showPersonalBest" to "Personal best").forEach{(key,label)->ToggleRow(label,isPro&&settings.enabled(key),{if(isPro)settings.setEnabled(key,it)else gated(Route.Paywall)})}
            listOf("readingAlertsEnabled" to "New-reading alerts","freshnessNudgesEnabled" to "Freshness nudges","monthlyRecapEnabled" to "Monthly recap").forEach{(key,label)->ToggleRow(label,isPro&&settings.enabled(key,false),{if(isPro)enableAlerts(key,it)else gated(Route.Paywall)})}
            Small("Alerts require notification and background Health Connect permissions. Android schedules reads periodically, so delivery can be delayed.")
            ActionRow("Monthly Recap",onClick={gated(Route.Recap)});ActionRow("Export fitness report",onClick={gated(Route.Report)})
            TextButton(onClick={scope.launch{graph.store.restorePurchases()}}){Text("Restore Purchases")}
            if(isPro)TextButton(onClick={openLink(context,"https://play.google.com/store/account/subscriptions?package=com.jackwallner.vo2max")}){Text("Manage subscription")}
        }
        CardBlock {
            Title("Support")
            ActionRow("Rate VO2 Max",onClick={if(openLink(context,Legal.PLAY_LISTING_URL))graph.review.markOpenedWriteReview()else linkError="Couldn't open Google Play."})
            ActionRow("Send Feedback",onClick={val opened=runCatching{context.startActivity(Intent(Intent.ACTION_SENDTO,Uri.parse("mailto:jackwallner+vo2@gmail.com?subject=VO2%20Max%20feedback")));true}.getOrDefault(false);if(opened)graph.review.markFeedbackSubmitted()else linkError="No email app is installed. Email jackwallner+vo2@gmail.com."})
            ActionRow("Privacy Policy",onClick={showPrivacy=true});ActionRow("Terms",onClick={openLink(context,Legal.TERMS_URL)})
            Small("Feedback opens your mail app with a private draft. No account.")
        }
        linkError?.let{Text(it)}
        graph.store.current.restoreError?.let{Text(it)}
        CardBlock{Title("For fitness awareness");Text(DISCLAIMER);Text("Version ${com.jackwallner.vo2max.BuildConfig.VERSION_NAME}",style=MaterialTheme.typography.bodySmall,color=MaterialTheme.colorScheme.onSurfaceVariant,modifier=Modifier.combinedClickable(onClick={},onLongClick={reviewer=true}))}
    }
    if(reviewer)ReviewerCodeDialog(graph){reviewer=false}
    if(appearance)AlertDialog(onDismissRequest={appearance=false},title={Text("Appearance")},text={Column{listOf("System","Light","Dark").forEach{option->TextButton(onClick={settings.updateAppearance(option);appearance=false}){Text(option)}}}},confirmButton={})
    if(showPrivacy)AlertDialog(onDismissRequest={showPrivacy=false},title={Text("Privacy Policy")},text={Column(Modifier.heightIn(max=480.dp).verticalScroll(rememberScrollState())){Text(PRIVACY_TEXT)}},confirmButton={TextButton(onClick={showPrivacy=false}){Text("Done")}})
}
@Composable private fun ReviewerCodeDialog(graph: AppGraph,close: ()->Unit) {
    var code by remember{mutableStateOf("")}
    var failed by remember{mutableStateOf(false)}
    AlertDialog(onDismissRequest=close,title={Text("Reviewer access")},text={Column {
        Text("Enter the code provided in the Play review instructions.")
        OutlinedTextField(code,{code=it;failed=false},label={Text("Reviewer code")},singleLine=true,keyboardOptions=androidx.compose.foundation.text.KeyboardOptions(keyboardType=androidx.compose.ui.text.input.KeyboardType.Password,autoCorrectEnabled=false),visualTransformation=androidx.compose.ui.text.input.PasswordVisualTransformation())
        if(failed)Text("That code isn't valid.",color=MaterialTheme.colorScheme.error)
    }},confirmButton={TextButton(onClick={if(graph.store.activateReviewAccess(code))close()else failed=true}){Text("Unlock")}},dismissButton={TextButton(onClick=close){Text("Cancel")}})
}
@Composable fun ToggleRow(label: String,checked: Boolean,onChange: (Boolean)->Unit) { Row(Modifier.fillMaxWidth().heightIn(min=52.dp),verticalAlignment=Alignment.CenterVertically){Text(label,Modifier.weight(1f));Switch(checked,onCheckedChange=onChange)} }
const val PRIVACY_TEXT="VO2 Max reads VO2 max estimates, optional resting heart rate, and exercise sessions from Health Connect with your permission. Health data and display caches stay on your device. We do not send health data to RevenueCat or any server. You can revoke access in Health Connect. Removing app storage deletes the cache. Reports leave your device only when you choose to share them. RevenueCat and Google Play process purchase information, anonymous app identifiers, and app version information for billing. We send RevenueCat counts, dates, and short labels about purchase screens, never health data or free text. There are no ads or accounts. Contact jackwallner+vo2@gmail.com for privacy questions."
@Composable fun PrivacyScreen() { Page { Spacer(Modifier.height(24.dp));Title("VO2 Max Privacy Policy");Text(PRIVACY_TEXT);Small(DISCLAIMER) } }
