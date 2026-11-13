#!/usr/bin/env python3
"""Compose 13-inch iPad App Store frames (2064x2752) from iPad raw captures.

Raws live at raw/<store-locale>/ipad/<scene>.png (2064x2752 UI test attachments).
Output goes to ipad/<store-locale>/<NN>_<slug>.png. Same headers, gradient and
navy type as the phone set; the device is a plain dark bezel.
"""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw

KIT = Path(__file__).resolve().parent.parent
W, H = 2064, 2752
TOP, BOTTOM = (238, 244, 255), (204, 217, 244)
NAVY = [28, 45, 74]
BEZEL, DEVICE_W, DEVICE_Y = 38, 1700, 440
FRAMES = [
    ("trends", "01-see-cardio-fitness-moving"),
    ("today", "02-make-the-daily-number-easier-to-read"),
    ("readings", "03-read-your-score-history"),
    ("trend", "04-see-the-change-by-time-window"),
    ("plus", "06-review-your-supporting-signals"),
]
EN = {
    "01-see-cardio-fitness-moving": "See how your cardio\nfitness is moving",
    "02-make-the-daily-number-easier-to-read": "Read your daily\nnumber",
    "03-read-your-score-history": "Read your score\nhistory",
    "04-see-the-change-by-time-window": "See the change by\ntime window",
    "06-review-your-supporting-signals": "Review your\nsupporting signals",
}


def headers(locale: str) -> dict[str, str]:
    if locale == "en-US":
        return EN
    return json.loads((KIT / "copy/headers.json").read_text(encoding="utf-8"))[locale]


def background() -> Image.Image:
    img = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(img)
    for y in range(H):
        t = y / (H - 1)
        draw.line([(0, y), (W, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(TOP, BOTTOM)))
    return img


def header(text: str, locale: str, out: Path) -> Image.Image:
    job = [{"text": text, "locale": locale, "font": "AvenirNext-Medium", "color": NAVY,
            "box": [1900, 330], "maxSize": 200, "minSize": 100, "align": "center", "out": str(out)}]
    res = subprocess.run([str(KIT / "tools/headline")], input=json.dumps(job), text=True, capture_output=True, check=True)
    info = json.loads(res.stdout)[0]
    if not info.get("fits", True):
        raise SystemExit(f"header does not fit: {locale} {text!r} {info}")
    return Image.open(out).convert("RGBA")


def device(raw: Image.Image) -> Image.Image:
    inner_w = DEVICE_W - 2 * BEZEL
    inner_h = round(raw.height * inner_w / raw.width)
    screen = raw.convert("RGB").resize((inner_w, inner_h), Image.Resampling.LANCZOS)
    dev_h = inner_h + 2 * BEZEL
    scale = 4
    body = Image.new("RGBA", (DEVICE_W * scale, dev_h * scale), (0, 0, 0, 0))
    ImageDraw.Draw(body).rounded_rectangle([0, 0, DEVICE_W * scale - 1, dev_h * scale - 1], 120 * scale, fill=(14, 14, 16, 255))
    body = body.resize((DEVICE_W, dev_h), Image.Resampling.LANCZOS)
    mask = Image.new("L", (inner_w * scale, inner_h * scale), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, inner_w * scale - 1, inner_h * scale - 1], 84 * scale, fill=255)
    mask = mask.resize((inner_w, inner_h), Image.Resampling.LANCZOS)
    body.paste(screen, (BEZEL, BEZEL), mask)
    return body


def compose(locale: str) -> None:
    copy = headers(locale)
    out_dir = KIT / "ipad" / locale
    out_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for scene, slug in FRAMES:
            raw = Image.open(KIT / "raw" / locale / "ipad" / f"{scene}.png")
            if raw.size != (W, H):
                raise SystemExit(f"{locale}/{scene}: raw is {raw.size}, expected {(W, H)}")
            canvas = background().convert("RGBA")
            head = header(copy[f"{slug}.png"] if f"{slug}.png" in copy else copy[slug], locale, Path(tmp) / "h.png")
            canvas.alpha_composite(head, ((W - head.width) // 2, 70 + (330 - head.height) // 2))
            dev = device(raw)
            canvas.alpha_composite(dev, ((W - dev.width) // 2, DEVICE_Y))
            canvas.convert("RGB").save(out_dir / f"{slug.split('-', 1)[0]}_{slug.split('-', 1)[1]}.png")
    print("composed", locale)


if __name__ == "__main__":
    for loc in sys.argv[1:] or [p.name for p in sorted((KIT / "raw").iterdir()) if (p / "ipad").is_dir()]:
        compose(loc)
