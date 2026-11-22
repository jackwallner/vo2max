# Android port of the 2026-11-20 bug fixes

Checked 2026-11-22 on `main`. Each row of
[2026-11-20-bug-fixes.md](2026-11-20-bug-fixes.md) was checked against the
`android/` port by reading the code. Bugs that exist there were fixed with the
smallest change that matches the iOS behavior.

Unit run (`fm-gradle testDebugUnitTest`, GitHub Linux) on the tree of HEAD
`be0928d`: `health-mbairfcc1-1122-103630-13470`, **171 passed, 0 failed.**

No run before the fixes: the new tests call parameters and functions the fixes
add, so they do not compile on the old code. No emulator run; the screen
wiring was checked by reading the code.

| iOS bug | Android verdict | Commit | Test | Notes |
|---|---|---|---|---|
| B1 Declined Health access lands on "wait for a Watch workout" with no way back | already fine | | | Health Connect reports what was granted, so `EmptyHealth` shows "Connect Health Connect" with a Connect button when the VO2 max permission is missing, and "Open Health Connect" in both states |
| B2 Declining the second Health sheet leaves a subscriber no way back | already fine | | | The empty resting heart rate and cardio load screens show an "Allow supporting signals" button (`ContextScreens.kt`) |
| B3 Custom range drops readings on the first and last day | ported | ef4c5a7 | `BugCatalogRegressionTest.b3_wholeDayPickCountsBothEndDays`, `b3_firstDayPickedExactlyTwoYearsBackKeepsItsReadings` | The picker already stored whole days (`DateSelection.localStart`, `localEnd`). Two things were wrong: a whole-day range counted one day short (Mar 1 to Mar 31 read as 30), and a first day exactly two years back was cut to its last moment. A part day now counts as a day, and the limit is measured from the start of the last day |
| B4 Ask to Buy or SCA pending purchase shown as failed | ported | 3697958 | `BugCatalogRegressionTest.b4_pendingPurchaseIsPending` | `PaymentPendingError` returns `PurchaseOutcome.PENDING`, which shows the paywall's existing "Purchase pending. VO2+ unlocks when payment is confirmed." line. The paywall is the only purchase surface on Android |
| B5 Plans-unavailable paywall has no Restore, Terms or Privacy | already fine | | | In `PaywallScreen` Restore Purchases, Terms and Privacy sit outside the plans branch, so they show under "VO2+ Plans Unavailable" too |
| B6 VO2+ custom-range statistics drop readings Trends counts | ported | 7f0387b | `BugCatalogRegressionTest.b6_signalSummaryAgreesWithRangeContains`, `b6_cardioLoadAgreesWithRangeContains`, `b6_fixedRangesComputeAsBefore` | `summarize`, `monthlyAverages`, `loadSummary` and `activityTotals` take the range's own start, every range-scoped caller passes it, and the previous window ends there. `FitnessAnalysis.change` has no range-scoped caller on Android and is unchanged |
| B7 Estimate Freshness reads notification denial once | not applicable | | | The Android Estimate Freshness screen shows no notification state, so there is nothing cached to go stale |
| B8 Freshness nudge fires at any hour | ported | 1eb6646 | `BugCatalogRegressionTest.b8_noNudgeAtNight`, `b8_nudgeInTheDaytime`, `b8_daytimeStillHonoursTheOtherRules` | Android sends the nudge from the 6-hourly background read rather than scheduling it. `FreshnessAnalysis.shouldNudge` now also requires 10:00 up to 19:00 local, so a stale estimate found at night is nudged by the next read inside the window. The 7-day spacing is unchanged |
| B9 A one-day custom range cannot be picked | already fine | ef4c5a7 (test) | `BugCatalogRegressionTest.b9_sameDayPickCoversTheWholeDay` | The same date picked twice was already stored as that whole day and counted as 1 day; the test pins it |
| B10 Plans-unavailable message truncated at the largest text size | not applicable | | | iOS Dynamic Type accessibility sizes. The Android message is plain wrapping text in a scrolling page |

Counts: 4 ported, 4 already fine, 2 not applicable.

## Also fixed: fitness band labels

`python3 scripts/sync-android-parity.py` showed the Swift parity fixture had
drifted from an earlier iOS change, not from this catalog: iOS reads "Below",
"Within" or "Above typical range" on the same bounds as the typical range that
Settings states, while Android still had four labels and called a value inside
that range "Above typical range". Commit be0928d ports the three labels and
re-exports `swift-parity.json` (`SwiftParityTest` passes, 60 scenarios).

## Needs Jack

Nothing blocking. Not uploaded to Play; the fixes ship with the next Android
build when you ask for one.
