VERDICT: FAIL

# Verify: state machine audit fixes, 2026-11-06

Independent regression check of the fixes in `state-machines-2026-11-06-fixes.md`, against the routes in `state-machines-2026-11-06-review.md`. Whole change read: `git diff 093d94d946553ccdcd21a2967786ef163dc1ec80..a45cd85` (13 commits, app code in `CardioFreshness.swift`, `NotificationService.swift`, `HealthKitService.swift`, `StoreService.swift`, `ReviewPromptTracker.swift`, `VO2ConversionCopy.swift`, `App.swift`, `PaywallView.swift`, `SettingsView.swift`, `CardioContextViews.swift`, plus the string catalog and tests). No app code or tests were changed by this check.

One failure: the SM-6 background re-verify configures RevenueCat on a background wake, which replays RevenueCat's cached record into the app's Pro flag before the fresh answer arrives. When that fetch fails or times out, a stale cache that reads a renewed member as lapsed stands, and the same refresh then cancels the member's pending freshness nudge and drops their reading alert. That is a teardown on an inferred state (check 4), and it contradicts the fixes doc's own claim that "on timeout or error the cached flag stands". Everything else works and is in scope.

## Fixes

| id | Works | Regression check | Evidence |
| --- | --- | --- | --- |
| SM-1 | Yes | Pass | Route: Pro, nudges on, stale estimate, keeps opening the app (two syncs per cold launch). `nextNudgeDate` now keeps a pending (future) `lastNudge` as the floor (`Shared/Utilities/CardioFreshness.swift:131-136`) and spaces 5 days from a delivered one; the stored value is the real fire date with the 1 s floor (`NotificationService.swift:197-206`, `HealthKitService.swift:363-366`). A second sync seconds later returns the same date, so a cold launch no longer fires a banner. Same key, same `Date` type: an upgraded install's stored value is either past (treated as delivered, spaced) or future (kept), so nothing resets. New estimate still pushes it later (`sm1_newEstimatePushesPendingNudgeLater`). Callers checked: `App.swift:398` `.task(id:)`, `SettingsView.swift:352`, `HealthKitService.swift:170`; the watch builds this code but its cached Pro flag is never set, so it only cancels, as before. Widgets do not read the key. Time zones: absolute dates and `Calendar.date(byAdding: .day)`, unchanged. Reverted test proof below: all three SM-1 tests fail without the fix. |
| SM-5 | Yes | Pass | Route: onboarding trial CTA, cancel the Apple sheet, Get Started, VO2+ tab. `PaywallView` no longer renders `store.errorMessage` live (`VO2Max/Views/PaywallView.swift:365-372`); it shows `attemptMessage`, set only after a purchase or restore started on that paywall (`:343-346`, `:380-385`) and cleared on a plan change (`:232`). `PlusTabView` builds a fresh `PaywallView` with `attemptMessage == nil`, so the renewal disclosure shows. A cancel or failure started on the paywall still shows its message. Store errors from `start()` (`Could not verify purchases.`, offering load) no longer reach the footer; that is the stale-singleton class the review asked to remove. Onboarding and Settings trial sheets keep their own error state, untouched. `sm5_paywallNeverRendersTheSharedStoreError` fails without the fix (reverted run). |
| SM-3 | Yes | Pass | Route: launch 2 is a HealthKit background relaunch. `recordReturnWithReading(appIsVisible:)` refuses when `UIApplication.shared.applicationState == .background` (`ReviewPromptTracker.swift:133-140`, `HealthKitService.swift:178`, `:373-379`), leaving the moment for the visible return, where the scene's `.active` refresh fires it. `MainTabView.onAppear` now also checks for a pending moment (`App.swift:392`), so a moment recorded before the view exists still gets the system ask; the ask stays behind the same gates (`shouldRequestAfterPositiveMoment`: pending moment, setup done, 2nd launch, 30-day cooldown, Today clear). Stored key `reviewPrompt.returnWithReadingFired` unchanged, so users who already spent it stay spent. Watch passes `true` (`:376-378`), the old behaviour. Not a paywall or trial change. `sm3_backgroundRelaunchLeavesTheReturnMomentForTheVisibleReturn` fails without the fix (reverted run). |
| SM-2 | Yes | Pass | Route: notifications denied earlier, Pro, Settings > VO2+ > toggle on. All three toggles read `stored && !notificationsDenied` (`SettingsView.swift:335,347,362`); `notificationsDenied` loads on appear and on every return to `.active` (`:109-113`), so it follows iOS Settings. Turning a toggle on calls `optIn()` (`NotificationService.swift:87-92`): a fresh decline shows the toggle off, an earlier denial opens "Notifications are off" with Open Settings and Not now (`SettingsView.swift:103-108,118-122`). The stored preference is kept. The Estimate Freshness card reads the same denial (`CardioContextViews.swift:1227,1335`). The recap toggle now also asks iOS, which `scheduleMonthlyRecap` already did on every schedule (`NotificationService.swift:100`); no new prompt. "Notifications are off" is in all 19 catalog languages, all `translated`; "Open Settings" and "Not now" already were. iPhone Duo Settings pane: same view, alert attaches to the `Form`. `sm2_togglesAndFreshnessCardReadTheDenial` fails without the fix (reverted run). |
| SM-6 | Partly: the lapse half works, the renewed member half regresses | **Fail** | Lapse route works: a background refresh calls `verifyEntitlementForBackgroundWork()` before alerts and the nudge (`HealthKitService.swift:167-170`); a fresh `.fetchCurrent` "not a member" flips the cached flag and cancels the recap and nudge (`StoreService.swift:432-450`). The `isPro` `didSet` no longer cancels anything. **Regression:** `configureIfNeeded()` at `StoreService.swift:434` is the first RevenueCat configure on a background wake (before this change only the scene's `start()` and paywall impressions configured it). Setting `Purchases.shared.delegate` (`:418`) makes RevenueCat call `purchases(_:receivedUpdated:)` with its cached `CustomerInfo` at once, regardless of age (purchases-ios `Purchases.swift` `delegate` setter, `sendCachedCustomerInfoToDelegateIfExists`), and `:386-389` writes it into `isPro` and the App Group flag (`:498-503`). RevenueCat judges a cache older than 3 days against the current date (`CustomerInfo+ActiveDates.swift`, `requestDateGracePeriod = .days(3)`), so a member who renewed since the app last fetched reads as lapsed. If the fresh fetch then errors (no signal) or exceeds 8 s, `guard let info else { return }` (`:444`) leaves that cached lapse in place, and the same refresh reads it: `handleNewReadings` skips the member's reading alert (`HealthKitService.swift:320-322`) and `syncFreshnessNudge` cancels their pending nudge (`:346-348`). Before the change, a background wake used the app's own flag (true) and did both. Who: a monthly or yearly member who has not opened the app since a renewal, whose new estimate (from an outdoor workout, often out of coverage) wakes the app without a working network. |
| Product call 8 | Yes | Pass | `restoreResultMessage` uses `String(localized:)` (`Shared/Utilities/VO2ConversionCopy.swift:87-89`); "VO2+ restored." added in all 19 languages, translated. English results unchanged, so `OvernightP1Tests.restore*` still pass. Callers: `SettingsView.swift` restore row and `PaywallView.swift:383-385`. `restoreResultIsLocalized` fails without the fix (reverted run). |
| SM-4 | Held | Pass | Net zero code: `32508da` added it, `f45439b` backed it out; `App.swift` `.onChange(of: routeCoordinator.pendingRecap)` is unchanged from `093d94d`. Holding is right: the claim is UNVERIFIED with no failing test on `093d94d`, and check 4 forbids fixing it without one. |
| SM-6 recap tap | Held | Pass | `App.swift:441-444` still opens `MonthlyRecapView` unconditionally, as on `093d94d`. A display-time gate would change who sees a paywall (check 4), and the review called it half a product call, so it is a real decision for Jack. |
| SM-7 | Not in scope | Pass | NOT A BUG; untouched. The review's footer copy note was explicitly "not counted". |

No "Disputed" section exists in the fixes doc, so there is nothing to rule on there.

## Must change

1. **SM-6, `Shared/Services/StoreService.swift:432-450`.** A failed or timed-out background verify must leave the app's own cached flag exactly as it was before the call, not RevenueCat's cached replay. Smallest fix: capture it before configuring and restore it when there is no fresh answer.

   ```swift
   func verifyEntitlementForBackgroundWork(timeout: Duration = .seconds(8)) async {
       guard isPro else { return }
       let cachedPro = isPro
       configureIfNeeded()
       guard isConfigured else { return }
       let info: CustomerInfo? = await withCheckedContinuation { ... }   // unchanged
       guard let info else {
           // Configuring replayed RevenueCat's cached record, which can read a
           // renewed member as lapsed. Without a fresh answer, keep our flag.
           isPro = cachedPro
           return
       }
       update(customerInfo: info)
       if !isPro {
           NotificationService.cancelMonthlyRecap()
           NotificationService.cancelFreshnessNudge()
       }
   }
   ```

   `isPro`'s `didSet` writes the App Group key back. Add a test that fails on the current code: the source-text pattern the repo already uses is enough (the `guard let info else` branch restores the pre-configure flag), or better, a seam that feeds a cached "lapsed" update and a nil fresh answer and asserts `isPro` stays true. Then correct the fixes doc's SM-6 row.

2. **Fixes doc accuracy (non-blocking, fix with item 1).** It cites `1cb1e08` and `a696eae`, which are not on this branch; the commits that are here are `5b78a32` (fresh-lapse-only teardown, recap paywall backed out) and `f45439b` (SM-4 backed out). Its final suite run was on `1cb1e08`, not on this branch's head.

## Tests

| Run | What | GitHub run | Result |
| --- | --- | --- | --- |
| Full suite on `a45cd85` (HEAD) | `gh-sim test --scheme VO2Max` | 42340089891 | Xcode 27.1, iPhone 17, iOS 27.2. 144 passed, 0 failed, 0 skipped. Matches the fixes doc (144 passed). No new failures, so no `--only` reruns on `093d94d` were needed. |
| Fixes reverted, tests kept | Throwaway `scratch-revert`: `CardioFreshness.swift`, `PaywallView.swift`, `VO2ConversionCopy.swift` restored to `093d94d`; the `appIsVisible` guard, the background verify call and the `&& !notificationsDenied` reads removed. 8 tests in one `--only` run. Branch deleted afterwards. | 42343698050 | Built; 0 passed, 8 failed, each on its bug assertion: `sm1_secondSyncSecondsLaterKeepsSpacing` (second 2026-11-07 06:40:40 vs first 2026-11-11 06:40:35), `sm1_secondForegroundDoesNotPullTheSpacedNudgeForward`, `sm1_staleUserOpeningDailyForTwoWeeksGetsAtMostOneNudgePerFiveDays` (min gap 1.0 day), `sm5_paywallNeverRendersTheSharedStoreError` (`if let error = store.errorMessage {`), `sm3_backgroundRelaunchLeavesTheReturnMomentForTheVisibleReturn`, `sm2_togglesAndFreshnessCardReadTheDenial`, `sm6_backgroundRefreshVerifiesBeforeNotifying`, `restoreResultIsLocalized`. |
| Screens | `gh-sim launch --args "-DemoData -DemoPro -ScreenshotTab 0" --screen "-DuoScreen settings" --screen "-DuoScreen plus"` | 42348257357 | Built and launched; all three screenshots blank white (identical 69840-byte PNGs). No screen evidence. |

## Notes

- SM-5 restyle: a restore that finds nothing now shows in `Theme.negative` (red) instead of `Theme.textSecondary`, because both outcomes share `attemptMessage` (`PaywallView.swift:368`). Minor; "nothing found" is not an error.
- SM-5, SM-6 and part of SM-2 are proved by source-text tests (the repo's existing pattern). They show the code shape, not behaviour; no seam exists for RevenueCat, `UNUserNotificationCenter` or view state.
- SM-3 residual: `appIsVisible` is read after the HealthKit fetch. If a visible cold launch's first refresh finished before the scene left `.background`, it would skip the moment, and `refreshCache` would fold the scene's `.active` refresh into that in-flight one. The moment then fires on the next refresh instead. Not observed, and the fetch takes far longer than scene connection, so not a failure.
- SM-2: after the user enables notifications in iOS Settings, the toggles show on again but the recap is only rescheduled when `MainTabView`'s `.task(id: recapSchedulingKey)` next runs (next cold launch). Same as `093d94d`.
- SM-6: an 8 s cap on a background wake delays the reading alert by at most that, inside HealthKit's budget; the observer acknowledges only after the refresh (`HealthKitService.swift:404-412`).
- Scope: no change to trial or onboarding flow, prices, offers, membership rule (still any active entitlement, `StoreService.swift:501`), or when a paywall shows. No backend, App Store Connect or RevenueCat change. No stored data format change. Held items untouched.
- Screens: the changed views (Settings toggles and alert, Estimate Freshness card, paywall footer) could not be seen. Headless `gh-sim launch` screenshots come back blank for this app (run 42348257357), as `.claude/rules/screenshots.md` already records. Even with a working capture, the paywall footer never renders on a simulator (RevenueCat is unconfigured, so `packages` is empty and `PaywallView` shows its empty state), and a denied notification permission cannot be set without tapping a system prompt. A device or XCUITest-attachment run is needed for those states. This does not fail the check.
