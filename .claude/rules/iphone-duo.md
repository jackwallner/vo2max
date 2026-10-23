---
paths:
  - "VO2Max/App.swift"
  - "VO2Max/Utilities/UnfoldedSplit.swift"
  - "VO2Max/Utilities/DuoScreenshotTour.swift"
  - "VO2Max/Views/DashboardView.swift"
  - "VO2Max/Views/SettingsView.swift"
  - "VO2Max/Views/PlusTabView.swift"
  - "VO2Max/Views/DetailViews.swift"
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
- Today's ring (floor 140 pt, where its caption still fits) and gaps shrink
  on short screens so the signal row clears the floating tab bar; standard
  iPhones are unchanged. A pane reserves 510 pt instead of 485, because its
  measured height runs under the tab bar band, and drops the content's
  `minHeight` so the spacers can't re-centre the cards into the band.
- iOS 27.1 moves a `NavigationStack`'s back button into a vertical bar on the
  stack's trailing edge, which in a pane lands beside the fold with the title
  still leading. Pane stacks (and the Settings pane) set
  `toolbarVerticalBehavior(.disabled)` while split; folded keeps `.automatic`.
  With both panes horizontal the system drops its vertical bar: the root is
  the full 951 pt, panes 0-455.5 and 495.5-951, and the status bar runs across
  the top of the trailing pane, level with its title (top safe area about 81 pt).
- Today hides its nav bar, so split it ignores that top inset
  (`isUnfoldedPane` environment) and sets its date row level with the other
  pane's title; otherwise the empty band pushed its signal row under the pill.
- Split, the leading pane's tab-bar inset is an opaque band with a hairline
  top edge, sized from the measured bar (`UnfoldedSplit.tabBarBandHeight`:
  bar + 12 pt margin + 10 pt gap, 77 pt on the Duo). Content stops at a hard
  edge there. A gradient band was rejected (2026-10-23 review): glyph halves
  showed as a faded line beside the pill. Folded it stays a clear 92 pt.
- The band still cut long leading-pane screens mid-card (2026-10-23 review:
  VO2+'s Heart Rate Recovery row, Fitness Age's methodology card). Split, their
  cards stack in `PaneRestStack` (`UnfoldedSplit.restingTops`): the first card
  the band's edge would cut starts at that edge, so the pane rests on whole
  cards. The rest height is the scroll view's frame less its safe area
  (`onScrollVisibleHeightChange`); `ScrollGeometry` container size less its
  content insets read about 74 pt short and pushed cards that fit. To keep the main cards above the bar, VO2+ drops its active
  banner and Fitness Age tightens its gaps and moves the disclaimer under the
  methodology card. Folded both keep a plain `VStack` (one `AnyLayout`).
- Measured on the gh-sim iPhone Duo (iOS 27.1): fold division 455.5...495.5.
  With automatic toolbars the inner root was 867 pt (84 pt trailing vertical
  bar); see the horizontal-pane note above for the current 951 pt. The folded
  outer display keeps its 84 pt trailing bar (382 pt root).
- Settings is owned by `MainTabView` (`showSettings`, bound into
  `DashboardView`): a sheet when folded, the trailing pane when split. Unfolding
  with the sheet up moves it to the pane. `SettingsView(onDone:)` closes the pane.
- Still across the fold: onboarding (root view on first launch) and the paywall,
  What's New, recap and range sheets, which present as centred form sheets.
- Unattended captures: base args `-DemoData -DemoPro -ScreenshotTab 0`, then
  one gh-sim `--screen "-DuoScreen <route>"` per surface (today, plus,
  fitness-age, trends/resting, settings); it holds that route, folded and
  split (`DUOSCREEN` lines in app.log). `-DuoTour` (with `-DuoTourFirst`,
  `-DuoTourStep`, `-DuoRoutes`, `-DuoRoutesRegular`) walks them on a timer for
  recordings. Never `--url`: `simctl openurl` raises an alert on iOS 27.
