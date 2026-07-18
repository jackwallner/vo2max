#!/usr/bin/env python3
"""Replace en-US iPhone 6.5" screenshots and delete the stale Watch screenshot.

One-off: the listing had wrong-app placeholder screenshots (a StatScout paywall on
iPhone, a calories/steps watch face). This uploads the real VO2Max marketing frames
to APP_IPHONE_65 and clears the wrong APP_WATCH_ULTRA image.
"""
from __future__ import annotations

import hashlib
import sys
import urllib.request
from pathlib import Path

import asc_lib as a

SCR = Path("/private/tmp/claude-501/-Users-jackwallner-health/87285979-2cac-4b41-8597-8dc40c0ceaf7/scratchpad")
IPHONE_SHOTS = ["shot-1-today.png", "shot-2-trends.png", "shot-3-vo2plus.png"]
VID = "a7ddd667-c50d-4225-acfc-838c9b3d0e7f"


def upload_bytes(op: dict, data: bytes) -> None:
    req = urllib.request.Request(op["url"], data=data, method=op["method"])
    for h in op.get("requestHeaders", []):
        req.add_header(h["name"], h["value"])
    with urllib.request.urlopen(req) as resp:
        if resp.status not in (200, 201, 204):
            raise RuntimeError(f"upload failed {resp.status}")


def add_screenshot(c: a.ASCClient, set_id: str, path: Path) -> str:
    data = path.read_bytes()
    body = {
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": path.name, "fileSize": len(data)},
            "relationships": {
                "appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}
            },
        }
    }
    res = c.post("/appScreenshots", body)["data"]
    sid = res["id"]
    for op in res["attributes"]["uploadOperations"]:
        upload_bytes(op, data[op["offset"]: op["offset"] + op["length"]])
    md5 = hashlib.md5(data).hexdigest()
    c.patch(f"/appScreenshots/{sid}", {
        "data": {"type": "appScreenshots", "id": sid,
                 "attributes": {"uploaded": True, "sourceFileChecksum": md5}}})
    print(f"  uploaded {path.name} -> {sid}")
    return sid


def main() -> None:
    kid, iid, kp = a.load_credentials()
    c = a.ASCClient(a.bearer_token(kid, iid, kp))
    enloc = next(l for l in a.list_all(c, f"/appStoreVersions/{VID}/appStoreVersionLocalizations")
                 if l["attributes"]["locale"] == "en-US")
    sets = a.list_all(c, f"/appStoreVersionLocalizations/{enloc['id']}/appScreenshotSets")

    for s in sets:
        disp = s["attributes"]["screenshotDisplayType"]
        sid = s["id"]
        existing = a.list_all(c, f"/appScreenshotSets/{sid}/appScreenshots")
        if disp == "APP_IPHONE_65":
            print(f"APP_IPHONE_65: deleting {len(existing)} old, uploading {len(IPHONE_SHOTS)} new")
            for img in existing:
                c.request("DELETE", f"/appScreenshots/{img['id']}")
            new_ids = [add_screenshot(c, sid, SCR / name) for name in IPHONE_SHOTS]
            c.patch(f"/appScreenshotSets/{sid}/relationships/appScreenshots", {
                "data": [{"type": "appScreenshots", "id": i} for i in new_ids]})
            print("  order set")
        elif disp == "APP_WATCH_ULTRA":
            print(f"APP_WATCH_ULTRA: deleting {len(existing)} stale watch screenshot(s)")
            for img in existing:
                c.request("DELETE", f"/appScreenshots/{img['id']}")


if __name__ == "__main__":
    sys.exit(main())
