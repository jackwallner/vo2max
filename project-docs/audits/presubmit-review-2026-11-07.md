# Pre-submit review: VO2 Max 1.1.6 (2026-11-07)

Last check before 1.1.6 (build 59) goes to App Review.

## Scope

- Live version: 1.1.5 (App Store lookup, released 2026-11-02).
- Base: `ee7e611`, the last commit at `MARKETING_VERSION` 1.1.5 before `82fdd43` bumped it to 1.1.6. Head: `origin/main` at `c6a7e63`.
- App sources only (`VO2Max`, `VO2MaxWidget`, `VO2MaxWatch`, `VO2MaxWatchWidget`, `Shared`, `project.yml`, `Info.plist`). Docs, fastlane, qa and tests were left out.
- 1.1.5 was built from `ship/1.1.5` (build 63), which split from main at `b07fa12`. Main redid those fixes in its own commits. The diff from `ship/1.1.5` to head was checked too. Head drops none of the ship branch's fixes: the only lines unique to ship are hyphen ranges and a span label without a start year, and main has the newer version of both.

## Findings

| # | Severity | File:line | What happens | Status |
|---|----------|-----------|--------------|--------|
| 1 | P1 | `VO2Max/App.swift:398` | User turns on Monthly Recap while iOS has notifications denied, gets "Notifications are off", taps Open Settings and allows them. Back in the app the toggle reads on (`notificationsDenied` refreshes on `scenePhase`), but no recap is queued. The only scheduler is `.task(id: recapSchedulingKey)`, keyed on `isPro` and the toggle, and neither changed. The recap stays unscheduled until the next cold launch. | Fixed: `MainTabView` re-queues the recap on return to active when the user is VO2+ and has the toggle on, through the new `NotificationService.scheduleMonthlyRecapIfAuthorized()`, which checks the grant first and never prompts. Test: `PresubmitReviewTests` (3 tests). |
| 2 | P2 | `VO2Max/App.swift:450` | A recap request queued while subscribed can still fire after a lapse if no background refresh has run since. Tapping it opens `MonthlyRecapView` without an entitlement check. | Not fixed: product call already held for Jack in `state-machines-2026-11-06-fixes.md` (show the recap or the recap-focused paywall). |
| 3 | P2 | `Shared/Services/HealthKitService.swift:167`, `:373` | `appIsVisible` reads `UIApplication.applicationState`. In a scene app that state is `.background` until a scene connects. If the launch observer's first refresh finishes before then, it runs the background entitlement verify (up to 8 s before alerts) and puts the once-ever return-visit review moment off to a later launch. Nothing is lost or shown wrongly. | Not fixed: timing-dependent and not confirmed on a device. Harmless if it happens. |
| 4 | P2 | `Shared/Utilities/CardioFreshness.swift:134` | A pending freshness nudge cancelled before it fires (toggle off, or a fresh lapse) keeps its future date in `lastFreshnessNudge`. Once that date passes it is treated as delivered, so a re-enabled nudge waits up to 7 more days. Clearing the date would break spacing from the nudge actually delivered before it. | Not fixed: a trade-off, not a definite bug. At worst one nudge comes late. |
| 5 | P2 | `VO2Max/Views/CardioContextViews.swift:1252` | The Estimate Freshness card checks the notification denial once, in `.task`. After allowing notifications in iOS Settings, it keeps reading off until the view re-appears. Settings refreshes on `scenePhase` and does not have this problem. | Not fixed: cosmetic and self-correcting. |
| 6 | P2 | `VO2Max/Views/PaywallView.swift:642` | `Tools/Localization/check.py` reports `no catalog key for "Instead of %lld"`. `anchor` is a `String`, so the runtime key is `Instead of %@`, which is in the catalog for every locale. Checker false positive. | Not fixed: tooling only. The app is unaffected. |

## Checked and clean

- Crashes and data loss: no new force unwraps, no index access on optional data, and no SwiftData schema change (`CardioFitnessSample` is unchanged). `CustomerInfoRace` resumes its continuation exactly once under a lock. Everything new in `HealthKitService` and `StoreService` stays on the main actor.
- Purchases: offering lookup (`default` then `current`), restore, trial eligibility (resolved per product, hidden on failure) and the permissive `isPro` check are unchanged. The background verify only withdraws requests on a fresh "not a member" answer and leaves the cached flag alone on a timeout. The paywall footer shows only its own attempt's outcome. The close button and `isPro` dismiss are unchanged. At accessibility sizes the checkout footer scrolls with the plans and stays reachable.
- Onboarding: the accessibility layout swap keeps all state in `OnboardingView`. The trial impression is deduped per session. Completion still runs through `finishOnboarding` on `isPro`.
- Notifications: freshness nudge spacing now uses the real fire date, and a pending nudge is never pulled earlier. Toggles follow the iOS denial.
- App Review: Terms (Apple EULA) and Privacy links are on the paywall and the onboarding trial step. Prices come only from StoreKit. Health copy keeps the "does not diagnose, treat" disclaimers. No other-platform links. The Pro override is `#if DEBUG`, and the simulator purchase note is simulator-only. `UIPrefersShowingLanguageSettings` is a valid Apple key.

## Verification

- `xcodegen` is not installed on jmbp2. `VO2Max.xcodeproj` is gitignored, and gh-sim generates it from `project.yml` on the runner, so the new `VO2MaxTests/PresubmitReviewTests.swift` is picked up there.
- Unit tests: see the commit log and the run below.
