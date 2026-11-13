import XCTest

/// iPad layout proof: every main screen, paywall and onboarding, portrait and
/// landscape. Run on an iPad destination with gh-sim and read the attachments.
@MainActor
final class IPadScreenshotsUITests: XCTestCase {
    private static let bundleID = "com.jackwallner.vo2max"

    private struct Scene {
        let name: String
        let args: [String]
    }

    private let scenes: [Scene] = [
        Scene(name: "today", args: ["-DemoData", "-DemoPro", "-ScreenshotTab", "0", "-DuoScreen", "today"]),
        Scene(name: "trends", args: ["-DemoData", "-DemoPro", "-ScreenshotTab", "0", "-DuoScreen", "trends"]),
        Scene(name: "plus", args: ["-DemoData", "-DemoPro", "-ScreenshotTab", "0", "-DuoScreen", "plus"]),
        Scene(name: "fitness-age", args: ["-DemoData", "-DemoPro", "-ScreenshotTab", "0", "-DuoScreen", "fitness-age"]),
        Scene(name: "resting", args: ["-DemoData", "-DemoPro", "-ScreenshotTab", "0", "-DuoScreen", "trends/resting"]),
        Scene(name: "settings", args: ["-DemoData", "-DemoPro", "-ScreenshotTab", "0", "-DuoScreen", "settings"]),
        Scene(name: "paywall", args: ["-DemoData", "-PaywallSnapshot"]),
        Scene(name: "onboarding0", args: ["-OnboardingPage", "0"]),
        Scene(name: "onboarding1", args: ["-OnboardingPage", "1"]),
        Scene(name: "onboarding2", args: ["-OnboardingPage", "2"]),
        Scene(name: "onboarding3", args: ["-OnboardingPage", "3"])
    ]

    func testIPadScreens() throws {
        for (orientationName, orientation) in [("portrait", UIDeviceOrientation.portrait), ("landscape", .landscapeLeft)] {
            XCUIDevice.shared.orientation = orientation
            for scene in scenes {
                let app = XCUIApplication(bundleIdentifier: Self.bundleID)
                app.launchArguments = scene.args
                app.launch()
                XCUIDevice.shared.orientation = orientation
                _ = app.wait(for: .runningForeground, timeout: 60)
                Thread.sleep(forTimeInterval: 14)
                let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                attachment.name = "\(orientationName)__\(scene.name).png"
                attachment.lifetime = .keepAlways
                add(attachment)
                app.terminate()
            }
        }
    }
}
