import XCTest

private struct StoreScreenshotLocale: Decodable {
    let store_locale: String
    let language: String
    let apple_locale: String
}

private struct StoreScreenshotScene: Decodable {
    let name: String
    let route: String
}

private struct StoreScreenshotLocales: Decodable {
    let locales: [StoreScreenshotLocale]
    let scenes: [StoreScreenshotScene]
}

/// The release gate's journeys (`qa-gate run`). Each step ends in a
/// `QA.checkpoint`, which runs the fleet oracles on whatever is on screen.
/// Core-loop journeys assert outcomes; the rest assert reachability.
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
        checkpoint("welcome", button: ["Continue", "Weiter"], in: app)
        tap(["Continue", "Weiter"], in: app)
        checkpoint("profile", button: ["Continue", "Weiter"], in: app)
        tap(["Continue", "Weiter"], in: app)
        checkpoint("target", button: ["Continue", "Weiter"], in: app)
        tap(["Continue", "Weiter"], in: app)
        XCTAssertTrue(button(["Continue with VO2+", "Weiter mit VO2+"], in: app).waitForExistence(timeout: 20))
        QA.checkpoint(app, "onboarding-trial", paywall: true)
        tap(["Get Started", "Los geht's"], in: app)
        let whatsNew = button(["Not now", "Nicht jetzt"], in: app)
        if whatsNew.waitForExistence(timeout: 8) {
            QA.checkpoint(app, "whats-new")
            whatsNew.tap()
        }
        XCTAssertTrue(button(Self.today, in: app).waitForExistence(timeout: 20))
        QA.checkpoint(app, "first-today")
    }

    func test2TabsUpgradeSettingsAndReturn() {
        let app = XCUIApplication(bundleIdentifier: Self.bundleID)
        QA.launch(app, environment: Self.customer,
                  arguments: ["-DemoData", "-SeedScreenshotData", "-rcfunnelprobe", "-ScreenshotTab", "0"])
        XCTAssertTrue(button(Self.today, in: app).waitForExistence(timeout: 20))
        QA.checkpoint(app, "today")

        openTrends(in: app)
        QA.checkpoint(app, "trends")

        tap(["VO2+"], in: app)
        XCTAssertTrue(button(["Restore", "Wiederherstellen"], in: app).waitForExistence(timeout: 20))
        QA.checkpoint(app, "upgrade", paywall: true)

        tap(Self.today, in: app)
        tap(["Settings", "Einstellungen"], in: app)
        XCTAssertTrue(settingsBar(in: app).waitForExistence(timeout: 15))
        QA.checkpoint(app, "settings")
        tap(["Done", "Fertig"], in: app)
        XCTAssertTrue(button(Self.today, in: app).waitForExistence(timeout: 15))

        QA.interrupt(app)
        XCTAssertTrue(button(Self.today, in: app).waitForExistence(timeout: 15))
        QA.checkpoint(app, "today-after-background")
        QA.relaunch(app)
        XCTAssertTrue(button(Self.today, in: app).waitForExistence(timeout: 20))
        QA.checkpoint(app, "today-after-relaunch")
    }

    /// Core loop: read the estimate on Today, see the same window's readings
    /// on Trends, open the full list, and find all of it again after a relaunch.
    func testCoreLoopEstimateAndReadingsSurviveRelaunch() {
        let app = XCUIApplication(bundleIdentifier: Self.bundleID)
        QA.launch(app, environment: Self.customer,
                  arguments: ["-DemoData", "-SeedScreenshotData", "-rcfunnelprobe", "-ScreenshotTab", "0"])
        XCTAssertTrue(button(Self.today, in: app).waitForExistence(timeout: 20))
        assertEstimateOnToday(in: app)
        QA.checkpoint(app, "core-today")

        openTrends(in: app)
        assertReadingCount(15, in: app)
        QA.checkpoint(app, "core-trends")

        // The row is one button whose label also carries its caption.
        let allReadings = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'All Readings' OR label BEGINSWITH 'Alle Messwerte'")).firstMatch
        XCTAssertTrue(allReadings.waitForExistence(timeout: 15), "All Readings missing")
        allReadings.tap()
        XCTAssertTrue(app.navigationBars.matching(NSPredicate(format: "identifier IN %@", ["All Readings", "Alle Messwerte"]))
            .firstMatch.waitForExistence(timeout: 15))
        QA.checkpoint(app, "core-all-readings")

        QA.relaunch(app)
        XCTAssertTrue(button(Self.today, in: app).waitForExistence(timeout: 20))
        assertEstimateOnToday(in: app)
        QA.checkpoint(app, "core-today-after-relaunch")
        openTrends(in: app)
        assertReadingCount(15, in: app)
        QA.checkpoint(app, "core-trends-after-relaunch")
    }

    /// Core loop: widen the target range in Settings, Today's ring follows
    /// it, and the new range is still set after the app is killed and reopened.
    func testCoreLoopTargetRangeDrivesTodayAndPersists() {
        let app = XCUIApplication(bundleIdentifier: Self.bundleID)
        QA.launch(app, environment: Self.customer,
                  arguments: ["-DemoData", "-SeedScreenshotData", "-rcfunnelprobe", "-ScreenshotTab", "0"])
        XCTAssertTrue(button(Self.today, in: app).waitForExistence(timeout: 20))
        tap(Self.settings, in: app)
        let slider = targetSlider(in: app)
        let (_, upper) = range(of: slider)
        XCTAssertLessThan(upper, 70, "the target can still widen")
        dragUpperHandleToEnd(slider, from: upper)
        let (lower, raised) = range(of: slider)
        XCTAssertGreaterThan(raised, upper, "the slider moves the top of the range")
        QA.checkpoint(app, "target-widened")
        tap(Self.done, in: app)
        assertTodayTarget(lower, raised, in: app)
        QA.checkpoint(app, "today-new-target")

        QA.relaunch(app)
        assertTodayTarget(lower, raised, in: app)
        tap(Self.settings, in: app)
        XCTAssertEqual(range(of: targetSlider(in: app)).upper, raised, "the target survives a relaunch")
        QA.checkpoint(app, "target-after-relaunch")
        tap(Self.done, in: app)
    }

    private func targetSlider(in app: XCUIApplication) -> XCUIElement {
        let slider = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label IN %@ AND elementType != %d", ["Target range", "Zielbereich"],
                                  XCUIElement.ElementType.staticText.rawValue)).firstMatch
        let scroller = [app.collectionViews, app.tables, app.scrollViews].map(\.firstMatch).first { $0.exists } ?? app.windows.firstMatch
        var scrolls = 0
        while !(slider.exists && slider.isHittable) && scrolls < 8 {
            QA.swipe(scroller, .up)
            scrolls += 1
        }
        XCTAssertTrue(slider.waitForExistence(timeout: 15), "target range slider")
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

    /// Today's caption spells the range out ("Target 40 to 70", "Ziel 40 bis 70").
    private func assertTodayTarget(_ lower: Int, _ upper: Int, in app: XCUIApplication) {
        XCTAssertTrue(button(Self.today, in: app).waitForExistence(timeout: 20))
        let caption = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", ".*\\b\(lower)\\b.*\\b\(upper)\\b.*")).firstMatch
        XCTAssertTrue(caption.waitForExistence(timeout: 15), "Today shows the \(lower) to \(upper) target")
    }

    func testLocalizedStoreScreenshots() throws {
        let bundles = [Bundle(for: Self.self), Bundle.main]
        let url = try XCTUnwrap(bundles.compactMap {
            $0.url(forResource: "StoreScreenshotLocales", withExtension: "json")
        }.first)
        let config = try JSONDecoder().decode(StoreScreenshotLocales.self, from: Data(contentsOf: url))
        for locale in config.locales {
            for scene in config.scenes {
                let app = XCUIApplication(bundleIdentifier: Self.bundleID)
                app.launchArguments = [
                    "-DemoData", "-DemoPro", "-ScreenshotTab", "0",
                    "-AppleLanguages", "(\(locale.language))",
                    "-AppleLocale", locale.apple_locale,
                    "-DuoScreen", scene.route
                ]
                app.launch()
                XCTAssertTrue(app.buttons["VO2+"].firstMatch.waitForExistence(timeout: 120), "App UI missing for \(locale.store_locale)/\(scene.name)")
                Thread.sleep(forTimeInterval: 14)

                let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                attachment.name = "\(locale.store_locale)__\(scene.name).png"
                attachment.lifetime = .keepAlways
                add(attachment)
                app.terminate()
            }
        }
    }

    private static let today = ["Today", "Heute"]
    private static let settings = ["Settings", "Einstellungen"]
    private static let done = ["Done", "Fertig"]

    private func button(_ labels: [String], in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label IN %@", labels)).firstMatch
    }

    private func settingsBar(in app: XCUIApplication) -> XCUIElement {
        app.navigationBars.matching(NSPredicate(format: "identifier IN %@", ["Settings", "Einstellungen"])).firstMatch
    }

    private func tap(_ labels: [String], in app: XCUIApplication) {
        let target = button(labels, in: app)
        XCTAssertTrue(target.waitForExistence(timeout: 15), "\(labels[0]) missing")
        target.tap()
    }

    /// Folded, Trends is a tab. On the unfolded Duo it is the trailing pane and
    /// the tab button is hidden, so only wait for the screen.
    private func openTrends(in app: XCUIApplication) {
        let tab = app.buttons["Trends"].firstMatch
        if tab.waitForExistence(timeout: 5), tab.isHittable { tab.tap() }
        XCTAssertTrue(app.navigationBars["Trends"].waitForExistence(timeout: 15), "Trends missing")
    }

    private func assertEstimateOnToday(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let estimate = app.staticTexts.matching(NSPredicate(format: "label IN %@", ["43.3", "43,3"])).firstMatch
        XCTAssertTrue(estimate.waitForExistence(timeout: 15), "Today estimate 43.3 missing", file: file, line: line)
    }

    private func assertReadingCount(_ count: Int, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let readings = app.staticTexts.matching(NSPredicate(format: "label == %@", "\(count)")).firstMatch
        XCTAssertTrue(readings.waitForExistence(timeout: 15), "\(count) readings missing on Trends", file: file, line: line)
    }

    private func checkpoint(_ name: String, button labels: [String], in app: XCUIApplication, journey: String = #function) {
        XCTAssertTrue(button(labels, in: app).waitForExistence(timeout: 15), "\(labels[0]) missing")
        QA.checkpoint(app, name, journey: journey)
    }
}
