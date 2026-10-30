import XCTest

/// Settings "Restore Purchases" must say what happened. Runs against
/// RevenueCat's Test Store (`-rcfunnelprobe`, never the production key) as a
/// customer with no purchase, so the expected outcome is the no-purchase line.
@MainActor
final class SettingsRestoreUITests: XCTestCase {
    func testRestoreWithNoPurchaseSaysSo() {
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.vo2max")
        app.launchArguments += ["-DemoData", "-SeedScreenshotData", "-rcfunnelprobe", "-ScreenshotTab", "0"]
        app.launchEnvironment["RC_PROBE_USER"] = "restore-probe-vo2max-\(UUID().uuidString.prefix(8))"
        app.launch()

        let settings = app.buttons["Settings"].firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 20))
        settings.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 15))

        let restore = app.buttons["Restore Purchases"].firstMatch
        for _ in 0..<8 where !restore.isHittable { app.swipeUp() }
        XCTAssertTrue(restore.isHittable, "Restore Purchases missing")
        restore.tap()

        let result = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "No active VO2+ purchase")).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 30), "Restore finished with no visible outcome")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "settings-restore-no-purchase"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
