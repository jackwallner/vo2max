# State machine audit fixes, 2026-11-06

Fixes for the claims `state-machines-2026-11-06-review.md` kept, taken in the review's ranked order and using its corrected routes. Base commit `a8725b3`.

**Summary: 7 claims in scope (2 CONFIRMED, 3 CONFIRMED-MINOR, 1 product call the review rated a bug, 1 UNVERIFIED). 7 fixed, 0 held, 0 skipped.** SM-7 (NOT A BUG) was left alone.

## Claims

| id | Verdict | Outcome | Commit | Regression test | What changed |
| --- | --- | --- | --- | --- | --- |
| SM-1 | CONFIRMED | Fixed | `2edb7ee`, `542c1c4` | `StateMachineFixTests/sm1_secondSyncSecondsLaterKeepsSpacing`, `sm1_secondForegroundDoesNotPullTheSpacedNudgeForward`, `sm1_staleUserOpeningDailyForTwoWeeksGetsAtMostOneNudgePerFiveDays` (now with the cold launch's two syncs), `sm1_newEstimatePushesPendingNudgeLater` | `nextNudgeDate` no longer ignores a future `lastNudge`. A pending nudge already honours the spacing, so its replacement never moves earlier than it, and a new estimate still pushes it later. `scheduleFreshnessNudge` now returns the fire date it queued (it floors the trigger at 1 s) and that is what gets stored, so the spacing counts from the real delivery; the first final run caught a gap 1 s short of five days. The stored key and what it means are unchanged, so existing installs carry over: a user whose stored date is a pending spaced nudge keeps that date, which is the upgrade case the tests cover. |
| SM-5 | CONFIRMED | Fixed | `1e8b0ec` | `StateMachineFixTests/sm5_paywallNeverRendersTheSharedStoreError` | `PaywallView` stopped rendering the shared `store.errorMessage` live. It keeps the outcome of a purchase or restore started on that paywall, clears it on the next attempt or a plan change, and otherwise shows the renewal disclosure. A cancel in onboarding or Settings no longer reaches the VO2+ tab footer. The never-cleared `restoreMessage` went with it. |
| SM-3 | CONFIRMED-MINOR | Fixed | `e5ef4fa` | `ReviewPromptTrackerTests/sm3_backgroundRelaunchLeavesTheReturnMomentForTheVisibleReturn` | `recordReturnWithReading(appIsVisible:)` does not fire while the app is in the background (HealthKit relaunch), so the once-ever moment waits for the visible return. `MainTabView` also checks for a pending moment when it appears, so one recorded before the view existed still gets its ask (the gap the review noted: nothing re-read a pending moment on a normal launch). |
| SM-2 | CONFIRMED-MINOR | Fixed | `ae931f1` | `StateMachineFixTests/sm2_optInSeparatesAFreshDeclineFromAnEarlierDenial`, `sm2_togglesAndFreshnessCardReadTheDenial` | The three notification toggles and the Estimate Freshness card read the iOS permission. With notifications denied they show off and the card shows its Off sentence. Turning a toggle on after an earlier denial, when iOS shows no prompt, opens a "Notifications are off" alert with Open Settings (the app's notification settings) and Not now. The stored preference is kept, so the toggles come back on once permission is granted. New string in all 18 locales. |
| SM-6 | CONFIRMED-MINOR | Fixed | `2013bf3` | `StateMachineFixTests/sm6_recapSheetChecksTheEntitlement`, `sm6_backgroundRefreshVerifiesBeforeNotifying` | The recap sheet shows `MonthlyRecapView` only while `store.isPro`, and otherwise shows the VO2+ paywall focused on the recap. That also covers a cold launch, where the cached flag flips once RevenueCat answers. A background HealthKit refresh re-verifies a cached entitlement before it posts reading alerts or reschedules the nudge (8 s cap, cached flag kept on timeout or error). A lapse now cancels the pending recap and nudge from `isPro`'s `didSet`, which runs with no scene connected too. |
| Product call 8 | CONFIRMED-MINOR (review) | Fixed | `8273e84` | `LocalizationTests/restoreResultIsLocalized` | `restoreResultMessage` uses `String(localized:)`; "VO2+ restored." is in the catalog in all 18 locales. |
| SM-4 | UNVERIFIED | Fixed | `54b9007` | `StateMachineFixTests/sm4_pendingRoutesAreConsumedOnAppear` | `MainTabView` consumes the recap and Today flags on appear as well as in `onChange`, ahead of What's New. Settling: the ordering cannot be observed headless (gh-sim cannot tap a banner), but the mechanism is confirmed (`onChange` without `initial` never fires for a value already true) and nothing guarantees the delegate's main-actor hop lands after the first render, so a customer can reach it. The change is safe in both orderings. |

Not in scope: SM-7 (NOT A BUG, left as is, including the footer copy the review mentions but did not count), product calls 1 to 7 and 9. The review's note on product call 3 (a returning subscriber skipping the Health prompt) is an onboarding flow change and would be held anyway; the dashboard Connect button recovers it.

## Held for Jack

None.

One call that is yours to reverse if you want it: a lapsed user tapping a recap notification now gets the VO2+ paywall focused on the recap. The review called showing the recap itself "arguably the best win-back moment". If you would rather show the lapsed user their recap, drop the `store.isPro` branch in `MainTabView`'s recap sheet.

## Skipped

None.

## Notes

- SM-1 trade-off: the nudge can now land later than the exact stale day, never earlier, when the stale day moves earlier while a nudge is pending. That happens if the latest reading is deleted in Health, or if the personal cadence shortens as old readings drop out of the one-year window. This leans the conservative way: the "at most once every five days" promise always holds.
- The review's other SM-1 observation, that a user who stops opening the app gets one nudge, then nothing until the next sync, is how the feature is built ("a reminder rather than a nag") and is not a separate claim. Unchanged.
- The source-text tests (SM-4, SM-5, SM-6, and part of SM-2) follow the repo's existing pattern (`OvernightP1Tests.watchAppEnablesBackgroundDeliveryAtLaunch`). These paths sit behind `UNUserNotificationCenter`, RevenueCat and SwiftUI view state, and none of the three has a test seam. On a simulator RevenueCat is unconfigured and the paywall footer never renders.
- The audit repro suite was never added to the test target. Its SM-1 tests live on, rewritten, in `StateMachineFixTests`.

## Test results

RESULTS_PLACEHOLDER
