#!/usr/bin/env bash
# Upload an existing archive of VO2Max to TestFlight (default build/VO2Max.xcarchive)
# with the App Store Connect API key. The shared fleet script does the work; see
# ~/ios/release/testflight.sh for flags and credentials.
cd "$(dirname "$0")/.." || exit 1
exec "$HOME/ios/release/testflight.sh" --project VO2Max.xcodeproj --scheme VO2Max --upload-only "$@"
