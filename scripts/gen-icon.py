#!/usr/bin/env python3
"""VO2Max app icon: an ascending cardio-fitness curve rising to a peak.

Vitals design language (soft diagonal gradient, one confident white glyph,
generous negative space) but a distinct big-picture concept: aerobic capacity
climbing, not a heart. Keeps the app's blue->teal cardio gradient identity.
"""
from PIL import Image, ImageDraw, ImageFilter

S = 1024
SS = 4          # supersample
W = S * SS

BLUE = (18, 120, 240)   # Theme.cardioBlue
TEAL = (15, 196, 200)   # Theme.cardio


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def gradient(w):
    """Diagonal top-left blue -> bottom-right teal."""
    img = Image.new("RGB", (w, w))
    px = img.load()
    for y in range(w):
        for x in range(w):
            t = (x + y) / (2 * (w - 1))
            px[x, y] = lerp(BLUE, TEAL, t)
    return img


def catmull_rom(pts, samples=120):
    """Smooth curve through control points."""
    p = [pts[0]] + list(pts) + [pts[-1]]
    out = []
    for i in range(1, len(p) - 2):
        p0, p1, p2, p3 = p[i - 1], p[i], p[i + 1], p[i + 2]
        for s in range(samples):
            t = s / samples
            t2, t3 = t * t, t * t * t
            x = 0.5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * t +
                       (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2 +
                       (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * t3)
            y = 0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t +
                       (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 +
                       (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)
            out.append((x, y))
    out.append(pts[-1])
    return out


def thick_polyline(draw, curve, width, fill):
    r = width / 2
    for (x0, y0), (x1, y1) in zip(curve, curve[1:]):
        draw.line((x0, y0, x1, y1), fill=fill, width=int(width))
    for x, y in curve:
        draw.ellipse((x - r, y - r, x + r, y + r), fill=fill)


# control points in 1024 space: a confident, ease-in upward sweep
CTRL = [(214, 626), (378, 606), (536, 556), (668, 448), (792, 314)]
LINE_W = 84


def build():
    img = gradient(W).convert("RGBA")
    scale = W / S
    ctrl = [(x * scale, y * scale) for x, y in CTRL]
    curve = catmull_rom(ctrl)

    # soft drop shadow beneath the glyph for premium depth
    shadow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    off = 16 * scale
    scurve = [(x, y + off) for x, y in curve]
    thick_polyline(sdraw, scurve, LINE_W * scale, (0, 40, 70, 90))
    ex, ey = ctrl[-1]
    dot = 66 * scale
    sdraw.ellipse((ex - dot, ey - dot + off, ex + dot, ey + dot + off), fill=(0, 40, 70, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(22 * scale))
    img = Image.alpha_composite(img, shadow)
    draw = ImageDraw.Draw(img)

    # subtle halo behind the peak "reading" dot
    ring = 116 * scale
    halo = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(halo).ellipse(
        (ex - ring, ey - ring, ex + ring, ey + ring),
        outline=(255, 255, 255, 66), width=int(11 * scale))
    img = Image.alpha_composite(img, halo)
    draw = ImageDraw.Draw(img)

    # the ascending line
    thick_polyline(draw, curve, LINE_W * scale, (255, 255, 255, 255))

    # punctuating peak dot (current reading, riding high)
    draw.ellipse((ex - dot, ey - dot, ex + dot, ey + dot), fill=(255, 255, 255, 255))

    out = img.convert("RGB").resize((S, S), Image.LANCZOS)
    return out


if __name__ == "__main__":
    import sys
    build().save(sys.argv[1] if len(sys.argv) > 1 else "icon_1024.png")
    print("wrote icon")
