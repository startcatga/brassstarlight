"""Paints Brass & Starlight's in-game art: four chapter skies, the
observatory hub scene and the parchment texture.

Run: python tool/make_art.py  -> writes assets/art/*.jpg
Only the project palette is used (see docs/DESIGN_LANGUAGE.md).
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

W, H = 1080, 1920
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'art')

NIGHT_INK = (10, 13, 36)
NIGHT_BLUE = (20, 26, 58)
HORIZON = (42, 46, 85)
STARLIGHT = (244, 239, 228)
TRACE_BLUE = (169, 196, 240)
BRASS = (226, 184, 76)
BRASS_DEEP = (156, 122, 34)
PARCHMENT = (239, 229, 207)
INK = (42, 33, 23)


def lerp(a, b, t):
    return a + (b - a) * t


def fractal_noise(w, h, seed, octaves=6, base=4):
    rng = np.random.default_rng(seed)
    out = np.zeros((h, w), np.float32)
    amp, total = 1.0, 0.0
    for o in range(octaves):
        n = base * 2 ** o
        small = rng.random((n * h // w + 2, n + 2)).astype(np.float32)
        img = Image.fromarray((small * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
        out += amp * (np.asarray(img, np.float32) / 255.0)
        total += amp
        amp *= 0.55
    return out / total


def sky_gradient(top, mid, bottom, mid_at=0.55):
    y = np.linspace(0, 1, H, dtype=np.float32)[:, None]
    img = np.zeros((H, W, 3), np.float32)
    for c in range(3):
        upper = lerp(top[c], mid[c], np.clip(y / mid_at, 0, 1))
        lower = lerp(mid[c], bottom[c], np.clip((y - mid_at) / (1 - mid_at), 0, 1))
        img[..., c] = np.where(y < mid_at, upper, lower).repeat(W, 1)
    return img


def add_glow(img, cx, cy, radius, colour, strength):
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / radius
    a = np.exp(-d * d) * strength
    for c in range(3):
        img[..., c] = img[..., c] * (1 - a) + colour[c] * a


def add_band(img, seed, angle, width, colour, strength):
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    nx, ny = math.cos(angle), math.sin(angle)
    d = ((xx - W / 2) * -ny + (yy - H * 0.45) * nx) / width
    n = fractal_noise(W, H, seed)
    a = np.exp(-d * d) * (0.35 + 0.9 * n ** 2) * strength
    for c in range(3):
        img[..., c] = img[..., c] * (1 - a) + colour[c] * a


def add_starfield(img, seed, count, max_y=1.0, dim=1.0):
    rng = np.random.default_rng(seed)
    pil = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
    layer = Image.new('RGB', (W, H), (0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(count):
        x, y = rng.random() * W, rng.random() * H * max_y
        b = rng.random() ** 3
        r = 0.6 + b * 1.6
        tint = TRACE_BLUE if rng.random() < 0.3 else STARLIGHT
        v = (0.25 + 0.55 * b) * dim
        col = tuple(int(t * v) for t in tint)
        d.ellipse([x - r, y - r, x + r, y + r], fill=col)
    halo = layer.filter(ImageFilter.GaussianBlur(3))
    base = np.asarray(pil, np.float32)
    base += np.asarray(layer, np.float32) + 0.6 * np.asarray(halo, np.float32)
    return base


def add_trails(img, centre, count, seed):
    """Long-exposure arcs around the pole, for 'Turning Skies'."""
    rng = np.random.default_rng(seed)
    pil = Image.new('RGB', (W, H), (0, 0, 0))
    d = ImageDraw.Draw(pil)
    cx, cy = centre
    for _ in range(count):
        r = rng.random() ** 0.7 * 1900 + 20
        start = rng.random() * 360
        span = 8 + rng.random() * 26
        b = 0.08 + rng.random() ** 2 * 0.32
        tint = TRACE_BLUE if rng.random() < 0.5 else STARLIGHT
        col = tuple(int(t * b) for t in tint)
        d.arc([cx - r, cy - r, cx + r, cy + r], start, start + span, fill=col, width=2)
    blur = pil.filter(ImageFilter.GaussianBlur(1.2))
    return img + np.asarray(blur, np.float32)


def add_veil(img, seed):
    """Slow pale ribbons of light across the upper sky (chapter IV)."""
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    n = fractal_noise(W, H, seed, octaves=4, base=2)
    wave = H * 0.28 + np.sin(xx / W * math.pi * 1.6 + 0.6) * H * 0.07 + (n - 0.5) * 260
    d = (yy - wave) / 150
    curtain = np.exp(-np.clip(d, 0, None) ** 2) * np.exp(-np.clip(-d, 0, None) * 0.35)
    a = np.clip(curtain * (0.25 + n) * 0.28, 0, 0.4) * (yy < wave + 400)
    for c in range(3):
        img[..., c] = img[..., c] * (1 - a) + TRACE_BLUE[c] * a


def grain(img, seed, amount=4.0):
    rng = np.random.default_rng(seed)
    return img + rng.normal(0, amount, img.shape).astype(np.float32)


def save(img, name, quality=90):
    os.makedirs(OUT, exist_ok=True)
    Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).save(
        os.path.join(OUT, name), quality=quality, optimize=True, progressive=True)
    print('wrote', name)


def chapter_skies():
    # I · First Light — dusk still glowing low on the horizon.
    s = sky_gradient(NIGHT_INK, NIGHT_BLUE, HORIZON, 0.6)
    add_glow(s, W * 0.65, H * 1.05, 900, BRASS_DEEP, 0.35)
    s = add_starfield(s, 11, 900, dim=0.8)
    save(grain(s, 1), 'sky_1.jpg')

    # II · Wandering Stars — the river of the galaxy across the sky.
    s = sky_gradient(NIGHT_INK, NIGHT_BLUE, HORIZON, 0.7)
    add_band(s, 22, math.radians(62), 260, (120, 128, 170), 0.55)
    add_band(s, 23, math.radians(62), 110, STARLIGHT, 0.10)
    s = add_starfield(s, 21, 1600)
    save(grain(s, 2), 'sky_2.jpg')

    # III · Turning Skies — star trails around the pole.
    s = sky_gradient(NIGHT_INK, NIGHT_INK, NIGHT_BLUE, 0.5)
    s = add_trails(s, (W * 0.72, H * 0.12), 900, 31)
    add_glow(s, W * 0.72, H * 0.12, 160, TRACE_BLUE, 0.10)
    s = add_starfield(s, 32, 500, dim=0.6)
    save(grain(s, 3), 'sky_3.jpg')

    # IV · The Unbroken Line — a pale veil hanging over a deep sky.
    s = sky_gradient(NIGHT_INK, NIGHT_BLUE, NIGHT_INK, 0.45)
    add_veil(s, 41)
    s = add_starfield(s, 42, 1200)
    save(grain(s, 4), 'sky_4.jpg')


def rooftop(draw, s, town_seed):
    """Observatory roof silhouette on a 2x canvas (draw scale s)."""
    rng = np.random.default_rng(town_seed)
    sil = NIGHT_INK
    far = (24, 28, 58)
    base_y = H * 0.70 * s
    # Distant town roofline with a few lit windows.
    x = 0
    while x < W * s:
        w = rng.integers(60, 160) * s
        h = rng.integers(40, 150) * s
        top = base_y - h + 120 * s
        draw.rectangle([x, top, x + w, H * s], fill=far)
        if rng.random() < 0.5:
            draw.polygon([(x, top), (x + w / 2, top - rng.integers(30, 70) * s), (x + w, top)], fill=far)
        for _ in range(rng.integers(0, 3)):
            wx = x + rng.random() * (w - 14 * s)
            wy = top + 20 * s + rng.random() * (h * 0.5)
            col = BRASS if rng.random() < 0.6 else BRASS_DEEP
            draw.rectangle([wx, wy, wx + 9 * s, wy + 12 * s], fill=col)
        x += w + rng.integers(0, 30) * s
    # Main roof: a sloped parapet across the bottom.
    roof_top = H * 0.78 * s
    draw.polygon([(0, roof_top + 30 * s), (W * s, roof_top - 10 * s), (W * s, H * s), (0, H * s)], fill=sil)
    draw.line([(0, roof_top + 30 * s), (W * s, roof_top - 10 * s)], fill=BRASS_DEEP, width=int(3 * s))
    # Observatory dome on the right with an open slit.
    cx, cy, r = W * 0.74 * s, roof_top - 4 * s, 190 * s
    draw.rectangle([cx - r, cy - 30 * s, cx + r, cy + 160 * s], fill=sil)
    draw.pieslice([cx - r, cy - r, cx + r, cy + r], 180, 360, fill=sil)
    draw.polygon([(cx - 26 * s, cy - r + 4 * s), (cx + 26 * s, cy - r + 4 * s),
                  (cx + 30 * s, cy - 20 * s), (cx - 30 * s, cy - 20 * s)], fill=(30, 36, 72))
    for k in range(1, 4):
        a = math.pi + k * math.pi / 4
        draw.line([(cx + math.cos(a) * r * 0.25, cy + math.sin(a) * r * 0.25),
                   (cx + math.cos(a) * r, cy + math.sin(a) * r)], fill=(22, 26, 52), width=int(3 * s))
    draw.arc([cx - r, cy - r, cx + r, cy + r], 180, 360, fill=BRASS_DEEP, width=int(3 * s))
    # Telescope poking out of the slit.
    draw.line([(cx, cy - 40 * s), (cx + 70 * s, cy - r - 70 * s)], fill=sil, width=int(34 * s))
    # Warm lit door.
    draw.rectangle([cx - 26 * s, cy + 60 * s, cx + 26 * s, cy + 160 * s], fill=(60, 48, 30))
    draw.rectangle([cx - 18 * s, cy + 70 * s, cx + 18 * s, cy + 160 * s], fill=BRASS_DEEP)
    # Small brass telescope on a tripod on the left.
    tx, ty = W * 0.16 * s, roof_top + 18 * s
    draw.line([(tx, ty - 120 * s), (tx - 60 * s, ty + 10 * s)], fill=sil, width=int(8 * s))
    draw.line([(tx, ty - 120 * s), (tx + 60 * s, ty + 10 * s)], fill=sil, width=int(8 * s))
    draw.line([(tx, ty - 120 * s), (tx + 4 * s, ty + 14 * s)], fill=sil, width=int(8 * s))
    draw.line([(tx - 70 * s, ty - 90 * s), (tx + 120 * s, ty - 200 * s)], fill=sil, width=int(26 * s))
    draw.line([(tx - 70 * s, ty - 90 * s), (tx + 120 * s, ty - 200 * s)], fill=BRASS_DEEP, width=int(4 * s))
    # Chimney pots.
    for px in (0.42, 0.47):
        x0 = W * px * s
        yb = roof_top + 30 * s - (W * px * s) * (40 / W)
        draw.rectangle([x0, yb - 90 * s, x0 + 36 * s, yb + 10 * s], fill=sil)


def hub():
    s = sky_gradient(NIGHT_INK, NIGHT_BLUE, HORIZON, 0.62)
    add_band(s, 52, math.radians(70), 230, (110, 118, 160), 0.45)
    add_glow(s, W * 0.3, H * 0.74, 700, BRASS_DEEP, 0.18)
    s = add_starfield(s, 51, 1500, max_y=0.8)
    scale = 2
    sky = Image.fromarray(np.clip(grain(s, 5), 0, 255).astype(np.uint8)).resize((W * scale, H * scale))
    d = ImageDraw.Draw(sky)
    rooftop(d, scale, 53)
    out = sky.resize((W, H), Image.LANCZOS)
    os.makedirs(OUT, exist_ok=True)
    out.save(os.path.join(OUT, 'hub.jpg'), quality=90, optimize=True, progressive=True)
    print('wrote hub.jpg')


def paper():
    n = fractal_noise(W, H, 61, octaves=7, base=3)
    fibres = fractal_noise(W, H, 62, octaves=3, base=60)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    edge = np.clip(np.sqrt(((xx - W / 2) / (W * 0.62)) ** 2 + ((yy - H / 2) / (H * 0.62)) ** 2), 0, 1)
    img = np.zeros((H, W, 3), np.float32)
    shade = 1.0 - 0.04 * (n - 0.5) * 2 - 0.10 * edge ** 3 - 0.03 * (fibres - 0.5)
    for c in range(3):
        img[..., c] = PARCHMENT[c] * shade + (INK[c] - PARCHMENT[c]) * 0.0
    save(grain(img, 6, 2.5), 'paper.jpg', quality=88)


if __name__ == '__main__':
    chapter_skies()
    hub()
    paper()
