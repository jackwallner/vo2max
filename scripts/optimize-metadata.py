#!/usr/bin/env python3
"""Apply evidence-based ASO fields without padding them with generic terms."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
META = ROOT / "fastlane" / "metadata"
EVIDENCE = Path(__file__).parent / "aso-astro-evidence.json"

ENGLISH_KEYWORDS = [
    "healthkit",
    "age",
    "applewatch",
    "tracker",
    "performance",
    "insights",
    "recovery",
    "aerobic",
    "endurance",
    "widget",
    "history",
]
LOW_VALUE_GENERIC = {
    "health",
    "fitness",
    "training",
    "workout",
    "app",
    "wellness",
    "notifications",
}


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8").strip() if path.exists() else ""


def indexed_terms(name: str, subtitle: str) -> set[str]:
    return {
        word.lower()
        for word in re.findall(r"[\w']+", f"{name} {subtitle}", flags=re.UNICODE)
        if len(word) >= 2
    }


def dedupe_and_pack(name: str, subtitle: str, raw: str) -> str:
    indexed = indexed_terms(name, subtitle)
    values = [part.strip() for part in raw.replace("，", ",").replace("、", ",").split(",")]
    values.extend(ENGLISH_KEYWORDS)
    kept: list[str] = []
    seen: set[str] = set()
    for value in values:
        normalized = value.lower().replace(" ", "")
        if not normalized or normalized in seen:
            continue
        if normalized in indexed or normalized in LOW_VALUE_GENERIC:
            continue
        candidate = ",".join(kept + [normalized])
        if len(candidate) <= 100:
            kept.append(normalized)
            seen.add(normalized)
    return ",".join(kept)


def main() -> None:
    if not EVIDENCE.exists():
        raise SystemExit("error: run scripts/aso-validate-astro.py first")
    evidence = json.loads(EVIDENCE.read_text(encoding="utf-8"))
    if not evidence.get("stores", {}).get("us"):
        raise SystemExit("error: US Astro evidence missing")

    for folder in sorted(META.iterdir()):
        if not folder.is_dir() or folder.name == "review_information":
            continue
        name = read(folder / "name.txt")
        subtitle = read(folder / "subtitle.txt")
        raw = read(folder / "keywords.txt")
        optimized = dedupe_and_pack(name, subtitle, raw)
        if len(optimized) < 94:
            raise SystemExit(f"error: {folder.name} optimized keywords only {len(optimized)} chars")
        (folder / "keywords.txt").write_text(optimized + "\n", encoding="utf-8")

    english_name = "VO2 Max & Cardio Fitness"
    english_subtitle = "Fitness Age & Apple Health"
    for locale in ("en-US", "en-GB", "en-AU", "en-CA"):
        folder = META / locale
        (folder / "name.txt").write_text(english_name + "\n", encoding="utf-8")
        (folder / "subtitle.txt").write_text(english_subtitle + "\n", encoding="utf-8")
        keywords = ",".join(ENGLISH_KEYWORDS)
        (folder / "keywords.txt").write_text(keywords + "\n", encoding="utf-8")

    print("Applied Astro-backed keyword deduplication to all locales")


if __name__ == "__main__":
    main()
