---
paths:
  - "android/**"
---

# VO2 Max Android

Native Compose phone port, package `com.jackwallner.vo2max`, Android9+,
compile/target36, version1.1.4, versionCode2. The iOS app remains the spec.

## Data and paid boundary

Read-only Health Connect VO2 max, optional resting heart rate and exercise.
Permissions are separate per type; reads paginate, and history/background
features are checked. Health values and caches stay on device. Revoking core
access clears the cache. A compatible source must write VO2 max; the app never
promises that a particular wearable or workout will create an estimate.

Health Connect has no direct one-minute heart rate recovery record. The screen
explains that gap without a purchase. It never invents or substitutes a value.
Latest estimate, basic trend, fitness age and reading history are free.
Supporting signals, custom ranges, deep comparisons, targets, age reference,
personal best, recap, alerts and exports require VO2+. Wear OS and widgets are
deferred. Notifications are opt-in, require entitlement and relevant grants,
and run periodically through WorkManager rather than at an exact time.

Settings has separate Rate and Send Feedback rows. Passive review waits for a
positive moment on a clear Today screen, second launch and30-day cooldown.

## Billing and reviewer access

RevenueCat project `9ca6f38c`, Play app `app3053bf5077`, entitlement lookup
`V02 Max Pro`. Any active entitlement grants the single premium tier, matching
iOS. Default offering preserves iOS/Test Store mappings and includes:

- `$rc_monthly`: `com.jackwallner.vo2max.monthly:monthly`
- `$rc_annual`: `com.jackwallner.vo2max.yearly:yearly`
- `$rc_lifetime`: `com.jackwallner.vo2max.pro.lifetime`

Keys live only in ignored `android/local.properties`. Debug uses Test Store;
release requires a Play `goog_` key and external signing. Optimized QA uses
release source/R8, debug signing, no SDK key and no debug launch hooks.
Upload key is `~/.android/keystores/vo2max-upload.p12`; existing credentials
are `~/.vo2max_credentials`, mode600. Never commit them or use a production key
in a directly installed emulator build. rc-clean platform filters are registered.

Reviewers long-press Settings > Version1.1.4, then enter the private
`VO2MAX_PLAY_REVIEW_CODE` from that credential file. Only its SHA-256 is supplied
as `PLAY_REVIEW_CODE_SHA256` in ignored properties. Input is masked, uses a
Password keyboard and disables autocorrect. Only the digest persists. Rotation
invalidates the grant; entitlement refresh preserves it without faking a
purchase cache. Supply the private `reviewCode` instrumentation argument only
through a local redacting harness. Never print it or capture a keyboard with it.

## Build and verification

All Android work runs on Pro. This queue builds directly on jmbp with JDK21:
`~/.jdk/jdk-21.0.12.1+1/Contents/Home`; SDK is `~/Library/Android/sdk`.
Use the checked-in wrapper, one worker and one full Gradle build at a time.
Stop the owned emulator during release/QA R8, then test after build completion.

```sh
python3 scripts/sync-android-parity.py
cd android
./gradlew --no-daemon --max-workers=1 '-Dorg.gradle.jvmargs=-Xmx3072m -XX:ActiveProcessorCount=4 -Dfile.encoding=UTF-8' testDebugUnitTest assembleDebug assembleDebugAndroidTest assembleRelease bundleRelease assembleQa lintRelease
```

The161-case JVM suite passes:87 named iOS tests,60 exported Swift scenarios,
10 Android cases and four reviewer cases. The accepted base passed15 Pro device
cases. Current vc2 device checks passed first-run/free exit/system-bar bounds in
59.345s and actual-dialog wrong/valid code, refresh and persistence in60.732s.
This is a current two-case run, not a fresh full16-case run.

Final full build and release lint pass in12m34s. Signed target36 vc2 APK/AAB
signatures, ZIP and all four native ELF16KB alignments pass. Both contain the
correct release SDK key and reviewer digest, with no Test Store key or private
code. QA has the digest and no SDK key. Optimized QA ignores unlock/seed/skip
extras, completes free onboarding, keeps the paid boundary locked, and masks
and rejects a wrong reviewer code. Final onboarding, free Today, locked paywall
and masked rejection captures were inspected. Onboarding uses safe drawing
padding so its step label and controls avoid the system bars.

Current proof is under `~/fleet-work/android-ports/verification/vo2max/`, with
`vo2max-vc2-final-build.log` and `vo2max-vc2-final-artifacts.log` at its parent.
The final device orchestrator stops only its owned AVD on completion.

Use one temporary Google Play API36 x86_64 AVD, `sol-vo2max`, serial5580,
720x1600 at320dpi,4GB/4cores. Launch headless with `-no-window -no-audio
-no-boot-anim -no-metrics -no-snapshot -gpu swiftshader -feature -Vulkan`.
Check `adb -s emulator-5580 shell getprop sys.boot_completed` before testing.
Stop only `adb -s emulator-5580 emu kill`, confirm the serial is absent, then
delete only the temporary owned AVD. Never kill the adb server or another AVD.
Google Play services/Digital Wellbeing were disabled on this disposable test
AVD to avoid system-service contention; no install-from-Play claim is made.

## Play state, 2026-10-18

Accepted vc2 is on pushed main, rebuilt from the identical tested Android tree
in34s and reverified. Play app `4974193923765162801` has internalvc2 completed
and production draftvc2, confirmed through a fresh Publisher API read. Console
confirms vc2 available to internal testers, not reviewed, at22:13PDT.
Actual internal opt-in: https://play.google.com/apps/internaltest/4701324108296678429.
Three Play products and eligible seven-day subscription trials are active at
US4.79/23.99/47.99. Existing service-account credentials, entitlement links and
three default packages are confirmed. No new permissions were granted.

Listing, icon, feature graphic, four real free-screen captures, contact,
privacy, no ads, government/ad-ID/financial declarations, full health/five
permission explanations, Health & Fitness category and178 countries are saved.
Managed publishing is off. Public privacy/deletion URL is live. Data safety is
drafted: purchase history, anonymous IDs and actual custom app interactions,
encrypted transit and support deletion. Health values stay local. Two private
transaction webhooks disable paywall forwarding; no ad integration is listed.

Sign in details is saved with full paid reviewer access; the saved code hash
was rechecked against the build. Target audience18+ is saved. Final Data safety is saved and its
preview matches actual app/SDK transfers. App content only lists Content ratings
as needing attention. IARC terms require Jack's explicit approval.
Licensed Play installation/purchase/restore needs a signed-in tester, and the
pre-launch overview has no report yet. Do not claim public availability.
Quit Zyn productionvc1(1.2.7) is still in review at22:01PDT, with managed
publishing off, so the next fleet production submission must wait.

Owned sol-vo2max5580 was stopped and its temporary AVD deleted after final
verification. Proof logs/captures are retained. Managed publishing is confirmed
off at22:13PDT. Pre-launch overview still has no report and suggests closed-track
testing. No production review was sent and public availability is not claimed.
