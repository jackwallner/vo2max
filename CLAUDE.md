# VO2Max - Project Guide

Local-first Apple Health cardio fitness tracker. XcodeGen project/scheme: `VO2Max`, sim lease owner `vo2max`.

## Tech Stack

- Swift 6 / SwiftUI with strict concurrency
- HealthKit read-only access to `vo2Max`
- SwiftData local cache for widgets and complications
- RevenueCat premium tier "VO2+": monthly/yearly/lifetime; any active entitlement unlocks (permissive check, mirrors Vitals+)
- XcodeGen targets: iOS 17+, watchOS 10+

## Targets / bundle IDs

- `VO2Max` - `com.jackwallner.vo2max`
- `VO2MaxWidget` - `com.jackwallner.vo2max.widget`
- `VO2MaxWatch` - `com.jackwallner.vo2max.watch`
- `VO2MaxWatchWidget` - `com.jackwallner.vo2max.watch.widget`
- App Group: `group.com.jackwallner.vo2max`

## Architecture

HealthKitService reads Apple Health VO2 max estimates and caches them as `CardioFitnessSample` records. App views query SwiftData directly. Widgets and Watch complications read the same schema from their local App Group cache. `CardioFitnessAnalysis` contains pure trend, target, and fitness-age estimate logic.

`CardioContextService` reads the VO2+ supporting signals (resting heart rate, 1-minute heart rate recovery, cardio workouts) into memory only — they have no widget or complication consumer, so they deliberately stay out of the shared SwiftData schema. `CardioDriverAnalysis` (what moved the estimate) and `CardioFreshnessAnalysis` (is the estimate overdue against this user's own cadence) are pure and unit-tested.

## App-specific notes

- VO2 max is not a daily metric. The positive loop is entering a target range or moving from stable/declining to improving.
- Always say "Apple Health estimate" and "cardio fitness trend". Never claim diagnosis, treatment, longevity prediction, or clinical accuracy.
- Fitness age is explicitly labeled a broad estimate and shows its methodology.
- RevenueCat must use a public `appl_` SDK key. Never embed an `sk_` secret key.

---
Shared iOS conventions come from the global AGENTS.md and the `ios-dev` skill.

## Subagent delegation
Follow the global CLAUDE.md subagent rules: ask Jack for the model before spawning, spawn at most one at a time unless Jack explicitly approves more, and never allow a subagent to spawn another subagent.

