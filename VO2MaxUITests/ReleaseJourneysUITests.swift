import XCTest

/// The release gate's journeys (`qa-gate run`). Each step ends in a
/// `QA.checkpoint`, which runs the fleet oracles on whatever is on screen.
/// Journeys assert reachability only.
///
/// `-DemoData` stands in for Apple Health, and `-rcfunnelprobe` loads plans from
/// RevenueCat's Test Store (a separate app in the project, never the production
/// key), so the paywalls render real prices on the simulator.
@MainActor
final class ReleaseJourneysUITests: XCTestCase {
    private static let bundleID = "com.jackwallner.vo2max"
    private static let customer = ["RC_PROBE_USER": "qa-ios-journeys", "RC_PROBE_SURFACE": "qa_gate"]

    override func setUp() {
        continueAfterFailure = false
    }

    func test1FirstRunToTrial() {
        let app = XCUIApplication(bundleIdentifier: Self.bundleID)
        QA.launch(app, environment: Self.customer, arguments: ["-DemoData", "-rcfunnelprobe"])
        checkpoint("welcome", button: L("Continue"), in: app)
        tap(L("Continue"), in: app)
        checkpoint("profile", button: L("Continue"), in: app)
        tap(L("Continue"), in: app)
        checkpoint("target", button: L("Continue"), in: app)
        tap(L("Continue"), in: app)
        XCTAssertTrue(app.buttons[L("Continue with VO2+")].waitForExistence(timeout: 20))
        QA.checkpoint(app, "onboarding-trial", paywall: true)
        tap(L("Get Started"), in: app)
        let whatsNew = app.buttons[L("Not now")]
        if whatsNew.waitForExistence(timeout: 8) {
            QA.checkpoint(app, "whats-new")
            whatsNew.tap()
        }
        XCTAssertTrue(app.buttons[L("Today")].waitForExistence(timeout: 20))
        QA.checkpoint(app, "first-today")
    }

    func test2TabsUpgradeSettingsAndReturn() {
        let app = XCUIApplication(bundleIdentifier: Self.bundleID)
        QA.launch(app, environment: Self.customer,
                  arguments: ["-DemoData", "-SeedScreenshotData", "-rcfunnelprobe", "-ScreenshotTab", "0"])
        XCTAssertTrue(app.buttons[L("Today")].waitForExistence(timeout: 20))
        QA.checkpoint(app, "today")

        tap(L("Trends"), in: app)
        QA.checkpoint(app, "trends")

        tap(L("VO2+"), in: app)
        XCTAssertTrue(app.buttons[L("Restore")].firstMatch.waitForExistence(timeout: 20))
        QA.checkpoint(app, "upgrade", paywall: true)

        tap(L("Today"), in: app)
        tap(L("Settings"), in: app)
        XCTAssertTrue(app.navigationBars[L("Settings")].waitForExistence(timeout: 15))
        QA.checkpoint(app, "settings")
        app.swipeDown(velocity: .fast)
        XCTAssertTrue(app.buttons[L("Today")].waitForExistence(timeout: 15))

        QA.interrupt(app)
        XCTAssertTrue(app.buttons[L("Today")].waitForExistence(timeout: 15))
        QA.checkpoint(app, "today-after-background")
        QA.relaunch(app)
        XCTAssertTrue(app.buttons[L("Today")].waitForExistence(timeout: 20))
        QA.checkpoint(app, "today-after-relaunch")
    }

    /// Core loop: widen the target range in Settings, Today's ring follows
    /// it, and the new range is still set after the app is killed and reopened.
    func testCoreLoopTargetRangeDrivesTodayAndPersists() {
        let app = XCUIApplication(bundleIdentifier: Self.bundleID)
        QA.launch(app, environment: Self.customer,
                  arguments: ["-DemoData", "-SeedScreenshotData", "-rcfunnelprobe", "-ScreenshotTab", "0"])
        XCTAssertTrue(app.buttons[L("Today")].waitForExistence(timeout: 20))
        tap(L("Settings"), in: app)
        let slider = targetSlider(in: app)
        let (_, upper) = range(of: slider)
        XCTAssertLessThan(upper, 70, "the target can still widen")
        dragUpperHandleToEnd(slider, from: upper)
        let (lower, raised) = range(of: slider)
        XCTAssertGreaterThan(raised, upper, "the slider moves the top of the range")
        QA.checkpoint(app, "target-widened")
        tap(L("Done"), in: app)
        assertTodayTarget(lower, raised, in: app)
        QA.checkpoint(app, "today-new-target")

        QA.relaunch(app)
        assertTodayTarget(lower, raised, in: app)
        tap(L("Settings"), in: app)
        XCTAssertEqual(range(of: targetSlider(in: app)).upper, raised, "the target survives a relaunch")
        QA.checkpoint(app, "target-after-relaunch")
        tap(L("Done"), in: app)
    }

    private func targetSlider(in app: XCUIApplication) -> XCUIElement {
        let slider = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@ AND elementType != %d", L("Target range"),
                                  XCUIElement.ElementType.staticText.rawValue)).firstMatch
        XCTAssertTrue(slider.waitForExistence(timeout: 15), "target range slider")
        var scrolls = 0
        while !slider.isHittable && scrolls < 5 {
            QA.swipe(app.collectionViews.firstMatch.exists ? app.collectionViews.firstMatch : app.windows.firstMatch, .up)
            scrolls += 1
        }
        return slider
    }

    /// Drags the upper handle to the end of the track (the Settings bounds are
    /// 20...70, with 30-point handles along the top of the control).
    private func dragUpperHandleToEnd(_ slider: XCUIElement, from upper: Int) {
        let width = slider.frame.width
        let handleX = CGFloat(upper - 20) / 50 * (width - 30) + 15
        let origin = slider.coordinate(withNormalizedOffset: .zero)
        origin.withOffset(CGVector(dx: handleX, dy: 15))
            .press(forDuration: 0.05, thenDragTo: origin.withOffset(CGVector(dx: width + 20, dy: 15)),
                   withVelocity: .slow, thenHoldForDuration: 0.1)
    }

    /// The slider reads "Target from 40 to 55" (German "Zielbereich von 40 bis 55").
    private func range(of slider: XCUIElement) -> (lower: Int, upper: Int) {
        let value = slider.value as? String ?? ""
        let numbers = value.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        XCTAssertEqual(numbers.count, 2, "range in \(value)")
        return numbers.count == 2 ? (numbers[0], numbers[1]) : (0, 0)
    }

    private func assertTodayTarget(_ lower: Int, _ upper: Int, in app: XCUIApplication) {
        XCTAssertTrue(app.buttons[L("Today")].waitForExistence(timeout: 20))
        let caption = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "\(lower)–\(upper)")).firstMatch
        XCTAssertTrue(caption.waitForExistence(timeout: 15), "Today shows the \(lower)–\(upper) target")
    }

    /// The German strings the journeys look for; other personas see the English source.
    private static let german = [
        "Continue": "Weiter", "Continue with VO2+": "Weiter mit VO2+", "Get Started": "Los geht's",
        "Not now": "Nicht jetzt", "Today": "Heute", "Trends": "Trends", "VO2+": "VO2+",
        "Restore": "Wiederherstellen", "Settings": "Einstellungen", "Target range": "Zielbereich",
        "Done": "Fertig",
    ]

    private func L(_ english: String) -> String {
        QA.persona == "german" ? Self.german[english] ?? english : english
    }

    private func tap(_ label: String, in app: XCUIApplication) {
        let button = app.buttons[label].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 15), "\(label) missing")
        button.tap()
    }

    private func checkpoint(_ name: String, button label: String, in app: XCUIApplication) {
        XCTAssertTrue(app.buttons[label].firstMatch.waitForExistence(timeout: 15), "\(label) missing")
        QA.checkpoint(app, name)
    }
}
