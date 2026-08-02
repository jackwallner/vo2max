# Handoff: VO2+ / range-picker UX audit

Status as of 2026-08-02. The sweep is complete; what is left is listed at the bottom.

## What shipped

- `64c7354` — VO2+ hub rebuilt (highlights table + three sectioned groups of tappable rows),
  segmented range Picker replaced with the Vitals capsule button bar, `CardioRange` +
  `CardioRangeStore` added, VO2+-gated Custom date range, date-span captions everywhere.
- `14059b0` — range-math fixes 1 to 4 below.
- This commit — accessibility, paywall-impression, and degenerate-state fixes 5 to 11.

## Round one: range math (2026-08-01)

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
   bar at `DynamicTypeSize.accessibility1` and lowered `minimumScaleFactor` to 0.65.

## Round two: accessibility, analytics, degenerate states (2026-08-02)

The suspicion left open in round one is **confirmed**, and it was worse than an accessibility
nuisance — the same always-alive tab stack was also inflating a RevenueCat metric.

5. **Hidden tabs were in the accessibility tree.** Standing on Trends, `axe describe-ui`
   returned 154 labelled elements: all of Today and all of VO2+ as well. The control that
   settles it is the locked Deep Trends teaser, whose blurred rows carry
   `.accessibilityHidden(true)` and are correctly absent from the same dump — so the tool
   honours the flag, and the tab guard genuinely was not applying. `.accessibilityHidden` on
   the outside of a `NavigationStack` does not reach the content it hosts; `tabContent` now
   applies it to each tab's root *inside* the stack. Trends alone now reports 78 elements.
6. **A free user's VO2+ tab logged a paywall impression on every launch.** `PlusTabView`
   rendered `PaywallView(embedded:impressionID:"vo2plus_tab")` inside the always-alive
   `ZStack`, so its `onAppear` fired whether or not the tab was ever opened, and
   `trackPaywallImpression` does not dedupe unless asked. Every free launch counted against
   that tab's conversion rate. The embedded paywall is now built on arrival (`isActiveTab`
   environment value, set by `tabContent`), and `PaywallView.onAppear` guards on it too.
   *Historic `vo2plus_tab` impression counts in RevenueCat are inflated and not comparable
   with post-fix numbers.*
   - Deferring the build was also the only thing that removed the paywall from the
     accessibility tree. `.accessibilityHidden(true)` had no effect on that subtree at three
     different levels (tab root, `PlusTabView`'s `Group`, the paywall's own state branch),
     verified with a runtime probe that confirmed the flag really was `false` there.
7. **Today's signal tiles announced their name and not their number.**
   `.accessibilityElement(children: .combine)` followed by `.accessibilityLabel` discards the
   combined text, so VoiceOver read "Resting Heart Rate" and stopped. Now carries an
   `accessibilityValue`: the reading and its change, "No readings in the …" when the window is
   empty, or the lock notice.
8. **The Trends chart spoke dates with no values.** Swift Charts announced each reading as a
   bare interval ("May 24, 2026 at 12 AM to May 31, 2026 at 12 AM"). The point marks now carry
   a label and value ("May 24, 2026" / "38.8 mL/kg/min") and the line mark is hidden. The two
   target `RuleMark`s also moved out of the per-sample closure, where they were being redrawn
   once per reading.
9. **Locked sparklines handed VoiceOver 11 week-intervals each, three times per screen.**
   `plusBlurred()`'s `accessibilityHidden` does not reach inside a `Chart`; the marks are now
   hidden individually, which is the level Swift Charts honours.
10. **Tab bar.** No `.isSelected` trait, so VoiceOver never said which tab you were on. Also no
    `contentShape`: an unselected tab reported a 30x34 accessibility frame where it draws
    72x44. Both fixed.
11. **Degenerate states.** The VO2+ highlights card emitted a divider after each of the first
    two rows, so an early-history user (personal best only — age reference needs a reference
    profile, target outlook needs five readings) got a card ending on a divider with nothing
    under it. Rows are now built as a list and separators interleaved. `EstimateFreshness`
    with no readings showed a giant "—" over "days since your last estimate", directly
    contradicting the "No estimate yet" headline below it; it now shows an icon instead.

Element counts, Trends tab, free user, seeded data: **154 → 78**.

## Verified this round

Light appearance throughout (the simulator was in light mode for every run). Free/locked pass
over Today, Trends and the VO2+ tab. Pro pass over the VO2+ hub with five readings and with
zero readings. HealthKit permission denied in every run, so the resting-heart-rate,
recovery and cardio-load empty states were exercised on both the tiles and the cards.
Estimate Freshness with no readings. 65 tests pass.

## Not yet done

- Swift Charts x-axis labels truncate at accessibility sizes ("Ma…", "Jun…"). Pre-existing,
  not caused by the range work. Would need `.chartXAxis` with an explicit reduced mark count.
- The floating tab bar's `.ultraThinMaterial.opacity(0.8)` barely obscures content scrolled
  under it in light mode — text behind it collides with the tab labels. **Left alone
  deliberately**: `~/vitals/Vitals/App.swift:807` uses the identical treatment, so this is a
  fleet-wide design decision, not a VO2Max regression. Raise it across the fleet or not at all.
- The highlights-card divider fix (11) is verified by reading and by confirming the three-row
  case is unchanged; the one-row case has no seeding flag, so it was not reproduced on device.
- Degenerate states still unreproduced for want of a seeding flag: exactly one reading, a
  custom range containing no data, a two-year custom range.
- Locked pass was at the default Dynamic Type size only, not at accessibility sizes.
- Dark appearance not re-checked this round (it was checked in round one).

## How to run it

```
UDID=$(agent-sim boot vo2max)          # prints the device UDID
xcodegen generate
xcodebuild -project VO2Max.xcodeproj -scheme VO2Max -destination "id=$UDID" -derivedDataPath /tmp/vo2max-verify build
xcrun simctl install "$UDID" /tmp/vo2max-verify/Build/Products/Debug-iphonesimulator/VO2Max.app
xcrun simctl launch "$UDID" com.jackwallner.vo2max -ScreenshotTab 1 -SeedScreenshotData -DemoPro
agent-sim screenshot vo2max   # writes /tmp/agent-sim.png
axe describe-ui --udid "$UDID"
```

Flags: `-ScreenshotTab 0|1|2` (Today, Trends, VO2+), `-SeedScreenshotData`, `-DemoPro`,
`-OnboardingPage 1`.

Gotchas:
- The device UDID is not stable across recreations — take it from `agent-sim boot`, don't
  hardcode it.
- `axe tap` fails with "No translation object returned" while the HealthKit sheet is up.
  `axe touch -x <x> -y <y> --down --up` works and is what the recipe below uses.
- `-DemoPro` **persists** `isPro` to defaults. Uninstall and reinstall to get back to the free
  state; relaunching without the flag is not enough.
- A fresh install shows the HealthKit permission sheet. It is a separate process and does not
  appear in `axe describe-ui`. Dismiss with "Don't Allow" at (201, 809), then "OK" at
  (201, 496). Screen is 402x874 points.
- Tab bar hit points, in points: Today (129, 834), Trends (201, 834), VO2+ (273, 834).
- First render after install can take several seconds. A blank screenshot usually means the app
  is still building its render pipeline, not that it crashed.

Tests: `xcodebuild -project VO2Max.xcodeproj -scheme VO2Max -destination "id=$UDID" -derivedDataPath build/dd test`
