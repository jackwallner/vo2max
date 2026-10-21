---
paths:
  - "VO2Max/App.swift"
  - "VO2Max/Utilities/UnfoldedSplit.swift"
  - "VO2Max/Utilities/DuoScreenshotTour.swift"
  - "VO2Max/Views/DashboardView.swift"
  - "VO2Max/Views/SettingsView.swift"
---

# VO2 Max: iPhone Duo (2026-10-21)

- Unfolded (regular width, room for two panes of at least 360 pt),
  `MainTabView` puts Today or VO2+, with the tab bar, on the leading side of the
  fold and Trends on the trailing side; the Trends tab button is hidden there.
  Fold edges come from `GeometryProxy.verticalFold()` (iOS 27.1
  `reservedRegions(.division)`), else an even split. Same shape as Vitals.
- Folding only moves frames: all three tabs stay mounted, so scroll position and
  pushed screens survive. Never swap layouts with an `if` around the tabs.
- Each pane gets `horizontalSizeClass = .compact`, so it lays out as on a phone.
  A pane frame must sit after the tab bar `safeAreaInset`, which fills its
  proposal and would centre a narrower pane across the fold.
- Never pin a pane's scroll content with `containerRelativeFrame`: as the
  trailing pane it resolved to the wrong container (466 pt in a 371.5 pt pane)
  and pushed Trends under the fold. `HistoryView` measures its scroll view.
- Today's ring shrinks on short screens (`availableHeight - 485`, floor 140) so
  the signal row clears the floating tab bar; on standard iPhones it is unchanged.
- Measured on the gh-sim iPhone Duo (iOS 27.1): inner root 867 pt wide (84 pt
  vertical bar on the trailing edge), fold division 455.5...495.5, so panes are
  0-455.5 and 495.5-867. The outer display also has an 84 pt trailing bar.
- Settings is owned by `MainTabView` (`showSettings`, bound into
  `DashboardView`): a sheet when folded, the trailing pane when split. Unfolding
  with the sheet up moves it to the pane. `SettingsView(onDone:)` closes the pane.
- Still across the fold: onboarding (root view on first launch) and the paywall,
  What's New, recap and range sheets, which present as centred form sheets.
- Unattended captures: `-DemoData -DemoPro -ScreenshotTab 0 -DuoTour` plus
  `-DuoTourFirst`, `-DuoTourStep`, `-DuoRoutes`, `-DuoRoutesRegular` (see
  `DuoScreenshotTour`). `DUOTOUR` lines in app.log map shots to routes.
  `simctl openurl` raises an alert on iOS 27, so the tour runs on a timer and
  gh-sim's `--url noop://N` only paces the screenshots.
