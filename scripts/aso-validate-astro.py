#!/usr/bin/env python3
"""Validate localized App Store keyword candidates with Astro MCP.

Adds candidate queries to the temporary VO2 Max app in Astro and records the
popularity/difficulty evidence returned by each storefront. Popularity <= 5 is
classified as effectively zero unless the query is the exact product category
anchor (VO2 max).
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).parent))
from astro_mcp import DEFAULT_MCP_URL, call, ping  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
META = ROOT / "fastlane" / "metadata"
CONFIG = Path(__file__).parent / ".astro-app.json"
OUT = Path(__file__).parent / "aso-astro-evidence.json"

LOCALE_TO_STORE = {
    "ar-SA": "sa", "ca": "es", "cs": "cz", "da": "dk", "de-DE": "de",
    "el": "gr", "en-AU": "au", "en-CA": "ca", "en-GB": "gb", "en-US": "us",
    "es-ES": "es", "es-MX": "mx", "fi": "fi", "fr-CA": "ca", "fr-FR": "fr",
    "he": "il", "hi": "in", "hr": "hr", "hu": "hu", "id": "id", "it": "it",
    "ja": "jp", "ko": "kr", "ms": "my", "nl-NL": "nl", "no": "no", "pl": "pl",
    "pt-BR": "br", "pt-PT": "pt", "ro": "ro", "ru": "ru", "sk": "sk", "sv": "se",
    "th": "th", "tr": "tr", "uk": "ua", "vi": "vn", "zh-Hans": "cn", "zh-Hant": "tw",
    "bn-BD": "in", "gu-IN": "in", "kn-IN": "in", "ml-IN": "in", "mr-IN": "in",
    "or-IN": "in", "pa-IN": "in", "sl-SI": "hr", "ta-IN": "in", "te-IN": "in",
    "ur-PK": "in",
}

UNIVERSAL = [
    "vo2 max", "fitness age", "cardio tracker", "healthkit", "apple health",
    "fitness tracker", "workout tracker", "running tracker", "athlete tracker",
]


def read(locale: str, field: str) -> str:
    path = META / locale / f"{field}.txt"
    return path.read_text(encoding="utf-8").strip() if path.exists() else ""


def candidates(locale: str) -> list[str]:
    values: list[str] = []
    values.extend(
        token.strip()
        for token in read(locale, "keywords").replace("，", ",").replace("、", ",").split(",")
    )
    for field in ("name", "subtitle"):
        text = read(locale, field)
        if text:
            values.append(text)
            words = re.findall(r"[\w']+", text.lower(), flags=re.UNICODE)
            values.extend(" ".join(words[index:index + 2]) for index in range(len(words) - 1))
    values.extend(UNIVERSAL)
    seen: set[str] = set()
    result: list[str] = []
    for value in values:
        normalized = value.strip().lower()
        if not normalized or normalized in seen or len(normalized) > 60:
            continue
        seen.add(normalized)
        result.append(normalized)
    return result[:100]


def parse_result(response: Any) -> list[dict[str, Any]]:
    if not isinstance(response, dict):
        return []
    return [item for item in response.get("results", []) if isinstance(item, dict)]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--store", help="Only validate one Astro store code")
    args = parser.parse_args()

    if not ping(DEFAULT_MCP_URL):
        raise SystemExit("error: Astro MCP not reachable")
    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    app_id = str(config["appId"])

    store_locales: dict[str, list[str]] = {}
    for locale, store in LOCALE_TO_STORE.items():
        if (META / locale).is_dir():
            store_locales.setdefault(store, []).append(locale)

    evidence: dict[str, Any] = {
        "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "appId": app_id,
        "rule": "popularity <= 5 is effectively zero except exact VO2 max category anchors",
        "stores": {},
    }

    for index, (store, locales) in enumerate(sorted(store_locales.items())):
        if args.store and store != args.store:
            continue
        queries: list[str] = []
        for locale in locales:
            queries.extend(candidates(locale))
        queries = list(dict.fromkeys(queries))[:100]
        print(f"[{index + 1}/{len(store_locales)}] {store}: {len(queries)} candidates", flush=True)
        response = call(
            DEFAULT_MCP_URL,
            "add_keywords",
            {"appId": app_id, "store": store, "keywords": queries},
            req_id=1000 + index,
            timeout=600,
        )
        rows = parse_result(response)
        if not rows:
            tracked = call(
                DEFAULT_MCP_URL,
                "get_app_keywords",
                {"appId": app_id, "store": store},
                req_id=2000 + index,
                timeout=120,
            )
            tracked_by_name = {
                str(item.get("keyword", "")).lower(): item
                for item in tracked
                if isinstance(item, dict)
            }
            rows = [tracked_by_name[q] for q in queries if q in tracked_by_name]
        evidence["stores"][store] = {
            "locales": locales,
            "candidates": sorted(
                rows,
                key=lambda item: (
                    -(item.get("popularity") or 0),
                    item.get("difficulty") or 100,
                    item.get("keyword") or "",
                ),
            ),
            "useful": [
                item for item in rows
                if (item.get("popularity") or 0) > 5
                or str(item.get("keyword", "")).lower() in {"vo2 max", "vo2max"}
            ],
        }
        OUT.write_text(json.dumps(evidence, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        time.sleep(1.0)

    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
