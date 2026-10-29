import XCTest

final class WidgetScreenshotUITests: XCTestCase {
    func testHomeScreenWidgetScreenshot() {
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.vo2max")
        app.launchArguments = [
            "-SeedScreenshotData",
            "-DemoData",
            "-DemoPro",
            "-ScreenshotTab", "0",
            "-AppleLanguages", "(de)",
            "-AppleLocale", "de_DE"
        ]
        app.launch()
        XCTAssertTrue(app.waitForExistence(timeout: 15))
        sleep(5)
        app.terminate()
        XCUIDevice.shared.press(.home)

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.swipeLeft()
        let appIcon = springboard.icons["VO2 Max"]
        XCTAssertTrue(appIcon.waitForExistence(timeout: 15), "VO2 Max app icon is missing from the Home Screen")
        appIcon.press(forDuration: 1.5)

        let editHomeScreen = springboard.buttons["Edit Home Screen"]
        if editHomeScreen.waitForExistence(timeout: 5) {
            editHomeScreen.tap()
        }

        let editMenu = springboard.buttons["Edit"]
        if editMenu.waitForExistence(timeout: 5) {
            editMenu.tap()
        }

        let addWidget = springboard.buttons["Add Widget"]
        XCTAssertTrue(addWidget.waitForExistence(timeout: 10), "The Home Screen widget gallery did not open")
        addWidget.tap()

        let search = springboard.searchFields.firstMatch
        if search.waitForExistence(timeout: 5) {
            search.tap()
            search.typeText("VO2 Max")
        }

        let widgetResult = springboard.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "VO2 Max")
        ).firstMatch
        XCTAssertTrue(widgetResult.waitForExistence(timeout: 15), "The cardio fitness widget was not listed")
        widgetResult.tap()

        let widgetPreview = springboard.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Cardio Fitness")
        ).firstMatch
        XCTAssertTrue(widgetPreview.waitForExistence(timeout: 10), "The widget preview did not load")

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "de-widget-preview"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
