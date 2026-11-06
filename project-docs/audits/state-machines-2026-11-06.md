# VO2 Max state machine audit, 2026-11-06

Scope: iOS app, `Shared/`, widgets, watch targets. No backend function exists in this repo (RevenueCat is the only entitlement authority; read through `StoreService`). Android out of scope. Audited committed code at `52955e8` (stash was empty; tree was clean). Nothing was fixed.

**Summary: 7 bugs. 1 proved by failing test (SM-1), 6 code path only (SM-2 to SM-7). 9 product calls (not counted).**

Evidence run: `gh-sim test --scheme VO2Max --only VO2MaxTests/StateMachineAuditRepro`, GitHub run 42286007203 (recorded values below; 1 passed, 2 failed). An earlier run, 42282994374, tripped the suite's own precondition by one second (fixed in the suite) and showed the same 7 nudges in 14 days. Repro file: `state-machines-2026-11-06-repro.swift`.

## Seams available (checked before marking anything "Code path")

| Seam | Where | Usable for |
| --- | --- | --- |
| `CardioFreshnessAnalysis.nextNudgeDate(points:lastNudge:now:calendar:)` | `CardioFreshness.swift:117` | Pure, used by SM-1. |
| `ConversionDiagnostics.defaultsOverride` | `ConversionDiagnostics.swift:44` | Funnel counters only. |
| `ReviewPromptTracker` static API + app-group defaults | `ReviewPromptTracker.swift` | Tracker rules, not the `HealthKitService` call site. |
| `CardioRangeStore` init takes `defaults`, but is private and `shared` is a singleton | `CardioRangeStore.swift:25` | Not constructible from tests. |
| `NotificationService` | `NotificationService.swift` | Static enum over `UNUserNotificationCenter.current()`. No injected scheduler, so no fake can sit behind it without an app change. Calls from a hosted test would hit the real center, whose authorization is `notDetermined` on the runner. |
| `StoreService` | `StoreService.swift:155` | `private init`, `private(set)` state, `Purchases.shared` is a trap when unconfigured. No `CustomerInfo` fixture path; `update(customerInfo:)` is private. |
| `GoalSettings` | `GoalSettings.swift:33` | `private init`, shared app-group suite. |
| `NSTimeZone.default` | n/a | Settable, but none of the claims below depend on the zone. |

Scheduler call sites (for the notification claims):

- Monthly recap: `scheduleMonthlyRecap` only from `MainTabView.syncMonthlyRecapSchedule` (`App.swift:451`, run by `.task(id: recapSchedulingKey)` at `App.swift:394`). Cancel from the same function.
- Reading alert: `scheduleNewReadingAlert` only from `HealthKitService.handleNewReadings` (`HealthKitService.swift:323-325`). Never pending (1 s trigger).
- Freshness nudge: `scheduleFreshnessNudge` only from `HealthKitService.syncFreshnessNudge` (`:356-360`). `syncFreshnessNudge` callers: `performRefresh` (`:163`), `MainTabView` `.task(id: freshnessSchedulingKey)` (`App.swift:395`), Settings toggle setter (`SettingsView.swift:319`). Cancel: `:341`, `:352`.
- `requestAuthorization` callers: `SettingsView.swift:305`, `:318`, and inside `scheduleMonthlyRecap` (`NotificationService.swift:71`). Nothing renders the result.

## Bugs, ranked by impact

| id | Bug | What the user sees | Promise | User route | Impact | Evidence | file:line |
| --- | --- | --- | --- | --- | --- | --- | --- |
| SM-1 | Freshness nudge spacing is defeated by its own bookkeeping: the spaced (future) fire date is stored as `lastNudge`, and the next evaluation discards any future `lastNudge` as "the pending request", so the nudge is pulled forward to now. | A stale-estimate user gets a "Your estimate has gone quiet" notification every second app open, about every 2 days, not every 5. | `CardioContextViews.swift:1333` "at most once every five days"; `CardioFreshness.swift:105` "Minimum days between two freshness nudges"; `:111` "never sooner than `nudgeSpacingDays` after a nudge that was delivered". | Today > gear > Settings > VO2+ section > "Know when your estimate goes stale" toggle on (Pro, tap Allow), estimate older than 2x own cadence (21 days when under 4 readings in a year). Nudge arrives within seconds. Background the app, reopen (foreground refresh runs `syncFreshnessNudge`), background, reopen again: the second reopen schedules a nudge for 1 s later. | Pro users with freshness nudges on and a stale estimate (the feature's whole target group: lapsed workouts, no Watch outdoor sessions). Triggers on every foreground refresh, so about every other open. Cost: notification spam from a paid feature, leading to muting notifications or cancelling. Moderate user count, high annoyance. | **Proved by test.** Recorded: `secondForegroundDoesNotPullTheSpacedNudgeForward` failed, after the precondition passed (first spaced nudge >= t0 + 5 d), the third evaluation (2 h after the first nudge) scheduled the nudge for 2026-11-06 22:39:21 when 2026-11-11 20:39:20 (t0 + 5 d) was the earliest allowed. `staleUserOpeningDailyForTwoWeeksGetsAtMostOneNudgePerFiveDays` failed: 7 nudges in 14 days, gaps `2.00` days x6, expected at most 3 and a minimum gap of 5. Controls `control_firstEvaluationAfterDeliveredNudgeKeepsSpacing` passed. Limit: the suite replays the read/compute/write cycle of `syncFreshnessNudge` around the real `nextNudgeDate`; that the app writes `date` into `lastFreshnessNudge` on success is read from `HealthKitService.swift:357-359`, not executed. | `HealthKitService.swift:348,356-359`; `CardioFreshness.swift:128-131` |
| SM-2 | Notification opt-in toggles never reconcile with the iOS permission. The setters drop the `requestAuthorization()` result, no view reads `isAuthorized()`, so after "Don't Allow" the toggle stays on and the freshness screen says nudges are on. | Toggle on, card reads "On. You'll get a nudge...", nothing is ever delivered. No hint that iOS notifications are off. Recap, reading alerts and nudges all behave this way. | `CardioContextViews.swift:1333` "On. You'll get a nudge when an estimate is overdue against your own cadence"; `PaywallView.swift:72` "A notification each time Apple Health logs a new VO2 max estimate". | Pro: Today > gear > Settings > VO2+ > toggle on > "Don't Allow". Then VO2+ tab > Estimate Freshness row > card says "On." | Every Pro user who declines the one-shot iOS prompt after flipping any of the three toggles (declining is common for a prompt that appears out of context). Cost: a paid feature silently does nothing, and the only fix is hidden in iOS Settings with no pointer. Permission granted later does recover (reading alerts check at fire time `NotificationService.swift:154`; nudges at the next refresh; recap at the next launch `App.swift:394`) but the UI is never told. | **Code path.** No injectable scheduler (`NotificationService` is a static enum). Settle with a UI test that runs with notification permission denied (`simctl privacy` cannot set it; needs `UNUserNotificationCenter` stub in the app) and reads the card text. | `SettingsView.swift:302-320,329-330`; `NotificationService.swift:44-53,57-64`; `CardioContextViews.swift:1328-1336` |
| SM-3 | The once-ever "first return visit with an estimate on screen" review moment is consumed by the background HealthKit relaunch, where nothing is on screen. | Rating prompt never appears for the typical new Watch user's first return; the one-time moment is spent. | `AGENTS.md:34` "(once ever) the first return visit with an estimate on screen"; `ReviewPromptTracker.swift:5,119-121`; `AGENTS.md:35-36` "from the 2nd launch". | Install, onboard, grant Health (launch 1, readings cached). Close the app. A new estimate lands overnight; HealthKit background delivery relaunches the process: `App.init` runs `recordAppLaunch()` (`App.swift:16`, count becomes 2) then `enableBackgroundDelivery()` (`:31`), the observer runs `performRefresh`, which calls `recordReturnWithReading()` (`HealthKitService.swift:171`) with no scene. User then opens the app: no ask. | Watch users who get a VO2 estimate before their second manual open, which is the common case (estimates arrive 1 to 2 times a week, delivery is `.daily`). Cost: a lost rating ask. Low money, wide reach. The ask later needs a PB or target entry (rare, per `HealthKitService.swift:285-287`). | **Code path.** `HealthKitService` is not constructible without HealthKit and `performRefresh` is private. Settle with a test that wraps the call in a seam taking `isForeground`, or a launch-args test that calls `performRefresh` with `-DemoData` and no scene and asserts `returnWithReadingFired` stays false. | `App.swift:16,31`; `HealthKitService.swift:168-173`; `ReviewPromptTracker.swift:121-129` |
| SM-4 | A recap or "open Today" notification tap delivered before `MainTabView` exists leaves `pendingRecap`/`pendingToday` stuck `true`; `onChange` never fires for it and every later tap sets `true` over `true`, also no change. | Tapping "Your cardio fitness month" opens the app on Today with no recap, and later taps do nothing until relaunch. | `MonthlyRecapView.swift:4` "Presented when the user taps the monthly notification". | Pro, recap on. Force-quit, wait for the 1st 18:00 notification, tap it (cold launch). The `didReceive` Task (`App.swift:182-195`) runs on the main actor right after launch; `MainTabView` observes with `.onChange(of:)` (`App.swift:396`) which does not fire for a value that was already `true` when the view appeared. | Pro users with recap on tapping from a cold start; the recap is monthly, so about 1 tap per month per such user. Timing dependent: only when the delegate callback beats the first render. Cost: feature appears broken once; recovers on next launch. | **Code path (timing dependent).** Needs a UI test that sends a notification response at cold launch (`XCUIApplication` + `UNUserNotificationCenter` delegate injection). Not possible from the unit target. Reviewer note: severity depends on iOS delivering the response before the first SwiftUI render; this audit did not observe the order. | `App.swift:147-160,182-195,396-405` |
| SM-5 | The required auto-renew disclosure under the paywall CTA is replaced by stale state: a shared singleton `store.errorMessage` (set by any surface) and a never-cleared `restoreMessage` `@State`. | After one failed Restore, or after cancelling the Apple sheet on another screen, the footer shows "No active VO2+ purchase was found." or "Trial wasn't started. Tap again to continue." in place of "...renews automatically unless you cancel...". | `VO2ConversionCopy.swift:52` "Apple 3.1.2 disclosure adjacent to the purchase button"; `PaywallView.swift:332` "CTA + required 3.1.2 disclosure". | Free user: VO2+ tab (embedded `PaywallView`) > Restore with no purchase. Footer text stays the restore message (`restoreMessage` is only set, never cleared: `PaywallView.swift:360,376`) until the paywall is rebuilt. Cross-surface: Settings > "Continue with VO2+" > Apple sheet > Cancel sets `store.errorMessage` (`StoreService.swift:277-280`), then VO2+ tab footer shows it red with no attempt made there (`PaywallView.swift:358`). | Free users who restore or cancel before buying: a large share of paywall sessions. Cost: App Review 3.1.2 exposure and a user who buys without the renewal text next to the button. | **Code path.** Views hold the state in `@State`/singleton; no view test harness. Settle with a UI test on the paywall that taps Restore and asserts the disclosure string is still present. | `PaywallView.swift:194,358-377`; `StoreService.swift:171,270,277,301,311,315` |
| SM-6 | Entitlement lapse does not reach pending local notifications or the notification route until the app next launches and verifies; the recap tap route opens the VO2+ recap with no `isPro` check. | A lapsed subscriber still gets the monthly recap push; tapping it shows the recap for free. | `PlusTabView.swift:25` recap lives under `store.isPro`; `StoreService.swift:158-159` cached flag documented as the widget/background gate; `NotificationService.swift:112-113` "Only call when the user is entitled". | Pro, recap on, subscription expires while app is closed (no push exists to tell the app). On the 1st at 18:00 the repeating request still fires. Tap: `showRecap = true` (`App.swift:398-399`) presents `MonthlyRecapView` with no entitlement check. After the process starts, `store.start()` flips `isPro` and `syncMonthlyRecapSchedule` cancels, but that happens after the tap. | Lapsed monthly subscribers who do not open the app before the next 1st: at most one leak each. Reading alerts also use the cached flag (`HealthKitService.swift:313`). Cost: one free recap, no data loss. Low. | **Code path.** Same seams missing as SM-2 and SM-5. Settle with a fixture-based `StoreService` test (needs `update(customerInfo:)` made internal) plus a route test. | `App.swift:394,396-405,451-457`; `HealthKitService.swift:313,339` |
| SM-7 | Settings shows "Connected" after the user denies Health, because the flag flips when the prompt returns, not when a reading arrives. | Apple Health status: green "Connected" with an empty app, while the footnote says Connected appears only after a reading. | `SettingsView.swift:216` "\"Connected\" appears once a reading has been read." | Fresh install > Continue on welcome (Health sheet, `OnboardingView.swift:387`) > Don't Allow > finish onboarding > Today gear > Settings > Apple Health section: "Connected". | Users who decline all Health access: a minority of installs, but they are exactly the ones who need to be told access is missing. Cost: the "Needs access" state and its recovery text never show. | **Code path.** `HealthKitService` needs a real or faked `HKHealthStore`; none is injected (`:17`). Settle by a test that stubs `store.requestAuthorization` to return with no readings and asserts `isAuthorized == false`. Design intent at `HealthKitService.swift:46-51` ("prompted is the strongest signal"): the code is deliberate, the user-facing sentence is what it contradicts. | `HealthKitService.swift:105-110,52-56`; `SettingsView.swift:163-166,216` |

## Product calls (not counted; no promise to cite)

1. Settings "Connected" never reverts once Health was prompted (`HealthKitService.swift:27-34,52-56` documents the one-way flag). A user who later revokes access in Health still sees "Connected" (`SettingsView.swift:165`). The never-reading case is SM-7.
2. An empty fetch prunes nothing (`HealthKitService.swift:440-441`, documented). A user who deletes all VO2 max data in Health keeps the cached history, widget value and trend in the app, while `:246` says deleted samples "must disappear here too".
3. Onboarding ends as soon as `isPro` turns true (`OnboardingView.swift:103-105`), at any step, so a returning subscriber can skip the Health prompt and profile with default age 35.
4. The freshness nudge fires at `latest.date + N days` at the wall-clock time of the last workout (`CardioFreshness.swift:125`), including overnight.
5. Ask to Buy returns `.pending`; `SettingsView.swift:145` closes the trial sheet silently and shows nothing.
6. `introEligibility` is refreshed only at `start()` and after a failed purchase (`StoreService.swift:300,427`). Within one process a user whose trial ended could still see trial copy.
7. A deferred purchase approved later flips `isPro` through the delegate and never calls `recordConversion` (`StoreService.swift:282-290`); the funnel attributes undercount.
8. `restoreResultMessage` returns unlocalized strings (`VO2ConversionCopy.swift:85-88`), unlike every other copy path (`.claude/rules/localization.md`).
9. Freshness nudge body says "in N days" computed at schedule time; a pending request is replaced on each refresh but is not cancelled if the observer wake is delayed (`.daily` delivery), so it can land after a new estimate was logged.

Considered and not counted (no way to prove, no clear promise): toggle-off while `scheduleFreshnessNudge` is awaiting `isAuthorized()` could leave a request pending (`HealthKitService.swift:356-360` vs `:341`); widget and watch do not gate on `isPro` (by design, "remain free", `SettingsView.swift:388`).

## Related fixes, in order

1. SM-1: store the fire date only after delivery is known, or keep a separate `lastDelivered` and compare future `lastNudge` to the request that is actually pending (keep the pending date, not the spaced one, as the thing to ignore). Add the repro tests as regressions.
2. SM-5: clear `restoreMessage` on any purchase or restore start and scope `errorMessage` to the surface that raised it (or clear it on `onAppear`).
3. SM-2: read `NotificationService.isAuthorized()` on toggle and on foreground, show an off state or a "Turn on in iOS Settings" row. Fixes the card copy as well.
4. SM-4: handle pending flags in `.onAppear` as well as `.onChange`.
5. SM-3: skip `recordReturnWithReading` unless the app is in the foreground.
6. SM-6: gate the recap sheet on `store.isPro` at presentation, not only at schedule time.

## State machines

Invariant ids are scoped per machine. "Breaks" in the tables names the invariant a bad transition violates.

### M1. Entitlement (`StoreService.isPro`)

States: `cachedTrue` or `cachedFalse` at launch (read from app group key `isPro`, `StoreService.swift:188`); `verified(true|false)` after a RevenueCat answer; `unverifiable` (fetch failed, cache kept).

Invariants:
- E1: `isPro` and the app-group key agree (`didSet` at `:163-166`, `update` at `:455`).
- E2: every VO2+ surface reads `store.isPro`; background code reads only the cached key.
- E3: persisted toggles survive a lapse (`GoalSettings.swift:44-45`), the views AND them with `isPro`.
- E4: scheduled notifications match `isPro && toggle`.

| From | Event | To | Notes |
| --- | --- | --- | --- |
| any | launch | cached(x) | E1 ok |
| cached | `refreshStatus` ok | verified | `:407` |
| cached | `refreshStatus` throws | unverifiable | error text, cache kept (`:409`) |
| verified true | lapse with app closed | verified true (stale) | **breaks E4** (SM-6) |
| any | purchase success | verified true | `:275` |
| any | restore | verified | `:314` |
| any | delegate update | verified | `:370` |
| any | DEBUG override | `isPro` forced | DEBUG only (`:362`, `SettingsView.swift:377`) |

### M2. Purchase and restore flow

States: idle; `isLoading`; result `.purchased | .cancelled | .pending | nil(error)`; `errorMessage` (singleton text).

Invariants: P1 `errorMessage` describes the latest attempt on the surface that shows it; P2 `isLoading` is false after every path (`defer`, `:271`, `:312`); P3 trial copy only when eligibility resolved and eligible (`:226-230`).

| From | Event | To | Notes |
| --- | --- | --- | --- |
| idle | purchase | loading | clears message |
| loading | user cancel | idle + cancel text | **breaks P1** on other surfaces (SM-5) |
| loading | success, pro true | idle, recordConversion | |
| loading | success, pro false | idle, `.pending` | no text; sheet closes (product call 5) |
| loading | throw | refreshIntroEligibility, failure text | |
| idle | restore ok, not pro | idle + "No active..." | PaywallView keeps copy forever, **breaks P1** (SM-5) |

### M3. Intro eligibility

States: unresolved; resolved with map. Resolved only from `loadOffering` (`:427`) and failed purchases (`:300`). I1: trial copy hidden unless resolved. Transition to a used trial inside one process is not observed (product call 6).

### M4. Onboarding and setup

States: `Step` welcome, profile, target, trial (`OnboardingView.swift:17-20`); `hasCompletedSetup` bool in app group.

Invariants: O1 edit buffers are written only at `finishOnboarding` (`:110-117`); O2 Health prompt fires once when leaving welcome (`:121-123`); O3 `hasCompletedSetup` only moves to true.

| From | Event | To | Notes |
| --- | --- | --- | --- |
| any step | `isPro` flips true | finished | skips O2 (product call 3) |
| trial | purchase | finish via `onChange` | `:540` |
| trial | restore | finish if pro | `:548` |
| trial | no monthly package | paywall sheet | `:530` |

### M5. HealthKit authorization, observer and refresh

States: `isAuthorized` (one-way), `hasGrantedHealthAccess` (one-way), observer installed or nil, `refreshTask` nil or running, `isRefreshing`.

Invariants: H1 one refresh at a time (`:139-147`); H2 observer is installed on any launch with a persisted grant (`:78-84`); H3 a refresh finishes the cache, widgets and alerts before acknowledging the wake (`:392-396`); H4 an empty fetch never prunes (`:448`).

| From | Event | To | Notes |
| --- | --- | --- | --- |
| not authorized | prompt returns | authorized | `:109` |
| authorized | user revokes in Health | authorized (stale) | product call 1 |
| any | background wake | observer refresh | H2/H3 hold |
| any | fetch throws not-determined | silent | `:180` |
| refreshing | second caller | awaits same task | H1 |
| refresh | readings empty | cache untouched | H4 |
| refresh | readings non-empty | recordReturnWithReading | **breaks AGENTS.md:34 when no scene** (SM-3) |

### M6. Local notifications (three loops)

State tuple per loop: (`isPro` cached, toggle, OS permission, pending request).

Invariants: N1 pending request exists iff `isPro && toggle && authorized` (for recap and nudge); N2 reading alerts post only for a genuinely newer estimate (`:293-296`); N3 a nudge is spaced 5 days from the last delivered one; N4 the toggle UI shows the real state.

| Loop | Event | Result | Breaks |
| --- | --- | --- | --- |
| Recap | toggle on, authorized | schedule day 1, 18:00 repeating (`:73-82`) | |
| Recap | toggle on, denied | nothing scheduled, toggle stays on | N4 (SM-2) |
| Recap | permission granted later | scheduled at next launch (`.task` on appear) | N4 (UI never says) |
| Recap | pro lapses, app closed | stays pending until launch | N1 (SM-6) |
| Nudge | toggle on, stale, authorized | schedule at now | |
| Nudge | second evaluation after a spaced one | rescheduled at now | **N3** (SM-1) |
| Nudge | toggle off | cancel (sync) | N1 ok; in-flight race considered, not counted |
| Reading | new estimate, pro, toggle, authorized | post in 1 s | |
| Reading | pro lapsed, cache stale | still posts | N1 variant (product call) |

### M7. Notification routing

State: `pendingRecap`, `pendingToday` flags, consumed by `MainTabView.onChange`. Invariants: R1 a flag is cleared when consumed (`App.swift:398,402`); R2 every tap yields a visible result.

| From | Event | To | Notes |
| --- | --- | --- | --- |
| false | tap, view mounted | true then false, sheet | R1 ok |
| false | tap before view exists | true, never consumed | **breaks R1, R2** (SM-4) |
| true (stuck) | tap again | true (no change) | **breaks R2** (SM-4) |
| any | tap while lapsed | recap sheet opens | **breaks entitlement gate** (SM-6) |

### M8. Review prompt (`ReviewPromptTracker`)

State: launch count, first open, last shown, outcome (`openedWriteReview` terminal, `submittedFeedback`), positive moment count, `hasPendingPositiveMoment`, `hasSeenReading`, `returnWithReadingFired`.

Invariants: V1 no ask in the first session; V2 30-day cooldown; V3 `openedWriteReview` ends the asks and feedback cannot reopen them (`:170-176`); V4 a blocked ask leaves the moment pending (`:150-157`); V5 return moment fires once ever, on a visible return.

| From | Event | To | Notes |
| --- | --- | --- | --- |
| any | process start (incl. background) | count + 1 | feeds V1 early (SM-3) |
| seen reading | refresh at count >= 2 | moment fired | **breaks V5** when background (SM-3) |
| pending | Today clear 3.5 s | `markShown` | |
| pending | sheet up | stays pending | V4 ok |
| any | open write-review | terminal | V3 ok |

### M9. MainTabView presentation

State: `selection`, `showSettings` (sheet folded, pane split), `showWhatsNew` with `pendingSettingsAfterWhatsNew`/`pendingPaywallAfterWhatsNew`, `showPaywallFromWhatsNew`, `showRecap`, `whatsNewEvaluated`, `reviewPromptShownThisSession`, `ReviewPromptCoordinator.openSheets`.

Invariants: S1 at most one sheet from `MainTabView` at a time (What's New hands off in `onDismiss`, `App.swift:409-417`); S2 split never leaves `selection == 1` (`App.swift:379,383`); S3 Settings moves between sheet and pane without dismissal (`settingsSheet`, `:314`); S4 What's New shows once per content version and is marked shown before presenting (`:459-467`).

No bad transition found. Recap opened while What's New is up is guarded by `!showRecap` only on the way in; a recap tap during What's New queues `showRecap = true` under an active sheet, which SwiftUI defers, so the recap appears when What's New is dismissed (not verified on device).

### M10. Range selection (`CardioRangeStore`)

State: `selection` (fixed windows or custom) plus `customStart/customEnd`. Invariants: C1 custom range ordered and at most `maximumCustomDays` (`applyCustom`, `:61-67`); C2 a non-Pro user is never left on custom (`MetricRangePicker.onAppear`, `CardioContextViews.swift:53-54`). Custom end date does not roll forward by design. No bad transition found.

### M11. Derived state: freshness, trend, target

`EstimateFreshnessState` noReadings, fresh (`days <= ref`), aging (`<= 2 x ref`), stale; `CardioTrend`; `TargetRangeStatus`. All pure functions of points and `now`; `nextNudgeDate` is consistent with `assess` at the boundary (existing test `OvernightP1Tests.nudgeIsScheduledForTheDayTheEstimateGoesStale`). Calendar-day arithmetic uses `Calendar.current`, so a zone change moves the day count by at most one.

### M12. Cache reconciliation (`HealthKitService.cache`)

Insert new, update existing, prune records absent from the fetch inside the fetch window and after `earliestPermittedSampleDate`. Invariants: K1 the watch keeps readings its HealthKit has purged; K2 a deleted reading disappears (except when the fetch is empty, product call 2); K3 background alerts fire only for readings newer than everything cached (`:296`). No bad transition found beyond product call 2.
