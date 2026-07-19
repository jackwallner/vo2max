---
name: verify-vo2max
summary: Verify VO2Max UI changes on the dedicated headless simulator.
---

# VO2Max runtime verification

Use only the dedicated `agent-vo2max` simulator. Never open Simulator.app and never configure RevenueCat on simulator.

```bash
xcodegen generate
UDID=$(agent-sim boot vo2max | tail -1)
xcodebuild -project VO2Max.xcodeproj -scheme VO2Max -destination "id=$UDID" -derivedDataPath /tmp/vo2max-verify build
APP=/tmp/vo2max-verify/Build/Products/Debug-iphonesimulator/VO2Max.app
xcrun simctl install "$UDID" "$APP"
```

DEBUG launch hooks:

- `-OnboardingPage 1` opens the profile page.
- `-ScreenshotTab 0|1|2` skips onboarding and opens Today, Trends, or VO2+.
- `-SeedScreenshotData` inserts representative Apple Health estimates when the local store is empty.
- `-DemoPro` enables the local subscriber override without contacting RevenueCat.

Drive with `axe describe-ui`, `axe tap --label ...`, and `axe tap --id BackButton`. Capture with `agent-sim screenshot vo2max`, which writes `/tmp/agent-vo2max.png`. Use `xcrun simctl ui "$UDID" appearance light|dark` and `content_size ...` for appearance and Dynamic Type probes.
