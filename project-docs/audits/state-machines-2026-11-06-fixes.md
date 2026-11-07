# State machine audit fixes, 2026-11-06

Fixes for the claims `state-machines-2026-11-06-review.md` kept, taken in the review's ranked order and using its corrected routes. Base commit `093d94d`.

**Summary: 7 claims in scope (2 CONFIRMED, 3 CONFIRMED-MINOR, 1 product call the review rated a bug, 1 UNVERIFIED). 6 fixed (SM-6 in part), 1 held (SM-4) plus SM-6's recap-tap half held, 0 skipped.** SM-7 (NOT A BUG) was left alone.

## Claims

| id | Verdict | Outcome | Commit | Regression test | What changed |
| --- | --- | --- | --- | --- | --- |
| SM-1 | CONFIRMED | Fixed | `64f4001`, `5092ded` | `StateMachineFixTests/sm1_secondSyncSecondsLaterKeepsSpacing`, `sm1_secondForegroundDoesNotPullTheSpacedNudgeForward`, `sm1_staleUserOpeningDailyForTwoWeeksGetsAtMostOneNudgePerFiveDays` (with the cold launch's two syncs), `sm1_newEstimatePushesPendingNudgeLater` | `nextNudgeDate` no longer ignores a future `lastNudge`. A pending nudge already honours the spacing, so its replacement never moves earlier than it, and a new estimate still pushes it later. `scheduleFreshnessNudge` returns the fire date it queued (it floors the trigger at 1 s) and that is what gets stored, so spacing counts from the real delivery. The stored key and its meaning are unchanged, so existing installs carry over: a stored date that is a pending spaced nudge keeps that date, the upgrade case the tests cover. |
| SM-5 | CONFIRMED | Fixed | `5b9c219` | `StateMachineFixTests/sm5_paywallNeverRendersTheSharedStoreError` | `PaywallView` no longer renders the shared `store.errorMessage` live. It keeps the outcome of a purchase or restore started on that paywall, clears it on the next attempt or a plan change, and otherwise shows the renewal disclosure. A cancel in onboarding or Settings no longer reaches the VO2+ tab footer. |
| SM-3 | CONFIRMED-MINOR | Fixed | `8c974bf` | `ReviewPromptTrackerTests/sm3_backgroundRelaunchLeavesTheReturnMomentForTheVisibleReturn` | `recordReturnWithReading(appIsVisible:)` does not fire during a HealthKit background relaunch, so the once-ever moment waits for the visible return. `MainTabView` also checks for a pending moment when it appears, so one recorded before the view existed still gets its ask. |
| SM-2 | CONFIRMED-MINOR | Fixed | `39097e6` | `StateMachineFixTests/sm2_optInSeparatesAFreshDeclineFromAnEarlierDenial`, `sm2_togglesAndFreshnessCardReadTheDenial` | The three notification toggles and the Estimate Freshness card read the iOS permission; with notifications denied they show off. Turning a toggle on after an earlier denial, when iOS shows no prompt, opens "Notifications are off" with Open Settings and Not now. The stored preference is kept, so the toggles come back on once permission is granted. New string in all 18 locales. |
| SM-6 | CONFIRMED-MINOR | Fixed in part (recap tap held) | `556c65f`, `1cb1e08` | `StateMachineFixTests/sm6_backgroundRefreshVerifiesBeforeNotifying` | A background HealthKit refresh re-verifies a cached entitlement with a fresh fetch before it posts reading alerts or reschedules the nudge (8 s cap; on timeout or error the cached flag stands). Only that fresh "not a member" withdraws the pending recap and nudge. The first version cancelled from `isPro`'s `didSet`, which also runs on RevenueCat's cached record at configure; `1cb1e08` moved it. What a lapsed user sees on tapping the recap is held (below). |
| Product call 8 | CONFIRMED-MINOR (review) | Fixed | `8df5840` | `LocalizationTests/restoreResultIsLocalized` | `restoreResultMessage` uses `String(localized:)`; "VO2+ restored." is in the catalog in all 18 locales. |
| SM-4 | UNVERIFIED | Held | `32508da` backed out in `a696eae` | none | No headless runner can settle it (below). |

Not in scope: SM-7 (NOT A BUG, including the footer copy the review mentions but did not count) and product calls 1 to 7 and 9.

## Held for Jack

- **SM-6, the recap tap after a lapse.** A recap request scheduled while subscribed can still fire after a lapse when no background refresh has run since, and its tap opens `MonthlyRecapView` with no entitlement check (`VO2Max/App.swift`, `.sheet(isPresented: $showRecap)`). The only fix is a display-time gate, which changes who sees a paywall. Decision: should a lapsed user tapping the recap see the recap (today, the review's "best win-back moment") or the VO2+ paywall focused on the recap (`PaywallView(focus: .monthlyRecap)`)? The earlier version of this run shipped the paywall branch; it was backed out in `1cb1e08`.
- **SM-4, a notification tap that beats MainTabView's first render.** The mechanism is real (`.onChange(of:)` without `initial` never fires for a value already true), but whether a cold-launch tap sets `pendingRecap` before `MainTabView` appears was never observed, and gh-sim cannot tap a banner. Decision: settle it on a device or with a Springboard UI test (terminate the app, deliver a payload with top-level `"route": "monthlyRecap"`, tap the banner, assert the "This Month" title). If it reproduces, re-apply `32508da`, which consumes the flags on appear as well and is safe in either ordering.

## Skipped

None.

## Notes

- SM-1 trade-off: the nudge can now land later than the exact stale day, never earlier, when the stale day moves earlier while a nudge is pending (the latest reading deleted in Health, or the cadence shortening as old readings leave the one-year window). The "at most once every five days" promise always holds.
- The review's other SM-1 observation, that a user who stops opening the app gets one nudge and then nothing until the next sync, is how the feature is built and not a separate claim. Unchanged.
- The source-text tests (SM-5, SM-6, part of SM-2) follow the repo's existing pattern (`OvernightP1Tests.watchAppEnablesBackgroundDeliveryAtLaunch`). These paths sit behind `UNUserNotificationCenter`, RevenueCat and SwiftUI view state with no test seam, and on a simulator RevenueCat is unconfigured.
- The audit repro suite was never added to the test target. Its SM-1 tests live on, rewritten, in `StateMachineFixTests`.
- Commit hashes earlier drafts of this doc listed (`2edb7ee` and so on) were from before the branch was rebased onto `093d94d`; the ones above are current.

## Test results

Full suite on `1cb1e08`: `gh-sim test --scheme VO2Max`, GitHub run 42336359428 (Xcode 27.1, iPhone 17, iOS 27.2). 144 passed, 0 failed, 0 skipped, unit and UI tests. Nothing failed, so no test needed a rerun on `093d94d`, and none already failed there as far as this run shows.
