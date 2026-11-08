---
paths:
  - "artifacts/asc-screenshots/**"
  - "fastlane/screenshots/**"
  - "VO2MaxUITests/ReleaseJourneysUITests.swift"
  - "VO2MaxUITests/StoreScreenshotLocales.json"
---

# Localized store sets

Run `artifacts/asc-screenshots/l10n-20261105/tools/capture.sh` from the repo root to recapture all target locales. Pass store locale IDs such as `fr-FR` to limit the run. The script uses one GH-SIM UI test job for the selected locales and English reference, waits for the app's tab bar, then waits 14 seconds before each screenshot attachment. It composes, gates, sheets, and copies the root-level phone frames.

Screenshots come from XCUITest attachments because headless GH-SIM launch screenshots were blank for this app. The test starts the real app with `-DemoData`, `-DemoPro`, and `-ScreenshotTab 0`, then applies the locale and `-DuoScreen <route>` arguments. Keep the 14-second wait after the UI appears because shorter captures sometimes remained blank.

For a targeted repair, pass `--scenes trends,trend --reuse-job <gh-sim-id>`. The adapter seeds unchanged scenes from that run's attachments, captures only the selected routes, then still composes and gates every managed frame.

Frame 05 is an Apple Watch display and stays English. The localized phone set contains frames 01, 02, 03, 04, and 06. `-DemoPro` is local screenshot state and does not configure RevenueCat.

Second run (2026-11-08): all 15 remaining languages went through one GH-SIM job. GitHub's Mac queue can hold a job for hours when other fleet runs are waiting, and the harness may kill a long foreground wrapper. If the wrapper dies, the gh-sim process keeps running: run `capture.sh --adopt-job <gh-sim-id>` (detached with `nohup`, macOS has no `setsid`) to wait for that job's attachments and compose, gate, sheet and copy every locale. Do not share a log file name with other sessions on the same host.
