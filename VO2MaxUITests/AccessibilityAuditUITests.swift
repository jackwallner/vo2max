import XCTest

/// Large-text and reach walk for the accessibility persona audit. Public demo
/// fixtures only (`-DemoData`, `-DemoPro`, no RevenueCat key on a simulator).
/// Dynamic Type is forced through launch arguments; each step attaches a
/// screenshot and element frames as text.
final class AccessibilityAuditUITests: XCTestCase {

    private var frames = [String]()
    private let ax3 = "UICTContentSizeCategoryAccessibilityL"
    private let ax5 = "UICTContentSizeCategoryAccessibilityXXXL"

    private func launch(_ extra: [String], size: String, tab: Int? = 0) -> XCUIApplication {
        continueAfterFailure = true
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.vo2max")
        var args = ["-DemoData", "-UIPreferredContentSizeCategoryName", size]
        if let tab { args += ["-DemoPro", "-ScreenshotTab", "\(tab)"] }
        app.launchArguments += args + extra
        app.launch()
        return app
    }

    private func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    private func dump(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(string: app.debugDescription)
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    private func note(_ label: String, _ el: XCUIElement) {
        let f = el.exists ? el.frame : .zero
        frames.append("\(label): exists=\(el.exists) hittable=\(el.exists && el.isHittable) \(Int(f.width))x\(Int(f.height)) at (\(Int(f.minX)),\(Int(f.minY)))")
    }

    private func flush(_ name: String) {
        let a = XCTAttachment(string: frames.joined(separator: "\n"))
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    @discardableResult
    private func tapIfThere(_ el: XCUIElement, wait: TimeInterval = 4) -> Bool {
        guard el.waitForExistence(timeout: wait) else { frames.append("MISSING: \(el)"); return false }
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

    private func scrollShots(_ app: XCUIApplication, _ prefix: String, count: Int = 3) {
        for i in 1...count {
            app.swipeUp(); sleep(1)
            shot("\(prefix)-scroll\(i)")
        }
    }

    /// Onboarding at the largest accessibility size: can every step be finished?
    func testOnboardingAtAX5() {
        let app = launch([], size: ax5, tab: nil)
        let cont = app.buttons["Continue"]
        XCTAssertTrue(cont.waitForExistence(timeout: 30))
        sleep(1)
        shot("01-ax5-welcome"); dump(app, "ax5-welcome-tree.txt")
        note("welcome Continue", cont)
        cont.tap(); sleep(1)
        shot("02-ax5-profile"); dump(app, "ax5-profile-tree.txt")
        note("profile Continue", app.buttons["Continue"])
        scrollShots(app, "02b-ax5-profile", count: 1)
        if tapIfThere(app.buttons["Continue"]) { sleep(1) }
        shot("03-ax5-target"); dump(app, "ax5-target-tree.txt")
        note("target Continue", app.buttons["Continue"])
        app.swipeUp(); sleep(1); shot("03b-ax5-target-lower")
        if tapIfThere(app.buttons["Continue"]) { sleep(2) }
        shot("04-ax5-trial"); dump(app, "ax5-trial-tree.txt")
        note("trial CTA", app.buttons["Continue with VO2+"])
        note("trial Get Started", app.buttons["Get Started"])
        note("trial Restore", app.buttons["Restore"])
        app.swipeUp(); sleep(1); shot("04b-ax5-trial-lower")
        app.swipeUp(); sleep(1); shot("04c-ax5-trial-bottom")
        flush("frames-onboarding-ax5.txt")
    }

    /// Today and its drill-downs at AX3 (a common low-vision setting).
    func testTodayAtAX3() {
        let app = launch([], size: ax3)
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 30))
        sleep(3)
        shot("10-ax3-today"); dump(app, "ax3-today-tree.txt")
        for tab in ["Today", "Trends", "VO2+"] { note("tab \(tab)", app.buttons[tab]) }
        note("settings gear", app.buttons["Settings"])
        note("ring", app.buttons["Latest Apple Health estimate"])
        scrollShots(app, "11-ax3-today")
        for name in ["Resting", "recovery", "load", "Cardio fitness trend", "Fitness age"] {
            note("row \(name)", label(app, contains: name))
        }
        flush("frames-today-ax3.txt")
    }

    /// Today at the largest size: the ring caption, signal row and tab bar.
    func testTodayAtAX5() {
        let app = launch([], size: ax5)
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 30))
        sleep(3)
        shot("20-ax5-today"); dump(app, "ax5-today-tree.txt")
        for tab in ["Today", "Trends", "VO2+"] { note("tab \(tab)", app.buttons[tab]) }
        note("settings gear", app.buttons["Settings"])
        scrollShots(app, "21-ax5-today", count: 4)
        let resting = label(app, contains: "Resting")
        if tapIfThere(resting, wait: 3) { sleep(2); shot("22-ax5-resting"); app.swipeUp(); sleep(1); shot("22b-ax5-resting-lower"); back(app) }
        if tapIfThere(label(app, contains: "Cardio fitness trend"), wait: 3) { sleep(2); shot("23-ax5-trend"); app.swipeUp(); sleep(1); shot("23b-ax5-trend-lower"); back(app) }
        flush("frames-today-ax5.txt")
    }

    /// Trends: the range picker is a row of small chips; at large text it must still be usable.
    func testTrendsAtAX5() {
        let app = launch([], size: ax5, tab: 1)
        XCTAssertTrue(app.buttons["Trends"].waitForExistence(timeout: 30))
        sleep(3)
        shot("30-ax5-trends"); dump(app, "ax5-trends-tree.txt")
        for r in ["30D", "90D", "6M", "1Y", "Custom"] { note("range \(r)", app.buttons[r]) }
        scrollShots(app, "31-ax5-trends", count: 3)
        app.swipeDown(velocity: .fast); app.swipeDown(velocity: .fast); app.swipeDown(velocity: .fast)
        if tapIfThere(app.buttons["Custom"], wait: 3) {
            sleep(2); shot("32-ax5-custom"); dump(app, "ax5-custom-tree.txt")
            note("Apply", app.buttons["Apply"]); note("Cancel", app.buttons["Cancel"])
            app.swipeUp(); sleep(1); shot("32b-ax5-custom-lower")
        }
        flush("frames-trends-ax5.txt")
    }

    /// VO2+ hub and Settings at AX5, plus reach from the bottom of the screen.
    func testPlusAndSettingsAtAX5() {
        var app = launch([], size: ax5, tab: 2)
        XCTAssertTrue(app.buttons["VO2+"].waitForExistence(timeout: 30))
        sleep(3)
        shot("40-ax5-plus"); dump(app, "ax5-plus-tree.txt")
        scrollShots(app, "41-ax5-plus", count: 4)
        app.terminate()

        app = launch([], size: ax5)
        XCTAssertTrue(tapIfThere(app.buttons["Settings"], wait: 30))
        sleep(2)
        shot("50-ax5-settings"); dump(app, "ax5-settings-tree.txt")
        note("Done", app.buttons["Done"])
        scrollShots(app, "51-ax5-settings", count: 5)
        frames.append("switches=\(app.switches.count) sliders=\(app.sliders.count)")
        flush("frames-plus-settings-ax5.txt")
    }

    /// Reach: where do the primary controls sit relative to the thumb zone?
    func testReachAtDefaultSize() {
        let app = launch([], size: "UICTContentSizeCategoryL")
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 30))
        sleep(3)
        let screen = app.frame
        frames.append("screen \(Int(screen.width))x\(Int(screen.height))")
        note("settings gear", app.buttons["Settings"])
        note("ring", app.buttons["Latest Apple Health estimate"])
        for tab in ["Today", "Trends", "VO2+"] { note("tab \(tab)", app.buttons[tab]) }
        shot("60-default-today")
        app.buttons["Trends"].tap(); sleep(2)
        for r in ["30D", "90D", "6M", "1Y", "Custom"] { note("range \(r)", app.buttons[r]) }
        shot("61-default-trends")
        flush("frames-reach.txt")
    }
}
