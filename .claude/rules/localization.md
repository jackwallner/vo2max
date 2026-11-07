---
paths:
  - "VO2Max/**"
  - "VO2MaxWidget/**"
  - "VO2MaxWatch/**"
  - "VO2MaxWatchWidget/**"
  - "Shared/**"
  - "Tools/Localization/**"
---

# VO2 Max localization

The app, widgets, Watch app, and complications share `Shared/Localizable.xcstrings`.
English is the source language; the shipped locales are de, fr, nl, zh-Hant,
ru, ar, es, ja, th, cs, it, he, hu, ro, el, pl, sk, and sv. XcodeGen 2.39 or later
reads the catalog locales into `knownRegions`. Each app and extension plist lists
the supported locales in `CFBundleLocalizations`.

`VO2Max/InfoPlist.xcstrings` and `VO2MaxWatch/InfoPlist.xcstrings` localize the
HealthKit permission purpose strings. Keep the complete read-only explanation
in both strings. `VO2MaxWidget/InfoPlist.xcstrings` and
`VO2MaxWatchWidget/InfoPlist.xcstrings` localize the extension names shown in
widget galleries. The widget targets do not request HealthKit access.

Run `python3 Tools/Localization/check.py` to check source literals, catalog
coverage, and format arguments. `LocalizationTests` verifies that each locale
compiles into an `.lproj` and that Russian, Polish, and Arabic plural forms
resolve distinctly.

SwiftUI literals localize automatically. Copy returned from a model, enum,
service, notification, or stored `String` must use `String(localized:)` with a
whole sentence. Localize stored English values at display time. Keep logs,
analytics names, HealthKit identifiers, persistence keys, and RevenueCat IDs
out of the catalog.

Use Apple's localized Health names for cardio fitness and the supporting
metrics. Preserve brand names and standard VO2 units. Format dates and numbers
with Foundation styles, durations with `DateComponentsFormatter`, and prices
only from StoreKit. Add plural variations for count strings, including the
one/few/many/other categories required by the locale.

Keep every health statement as careful as the English copy. Fitness age remains
a broad estimate; cardio fitness is motivational context, not a diagnosis or
clinical result. Keep the full disclaimer. Avoid fixed left/right arrows so
SwiftUI can mirror Arabic layouts. German copy uses informal address and
Japanese uses polite address.

## Language row

Settings has a Language row that names the running localization in itself
(`Bundle.main.preferredLocalizations`) and opens `openSettingsURLString`, Apple's
route for a per-app language change. iOS hides the app's Language option on a
device with one preferred language unless `UIPrefersShowingLanguageSettings` is
YES in `Info.plist`, so keep that key. The simulator's Settings opens at its root
for this link; check the landing on a real iPhone.

## Ranges

Never print a range with an en dash ("31–51"). Each range string in the catalog
spells the connector in the language ("31 to 51", "31 bis 51", "de 31 à 51",
"от 31 до 51"); Japanese keeps the wave dash. Keys may keep the dash, the
translated values may not. German labels the paywall privacy link "Datenschutz".
