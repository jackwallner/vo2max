# VO2 Max Daily Tracker

A local-first iPhone and Apple Watch dashboard for Apple Health cardio fitness estimates.

## Features

- Latest VO2 max estimate with a configurable target range
- 30-day and 90-day trend analysis
- One-year chart history with target-range band and period stats
- Clear guidance when Apple Health has not recorded a value yet
- iPhone widgets and Apple Watch complications (with sparkline)
- Local SwiftData cache shared with widgets

## VO2+ (premium)

Subscription/lifetime unlock through RevenueCat (any active entitlement unlocks).
The four pillars:

- What Moved It: pairs each stretch between estimates with the cardio workouts
  recorded inside it, then compares rising stretches with flat ones
- Heart Signals: resting heart rate and 1-minute heart rate recovery, the
  signals that keep moving while VO2 max is quiet
- Estimate Freshness: whether an estimate is overdue against the user's own
  median cadence, what qualifies as a refresh, and an opt-in nudge when it goes
  stale (rate-limited to one every five days)
- Monthly recap, reading alerts, and the shareable PDF report

Supporting depth (unchanged): Deep Trends period comparisons, target outlook,
typical-range context, personal best.

Free users see a locked teaser card and locked Settings toggles that open a
focused paywall. Trial copy only appears when StoreKit intro eligibility is
confirmed (Apple 3.1.2).

VO2 max values are Apple Health estimates, not medical measurements. The app is for fitness awareness and does not diagnose, treat, or predict health conditions.

## Build

```sh
xcodegen generate
UDID=$(agent-sim boot vo2max)
xcodebuild -project VO2Max.xcodeproj -scheme VO2Max -destination "id=$UDID" build
xcodebuild test -project VO2Max.xcodeproj -scheme VO2Max -destination "id=$UDID"
```

For a populated simulator UI, add `-DemoData` to the scheme launch arguments.

## RevenueCat

Set `RevenueCatConfig.publicSDKKey` to the app-specific public key beginning with `appl_`. Never place a RevenueCat secret key beginning with `sk_` in the app or repository. The simulator intentionally skips RevenueCat configuration and uses the local Pro override in Settings.

