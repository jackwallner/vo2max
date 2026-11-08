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

/// Captures the localized App Store frames for `capture.sh`. Kept out of
/// `ReleaseJourneysUITests` so the release gate never runs this capture loop
/// as a journey.
@MainActor
final class StoreScreenshotsUITests: XCTestCase {
    private static let bundleID = "com.jackwallner.vo2max"

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
}
