import XCTest

/// Interrupted-user walk for the persona audit: leave mid-task (home button,
/// force quit), come back later and see what survived. Public demo fixtures only
/// (`-DemoData`, `-DemoPro`; no RevenueCat key on a simulator). Each step attaches
/// a screenshot; observations are attached as text. Test names are ordered so the
/// onboarding walk runs first on a clean install.
final class InterruptedAuditUITests: XCTestCase {

    private var notes = [String]()

    private func launch(_ extra: [String], tab: Int? = nil, pro: Bool = true) -> XCUIApplication {
        continueAfterFailure = true
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.vo2max")
        app.launchArguments += ["-DemoData"]
        if pro { app.launchArguments += ["-DemoPro"] }
        if let tab { app.launchArguments += ["-ScreenshotTab", "\(tab)"] }
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

    private func note(_ line: String) { notes.append(line) }

    private func flush(_ name: String) {
        let a = XCTAttachment(string: notes.joined(separator: "\n"))
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    @discardableResult
    private func tapIfThere(_ el: XCUIElement, wait: TimeInterval = 4) -> Bool {
        guard el.waitForExistence(timeout: wait) else {
            note("MISSING: \(el)")
            return false
        }
        el.tap()
        return true
    }

    private func label(_ app: XCUIApplication, contains text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }

    /// Home button, a pause, then back to the app: the phone call or text.
    private func interrupt(_ app: XCUIApplication, seconds: UInt32 = 6) {
        XCUIDevice.shared.press(.home)
        sleep(seconds)
        app.activate()
        sleep(2)
    }

    private func back(_ app: XCUIApplication) {
        let b = app.navigationBars.buttons.firstMatch
        if b.exists { b.tap() }
        sleep(1)
    }

    /// Runs first on a clean install: onboarding is abandoned at the trial pitch
    /// (backgrounded, then force quit) and reopened.
    func testA_OnboardingInterrupted() {
        var app = launch([], pro: false)
        guard app.buttons["Continue"].waitForExistence(timeout: 30) else {
            note("no onboarding: install was not clean")
            shot("A00-not-clean")
            flush("notes-onboarding.txt")
            return
        }
        shot("A01-welcome")
        app.buttons["Continue"].tap(); sleep(2)

        // Profile: pick a distinctive age so a reset is visible.
        let wheel = app.pickerWheels.firstMatch
        if wheel.waitForExistence(timeout: 4) {
            wheel.adjust(toPickerWheelValue: "52")
            note("profile wheel after adjust: \(wheel.value ?? "nil")")
        } else {
            note("MISSING age wheel")
        }
        sleep(1); shot("A02-profile-age-52")
        app.buttons["Continue"].tap(); sleep(2)
        shot("A03-target-for-52")
        let target = app.staticTexts.matching(NSPredicate(format: "label MATCHES '^[0-9]+.[0-9]+$'")).allElementsBoundByIndex.map(\.label)
        note("target values shown: \(target)")
        app.buttons["Continue"].tap(); sleep(2)
        shot("A04-trial-pitch")

        // Phone call: background for a few seconds on the trial pitch.
        interrupt(app)
        shot("A05-trial-after-background")
        note("A05 trial CTA still there: \(app.buttons["Continue with VO2+"].exists)")

        // Force quit (swipe-away or the OS reclaiming memory), then reopen.
        app.terminate()
        sleep(1)
        let t0 = Date()
        app = launch([], pro: false)
        let cont = app.buttons["Continue"]
        let appeared = cont.waitForExistence(timeout: 20)
        note("after relaunch Continue visible=\(appeared) in \(String(format: "%.1f", Date().timeIntervalSince(t0)))s")
        note("after relaunch: welcome title exists=\(app.staticTexts["Welcome to VO2 Max"].exists)")
        shot("A06-relaunch-after-trial-pitch")
        // Walk forward again and see whether the age and target survived.
        cont.tap(); sleep(2)
        let wheel2 = app.pickerWheels.firstMatch
        note("relaunch profile age wheel value: \(wheel2.exists ? "\(wheel2.value ?? "nil")" : "no wheel")")
        shot("A07-relaunch-profile")
        app.buttons["Continue"].tap(); sleep(2)
        shot("A08-relaunch-target")
        let target2 = app.staticTexts.matching(NSPredicate(format: "label MATCHES '^[0-9]+.[0-9]+$'")).allElementsBoundByIndex.map(\.label)
        note("relaunch target values shown: \(target2)")
        app.buttons["Continue"].tap(); sleep(2)
        shot("A09-relaunch-trial")
        if tapIfThere(app.buttons["Continue with VO2+"]) {
            sleep(3)
            shot("A10-cta-tap-no-store")
            note("fallback paywall close button: \(app.buttons["Close"].exists)")
            app.swipeDown(velocity: .fast); sleep(1)
            shot("A11-after-paywall-swipe-down")
        }
        tapIfThere(app.buttons["Get Started"]); sleep(3)
        shot("A12-today-after-onboarding")
        note("finished onboarding, Today tab exists=\(app.buttons["Today"].exists)")
        flush("notes-onboarding.txt")
    }

    /// Mid-task on Today: a pushed detail screen, scrolled, then the phone call.
    func testB_PushedDetailSurvivesBackground() {
        let app = launch([], tab: 0)
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 30))
        sleep(3)
        if tapIfThere(label(app, contains: "Cardio fitness trend")) {
            sleep(2)
            app.swipeUp(); sleep(1)
            shot("B01-trend-detail-scrolled")
            let before = app.navigationBars.firstMatch.identifier
            interrupt(app)
            shot("B02-trend-detail-after-background")
            note("detail nav bar before='\(before)' after='\(app.navigationBars.firstMatch.identifier)'")
            note("back button exists after return: \(app.navigationBars.buttons.firstMatch.exists)")
            back(app)
        }
        shot("B03-today-after-back")

        // Force quit while deep in a screen: where does a relaunch land?
        if tapIfThere(label(app, contains: "Fitness age")) { sleep(2); shot("B04-fitness-age") }
        app.terminate()
        let relaunched = launch([], tab: 0)
        XCTAssertTrue(relaunched.buttons["Today"].waitForExistence(timeout: 30))
        sleep(3)
        shot("B05-relaunch-lands-on-today")
        note("relaunch shows ring: \(relaunched.buttons["Latest Apple Health estimate"].exists)")
        flush("notes-pushed-detail.txt")
    }

    /// Trends range and the custom range, across background and force quit.
    func testC_RangeAndCustomRangeSurvive() {
        var app = launch([], tab: 1)
        XCTAssertTrue(app.buttons["Trends"].waitForExistence(timeout: 30))
        sleep(2)
        tapIfThere(app.buttons["1Y"]); sleep(1)
        shot("C01-picked-1Y")
        // Custom: open the sheet, move a date, then get interrupted before Apply.
        if tapIfThere(app.buttons["Custom"]) {
            sleep(2); shot("C02-custom-sheet-open")
            interrupt(app)
            shot("C03-custom-sheet-after-background")
            note("custom sheet still up after background: \(app.buttons["Apply"].exists)")
            tapIfThere(app.buttons["Apply"]); sleep(2)
            shot("C04-custom-applied")
        }
        let span = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Showing'")).firstMatch
        note("span label after apply: \(span.exists ? span.label : "none")")
        app.terminate()
        app = launch([], tab: 1)
        XCTAssertTrue(app.buttons["Trends"].waitForExistence(timeout: 30))
        sleep(3)
        shot("C05-relaunch-trends")
        let span2 = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Showing'")).firstMatch
        note("span label after relaunch: \(span2.exists ? span2.label : "none")")
        note("Custom selected after relaunch: \(app.buttons["Custom"].isSelected)")
        flush("notes-range.txt")
    }

    /// Settings edits are live; interrupt mid-edit and check what is kept.
    func testD_SettingsEditSurvivesInterruption() {
        var app = launch([], tab: 0)
        XCTAssertTrue(tapIfThere(app.buttons["Settings"], wait: 30))
        sleep(2)
        shot("D01-settings")
        let age = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Age'")).firstMatch
        note("age row: \(age.exists ? age.label : "none")")
        if tapIfThere(age, wait: 3) {
            sleep(1)
            let wheel = app.pickerWheels.firstMatch
            if wheel.exists { wheel.adjust(toPickerWheelValue: "47") }
            shot("D02-age-47-picked")
        }
        interrupt(app)
        shot("D03-settings-after-background")
        note("Done button exists: \(app.buttons["Done"].exists)")
        app.terminate()
        app = launch([], tab: 0)
        XCTAssertTrue(tapIfThere(app.buttons["Settings"], wait: 30))
        sleep(2)
        shot("D04-settings-after-force-quit")
        let age2 = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Age'")).firstMatch
        note("age row after relaunch: \(age2.exists ? age2.label : "none")")
        flush("notes-settings.txt")
    }

    /// Free user opens a locked surface, leaves, and returns.
    func testE_PaywallInterruptedAsFreeUser() {
        let app = launch([], tab: 1, pro: false)
        XCTAssertTrue(app.buttons["Trends"].waitForExistence(timeout: 30))
        sleep(2)
        if tapIfThere(app.buttons["Custom"]) {
            sleep(2); shot("E01-locked-custom-paywall")
            interrupt(app)
            shot("E02-paywall-after-background")
            note("paywall still up: \(app.buttons["Try Again"].exists || app.buttons["Restore"].exists)")
            app.swipeDown(velocity: .fast); sleep(1)
            shot("E03-after-swipe-dismiss")
            app.buttons["Custom"].tap(); sleep(2)
            shot("E04-paywall-reopened")
            app.swipeDown(velocity: .fast); sleep(1)
        }
        if tapIfThere(app.buttons["VO2+"]) {
            sleep(2); shot("E05-plus-tab-free")
            interrupt(app)
            shot("E06-plus-tab-after-background")
        }
        flush("notes-paywall.txt")
    }

    /// Return after a long absence: the app stays alive in the background while
    /// the user does something else, then foregrounds on a different tab.
    func testF_TabAndScrollSurviveBackground() {
        let app = launch([], tab: 0)
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 30))
        sleep(2)
        tapIfThere(app.buttons["VO2+"]); sleep(2)
        app.swipeUp(); sleep(1)
        shot("F01-plus-scrolled")
        interrupt(app, seconds: 10)
        shot("F02-plus-scrolled-after-background")
        note("VO2+ tab selected after return: \(app.buttons["VO2+"].isSelected)")
        flush("notes-tab.txt")
    }
}
