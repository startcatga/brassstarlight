# Brass & Starlight — Design Language (v2)

The game lives in two materials: **the night sky** (dark, deep, alive) and
**the cartographer's paper** (ink on cream, brass fittings). The sky is where
you play; paper is where you record. Every screen is one or the other — never
a generic dark card UI.

## Choices for this game (and why)

| Decision | Chosen | Why it fits |
|----------|--------|-------------|
| Hub | A painted rooftop observatory scene. The menu is five small star clusters in the sky; your sealed constellations accumulate faintly in gold in the same sky. | The menu is the sky you are charting; progress is visible as the sky itself. |
| Level select | **Observation Log** — a cream ledger page, one ruled line per night (night number, tiny glyph of the figure, name, seal mark), with brass chapter tabs down the left edge. | An astronomer's logbook, not a tile grid. |
| Progress | Gold figures in the hub sky; seal marks in the log; the Atlas as a bound collection. | Collection, not bars. |
| Result | **Atlas plate**: the figure redrawn large on paper, the name inked in, the score in a small ledger beneath. | Sealing = writing it into the book. |
| Play | Full-bleed sky, minimal chrome: name top-left, a brass pause, a strip of star pips. Chart card (Ch III) pinned top-right like a note clipped to the eyepiece. | Nothing between the player and the sky. |

## Palette — each colour has one job

| Token | Hex | Job |
|-------|-----|-----|
| `nightInk` | `#0A0D24` | Deepest sky, play background base |
| `nightBlue` | `#141A3A` | Upper sky band, pause veil |
| `horizon` | `#2A2E55` | Horizon glow (sky gradient only) |
| `starlight` | `#F4EFE4` | Stars, text on sky |
| `traceBlue` | `#A9C4F0` | The live line your finger draws |
| `brass` | `#E2B84C` | Sealed lines, primary action, the next-star pulse |
| `brassDeep` | `#9C7A22` | Brass edges, pressed state, ink rules on paper |
| `parchment` | `#EFE5CF` | Paper surfaces (log, atlas plate, guide, pledge) |
| `ink` | `#2A2117` | Text on paper |
| `inkSoft` | `#6A5A44` | Secondary text on paper |
| `ember` | `#E58A72` | Broken line / decoy touched (never alone: also shake + message) |
| `mist` | `#8A90B8` | Secondary text on sky, locked items |

No other colours. Gradients exist only as sky (top→horizon) and light falloff
around stars.

## Type

- **Cinzel** (OFL) — titles, constellation names, chapter names. Never below 15sp.
- **Crimson Pro** (OFL) — everything read: body, myth lines (italic), labels, numbers (tabular figures for scores).
- Scale: 34 / 24 / 19 / 16 / 14 sp. Heading weight 600, body 400–500.

## Space & shape

- 4dp grid; screen gutter 20dp; group gap 8–12dp; section gap 28–36dp.
- Paper corners 2dp (cut paper, not pills). Brass controls are octagons or
  bevelled plates, not rounded pills.
- Separation by space and ruled ink lines, not by bordered cards.

## Motion (calm, weighted, like a slow telescope)

- Default ease: `easeOutCubic`, 280–360ms. Nothing bounces.
- Star touch: ring blooms 1→1.6× and fades, 300ms; chime pitched up the scale.
- Broken line: segments fall and fade 400ms, 6px horizontal shake of the pip strip.
- Seal: lines flare brass in sequence (60ms stagger), stars twinkle, then the
  plate slides up from below.
- Hub: two parallax star layers drift; occasional shooting star (≥12s apart).
- Reduce motion (setting or system): no drift, no shooting stars, no shake;
  fades only.

## Icons

Drawn in code with a 1.6dp brass stroke (pause octagon, lantern, back arrow,
chart card), never emoji or stock icons.

## Bans for this project

No purple/neon gradients, no glassmorphism, no bordered card grids, no pill
button stacks, no "Play/Settings" labels, no emoji.
