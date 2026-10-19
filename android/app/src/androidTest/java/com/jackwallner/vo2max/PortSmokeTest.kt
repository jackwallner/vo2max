package com.jackwallner.vo2max

import android.content.Intent
import android.graphics.Bitmap
import java.io.File
import java.time.Instant

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.test.core.app.ActivityScenario
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

import com.jackwallner.vo2max.data.ReportExporter
import com.jackwallner.vo2max.data.StoreService
import com.jackwallner.vo2max.model.*

@RunWith(AndroidJUnit4::class)
class PortSmokeTest {
    @get:Rule val compose=createEmptyComposeRule()
    private var scenario: ActivityScenario<MainActivity>?=null
    private fun launch(pro: Boolean=false,seed: Boolean=true,onboarding: Boolean=false,dark: Boolean=false) {
        val context=ApplicationProvider.getApplicationContext<VO2Application>()
        val intent=Intent(context,MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            .putExtra("uiTest",true).putExtra("skipOnboarding",!onboarding).putExtra("seedScreenshotData",seed).putExtra("forcePro",pro).putExtra("appearance",if(dark)"dark" else "light")
        scenario=ActivityScenario.launch(intent);compose.waitForIdle()
    }
    private fun click(text: String) { val node=compose.onNodeWithText(text);if(!node.isDisplayed())node.performScrollTo();node.performClick();compose.waitForIdle() }
    private fun tab(index: Int) { compose.onNodeWithTag("tab-$index").performClick();compose.waitForIdle() }
    private fun screenshot(name: String) {
        val instrumentation=InstrumentationRegistry.getInstrumentation()
        val bitmap=instrumentation.uiAutomation.takeScreenshot()
        val context=instrumentation.targetContext
        val values=android.content.ContentValues().apply {
            put(android.provider.MediaStore.Images.Media.DISPLAY_NAME,"$name.png")
            put(android.provider.MediaStore.Images.Media.MIME_TYPE,"image/png")
            put(android.provider.MediaStore.Images.Media.RELATIVE_PATH,"Pictures/sol-vo2max")
        }
        val uri=context.contentResolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI,values)!!
        context.contentResolver.openOutputStream(uri)!!.use{bitmap.compress(Bitmap.CompressFormat.PNG,100,it)}
    }
    @After fun close() { scenario?.close() }
    @Test fun reviewerAccessRejectsWrongCodeAndPersistsValidGrant()=runBlocking {
        val code=checkNotNull(InstrumentationRegistry.getArguments().getString("reviewCode")){"Supply the private reviewer code through the local test harness."}
        launch(seed=false)
        compose.onNodeWithContentDescription("Settings").performClick()
        compose.onNodeWithText("Version 1.1.4").performScrollTo().performTouchInput{longClick()}
        compose.onNodeWithText("Reviewer code").performTextInput("wrong")
        click("Unlock")
        compose.onNodeWithText("That code isn't valid.").assertIsDisplayed()
        val app=ApplicationProvider.getApplicationContext<VO2Application>()
        assertFalse(app.graph.store.current.isPro)
        compose.onNodeWithText("Reviewer code").performTextClearance()
        compose.onNodeWithText("Reviewer code").performTextInput(code)
        click("Unlock")
        assertTrue(app.graph.store.current.isPro)
        app.graph.store.start()
        assertTrue(app.graph.store.current.isPro)
        assertTrue(StoreService(app,app.graph.diagnostics).current.isPro)
    }
    @Test fun firstRunCanCompleteWithoutHealthOrPurchase() {
        launch(seed=false,onboarding=true)
        var statusTop=0
        var safeBottom=Int.MAX_VALUE
        scenario!!.onActivity { activity ->
            val decor=activity.window.decorView
            val insets=checkNotNull(androidx.core.view.ViewCompat.getRootWindowInsets(decor))
                .getInsets(androidx.core.view.WindowInsetsCompat.Type.systemBars())
            statusTop=insets.top
            safeBottom=decor.height-insets.bottom
        }
        assertTrue("The device must expose a status bar for this layout check",statusTop>0)
        assertTrue("Step label must stay below the status bar",compose.onNodeWithText("1 of 5").fetchSemanticsNode().boundsInRoot.top>=statusTop)
        assertTrue("Continue control must stay above the navigation bar",compose.onNodeWithText("Get Started").fetchSemanticsNode().boundsInRoot.bottom<=safeBottom)
        compose.onNodeWithText("Welcome to VO2 Max").assertIsDisplayed();click("Get Started");click("Continue");click("Skip profile");click("Continue");click("Continue free")
        compose.onNodeWithTag("tab-0").assertIsDisplayed();assertFalse(ApplicationProvider.getApplicationContext<VO2Application>().graph.store.current.isPro);screenshot("01-empty")
    }
    @Test fun freeTodayHasEstimateTrendAndAge() {
        launch();compose.onNodeWithText("mL/kg/min").assertIsDisplayed();compose.onNodeWithText("Cardio fitness trend").assertIsDisplayed();compose.onNodeWithText("Fitness age estimate").performScrollTo().assertIsDisplayed();screenshot("02-today")
    }
    @Test fun freeSupportingSignalsOpenPaywall() {
        launch();compose.onNodeWithContentDescription("Resting Heart Rate").performScrollTo().performClick();compose.onNodeWithText("Follow your resting heart rate").assertIsDisplayed();screenshot("03-paywall")
    }
    @Test fun freeCustomRangeOpensPaywall() {
        launch();tab(1);click("Custom");compose.onNodeWithText("Go further with VO2+").assertIsDisplayed()
    }
    @Test fun freeHistoryAndBackWork() {
        launch();tab(1);click("View every estimate");compose.onNodeWithText("Reading history").assertIsDisplayed();compose.onNodeWithContentDescription("Back").performClick();compose.onNodeWithText("Cardio fitness trend").assertIsDisplayed()
    }
    @Test fun paidRestingSignalShowsRealSeededRange() {
        launch(pro=true);compose.onNodeWithContentDescription("Resting Heart Rate").performScrollTo().performClick();compose.onNodeWithText("Latest resting heart rate").performScrollTo().assertIsDisplayed();compose.onAllNodesWithText("mL/kg/min").assertCountEquals(0);screenshot("04-resting")
    }
    @Test fun recoveryGapIsExplicit() {
        launch();compose.onNodeWithContentDescription("Heart Rate Recovery").performScrollTo().performClick();compose.onNodeWithText("One-minute recovery is unavailable").assertIsDisplayed();screenshot("05-recovery-gap")
    }
    @Test fun paidTrendsAndCustomRangeRender() {
        launch(pro=true);tab(1);compose.onNodeWithText("90D").assertIsSelected();screenshot("06-trends");click("Custom");compose.onNodeWithText("Choose up to two years").assertIsDisplayed();click("Cancel");compose.onNodeWithText("Deep Trends").performScrollTo().assertIsDisplayed()
    }
    @Test fun paidCardioLoadRendersAndScrolls() {
        launch(pro=true);compose.onNodeWithContentDescription("Cardio Load").performScrollTo().performClick();compose.onNodeWithText("Activity mix").performScrollTo().assertIsDisplayed();screenshot("07-load")
    }
    @Test fun paidDriverComparisonRenders() {
        launch(pro=true);tab(1);click("What Moved It");compose.onNodeWithText("How this comparison works").performScrollTo().assertIsDisplayed();screenshot("08-drivers")
    }
    @Test fun fitnessAgeRemainsFree() {
        launch();click("Fitness age estimate");compose.onNodeWithText("How fitness age works").performScrollTo().assertIsDisplayed();screenshot("09-age")
    }
    @Test fun subscriberHubAndRecapRenderInDarkMode() {
        launch(pro=true,dark=true);tab(2);compose.onNodeWithText("VO2+ active").assertIsDisplayed();screenshot("10-plus-dark");click("Monthly Recap");compose.onNodeWithText("Last 30 days").performScrollTo().assertIsDisplayed();screenshot("11-recap-dark")
    }
    @Test fun settingsSupportsAppearanceAndSeparateFeedback() {
        launch();compose.onNodeWithContentDescription("Settings").performClick();click("Appearance");click("Dark");compose.onNodeWithText("Rate VO2 Max").performScrollTo().assertIsDisplayed();compose.onNodeWithText("Send Feedback").performScrollTo().assertIsDisplayed();screenshot("12-settings-dark")
    }
    @Test fun pdfContainsPeriodAndReferenceProfile() {
        launch(pro=true)
        val context=ApplicationProvider.getApplicationContext<VO2Application>();val graph=context.graph
        val exporter=ReportExporter(context);val range=CardioRange.fixed(MetricRange.year)
        val pdf=exporter.pdf(graph.health.state.value.points,range,35.0,45.0,graph.settings.age,graph.settings.sex)
        assertTrue(pdf.readBytes().take(4).toByteArray().contentEquals("%PDF".toByteArray()));assertTrue(pdf.length()>1000)
        android.graphics.pdf.PdfRenderer(android.os.ParcelFileDescriptor.open(pdf,android.os.ParcelFileDescriptor.MODE_READ_ONLY)).use{assertEquals(1,it.pageCount)}
    }
    @Test fun actualHealthConnectReadDoesNotFabricateEstimates() {
        val context=ApplicationProvider.getApplicationContext<VO2Application>()
        val instrumentation=InstrumentationRegistry.getInstrumentation()
        val permission="android.permission.health.READ_VO2_MAX"
        instrumentation.uiAutomation.grantRuntimePermission(context.packageName,permission)
        instrumentation.waitForIdleSync()
        launch(seed=false)
        val graph=context.graph
        runBlocking { graph.health.refresh() }
        val state=graph.health.state.value
        assertTrue("${state.status}; ${state.error}",state.granted.contains(permission))
        assertTrue("An empty Health Connect store must not invent estimates",state.points.isEmpty())
        assertNull(state.error)
        assertTrue(context.getFileStreamPath("cardio-cache.json").exists())
    }
}
