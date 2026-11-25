"""Draws Brass & Starlight's logo mark, launcher icon sources, web icons and
the Play Store feature graphic + 512 icon.

Run: python tool/make_store_art.py
  -> assets/icon/icon_foreground.png  (adaptive foreground, transparent)
  -> assets/icon/icon_full.png        (legacy/full icon, 1024)
  -> web/favicon.png, web/icons/*.png
  -> store/icon-512.png, store/feature-graphic.png   (store/ is gitignored)
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), '..')
NIGHT_INK = (10, 13, 36)
NIGHT_BLUE = (20, 26, 58)
STARLIGHT = (244, 239, 228)
BRASS = (226, 184, 76)
BRASS_DEEP = (156, 122, 34)
MIST = (138, 144, 184)

# The emblem figure: five stars in a rising, bending line (normalised -1..1).
FIGURE = [(-0.52, 0.38), (-0.22, 0.18), (0.02, 0.30), (0.26, -0.06), (0.50, -0.40)]


def emblem(size, ring=True, glow=True):
    """Transparent RGBA emblem at `size`, drawn 4x and downsampled."""
    s = size * 4
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = s / 2
    r = s * 0.40

    def p(v):
        return (c + v[0] * r * 0.92, c + v[1] * r * 0.92)

    if glow:
        g = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        gd = ImageDraw.Draw(g)
        for i, v in enumerate(FIGURE):
            x, y = p(v)
            rr = s * (0.075 if i == len(FIGURE) - 1 else 0.05)
            gd.ellipse([x - rr, y - rr, x + rr, y + rr], fill=BRASS + (150,))
        g = g.filter(ImageFilter.GaussianBlur(s * 0.03))
        img.alpha_composite(g)

    if ring:
        w = max(2, int(s * 0.012))
        d.ellipse([c - r, c - r, c + r, c + r], outline=BRASS, width=w)
        r2 = r * 0.90
        d.ellipse([c - r2, c - r2, c + r2, c + r2], outline=BRASS_DEEP, width=max(1, w // 2))
        for k in range(72):
            a = k / 72 * 2 * math.pi
            inner = r2 if k % 6 == 0 else r * 0.945
            d.line([(c + math.cos(a) * inner, c + math.sin(a) * inner),
                    (c + math.cos(a) * r, c + math.sin(a) * r)],
                   fill=BRASS if k % 6 == 0 else BRASS_DEEP, width=max(1, w // 2))
        # North pointer.
        d.polygon([(c, c - r * 1.13), (c - r * 0.06, c - r * 0.99), (c + r * 0.06, c - r * 0.99)], fill=BRASS)

    lw = max(2, int(s * 0.012))
    pts = [p(v) for v in FIGURE]
    for a, b in zip(pts, pts[1:]):
        d.line([a, b], fill=STARLIGHT, width=lw)
    for i, (x, y) in enumerate(pts):
        big = i == len(pts) - 1
        rr = s * (0.034 if big else 0.022)
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=BRASS if big else STARLIGHT)
    return img.resize((size, size), Image.LANCZOS)


def night_square(size):
    y = np.linspace(0, 1, size)[:, None]
    arr = np.zeros((size, size, 3), np.float32)
    for k in range(3):
        arr[..., k] = (NIGHT_BLUE[k] * (1 - y) + NIGHT_INK[k] * y).repeat(size, 1)
    rng = np.random.default_rng(3)
    img = Image.fromarray(arr.astype(np.uint8)).convert('RGBA')
    d = ImageDraw.Draw(img)
    for _ in range(int(size * 0.12)):
        x, yy = rng.random() * size, rng.random() * size
        rr = 0.4 + rng.random() ** 3 * size * 0.0025
        a = int(60 + rng.random() * 120)
        d.ellipse([x - rr, yy - rr, x + rr, yy + rr], fill=STARLIGHT + (a,))
    return img


def full_icon(size):
    bg = night_square(size)
    bg.alpha_composite(emblem(size))
    return bg.convert('RGB')


def main():
    icon_dir = os.path.join(ROOT, 'assets', 'icon')
    os.makedirs(icon_dir, exist_ok=True)
    # Adaptive foreground: the tool insets by 16%, so draw edge to edge.
    emblem(1024).save(os.path.join(icon_dir, 'icon_foreground.png'))
    full = full_icon(1024)
    full.save(os.path.join(icon_dir, 'icon_full.png'))

    web = os.path.join(ROOT, 'web')
    full.resize((32, 32), Image.LANCZOS).save(os.path.join(web, 'favicon.png'))
    for n in (192, 512):
        full.resize((n, n), Image.LANCZOS).save(os.path.join(web, 'icons', f'Icon-{n}.png'))
        m = night_square(n)
        inner = emblem(int(n * 0.8))
        m.alpha_composite(inner, (int(n * 0.1), int(n * 0.1)))
        m.convert('RGB').save(os.path.join(web, 'icons', f'Icon-maskable-{n}.png'))

    store = os.path.join(ROOT, 'store')
    os.makedirs(store, exist_ok=True)
    full.resize((512, 512), Image.LANCZOS).save(os.path.join(store, 'icon-512.png'))

    # Feature graphic 1024x500: the hub scene on the left, title on the right.
    hub = Image.open(os.path.join(ROOT, 'assets', 'art', 'hub.jpg')).convert('RGB')
    fg = Image.new('RGB', (1024, 500), NIGHT_INK)
    crop = hub.resize((1024, int(1024 * hub.height / hub.width)), Image.LANCZOS)
    top = int(crop.height * 0.80) - 500
    fg.paste(crop.crop((0, top, 1024, top + 500)), (0, 0))
    shade = Image.new('RGBA', (1024, 500), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    for x in range(1024):
        a = int(max(0, min(1, (x - 360) / 420)) * 190)
        sd.line([(x, 0), (x, 500)], fill=NIGHT_INK + (a,))
    fg = Image.alpha_composite(fg.convert('RGBA'), shade)
    em = emblem(210)
    fg.alpha_composite(em, (70, 18))
    d = ImageDraw.Draw(fg)
    font_dir = os.path.join(ROOT, 'assets', 'fonts')
    title = ImageFont.truetype(os.path.join(font_dir, 'Cinzel.ttf'), 64)
    try:
        title.set_variation_by_axes([600])
    except Exception:
        pass
    sub = ImageFont.truetype(os.path.join(font_dir, 'CrimsonPro-Italic.ttf'), 34)
    d.text((440, 170), 'Brass &', font=title, fill=STARLIGHT)
    d.text((440, 240), 'Starlight', font=title, fill=STARLIGHT)
    d.text((442, 330), 'Chart the night sky, one line at a time.', font=sub, fill=BRASS)
    fg.convert('RGB').save(os.path.join(store, 'feature-graphic.png'))
    print('icons, web icons, store icon and feature graphic written')


if __name__ == '__main__':
    main()
