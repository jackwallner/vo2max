#!/usr/bin/env python3
"""Upload a single Apple Watch screenshot to an App Store version, in place.

Direct ASC reserve -> PUT bytes -> commit flow. Touches only the watch
screenshot set for the given locale; leaves iPhone screenshots untouched.

Usage: asc-upload-watch-screenshot.py <image.png> [--version 1.0.0]
                                       [--locale en-US]
                                       [--display-type APP_WATCH_SERIES_4]
"""
from __future__ import annotations

import argparse
import hashlib
import sys
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import asc_lib  # noqa: E402

BUNDLE = "com.jackwallner.vo2max"


def put_bytes(op: dict, chunk: bytes) -> None:
    headers = {h["name"]: h["value"] for h in (op.get("requestHeaders") or [])}
    req = urllib.request.Request(op["url"], data=chunk, method=op["method"], headers=headers)
    with urllib.request.urlopen(req, timeout=120) as resp:
        resp.read()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("image")
    parser.add_argument("--version", default="1.0.0")
    parser.add_argument("--locale", default="en-US")
    parser.add_argument("--display-type", default="APP_WATCH_SERIES_4")
    args = parser.parse_args()

    img = Path(args.image)
    data = img.read_bytes()
    checksum = hashlib.md5(data).hexdigest()
    print(f"image {img.name} bytes={len(data)} md5={checksum}")

    client = asc_lib.ASCClient(asc_lib.bearer_token(*asc_lib.load_credentials()))
    app = asc_lib.find_app(client, BUNDLE)
    version = asc_lib.find_version_by_string(client, app["id"], args.version)
    if not version:
        raise SystemExit(f"error: version {args.version} not found")
    vid = version["id"]

    locs = asc_lib.list_all(client, f"/appStoreVersions/{vid}/appStoreVersionLocalizations?limit=200")
    loc = next((l for l in locs if l["attributes"].get("locale") == args.locale), None)
    if not loc:
        raise SystemExit(f"error: locale {args.locale} not found on version")
    lid = loc["id"]

    sets = asc_lib.list_all(client, f"/appStoreVersionLocalizations/{lid}/appScreenshotSets?limit=50")
    sset = next((s for s in sets if s["attributes"].get("screenshotDisplayType") == args.display_type), None)
    if sset:
        set_id = sset["id"]
        print(f"reusing screenshot set {set_id} ({args.display_type})")
        existing = asc_lib.list_all(client, f"/appScreenshotSets/{set_id}/appScreenshots?limit=50")
        if existing:
            print(f"note: set already has {len(existing)} screenshot(s); adding one more")
    else:
        set_id = client.post(
            "/appScreenshotSets",
            {
                "data": {
                    "type": "appScreenshotSets",
                    "attributes": {"screenshotDisplayType": args.display_type},
                    "relationships": {
                        "appStoreVersionLocalization": {
                            "data": {"type": "appStoreVersionLocalizations", "id": lid}
                        }
                    },
                }
            },
        )["data"]["id"]
        print(f"created screenshot set {set_id} ({args.display_type})")

    reserved = client.post(
        "/appScreenshots",
        {
            "data": {
                "type": "appScreenshots",
                "attributes": {"fileName": img.name, "fileSize": len(data)},
                "relationships": {
                    "appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}
                },
            }
        },
    )["data"]
    shot_id = reserved["id"]
    ops = reserved["attributes"].get("uploadOperations") or []
    print(f"reserved appScreenshot {shot_id} with {len(ops)} upload operation(s)")

    for op in ops:
        offset = op.get("offset", 0)
        length = op.get("length", len(data))
        put_bytes(op, data[offset:offset + length])
    print("uploaded bytes")

    committed = client.patch(
        f"/appScreenshots/{shot_id}",
        {
            "data": {
                "type": "appScreenshots",
                "id": shot_id,
                "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
            }
        },
    )["data"]
    state = (committed["attributes"].get("assetDeliveryState") or {}).get("state")
    print(f"committed. assetDeliveryState={state}")


if __name__ == "__main__":
    main()
