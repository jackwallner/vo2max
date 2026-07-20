#!/usr/bin/env python3
"""Delete duplicate App Store screenshots while preserving their first occurrence."""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import asc_lib  # noqa: E402

BUNDLE = "com.jackwallner.vo2max"
VERSION = "1.0.0"
LOCALE = "en-US"


def main() -> None:
    client = asc_lib.ASCClient(asc_lib.bearer_token(*asc_lib.load_credentials()))
    app = asc_lib.find_app(client, BUNDLE)
    version = asc_lib.find_version_by_string(client, app["id"], VERSION)
    if not version:
        raise SystemExit(f"error: version {VERSION} not found")
    localizations = asc_lib.list_all(client, f"/appStoreVersions/{version['id']}/appStoreVersionLocalizations")
    localization = next(item for item in localizations if item["attributes"]["locale"] == LOCALE)

    removed = 0
    for screenshot_set in asc_lib.list_all(client, f"/appStoreVersionLocalizations/{localization['id']}/appScreenshotSets"):
        screenshots = asc_lib.list_all(client, f"/appScreenshotSets/{screenshot_set['id']}/appScreenshots")
        seen: set[str] = set()
        for screenshot in screenshots:
            name = screenshot["attributes"].get("fileName", "")
            if name in seen:
                client.delete(f"/appScreenshots/{screenshot['id']}")
                print(f"deleted duplicate {name}")
                removed += 1
            else:
                seen.add(name)
    print(f"Deleted {removed} duplicate screenshot(s)")


if __name__ == "__main__":
    main()
