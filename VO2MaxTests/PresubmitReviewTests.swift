import Foundation
import Testing
@testable import VO2Max

/// Regression guards for the 2026-11-07 pre-submit review
/// (`project-docs/audits/presubmit-review-2026-11-07.md`).
struct PresubmitReviewTests {
    private func source(_ path: String) throws -> String {
        let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        return try String(contentsOf: repo.appendingPathComponent(path), encoding: .utf8)
    }

    /// PR-1: the recap toggle turned on while iOS denied notifications queued
    /// nothing, and allowing them in iOS Settings changed no scheduling key, so
    /// the toggle read on with no recap pending until the next cold launch.
    /// The tab view re-queues it when the scene returns to active.
    @Test func pr1_recapIsRequeuedWhenTheAppReturnsActive() throws {
        let app = try source("VO2Max/App.swift")
        let tabView = try #require(app.range(of: "private struct MainTabView"))
        let body = app[tabView.upperBound...]
        let hook = try #require(body.range(of: ".onChange(of: scenePhase)"))
        let after = body[hook.upperBound...].prefix(400)
        #expect(after.contains("phase == .active"))
        #expect(after.contains("settings.monthlyRecapEnabled"))
        #expect(after.contains("NotificationService.scheduleMonthlyRecapIfAuthorized()"))
    }

    /// The foreground re-queue must never raise the permission prompt, so it
    /// checks the current grant before the scheduling call that requests it.
    @Test func pr1_foregroundRequeueChecksTheGrantBeforeScheduling() throws {
        let service = try source("Shared/Services/NotificationService.swift")
        let start = try #require(service.range(of: "static func scheduleMonthlyRecapIfAuthorized()"))
        let rest = service[start.upperBound...]
        let guardCheck = try #require(rest.range(of: "guard await isAuthorized() else { return false }"))
        let schedule = try #require(rest.range(of: "return await scheduleMonthlyRecap()"))
        #expect(guardCheck.lowerBound < schedule.lowerBound)
        #expect(!rest[..<schedule.lowerBound].contains("requestAuthorization"))
    }

    /// Not authorized (the unit-test host never grants), so nothing is queued
    /// and no prompt is raised.
    @Test func pr1_requeueWithoutAGrantQueuesNothing() async {
        #expect(await NotificationService.scheduleMonthlyRecapIfAuthorized() == false)
    }
}
