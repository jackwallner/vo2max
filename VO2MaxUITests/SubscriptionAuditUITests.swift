import XCTest

/// Skeptical-free-user walk for the subscription persona audit. What is locked,
/// what the pitch says, how to restore, how to leave, and what a subscriber can
/// do to manage or cancel. Public demo fixtures only (`-DemoData`, optionally
/// `-DemoPro`). The store tests use RevenueCat's Test Store through the existing
/// DEBUG `-rcfunnelprobe` path, so plans render without a production key. No test
/// here taps a purchase button.
final class SubscriptionAuditUITests: XCTestCase {

    private var frames = [String]()

    private func launch(_ extra: [String] = [], env: [String: String] = [:]) -> XCUIApplication {
        continueAfterFailure = true
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.vo2max")
        app.launchArguments += ["-DemoData", "-ResetProCache"] + extra
        for (key, value) in env { app.launchEnvironment[key] = value }
        app.launch()
        return app
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func attach(_ text: String, _ name: String) {
        let a = XCTAttachment(string: text)
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    private func dump(_ app: XCUIApplication, _ name: String) { attach(app.debugDescription, name) }

    private func note(_ label: String, _ element: XCUIElement) {
        let f = element.exists ? element.frame : .zero
        frames.append("\(label): exists=\(element.exists) \(Int(f.width))x\(Int(f.height)) at (\(Int(f.minX)),\(Int(f.minY)))")
    }

    /// Every visible static text, so the report can quote what the user reads.
    private func texts(_ app: XCUIApplication, _ name: String) {
        let all = app.staticTexts.allElementsBoundByIndex.map { $0.label }.filter { !$0.isEmpty }
        attach(all.joined(separator: "\n"), "texts-\(name).txt")
    }

    private func flushFrames(_ name: String) { attach(frames.joined(separator: "\n"), name) }

    @discardableResult
    private func tapIfThere(_ el: XCUIElement, wait: TimeInterval = 4) -> Bool {
        guard el.waitForExistence(timeout: wait) else {
            frames.append("MISSING: \(el)")
            return false
        }
        el.tap()
        return true
    }

    private func any(_ app: XCUIApplication, containing text: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }

    /// A SwiftUI Toggle row ignores a tap on its label centre in this layout, so
    /// press the switch itself at the trailing edge.
    private func flip(_ sw: XCUIElement) {
        sw.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
    }

    /// The Trends tab keeps a second page alive behind the visible one, so a
    /// label can match twice. Take the one on screen.
    private func visible(_ app: XCUIApplication, _ label: String) -> XCUIElement {
        let all = app.buttons.matching(NSPredicate(format: "label == %@", label)).allElementsBoundByIndex
        return all.first(where: { $0.isHittable }) ?? app.buttons[label].firstMatch
    }

    private func dismissSheet(_ app: XCUIApplication, _ tag: String) {
        let close = app.buttons["Close"]
        let notNow = app.buttons["Not now"]
        if close.exists {
            note("\(tag) Close", close)
            close.tap()
        } else if notNow.exists {
            note("\(tag) Not now", notNow)
            notNow.tap()
        } else {
            frames.append("\(tag): no Close or Not now button, swiping down")
            app.swipeDown(velocity: .fast)
        }
        sleep(1)
    }

    // MARK: - Free tier

    /// Everything a free user can tap that is locked, and where each tap lands.
    func testFreeTierLocksAndPitchSurfaces() {
        let app = launch(["-ScreenshotTab", "0"])
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 30))
        sleep(3)
        shot("01-today-free")
        texts(app, "today-free")
        dump(app, "today-free-tree.txt")

        for name in ["Resting", "recovery", "load"] {
            note("free tile \(name)", any(app, containing: name))
        }
        let tile = any(app, containing: "Resting")
        if tapIfThere(tile) {
            sleep(2)
            shot("02-tap-locked-rhr-tile")
            texts(app, "paywall-from-rhr")
            dump(app, "paywall-from-rhr-tree.txt")
            dismissSheet(app, "rhr paywall")
            shot("03-after-dismiss-rhr")
        }

        app.swipeUp(); sleep(1)
        shot("04-today-free-scrolled")
        app.swipeUp(); sleep(1)
        shot("04b-today-free-scrolled-more")
        app.swipeDown(velocity: .fast); app.swipeDown(velocity: .fast); sleep(1)

        // Trend detail and fitness age for a free user.
        if tapIfThere(any(app, containing: "Cardio fitness trend")) {
            sleep(2); shot("05-trend-detail-free")
            app.swipeUp(); sleep(1); shot("05b-trend-detail-free-lower")
            texts(app, "trend-detail-free")
            app.navigationBars.buttons.firstMatch.tap(); sleep(1)
        }

        // Trends tab: Custom range and the deep trends teaser.
        if tapIfThere(app.buttons["Trends"]) {
            sleep(2); shot("06-trends-free")
            for r in ["30D", "90D", "6M", "1Y", "Custom"] { note("range \(r)", visible(app, r)) }
            if tapIfThere(visible(app, "Custom")) {
                sleep(2)
                shot("07-tap-custom-free")
                dismissSheet(app, "custom paywall")
                shot("08-after-custom-dismiss")
            }
            app.swipeUp(); sleep(1); shot("09-trends-free-lower")
            app.swipeUp(); sleep(1); shot("09b-trends-free-lowest")
            texts(app, "trends-free-lowest")
        }

        // VO2+ tab as a free user: the embedded purchase surface.
        if tapIfThere(app.buttons["VO2+"]) {
            sleep(3)
            shot("10-plus-tab-free")
            texts(app, "plus-tab-free")
            dump(app, "plus-tab-free-tree.txt")
            for t in ["Restore", "Terms", "Privacy", "Try Again", "Continue with VO2+"] {
                note("plus tab \(t)", app.buttons[t])
            }
        }
        flushFrames("frames-free-locks.txt")
    }

    /// Settings as a free user: the VO2+ section, locked toggles, Restore with
    /// nothing to restore, and how to leave each sheet.
    func testFreeSettingsRestoreAndExit() {
        let app = launch(["-ScreenshotTab", "0"])
        XCTAssertTrue(tapIfThere(app.buttons["Settings"], wait: 30))
        sleep(2)
        shot("20-settings-free-top")
        app.swipeUp(); sleep(1)
        shot("21-settings-free-mid")
        app.swipeUp(); sleep(1)
        shot("22-settings-free-plus-section")
        texts(app, "settings-free-plus")
        dump(app, "settings-free-plus-tree.txt")

        let restore = app.buttons["Restore Purchases"]
        note("Restore Purchases", restore)
        note("Continue with VO2+ row", app.buttons["Continue with VO2+"])
        note("Done", app.buttons["Done"])
        if restore.exists {
            restore.tap()
            sleep(1); shot("23-restore-tap-1s")
            sleep(4); shot("24-restore-tap-5s")
            texts(app, "after-restore")
        }

        // A locked toggle snaps back and opens the pitch.
        let sw = app.switches.firstMatch
        note("first switch", sw)
        for i in 0..<min(app.switches.count, 4) {
            note("switch \(i) '\(app.switches.element(boundBy: i).label)'", app.switches.element(boundBy: i))
        }
        flip(sw)
        if sw.exists {
            sleep(2)
            shot("25-locked-toggle-tapped")
            frames.append("switch value after tap: \(String(describing: app.switches.firstMatch.value))")
            texts(app, "after-toggle")
            dismissSheet(app, "toggle pitch")
            shot("26-after-toggle-pitch-dismissed")
        }

        let upgrade = app.buttons["Continue with VO2+"]
        if tapIfThere(upgrade, wait: 3) {
            sleep(2)
            shot("27-settings-upgrade-row")
            dismissSheet(app, "settings upgrade")
        }

        // Exit: Done closes Settings.
        if app.buttons["Done"].exists {
            app.buttons["Done"].tap(); sleep(1)
            shot("28-settings-closed")
        }
        flushFrames("frames-free-settings.txt")
    }

    // MARK: - Store loaded (RevenueCat Test Store, no purchase)

    /// The VO2+ tab with real plans: price clarity, plan selection, Restore with
    /// nothing to restore, legal links.
    func testPaywallWithPlansLoaded() {
        let app = launch(
            ["-ScreenshotTab", "2", "-rcfunnelprobe"],
            env: ["RC_PROBE_USER": "audit-subscription-uitest", "RC_PROBE_SURFACE": "vo2plus_tab"]
        )
        XCTAssertTrue(app.buttons["VO2+"].waitForExistence(timeout: 30))
        let cta = app.buttons["Continue with VO2+"]
        let loaded = cta.waitForExistence(timeout: 45)
        frames.append("plans loaded (CTA visible): \(loaded)")
        sleep(2)
        shot("30-paywall-plans")
        texts(app, "paywall-plans")
        dump(app, "paywall-plans-tree.txt")
        note("CTA", cta)
        for t in ["Restore", "Terms", "Privacy", "Try Again"] {
            let b = app.buttons[t].exists ? app.buttons[t] : app.links[t]
            note("paywall \(t)", b)
        }
        let cards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'year' OR label CONTAINS[c] 'month' OR label CONTAINS[c] 'lifetime'"))
        for i in 0..<cards.count { note("plan card \(i) '\(cards.element(boundBy: i).label)'", cards.element(boundBy: i)) }

        for plan in ["Monthly", "Lifetime", "Yearly"] {
            let card = any(app, containing: plan)
            if tapIfThere(card, wait: 3) { sleep(1); shot("31-select-\(plan)"); texts(app, "select-\(plan)") }
        }

        app.swipeUp(); sleep(1); shot("32-paywall-scrolled")

        let restore = app.buttons["Restore"]
        if tapIfThere(restore, wait: 3) {
            sleep(1); shot("33-restore-1s")
            sleep(5); shot("34-restore-6s")
            texts(app, "after-restore-paywall")
        }

        // Leave without buying: the tab bar is the only exit on this surface.
        if tapIfThere(app.buttons["Today"], wait: 3) { sleep(1); shot("35-left-paywall-to-today") }
        flushFrames("frames-paywall-plans.txt")
    }

    /// Settings with plans loaded: the trial sheet an eligible user sees and the
    /// way out of it.
    func testTrialSheetWithPlansLoaded() {
        let app = launch(
            ["-ScreenshotTab", "0", "-rcfunnelprobe"],
            env: ["RC_PROBE_USER": "audit-subscription-uitest", "RC_PROBE_SURFACE": "vo2plus_tab"]
        )
        XCTAssertTrue(tapIfThere(app.buttons["Settings"], wait: 30))
        sleep(3)
        app.swipeUp(); sleep(1); app.swipeUp(); sleep(1)
        let upgrade = app.buttons["Continue with VO2+"]
        if tapIfThere(upgrade, wait: 8) {
            sleep(3)
            shot("40-trial-sheet")
            texts(app, "trial-sheet")
            dump(app, "trial-sheet-tree.txt")
            for t in ["Continue with VO2+", "Not now", "Terms", "Privacy Policy"] {
                let b = app.buttons[t].exists ? app.buttons[t] : app.links[t]
                note("trial \(t)", b)
            }
            let big = app.buttons["Continue with VO2+"]
            if big.exists { frames.append("sheet CTA frame \(big.frame)") }
            // Pull the sheet to large to see whether the content fits.
            app.swipeUp(velocity: .slow); sleep(1)
            shot("41-trial-sheet-large")
            dismissSheet(app, "trial sheet")
            shot("42-after-not-now")
        }
        flushFrames("frames-trial-sheet.txt")
    }

    /// Onboarding's last page with plans loaded: what is sold, at what price,
    /// and the free exit and Restore.
    func testOnboardingPitchWithPlansLoaded() {
        let app = launch(
            ["-rcfunnelprobe"],
            env: ["RC_PROBE_USER": "audit-subscription-uitest", "RC_PROBE_SURFACE": "vo2plus_onboarding_trial"]
        )
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 30))
        for _ in 0..<3 { app.buttons["Continue"].tap(); sleep(1) }
        let cta = app.buttons["Continue with VO2+"]
        XCTAssertTrue(cta.waitForExistence(timeout: 20))
        sleep(10)
        shot("50-onboarding-pitch-plans")
        texts(app, "onboarding-pitch")
        dump(app, "onboarding-pitch-tree.txt")
        for t in ["Get Started", "Continue with VO2+", "Restore", "Terms", "Privacy"] {
            let b = app.buttons[t].exists ? app.buttons[t] : app.links[t]
            note("pitch \(t)", b)
        }
        if tapIfThere(app.buttons["Restore"], wait: 3) {
            sleep(1); shot("51-onboarding-restore-1s")
            sleep(5); shot("52-onboarding-restore-6s")
            texts(app, "onboarding-after-restore")
        }
        if tapIfThere(app.buttons["Get Started"], wait: 3) {
            sleep(3); shot("53-free-exit-today")
        }
        flushFrames("frames-onboarding-pitch.txt")
    }

    // MARK: - Subscriber

    /// A subscriber looks for a way to see status, manage or cancel, and then the
    /// entitlement lapses (the DEBUG override stands in for a cancellation).
    func testSubscriberManageCancelAndLapse() {
        let app = launch(["-DemoPro", "-ScreenshotTab", "2"])
        XCTAssertTrue(app.buttons["VO2+"].waitForExistence(timeout: 30))
        sleep(3)
        shot("60-hub-pro")
        texts(app, "hub-pro")
        for _ in 0..<3 { app.swipeUp(); sleep(1) }
        shot("61-hub-pro-bottom")
        texts(app, "hub-pro-bottom")
        for word in ["Manage", "Cancel", "Subscription", "Billing", "Renew", "Expires"] {
            note("hub contains '\(word)'", any(app, containing: word))
        }

        // Settings as a subscriber.
        app.buttons["Today"].tap(); sleep(1)
        XCTAssertTrue(tapIfThere(app.buttons["Settings"], wait: 10))
        sleep(2)
        app.swipeUp(); sleep(1); app.swipeUp(); sleep(1)
        shot("62-settings-pro-plus-section")
        texts(app, "settings-pro")
        dump(app, "settings-pro-tree.txt")
        for word in ["Manage", "Cancel", "Subscription", "Billing", "Renew", "Expires", "Restore Purchases"] {
            note("settings contains '\(word)'", any(app, containing: word))
        }
        let restore = app.buttons["Restore Purchases"]
        if tapIfThere(restore, wait: 3) { sleep(2); shot("63-pro-restore-tap") }

        // Lapse: the debug override turns Pro off in place.
        let override = app.switches["Local Pro override"]
        note("Local Pro override", override)
        if override.waitForExistence(timeout: 3) {
            flip(override)
            sleep(2)
            shot("64-after-lapse-settings")
            texts(app, "settings-after-lapse")
            frames.append("switch values after lapse: \((0..<app.switches.count).map { "\(app.switches.element(boundBy: $0).label)=\(String(describing: app.switches.element(boundBy: $0).value))" })")
        }
        app.swipeDown(velocity: .fast); sleep(1)
        if app.buttons["Done"].exists { app.buttons["Done"].tap(); sleep(1) }
        app.buttons["Today"].tap(); sleep(2)
        shot("65-today-after-lapse")
        if tapIfThere(app.buttons["VO2+"], wait: 3) { sleep(3); shot("66-plus-tab-after-lapse") }
        if tapIfThere(app.buttons["Trends"], wait: 3) { sleep(2); shot("67-trends-after-lapse") }
        flushFrames("frames-subscriber.txt")
    }

    /// Custom range chosen as a subscriber, then the entitlement lapses: does the
    /// selection revert with an explanation or silently?
    func testCustomRangeSurvivesLapseSilently() {
        let app = launch(["-DemoPro", "-ScreenshotTab", "1"])
        XCTAssertTrue(app.buttons["Trends"].waitForExistence(timeout: 30))
        sleep(2)
        if tapIfThere(visible(app, "Custom")) {
            sleep(2)
            if tapIfThere(app.buttons["Apply"], wait: 4) { sleep(2) }
        }
        shot("70-custom-applied-pro")
        texts(app, "custom-pro")
        // Lapse through Settings (Today tab owns the gear).
        app.buttons["Today"].tap(); sleep(1)
        XCTAssertTrue(tapIfThere(app.buttons["Settings"], wait: 10))
        sleep(2)
        app.swipeUp(); sleep(1); app.swipeUp(); sleep(1)
        let override = app.switches["Local Pro override"]
        if override.waitForExistence(timeout: 3) { flip(override); sleep(2) }
        if app.buttons["Done"].exists { app.swipeDown(velocity: .fast); sleep(1) }
        if app.buttons["Done"].exists { app.buttons["Done"].tap(); sleep(1) }
        if tapIfThere(app.buttons["Trends"], wait: 5) {
            sleep(2)
            shot("71-trends-after-lapse-custom")
            texts(app, "trends-after-lapse")
            frames.append("Custom selected after lapse: \(visible(app, "Custom").isSelected)")
            frames.append("90D selected after lapse: \(visible(app, "90D").isSelected)")
        }
        flushFrames("frames-lapse-custom.txt")
    }
}
