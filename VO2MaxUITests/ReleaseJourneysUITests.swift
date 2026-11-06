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
        checkpoint("welcome", button: "Continue", in: app)
        tap("Continue", in: app)
        checkpoint("profile", button: "Continue", in: app)
        tap("Continue", in: app)
        checkpoint("target", button: "Continue", in: app)
        tap("Continue", in: app)
        XCTAssertTrue(app.buttons["Continue with VO2+"].waitForExistence(timeout: 20))
        QA.checkpoint(app, "onboarding-trial", paywall: true)
        tap("Get Started", in: app)
        let whatsNew = app.buttons["Not now"]
        if whatsNew.waitForExistence(timeout: 8) {
            QA.checkpoint(app, "whats-new")
            whatsNew.tap()
        }
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 20))
        QA.checkpoint(app, "first-today")
    }

    func test2TabsUpgradeSettingsAndReturn() {
        let app = XCUIApplication(bundleIdentifier: Self.bundleID)
        QA.launch(app, environment: Self.customer,
                  arguments: ["-DemoData", "-SeedScreenshotData", "-rcfunnelprobe", "-ScreenshotTab", "0"])
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 20))
        QA.checkpoint(app, "today")

        tap("Trends", in: app)
        QA.checkpoint(app, "trends")

        tap("VO2+", in: app)
        XCTAssertTrue(app.buttons["Restore"].firstMatch.waitForExistence(timeout: 20))
        QA.checkpoint(app, "upgrade", paywall: true)

        tap("Today", in: app)
        tap("Settings", in: app)
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 15))
        QA.checkpoint(app, "settings")
        app.swipeDown(velocity: .fast)
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 15))

        QA.interrupt(app)
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 15))
        QA.checkpoint(app, "today-after-background")
        QA.relaunch(app)
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 20))
        QA.checkpoint(app, "today-after-relaunch")
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
