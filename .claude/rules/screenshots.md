---
paths:
  - "artifacts/asc-screenshots/**"
  - "fastlane/screenshots/**"
  - "VO2MaxUITests/ReleaseJourneysUITests.swift"
  - "VO2MaxUITests/StoreScreenshotLocales.json"
---

# Localized store sets

Run `artifacts/asc-screenshots/l10n-20261105/tools/capture.sh` from the repo root to recapture all target locales. Pass store locale IDs such as `fr-FR` to limit the run. The script uses one GH-SIM UI-test job for the selected locales and the English reference, then composes, gates, sheets, and copies the root-level phone frames.

The UI-test adapter launches the real app with `-DemoData`, `-DemoPro`, `-ScreenshotTab 0`, and `-DuoScreen <route>`. It waits for the tab bar before taking each screenshot. GH-SIM launch captures sometimes remained blank on English startup, so keep the UI-state wait in the test.

Frame 05 is an Apple Watch display and stays English. The localized phone set contains frames 01, 02, 03, 04, and 06. `-DemoPro` is local screenshot state and does not configure RevenueCat.
