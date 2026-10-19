---
paths:
  - "android/**"
---

# VO2 Max Android

Native Compose port, package and namespace `com.jackwallner.vo2max`. Android 9+,
compile/target API 36, version 1.1.4, versionCode 1. The iOS app remains the spec.

## Data and paid boundary

- Read-only Health Connect VO2 max, optional resting heart rate and exercise.
  Separate per-type permissions, paginated reads, history and background feature
  checks. Cache stays on device and is cleared when core access is revoked.
- A compatible source must write VO2 max. Android does not use Apple Watch rules
  to promise that a particular workout will create an estimate. Exercise source
  records do not always distinguish indoor sessions; the UI says so.
- Health Connect has no direct one-minute heart rate recovery record. The
  recovery screen explains that gap without a purchase and never fabricates or
  substitutes a value.
- Latest estimate, basic trend, fitness age and reading history are free.
  Supporting signals, custom ranges, deep comparisons, target outlook, age
  reference, personal best, recap, alerts and exports require VO2+.
- Wear OS and Glance widgets are deferred, as allowed by the fleet port brief.
- Notifications are opt-in, require active entitlement and background/read
  grants. WorkManager runs periodically, so delivery is not instant.
- Separate Settings Rate and Send Feedback rows. Passive review uses the second
  launch, a positive moment, a clear Today screen and 30-day cooldown.

## Billing and signing

RevenueCat project `9ca6f38c`, Play app `app3053bf5077`, entitlement lookup key
`V02 Max Pro`. Like iOS, any active entitlement grants the single premium tier.
Default offering preserves the existing iOS and Test Store mappings and adds:

- `$rc_monthly`: `com.jackwallner.vo2max.monthly:monthly`
- `$rc_annual`: `com.jackwallner.vo2max.yearly:yearly`
- `$rc_lifetime`: `com.jackwallner.vo2max.pro.lifetime`

SDK keys live only in ignored `android/local.properties`. Debug uses Test Store.
Release requires a `goog_` key and external upload signing. QA uses release R8
and no SDK key or debug launch hooks. Upload keystore:
`~/.android/keystores/vo2max-upload.p12`, local credentials:
`~/.vo2max_credentials`. Never copy production keys or signing assets to Pro.

Android cleanup is registered in `~/.rc-clean/apps.json` on Air and Pro, with
platform filters separating the shared iOS/Android RevenueCat project.

## Build and parity

Non-release Gradle runs on jmbp through `fm-gradle` (copies outputs, reports
and test results back). Only the signed release tasks run on the Air, with
`./gradlew` and its local JDK 17, because the upload keystore stays there.

```sh
python3 scripts/sync-android-parity.py
cd android
fm-gradle testDebugUnitTest assembleDebug assembleQa
./gradlew assembleRelease bundleRelease --no-daemon
```

The 157-case JVM suite ports all 87 named iOS tests, adds ten Android cases,
and compares 60 synthetic scenarios
exported from unchanged Swift analysis. The exporter does not need an iOS runtime.
Re-run `xcodegen generate` if adding or removing Swift files.

## Pro runtime isolation

Only emulator host: `jackwallner@192.168.4.25`. SDK:
`/Users/jackwallner/Library/Android/sdk`. Temporary AVD for this run:
`sol-vo2max`, serial `emulator-5580`, API 36 Play x86_64 image, 720 x 1600 at 320 dpi, 3 GB RAM. Sync Android
sources to `~/tmp/sol-vo2max/android`, excluding build, .gradle, local.properties
and signing assets. Remote local.properties contains SDK path and Test Store key.

```sh
ssh jackwallner@192.168.4.25 '~/Library/Android/sdk/platform-tools/adb -s emulator-5580 shell getprop sys.boot_completed'
ssh jackwallner@192.168.4.25 'export JAVA_HOME="$HOME/.jdk/jdk-21.0.12.1+1/Contents/Home"; export PATH="$JAVA_HOME/bin:$PATH"; export ANDROID_SERIAL=emulator-5580; cd ~/tmp/sol-vo2max/android; ./gradlew testDebugUnitTest connectedDebugAndroidTest --no-daemon --max-workers=1 -Dorg.gradle.jvmargs=-Xmx1536m'
```

For a new run, create this temporary AVD only when the name and port are free.
Launch headless with `-avd sol-vo2max -port 5580 -memory 3072 -cores 2 -no-window
-no-audio -no-boot-anim -no-metrics -no-snapshot -gpu swiftshader -feature -Vulkan`. Never reset another AVD.
At completion stop only `adb -s emulator-5580 emu kill`, confirm its absence,
then delete only the temporary `sol-vo2max` AVD and `~/tmp/sol-vo2max`.

## Verification and Play state

2026-10-18: 157 JVM tests and all 15 connected cases pass on the isolated Pro
AVD. The suite covers onboarding without purchase, free/paid navigation, date
ranges, appearance, reports and an actual empty Health Connect read. An external
permission revoke followed by process restart clears the on-device cache. The
harness rejects zero-test Gradle successes.

Optimized QA also completed free onboarding and ignored all debug unlock/seed/
skip extras. Final light/dark captures, loaded Test Store plans and the rendered
one-page PDF were reviewed. Proof is local and ignored under
`android/verification/final/`. Test Store prices are fixtures, not Play prices.
No production billing purchase or install-from-Play claim has been made.

`play-assets/` has listing copy, icon, feature graphic and real Pro free-screen
captures. `scripts/play-products.py` prints an offline plan by default, with the
proposed $4.79 / $23.99 / $47.99 US ladder, seven-day new-subscriber trials and
fleet PPP adjustments. The plan was checked without making any Play requests.

Play Console app creation, products, credentials, uploads, listings, app-content
forms and submissions are deferred.

Health Connect integration reference:
https://developer.android.com/health-and-fitness/health-connect/get-started

Data type reference: https://developer.android.com/health-and-fitness/health-connect/data-types

## Verified build

Final source build succeeded on 2026-10-18: version 1.1.4, versionCode 1,
targetSdk 36. APK and AAB signatures verified, 16 KB ZIP alignment and all four
native ELF libraries verified. Release contains no Test Store key or debug
launch hooks, no health-write permissions and no advertising ID permission.

- `android/app/build/outputs/apk/release/app-release.apk`
  SHA-256: `7f8e3f900b6727b9ac4b9de5aa723b7d58386904a04a33c93e579562d7e99534`
- `android/app/build/outputs/bundle/release/app-release.aab`
  SHA-256: `f5c50ad33232c0e36ce069fdfaed4e75d5e2d969f26219b2916eb08275d3950f`

The isolated `sol-vo2max` AVD and `~/tmp/sol-vo2max` source directory were removed
after verification. The target serial and emulator process were confirmed gone.
Recreate only an owned temporary AVD before rerunning the Pro harness.
