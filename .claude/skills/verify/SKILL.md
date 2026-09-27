---
name: verify-vo2max
description: Verify VO2Max UI changes on a leased device from the shared headless agent-sim pool.
---

# VO2Max runtime verification

Lease a device from the shared pool. Never open Simulator.app and never configure RevenueCat on simulator.

```bash
xcodegen generate
agent-sim checkout vo2max
UDID=$(agent-sim udid vo2max)
agent-sim boot vo2max
xcodebuild -project VO2Max.xcodeproj -scheme VO2Max -destination "id=$UDID" build
APP=$(find ~/Library/Developer/Xcode/DerivedData/VO2Max-*/Build/Products -maxdepth 2 -name VO2Max.app -path "*iphonesimulator*" | head -1)
xcrun simctl install "$UDID" "$APP"
```

DEBUG launch hooks:

- `-OnboardingPage 1` opens the profile page.
- `-ScreenshotTab 0|1|2` skips onboarding and opens Today, Trends, or VO2+.
- `-SeedScreenshotData` inserts representative Apple Health estimates when the local store is empty.
- `-DemoPro` enables the local subscriber override without contacting RevenueCat.

Drive with `axe describe-ui`, `axe tap --label ...`, and `axe tap --id BackButton`. Capture with `agent-sim screenshot vo2max <path>`, which prints the path it wrote (default `/tmp/agent-sim.png`). Use `xcrun simctl ui "$UDID" appearance light|dark` and `content_size ...` for appearance and Dynamic Type probes.

Run `agent-sim checkin vo2max` when the last capture is done.
