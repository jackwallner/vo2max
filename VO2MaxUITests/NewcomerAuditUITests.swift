import XCTest

/// First-time-user walk for the newcomer persona audit. Public demo fixtures
/// only (`-DemoData`, no RevenueCat on a simulator). Each step attaches a
/// screenshot; target frames are attached as text for touch-target review.
final class NewcomerAuditUITests: XCTestCase {

    private func launch(_ extra: [String]) -> XCUIApplication {
        continueAfterFailure = true
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.vo2max")
        app.launchArguments += extra
        app.launch()
        return app
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private var frames = [String]()

    private func note(_ label: String, _ element: XCUIElement) {
        let f = element.exists ? element.frame : .zero
        frames.append("\(label): exists=\(element.exists) \(Int(f.width))x\(Int(f.height)) at (\(Int(f.minX)),\(Int(f.minY)))")
    }

    private func flushFrames(_ name: String) {
        let a = XCTAttachment(string: frames.joined(separator: "\n"))
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    private func tapIfThere(_ el: XCUIElement, wait: TimeInterval = 4) -> Bool {
        guard el.waitForExistence(timeout: wait) else { return false }
        el.tap()
        return true
    }

    /// Welcome, profile, target, trial, free exit, Today, then the main screens.
    func testNewcomerFullWalkWithDemoData() {
        let app = launch(["-DemoData"])
        let cont = app.buttons["Continue"]
        XCTAssertTrue(cont.waitForExistence(timeout: 20))
        sleep(1)
        shot("01-welcome")
        note("welcome Continue", cont)
        cont.tap()

        sleep(1)
        shot("02-profile")
        note("profile Continue", app.buttons["Continue"])
        app.buttons["Continue"].tap()

        sleep(1)
        shot("03-target")
        app.buttons["Continue"].tap()

        sleep(2)
        shot("04-trial-pitch")
        let getStarted = app.buttons["Get Started"]
        note("trial Get Started", getStarted)
        note("trial Continue with VO2+", app.buttons["Continue with VO2+"])
        note("trial Restore", app.buttons["Restore"])
        note("trial Terms", app.links["Terms"].exists ? app.links["Terms"] : app.buttons["Terms"])
        note("trial Privacy", app.links["Privacy"].exists ? app.links["Privacy"] : app.buttons["Privacy"])

        // Tap the CTA with no store loaded: what does a newcomer see?
        app.buttons["Continue with VO2+"].tap()
        sleep(3)
        shot("05-trial-cta-tap-no-store")
        // Dismiss any fallback paywall.
        let close = app.buttons["Close"]
        if close.exists { close.tap(); sleep(1) }
        else { app.swipeDown(velocity: .fast); sleep(1) }
        shot("06-after-cta-dismiss")

        XCTAssertTrue(tapIfThere(app.buttons["Get Started"]))
        sleep(3)
        shot("07-today")
        note("Today settings gear", app.buttons["Settings"])
        note("Tab Today", app.buttons["Today"])
        note("Tab Trends", app.buttons["Trends"])
        note("Tab VO2+", app.buttons["VO2+"])

        // Ring
        let ring = app.buttons["Latest Apple Health estimate"]
        let ringAny = ring.exists ? ring : app.otherElements["Latest Apple Health estimate"]
        note("Today ring", ringAny)
        if ringAny.exists { ringAny.tap(); sleep(2); shot("08-readings-from-ring"); app.navigationBars.buttons.firstMatch.tap(); sleep(1) }

        // Scroll to see the lower content
        app.swipeUp(); sleep(1)
        shot("09-today-scrolled")
        app.swipeDown(); sleep(1)

        // Trend card
        let trend = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Cardio fitness trend'")).firstMatch
        if tapIfThere(trend) { sleep(2); shot("10-trend-detail"); app.swipeUp(); sleep(1); shot("10b-trend-detail-lower"); app.navigationBars.buttons.firstMatch.tap(); sleep(1) }

        let age = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Fitness age estimate'")).firstMatch
        if tapIfThere(age) { sleep(2); shot("11-fitness-age"); app.swipeUp(); sleep(1); shot("11b-fitness-age-lower"); app.navigationBars.buttons.firstMatch.tap(); sleep(1) }

        // Trends tab
        if tapIfThere(app.buttons["Trends"]) { sleep(2); shot("12-trends"); app.swipeUp(); sleep(1); shot("12b-trends-lower") }

        // VO2+ tab (free user)
        if tapIfThere(app.buttons["VO2+"]) { sleep(2); shot("13-vo2plus-tab"); app.swipeUp(); sleep(1); shot("13b-vo2plus-lower") }

        // Settings
        app.buttons["Today"].tap(); sleep(1)
        if tapIfThere(app.buttons["Settings"]) { sleep(2); shot("14-settings"); app.swipeUp(); sleep(1); shot("14b-settings-lower") }
        flushFrames("target-frames.txt")
    }

    /// Return visit: relaunch after onboarding completed (persisted defaults).
    func testReturnVisit() {
        var app = launch(["-DemoData"])
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 20))
        for _ in 0..<3 { app.buttons["Continue"].tap(); sleep(1) }
        XCTAssertTrue(tapIfThere(app.buttons["Get Started"]))
        sleep(2)
        app.terminate()
        app = launch(["-DemoData"])
        sleep(4)
        shot("20-return-launch")
        sleep(2)
        shot("21-return-launch-settled")
    }

    /// No fixture: what an empty Health shows right after a brand new install.
    func testEmptyStateNoData() {
        let app = launch([])
        let cont = app.buttons["Continue"]
        XCTAssertTrue(cont.waitForExistence(timeout: 20))
        cont.tap()
        sleep(3)
        shot("30-after-welcome-continue-health-prompt")
        // Best effort: Health permission sheet.
        for label in ["Turn On All", "Allow", "Don\u{2019}t Allow", "Don't Allow"] {
            let b = app.buttons[label]
            if b.waitForExistence(timeout: 2) { b.tap(); break }
        }
        sleep(2)
        shot("31-after-health-sheet")
        for _ in 0..<2 {
            if app.buttons["Continue"].waitForExistence(timeout: 4) { app.buttons["Continue"].tap(); sleep(1) }
        }
        shot("32-trial")
        if tapIfThere(app.buttons["Get Started"]) {
            sleep(3)
            shot("33-today-empty")
            let connect = app.buttons["Connect Apple Health"]
            note("empty Connect", connect)
            note("empty Open Apple Health", app.buttons["Open Apple Health"])
            note("empty Settings", app.buttons["Settings"])
            app.swipeUp(); sleep(1); shot("34-today-empty-scrolled")
            if tapIfThere(app.buttons["Trends"]) { sleep(2); shot("35-trends-empty") }
            if tapIfThere(app.buttons["VO2+"]) { sleep(2); shot("36-plus-empty") }
        }
        flushFrames("target-frames-empty.txt")
    }

    /// Large Dynamic Type through onboarding and Today.
    func testLargeTextOnboarding() {
        let app = launch(["-DemoData", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"])
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 20))
        sleep(1); shot("40-large-welcome")
        app.buttons["Continue"].tap(); sleep(1); shot("41-large-profile")
        app.buttons["Continue"].tap(); sleep(1); shot("42-large-target")
        app.buttons["Continue"].tap(); sleep(2); shot("43-large-trial")
        if tapIfThere(app.buttons["Get Started"]) { sleep(3); shot("44-large-today") }
    }
}
