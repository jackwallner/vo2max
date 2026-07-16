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

Subscription/lifetime unlock through RevenueCat (any active entitlement unlocks):

- Deep Trends: 30/90/180-day period-over-period comparisons
- Target outlook: broad time-to-range estimate from the recent trend slope
- Typical-range context vs. broad age/sex reference values
- Personal best tracking

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

