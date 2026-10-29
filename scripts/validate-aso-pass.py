#!/usr/bin/env python3
"""Validate App Store metadata fields changed in a focused ASO pass."""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
META = ROOT / "fastlane" / "metadata"
FIELDS = ("name", "subtitle", "keywords", "promotional_text", "description")
DEFAULT_LOCALES = tuple(sorted(
    p.name for p in META.iterdir()
    if p.is_dir() and any((p / f"{field}.txt").exists() for field in FIELDS)
))
LIMITS = {"name": 30, "subtitle": 30, "keywords": 100, "promotional_text": 170, "description": 4000}
WORD = re.compile(r"[\w']+", flags=re.UNICODE)
CJK = re.compile(r"[\u3400-\u9fff\u3040-\u30ff\uac00-\ud7af]")


def read_field(locale: str, field: str) -> tuple[str, str]:
    path = META / locale / f"{field}.txt"
    raw = path.read_text(encoding="utf-8")
    value = raw.removesuffix("\n").removesuffix("\r")
    return raw, value


def validate(locale: str) -> list[str]:
    errors: list[str] = []
    values: dict[str, str] = {}
    for field in FIELDS:
        path = META / locale / f"{field}.txt"
        if not path.exists():
            errors.append(f"{locale}: missing {field}.txt")
            continue
        raw, value = read_field(locale, field)
        values[field] = value
        if not value:
            errors.append(f"{locale}: empty {field}")
        if value != value.strip():
            errors.append(f"{locale}: leading or trailing whitespace in {field}")
        if "\u2014" in value:
            errors.append(f"{locale}: em dash in {field}")
        if len(value) > LIMITS[field]:
            errors.append(f"{locale}: {field} is {len(value)} characters, limit {LIMITS[field]}")

    keywords = values.get("keywords", "")
    raw_tokens = keywords.split(",")
    if any(not token or token != token.strip() or any(char.isspace() for char in token) for token in raw_tokens):
        errors.append(f"{locale}: keywords must be nonempty comma-separated tokens without spaces")
    tokens = [token.lower() for token in raw_tokens if token]
    if len(tokens) != len(set(tokens)):
        errors.append(f"{locale}: repeated keyword token")

    display = f"{values.get('name', '')} {values.get('subtitle', '')}".lower()
    indexed_words = {word.lower() for word in WORD.findall(display)}
    for token in tokens:
        if token in indexed_words or (CJK.search(token) and token in display):
            errors.append(f"{locale}: keyword repeats name or subtitle token {token!r}")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("locales", nargs="*", default=DEFAULT_LOCALES)
    args = parser.parse_args()

    for locale in args.locales:
        path = META / locale / "keywords.txt"
        if path.exists():
            length = len(path.read_text(encoding="utf-8").rstrip("\r\n").encode("utf-8"))
            if length > 100:
                print(f"WARNING {locale}: keywords are {length} UTF-8 bytes (over 100)")

    errors = [error for locale in args.locales for error in validate(locale)]
    if errors:
        print("ASO metadata validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print(f"ASO metadata valid: {len(args.locales)} locales; field caps, duplicate tokens, whitespace, em dashes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
