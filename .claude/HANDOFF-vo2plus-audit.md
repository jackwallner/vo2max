# Handoff: VO2+ / range-picker UX audit

Status as of 2026-08-01. Resume from here if a session ends or a usage limit hits.

## What shipped

- `64c7354` — VO2+ hub rebuilt (highlights table + three sectioned groups of tappable rows),
  segmented range Picker replaced with the Vitals capsule button bar, `CardioRange` +
  `CardioRangeStore` added, VO2+-gated Custom date range, date-span captions everywhere.
- Follow-up commit — audit fixes 1 to 3 below.

## Audit fixes applied

1. `CardioFitnessAnalysis.change(points:days:now:)` took the all-time latest point instead of
   the latest at or before `now`. With a custom range that ends in the past, the Trends
   "Change" stat mixed in readings from after the window the caption claimed. Bounded to `now`.
   Tests: `changeIgnoresReadingsAfterNow`, `changeIsNilWhenNoReadingFallsAtOrBeforeNow`.
2. `CardioRange.weeks` has a 4-bar floor, but `weeklyLoad` trails back from `end`, so a 3-day
   custom range drew four weeks of bars under a caption that said three days. Added
   `chartWeeks` (ceil(days/7), floor 1, custom only) and wired it into both `weeklyLoad`
   call sites. Test: `chartWeeksDoesNotPadACustomRangePastItsOwnSpan`.
3. `priorPhrase` read "previous 1 days" for a one-day custom pick. Singularized.
   Test: `customPriorPhraseSingularizesOneDay`.
4. At `accessibility-large` the five-segment capsule truncated "Custom" to "Cust…". Capped the
   bar at `DynamicTypeSize.accessibility1` (UISegmentedControl capped its own text the same
   way) and lowered `minimumScaleFactor` to 0.65. Verified on device at both sizes.

## Not yet done

Order these by value if picking the work back up.

- **SUSPECTED, unconfirmed: hidden tabs leak into the accessibility tree.** `MainTabView` in
  `VO2Max/App.swift` stacks all three tabs in a `ZStack` and hides the inactive ones with
  `.opacity(0) + .allowsHitTesting(false) + .accessibilityHidden(!isVisible)`. An
  `axe describe-ui` run while Today was showing listed the Trends range segments (30D/90D/6M/1Y).
  That may just be `describe-ui` dumping the raw tree rather than a real VoiceOver defect.
  Confirm with an actual VoiceOver pass before changing anything; the ZStack exists to preserve
  per-tab scroll state, so do not switch to conditional rendering casually.
- Swift Charts x-axis labels truncate at accessibility sizes ("Ma…", "Jun…"). Pre-existing,
  not caused by the range work. Would need `.chartXAxis` with an explicit reduced mark count.
- Empty and degenerate states not yet swept end to end: no HealthKit permission, exactly one
  reading, all readings outside the selected window, a custom range containing no data,
  a 2-year custom range. Range math is unit-tested; the screens are not.
- Locked (non-subscriber) pass over every screen at both Dynamic Type sizes.
- Light appearance not checked (`xcrun simctl ui <UDID> appearance light`).

## How to run it

```
UDID=44262C84-C8E5-4C52-B90F-47CEF9434E26
xcodegen generate
agent-sim boot vo2max
xcodebuild -project VO2Max.xcodeproj -scheme VO2Max -destination "id=$UDID" -derivedDataPath /tmp/vo2max-verify build
xcrun simctl install "$UDID" /tmp/vo2max-verify/Build/Products/Debug-iphonesimulator/VO2Max.app
xcrun simctl launch "$UDID" com.jackwallner.vo2max -ScreenshotTab 1 -SeedScreenshotData -DemoPro
agent-sim screenshot vo2max   # writes /tmp/agent-vo2max.png
```

Flags: `-ScreenshotTab 0|1|2` (Today, Trends, VO2+), `-SeedScreenshotData`, `-DemoPro`,
`-OnboardingPage 1`.

Gotchas:
- `-DemoPro` **persists** `isPro` to defaults. Uninstall and reinstall to get back to the free
  state; relaunching without the flag is not enough.
- A fresh install shows the HealthKit permission sheet. It is a separate process and does not
  appear in `axe describe-ui`. Dismiss by tapping "Don't Allow" at about (201, 809), then "OK"
  at about (201, 496). Screen is 402x874 points.
- First render after install can take several seconds. A blank screenshot usually means the app
  is still building its render pipeline, not that it crashed.

Tests: `xcodebuild -project VO2Max.xcodeproj -scheme VO2Max -destination "id=$UDID" -derivedDataPath build/dd test`
