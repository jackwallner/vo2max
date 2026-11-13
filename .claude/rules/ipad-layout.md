---
paths:
  - VO2Max/App.swift
  - VO2Max/Utilities/IPadLayout.swift
  - VO2Max/Views/**
  - VO2MaxUITests/IPadScreenshotsUITests.swift
---

# VO2 Max: iPad (2026-11-12)

- The app target is universal (`TARGETED_DEVICE_FAMILY: "1,2"`) with all four
  orientations on iPad (`UISupportedInterfaceOrientations~ipad`). Watch targets
  are untouched. HealthKit data is thinner on iPad (no Watch there), so every
  screen keeps its sparse and empty states.
- Screens keep their phone layout inside a centred readable column.
  `IPadLayout.columnWidth` (660 pt) caps tab content in `MainTabView` and
  onboarding; the paywall uses 560. `iPadReadableColumn(maxWidth:)` is a no-op
  on iPhone. Never stretch a phone layout across the full iPad width.
- iPad landscape reuses the iPhone Duo split (Today or VO2+ beside Trends, see
  `iphone-duo.md`). Portrait and Split View stay single column: `MainTabView`
  returns no split on iPad while `width <= height` (`PaneGeometry` carries the
  height for that check).
- Today's ring grows on iPad outside a pane (340 pt ring, 96 pt figure) because
  the phone caps left it small in a tall portrait window. Panes keep phone caps.
- Onboarding pages centre vertically on iPad (`defaultScrollAnchor(.center)`);
  the bottom bar stays pinned.
- Sheets (paywall, What's New, recap, range) present as iPad form sheets; do not
  set phone detents for them.
- Capture: `VO2MaxUITests/IPadScreenshotsUITests` attaches a screenshot per scene
  and orientation (launch screenshots are blank on gh-sim). Run it with
  `gh-sim test --device "iPad Pro 13-inch (M5)" --scheme VO2MaxUITests --only VO2MaxUITests/IPadScreenshotsUITests`
  and read the PNGs from `~/.gh-sim/results/<id>/attachments` (names in
  `manifest.json`). Simulators have no RevenueCat offerings, so the paywall
  frame shows the unavailable state; its column cap cannot be seen with plans.
