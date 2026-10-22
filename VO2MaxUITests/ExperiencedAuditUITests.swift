import XCTest

/// Returning-user walk for the experienced persona audit. Public demo fixtures
/// only: `-DemoData -DemoPro` (no RevenueCat key on a simulator) and
/// `-ScreenshotTab` to skip onboarding. Each step attaches a screenshot; element
/// frames and accessibility dumps are attached as text.
final class ExperiencedAuditUITests: XCTestCase {

    private var frames = [String]()

    private func launch(_ extra: [String] = [], tab: Int = 0) -> XCUIApplication {
        continueAfterFailure = true
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.vo2max")
        app.launchArguments += ["-DemoData", "-DemoPro", "-ScreenshotTab", "\(tab)"] + extra
        app.launch()
        return app
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func dump(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(string: app.debugDescription)
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

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

    @discardableResult
    private func tapIfThere(_ el: XCUIElement, wait: TimeInterval = 4) -> Bool {
        guard el.waitForExistence(timeout: wait) else {
            frames.append("MISSING: \(el)")
            return false
        }
        el.tap()
        return true
    }

    private func label(_ app: XCUIApplication, contains text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }

    private func back(_ app: XCUIApplication) {
        let b = app.navigationBars.buttons.firstMatch
        if b.exists { b.tap() }
        sleep(1)
    }

    /// Today, then every drill-down a returning user repeats.
    func testProTodayAndDetails() {
        let app = launch()
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 30))
        sleep(3)
        shot("01-today-pro")
        dump(app, "today-tree.txt")
        for tab in ["Today", "Trends", "VO2+"] { note("tab \(tab)", app.buttons[tab]) }
        note("settings gear", app.buttons["Settings"])
        note("ring", app.buttons["Latest Apple Health estimate"])

        app.swipeUp(); sleep(1)
        shot("02-today-scrolled")
        app.swipeUp(); sleep(1)
        shot("02b-today-scrolled-more")
        app.swipeDown(velocity: .fast); app.swipeDown(velocity: .fast); sleep(1)

        // Signal tiles (RHR / HRR / Load) as a Pro user.
        for name in ["Resting", "recovery", "load"] {
            let tile = label(app, contains: name)
            note("tile \(name)", tile)
        }
        let resting = label(app, contains: "Resting")
        if tapIfThere(resting) {
            sleep(2); shot("03-resting-hr-detail"); dump(app, "resting-tree.txt")
            app.swipeUp(); sleep(1); shot("03b-resting-hr-lower")
            back(app)
        }
        let recovery = label(app, contains: "recovery")
        if tapIfThere(recovery) {
            sleep(2); shot("04-hrr-detail")
            app.swipeUp(); sleep(1); shot("04b-hrr-lower")
            back(app)
        }
        let load = label(app, contains: "load")
        if tapIfThere(load) {
            sleep(2); shot("05-load-detail")
            app.swipeUp(); sleep(1); shot("05b-load-lower")
            back(app)
        }

        if tapIfThere(label(app, contains: "Cardio fitness trend")) {
            sleep(2); shot("06-trend-detail"); dump(app, "trend-tree.txt")
            app.swipeUp(); sleep(1); shot("06b-trend-lower")
            back(app)
        }
        if tapIfThere(label(app, contains: "Fitness age")) {
            sleep(2); shot("07-fitness-age")
            app.swipeUp(); sleep(1); shot("07b-fitness-age-lower")
            back(app)
        }
        flushFrames("frames-today.txt")
    }

    /// Trends: the range picker, a custom range, chart interaction, and the
    /// comparison rows.
    func testTrendsRangesAndCustom() {
        let app = launch(tab: 1)
        XCTAssertTrue(app.buttons["Trends"].waitForExistence(timeout: 30))
        sleep(3)
        shot("10-trends-default")
        dump(app, "trends-tree.txt")
        for r in ["30D", "90D", "6M", "1Y", "Custom"] { note("range \(r)", app.buttons[r]) }
        note("Readings", app.staticTexts["Readings"])
        note("first scroll view", app.scrollViews.firstMatch)

        for r in ["30D", "6M", "1Y", "90D"] {
            if tapIfThere(app.buttons[r]) { sleep(1); shot("11-range-\(r)") }
        }

        // Chart: tap and drag across it to see if anything is selectable.
        let chart = app.otherElements["Chart"].exists ? app.otherElements["Chart"] : app.images.firstMatch
        note("chart", chart)
        let mid = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        mid.tap(); sleep(1); shot("12-chart-tap-center")
        mid.press(forDuration: 0.8); sleep(1); shot("12b-chart-longpress")

        // Custom range
        if tapIfThere(app.buttons["Custom"]) {
            sleep(2); shot("13-custom-sheet"); dump(app, "custom-tree.txt")
            note("Apply", app.buttons["Apply"])
            note("Cancel", app.buttons["Cancel"])
            if tapIfThere(app.buttons["Apply"]) { sleep(2); shot("14-after-custom-apply") }
        }
        app.swipeUp(); sleep(1); shot("15-trends-lower-custom")
        app.swipeUp(); sleep(1); shot("15b-trends-lowest-custom")

        // Switching away and back: does the range follow the user?
        app.buttons["VO2+"].tap(); sleep(2); shot("16-plus-tab-range-caption")
        app.buttons["Trends"].tap(); sleep(1)
        shot("17-trends-back")
        flushFrames("frames-trends.txt")
    }

    /// The VO2+ hub and every row it links to.
    func testPlusHubRows() {
        let app = launch(tab: 2)
        XCTAssertTrue(app.buttons["VO2+"].waitForExistence(timeout: 30))
        sleep(3)
        shot("20-plus-hub")
        dump(app, "plus-tree.txt")
        app.swipeUp(); sleep(1); shot("20b-plus-hub-mid")
        app.swipeUp(); sleep(1); shot("20c-plus-hub-bottom")
        app.swipeDown(velocity: .fast); app.swipeDown(velocity: .fast); sleep(1)

        for title in ["Estimate Freshness", "Deep Trends", "Target Outlook", "Fitness Context"] {
            app.swipeUp(); sleep(1)
            let row = label(app, contains: title)
            note("row \(title)", row)
            if tapIfThere(row, wait: 3) {
                sleep(2); shot("21-\(title.replacingOccurrences(of: " ", with: "-"))")
                app.swipeUp(); sleep(1)
                shot("21b-\(title.replacingOccurrences(of: " ", with: "-"))-lower")
                back(app)
            }
        }
        app.swipeUp(); app.swipeUp(); sleep(1)
        let recap = label(app, contains: "Monthly Recap")
        note("Monthly Recap row", recap)
        if tapIfThere(recap, wait: 3) {
            sleep(2); shot("22-monthly-recap"); dump(app, "recap-tree.txt")
            app.swipeUp(); sleep(1); shot("22b-recap-lower")
        }
        flushFrames("frames-plus.txt")
    }

    /// Settings as a returning user adjusting target and profile.
    func testSettingsAdjustments() {
        let app = launch()
        XCTAssertTrue(tapIfThere(app.buttons["Settings"], wait: 30))
        sleep(2)
        shot("30-settings")
        dump(app, "settings-tree.txt")
        note("Done", app.buttons["Done"])
        app.swipeUp(); sleep(1); shot("31-settings-mid")
        dump(app, "settings-mid-tree.txt")
        app.swipeUp(); sleep(1); shot("32-settings-lower")
        app.swipeUp(); sleep(1); shot("33-settings-bottom")
        app.swipeDown(velocity: .fast); app.swipeDown(velocity: .fast); app.swipeDown(velocity: .fast); sleep(1)

        // Target slider: nudge it and see feedback.
        let sliders = app.sliders
        frames.append("sliders=\(sliders.count) switches=\(app.switches.count) pickers=\(app.pickerWheels.count)")
        for i in 0..<min(app.switches.count, 6) {
            note("switch \(i) '\(app.switches.element(boundBy: i).label)'", app.switches.element(boundBy: i))
        }
        // Age picker
        let age = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Age'")).firstMatch
        note("Age picker", age)
        if tapIfThere(age, wait: 3) { sleep(1); shot("34-age-picker"); dump(app, "age-tree.txt") }
        flushFrames("frames-settings.txt")
    }

    /// Relaunch twice in a row: what state persists for a repeat visit?
    func testRepeatLaunchStateAndSpeed() {
        var app = launch(tab: 1)
        XCTAssertTrue(app.buttons["Trends"].waitForExistence(timeout: 30))
        sleep(2)
        tapIfThere(app.buttons["1Y"]); sleep(1)
        shot("40-picked-1Y")
        app.terminate()
        let t0 = Date()
        app = launch(tab: 0)
        let appeared = app.buttons["Latest Apple Health estimate"].waitForExistence(timeout: 20)
        frames.append("cold relaunch to ring visible: \(appeared) \(String(format: "%.1f", Date().timeIntervalSince(t0)))s (includes harness launch)")
        shot("41-relaunch-today")
        app.buttons["Trends"].tap(); sleep(2)
        shot("42-relaunch-trends-range-kept")
        note("1Y selected?", app.buttons["1Y"])
        frames.append("1Y isSelected=\(app.buttons["1Y"].isSelected)")
        flushFrames("frames-relaunch.txt")
    }
}
