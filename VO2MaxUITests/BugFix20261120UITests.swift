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

    /// B2: a VO2+ subscriber whose supporting Health types return nothing (the
    /// second Health sheet was declined). The empty cards point at the setting
    /// instead of blaming the Health data, and the detail screen opens Health.
    func testB2DeclinedSupportingTypesShowTheWayBack() {
        let app = XCUIApplication(bundleIdentifier: Self.bundleID)
        app.launchArguments += [
            "-ScreenshotTab", "1", "-DemoPro",
            "-hasGrantedHealthAccess", "YES", "-hasRequestedExtendedHealthTypes", "YES"
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars["Trends"].waitForExistence(timeout: 30))
        let steps = element(containing: "Privacy > Apps > VO2 Max Daily Tracker", in: app)
        scrollTo(steps, in: app)
        attach(app, "b2-trends-empty-signals")
        XCTAssertTrue(steps.waitForExistence(timeout: 15), "empty signal cards never mention Health access")
        XCTAssertFalse(element(containing: "check that Apple Health has this data", in: app).exists)

        steps.tap()
        let open = app.buttons["Open Apple Health"].firstMatch
        XCTAssertTrue(open.waitForExistence(timeout: 15), "detail screen has no way to open Health")
        attach(app, "b2-detail-empty")
    }

    /// Every launch that wants a free user overrides the App Group's cached
    /// entitlement: `-DemoPro` (the B2 test) writes it, and a later launch on
    /// the same simulator would otherwise start as a subscriber.
    private static let freeUser = ["-isPro", "NO"]

    /// B5: the plans-unavailable paywall still offers Restore, Terms and Privacy.
    func testB5PlansUnavailableKeepsRestoreAndLegalLinks() {
        let app = XCUIApplication(bundleIdentifier: Self.bundleID)
        app.launchArguments += ["-PaywallSnapshot"] + Self.freeUser
        app.launch()

        XCTAssertTrue(app.staticTexts["VO2+ Plans Unavailable"].waitForExistence(timeout: 30))
        attach(app, "b5-paywall-unavailable")
        XCTAssertTrue(app.buttons["Try Again"].exists)
        XCTAssertTrue(app.buttons["Restore"].exists, "no Restore")
        XCTAssertTrue(app.links["Terms"].exists || app.buttons["Terms"].exists, "no Terms")
        XCTAssertTrue(app.links["Privacy"].exists || app.buttons["Privacy"].exists, "no Privacy")

        app.buttons["Restore"].tap()
        XCTAssertTrue(element(containing: "No active VO2+ purchase", in: app).waitForExistence(timeout: 15),
                      "Restore finished with no visible outcome")
    }

    /// B5 and B10 on the VO2+ tab, the other way a free user reaches the
    /// paywall: at the largest text size Restore, Terms and Privacy are still
    /// reachable above the tab bar.
    func testB5EmbeddedPlansUnavailableAtLargestTextKeepsRestore() {
        let app = XCUIApplication(bundleIdentifier: Self.bundleID)
        app.launchArguments += [
            "-ScreenshotTab", "2",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ] + Self.freeUser
        app.launch()

        XCTAssertTrue(app.staticTexts["VO2+ Plans Unavailable"].waitForExistence(timeout: 30))
        attach(app, "b5-plus-tab-unavailable-axxxl-top")
        // The tab bar band (`MainTabView.tabBarBandHeight`, 92 pt folded) is
        // opaque but ignores touches, so `isHittable` alone passes for a link
        // drawn underneath it. Scroll until the link sits above the band.
        let bandTop = app.windows.firstMatch.frame.maxY - 92
        let privacy = app.links["Privacy"].exists ? app.links["Privacy"] : app.buttons["Privacy"]
        let restore = app.buttons["Restore"]
        for _ in 0..<8 where !(privacy.exists && privacy.frame.maxY <= bandTop) { app.swipeUp() }
        attach(app, "b5-plus-tab-unavailable-axxxl-bottom")
        XCTAssertTrue(privacy.exists && privacy.frame.maxY <= bandTop, "Privacy link stays under the tab bar on the VO2+ tab")
        XCTAssertTrue(restore.frame.minY >= 0 && restore.frame.maxY <= bandTop, "Restore out of view on the VO2+ tab")
    }

    /// B10: at the largest text size the plans-unavailable state scrolls, so
    /// its whole message and the buttons under it stay reachable.
    func testB10PlansUnavailableAtLargestTextReachesEveryControl() {
        let app = XCUIApplication(bundleIdentifier: Self.bundleID)
        app.launchArguments += [
            "-PaywallSnapshot",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ] + Self.freeUser
        app.launch()

        XCTAssertTrue(app.staticTexts["VO2+ Plans Unavailable"].waitForExistence(timeout: 30))
        attach(app, "b10-paywall-unavailable-axxxl-top")
        let privacy = app.links["Privacy"].exists ? app.links["Privacy"] : app.buttons["Privacy"]
        scrollTo(privacy, in: app)
        attach(app, "b10-paywall-unavailable-axxxl-bottom")
        XCTAssertTrue(privacy.exists && privacy.isHittable, "Privacy link out of reach at the largest text size")
    }
}
