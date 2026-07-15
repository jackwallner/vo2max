#!/usr/bin/env python3
"""Inspect non-secret RevenueCat project configuration using RC_KEY."""
from __future__ import annotations

import json
import os
import urllib.request

API = "https://api.revenuecat.com/v2"


def get(path: str) -> dict:
    request = urllib.request.Request(
        API + path,
        headers={"Authorization": f"Bearer {os.environ['RC_KEY']}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


def main() -> None:
    projects = get("/projects").get("items", [])
    print("projects", [(item["id"], item.get("name")) for item in projects])
    for project in projects:
        project_id = project["id"]
        apps = get(f"/projects/{project_id}/apps?limit=100").get("items", [])
        print("apps", [(item["id"], item.get("name"), item.get("type"), item.get("app_store", {}).get("bundle_id")) for item in apps])
        for app in apps:
            keys = get(f"/projects/{project_id}/apps/{app['id']}/public_api_keys").get("items", [])
            print("public keys", app["id"], [item.get("key") for item in keys])
        for resource in ("products", "entitlements", "offerings"):
            items = get(f"/projects/{project_id}/{resource}?limit=100").get("items", [])
            print(resource, json.dumps(items, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
