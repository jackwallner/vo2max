import XCTest

/// Screen-level guards for the 2026-11-20 bug catalog. None of these
/// configure RevenueCat: the simulator never configures the production key,
/// so the paywall shows its plans-unavailable state.
@MainActor
final class BugFix20261120UITests: XCTestCase {
    private static let bundleID = "com.jackwallner.vo2max"

    override func setUp() {
        continueAfterFailure = false
    }

    /// Text anywhere on screen, including inside a button or a combined card.
    private func element(containing text: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", text))
            .firstMatch
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func scrollTo(_ target: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 where !(target.exists && target.isHittable) { app.swipeUp() }
    }

    /// B1: the Health prompt has been answered (the persisted grant flag is
    /// set), but Apple Health returns nothing, which is what a decline looks
    /// like. Today has to say where VO2 max is switched back on.
    func testB1DeclinedHealthAccessShowsTheWayBack() {
        let app = XCUIApplication(bundleIdentifier: Self.bundleID)
        app.launchArguments += ["-ScreenshotTab", "0", "-hasGrantedHealthAccess", "YES"]
        app.launch()

        XCTAssertTrue(element(containing: "Your first estimate will appear here", in: app).waitForExistence(timeout: 30))
        let steps = element(containing: "Privacy > Apps > VO2 Max Daily Tracker", in: app)
        scrollTo(steps, in: app)
        attach(app, "b1-today-no-estimate")
        XCTAssertTrue(steps.exists, "no way to turn VO2 max back on")
        XCTAssertTrue(app.buttons["Open Apple Health"].exists)
    }
}
