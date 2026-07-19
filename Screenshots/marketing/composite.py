#!/usr/bin/env python3
"""Chroma-key a real app screenshot into a poster's flat teal phone screen.

The ChatGPT posters draw a front-facing iPhone with a flat teal (#18D5C8)
placeholder screen. We replace only the teal pixels with the corresponding
pixels of the real screenshot, so the poster's drawn Dynamic Island and rounded
corners (which are black, not teal) survive on top. Output is upscaled to the
App Store 6.9" size (1320x2868), whose aspect matches the 851x1849 posters.
"""
import sys
from PIL import Image
import numpy as np

TEAL = np.array([24, 213, 200])   # sampled placeholder color
# Wide threshold catches the anti-aliased teal/bezel blend ring too; the near-
# black bezel sits ~290 away from teal, so there is no risk of eating the frame.
THRESH = 150
OUT_W, OUT_H = 1320, 2868          # App Store 6.9" portrait

def composite(poster_path: str, shot_path: str, out_path: str) -> None:
    poster = Image.open(poster_path).convert("RGB")
    P = np.array(poster)
    dist = np.linalg.norm(P.astype(int) - TEAL, axis=2)
    mask = dist < THRESH
    if mask.sum() < 1000:
        raise SystemExit(f"no teal screen found in {poster_path}")

    # The corner background glows are also teal; keep only the largest connected
    # component, which is the phone screen.
    from scipy import ndimage
    labels, n = ndimage.label(mask)
    if n > 1:
        sizes = ndimage.sum(mask, labels, range(1, n + 1))
        mask = labels == (int(np.argmax(sizes)) + 1)

    # Grow 2px into the bezel so no teal halo survives at the screen border.
    mask = ndimage.binary_dilation(mask, iterations=2)

    ys, xs = np.where(mask)
    y0, y1, x0, x1 = ys.min(), ys.max(), xs.min(), xs.max()
    bw, bh = x1 - x0 + 1, y1 - y0 + 1

    shot = Image.open(shot_path).convert("RGB").resize((bw, bh), Image.LANCZOS)
    S = np.array(shot)

    sub_mask = mask[y0:y1 + 1, x0:x1 + 1]
    region = P[y0:y1 + 1, x0:x1 + 1]
    region[sub_mask] = S[sub_mask]
    P[y0:y1 + 1, x0:x1 + 1] = region

    out = Image.fromarray(P)
    if out.size != (OUT_W, OUT_H):
        out = out.resize((OUT_W, OUT_H), Image.LANCZOS)
    out.save(out_path)
    print(f"wrote {out_path}  screen bbox=({x0},{y0},{x1},{y1}) {bw}x{bh}")

if __name__ == "__main__":
    composite(sys.argv[1], sys.argv[2], sys.argv[3])
