# Star Cartographer — Design Language

## Vibe

Quiet rooftop astronomy at midnight: brass instruments, ink charts, and infinite depth. The UI should feel **ceremonial but calm** — like inscribing a map by starlight. Motion is slow and orbital, never frantic. Gold marks achievement; cool blues hold the sky.

## Color Palette

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| Sky deep | **Midnight Ink** | `#0B0E2A` | Primary background, splash base |
| Sky mid | **Observatory Blue** | `#141832` | Gradient mid-tone, cards on dark |
| Sky lift | **Horizon Haze** | `#1E2548` | Bottom horizon glow |
| Star core | **Moonlit White** | `#F5F0E8` | Stars, primary text on dark |
| Line active | **Chart Blue** | `#B8C9E8` | In-progress trace lines |
| Line locked | **Brass Gold** | `#E8C547` | Completed constellation lines |
| Accent | **Telescope Brass** | `#C9A227` | Buttons, borders, score highlights |
| Parchment | **Atlas Cream** | `#F0E6D3` | Guide/privacy panels, dark-mode secondary surface |
| Text on parchment | **Ink Brown** | `#2C2416` | Body text on cream panels |
| Success | **Aurora Green** | `#6BCB9F` | Flawless badge, subtle success flash |
| Error | **Ember Coral** | `#E8847C` | Wrong stroke, decoy flash |
| Muted | **Dust Gray** | `#6B7094` | Locked items, disabled hints |
| Overlay | **Cloud Veil** | `#0B0E2A` @ 75% | Pause overlay |
| Silhouette | **Rooftop Black** | `#080A18` | Parapet, telescope silhouette |

### Gradients (code-drawn)

- **Sky dome:** linear top `#0B0E2A` → bottom `#1E2548` (default everywhere).
- **Gold button:** linear `#E8C547` → `#C9A227`.
- **Vignette:** radial transparent center → `#080A18` @ 60% at edges.

## Typography

**Font family:** [Cinzel](https://fonts.google.com/specimen/Cinzel) — inscriptional, celestial, distinctive. **Do not use Fredoka.**

### Bundling (offline)

1. Download Cinzel Regular (400) and SemiBold (600) `.ttf` files.
2. Place in `assets/fonts/Cinzel-Regular.ttf` and `assets/fonts/Cinzel-SemiBold.ttf`.
3. Declare in `pubspec.yaml`:

```yaml
fonts:
  - family: Cinzel
    fonts:
      - asset: assets/fonts/Cinzel-Regular.ttf
        weight: 400
      - asset: assets/fonts/Cinzel-SemiBold.ttf
        weight: 600
```

4. Reference: `TextStyle(fontFamily: 'Cinzel', ...)`.
5. Do **not** use runtime `GoogleFonts.cinzel()` fetching (no network).

### Type Scale

| Token | Family | Weight | Size | Letter-spacing | Use |
|-------|--------|--------|------|----------------|-----|
| `display` | Cinzel | 600 | 28sp | 2.0 | App title, myth names on seal |
| `heading` | Cinzel | 600 | 20sp | 1.2 | Screen titles, chapter names |
| `subheading` | Cinzel | 400 | 16sp | 0.8 | HUD constellation name |
| `body` | Cinzel | 400 | 14sp | 0.4 | Flavor lines, guide text |
| `caption` | Cinzel | 400 | 12sp | 0.6 | Hints, progress labels |
| `button` | Cinzel | 600 | 14sp | 1.0 | All button labels |
| `score` | Cinzel | 600 | 24sp | 0.5 | Score numbers |

Line height: 1.35 for body, 1.1 for display.

## Spacing Scale

Base unit: **4dp**.

| Token | Value |
|-------|-------|
| `xs` | 4 |
| `sm` | 8 |
| `md` | 16 |
| `lg` | 24 |
| `xl` | 32 |
| `xxl` | 48 |

- Screen horizontal padding: `md` (16dp), `lg` on tablets if detected (>600dp width).
- Minimum touch target: **48×48dp** (navigation star clusters: 72×72dp).
- Gap between HUD elements: `sm`.
- Card internal padding: `md`.

## Layout Rules

- **Safe areas:** Respect `MediaQuery.padding`; HUD sits below status bar, ledge above home indicator.
- **Hierarchy:** Sky canvas always dominant (≥70% vertical on gameplay and menu).
- **Alignment:** Myth names center on overlays; HUD left/right balanced.
- **Grid:** Atlas uses 2-column (`crossAxisCount: 2`) when width ≥360dp; else 1 column.
- **No Material defaults showing through:** Custom button shapes, transparent `ThemeData.scaffoldBackgroundColor`, disable default elevation shadows on cards — use gold border strokes instead.

## UI Elements

### Buttons

- **Primary (gold):** Rounded rect radius 8dp, gold gradient fill, Ink Brown text, height 48dp, min width 140dp.
- **Secondary (outline):** Transparent fill, 1.5dp Brass Gold border, Moonlit White text.
- **Icon-only (Brass Pause):** Octagon 40dp, flat `#141832` fill, gold border 1dp. Material `Icons.pause` allowed in white at 18dp OR two vertical gold bars drawn in code.

### Cards

- Background `#141832`, border 1dp `#C9A227` @ 50% opacity, radius 12dp.
- No drop shadow; optional inner glow via 1dp inset gold line at 20% opacity.

### Stars (gameplay)

- **Target star:** Circle radius 8dp (scaled by screen), fill Moonlit White, outer pulse ring `#E8C547` @ 40%, animated 1.5s.
- **Connected star:** Fill Brass Gold, ring off.
- **Decoy star:** Fill Moonlit White @ 70%, no pulse, slightly smaller (6dp).
- **Background star:** 1–2dp dots, white @ 20–40% random.

### Lines

- **Active trace:** 2.5dp stroke Chart Blue, round caps, subtle outer glow (duplicate path 4dp @ 30% opacity).
- **Locked:** 3dp Brass Gold, no glow.

### Toggles (Observatory Tools)

- Custom track: 48×28dp rounded rect Dust Gray / Aurora Green when on.
- Thumb: 24dp circle Moonlit White.

### Progress Dots

- 6dp circles, spacing 4dp; filled = Brass Gold, empty = Dust Gray outline.

## Motion

| Animation | Duration | Curve | Notes |
|-----------|----------|-------|-------|
| Star pulse | 1500ms | easeInOut | loop |
| Line draw (splash) | 300ms/stroke | easeOut | stagger |
| Screen fade | 400ms | easeInOut | route transitions |
| Wrong stroke fade | 400ms | easeIn | opacity 1→0 |
| Seal shimmer | 600ms | easeInOut | gold opacity pulse once |
| Parallax drift | 60s loop | linear | background stars |
| Cloud pass (pause) | 8s loop | linear | horizontal translate |

Prefer `AnimationController` + `Tween`; Flame effects for in-game particles only.

## Iconography

- **No custom icon files.** Use Material Icons sparingly (`pause` only if not code-drawn) or pure canvas shapes.
- Navigation clusters drawn as small constellation patterns (3–5 dots + lines), not generic icons.
- Flawless badge: 6-point star path in Aurora Green.

## Responsiveness

- All star coordinates normalized; recompute on `onGameResize`.
- Text scales down one step (display→heading) if width <340dp.
- Chapter cards: width = 75% of screen in horizontal scroll.
- Test at 360×640 and 412×915 minimum.

## Assets Policy (v1)

- **No** image, audio, sprite, Lottie, or Rive files.
- **Allowed:** bundled Cinzel `.ttf`, generated launcher icon.
- **Graphics:** Flame canvas + Flutter `CustomPainter` only.
- **Feedback:** `HapticFeedback`, `SystemSound` only.

Everything expresses the observatory-night theme through color, type, and motion — never through imported art.
