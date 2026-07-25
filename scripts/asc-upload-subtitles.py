#!/usr/bin/env python3
"""Push fastlane subtitles (and optionally names) to the editable appInfo.

Subtitle and name live on `appInfoLocalizations`, not on the version
localizations that asc-upload-metadata.py patches, so they need their own pass.
Written for the Guideline 5.2.5 fix, where every locale's subtitle had to stop
naming an Apple product.

    python3 scripts/asc-upload-subtitles.py [--names] [--dry-run]
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import asc_lib  # noqa: E402

BUNDLE = "com.jackwallner.vo2max"
# An appInfo in any of these states still accepts edits.
EDITABLE_INFO_STATES = frozenset(
    {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED", "WAITING_FOR_REVIEW"}
)
APPLE_TERMS = ("Apple", "Watch", "iPhone", "iPad", "HealthKit", "Siri", "iOS")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--names", action="store_true", help="also push name.txt")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    client = asc_lib.ASCClient(asc_lib.bearer_token(*asc_lib.load_credentials()))
    app = asc_lib.find_app(client, BUNDLE)

    infos = client.get(f"/apps/{app['id']}/appInfos?limit=10").get("data", [])
    editable = [i for i in infos if i["attributes"].get("appStoreState") in EDITABLE_INFO_STATES]
    if not editable:
        states = [i["attributes"].get("appStoreState") for i in infos]
        raise SystemExit(f"error: no editable appInfo (states: {states})")
    info = editable[0]
    print(f"appInfo {info['id']} state={info['attributes'].get('appStoreState')}")

    locs = asc_lib.list_all(client, f"/appInfos/{info['id']}/appInfoLocalizations?limit=200")
    by_locale = {loc["attributes"]["locale"]: loc for loc in locs}

    changed = skipped = 0
    for locale in asc_lib.fastlane_locale_dirs():
        loc = by_locale.get(locale)
        if not loc:
            print(f"{locale}: not present in ASC, skipped")
            continue

        attrs: dict[str, str] = {}
        subtitle = asc_lib.read_meta(locale, "subtitle")
        if subtitle and subtitle != loc["attributes"].get("subtitle"):
            attrs["subtitle"] = subtitle
        if args.names:
            name = asc_lib.read_meta(locale, "name")
            if name and name != loc["attributes"].get("name"):
                attrs["name"] = name

        if not attrs:
            skipped += 1
            continue

        print(f"{locale}: {loc['attributes'].get('subtitle')!r} -> {attrs.get('subtitle', '(unchanged)')!r}")
        if args.dry_run:
            continue
        client.patch(
            f"/appInfoLocalizations/{loc['id']}",
            {"data": {"type": "appInfoLocalizations", "id": loc["id"], "attributes": attrs}},
        )
        changed += 1

    print(f"\npatched {changed}, already current {skipped}")

    if args.dry_run:
        return

    # Read back and prove no subtitle names an Apple product (Guideline 5.2.5).
    fresh = asc_lib.list_all(client, f"/appInfos/{info['id']}/appInfoLocalizations?limit=200")
    offenders = [
        (loc["attributes"]["locale"], term, loc["attributes"].get("subtitle"))
        for loc in fresh
        for term in APPLE_TERMS
        if term in (loc["attributes"].get("subtitle") or "")
    ]
    if offenders:
        print("\nFAIL: subtitles still naming Apple products:")
        for locale, term, text in offenders:
            print(f"  {locale}: {term!r} in {text!r}")
        raise SystemExit(1)
    print(f"verified {len(fresh)} live subtitles are clean of Apple product terms")


if __name__ == "__main__":
    main()
