# Brass & Starlight — Game Design Document

## Concept

You are an apprentice cartographer on a rooftop observatory. Each night a
figure is hidden among the stars. Find it, trace it with one continuous drag,
and it is sealed into your Star Atlas with its name and myth. The skill you
practise changes chapter by chapter.

## Core loop

1. Choose a night (hub: **Chart Night N**, or the **Observation Log**).
2. Trace the figure on the **Observatory Deck**.
3. Seal it, which shows the **Constellation Sealed** plate: score, myth, any lantern or seal earned.
4. Continue to the next night or return to the hub, whose sky now holds the new figure in gold.

Sessions take 1–3 minutes per night. There are no timers or lives, and a broken line simply resets.

## Rules (lib/core/trace_engine.dart)

- **Guided** (Ch I–II): start on the ringed star; the next star pulses; drag through stars in order. Passing over an already-linked star is fine. Touching a later star, a loose star, or lifting early breaks the line.
- **Chart card** (Ch III): stars are unmarked and the figure is rotated among loose stars. The card shows it upright with both ends ringed; start from either end.
- **One stroke** (Ch IV): dashed lines show a figure with branches and loops. Start on any star and draw every line exactly once in one stroke. Retracing a drawn line, or moving to a star with no line, breaks it. Only some starting stars can finish; the solver knows which.
- Fast swipes are sampled so a star can't be skipped. A single tap on a star is never counted as a mistake.

## Chapters — 40 nights

| Chapter | Nights | New idea | Loose stars | Notes |
|---|---|---|---|---|
| I · First Light | 8 | Guided tracing | 0 | 4–7 stars; finale *The First Key* |
| II · Wandering Stars | 10 | Loose stars break the line | 2–5 | Finale *The Bell Tower* |
| III · Turning Skies | 12 | Chart card, rotation 35°–180° | 4–8 | Finale *The Northern Gate* |
| IV · The Unbroken Line | 10 | One stroke, branches and loops | 0–4 | Finale *The Master Chart* (11 stars) |

23 nights are hand-placed and 17 are generated from fixed seeds; all are named by hand. Tests prove that:
- every star is ≥0.15 apart;
- every line clears other stars by ≥0.085 (sky units; ≈28dp on a small phone);
- everything fits any rotation;
- every night completes when traced by the engine;
- loose stars and line counts ramp up by chapter.

## Scoring

100 per star, +50 per star if flawless (no broken line), +200 for a chapter finale. The best score per night counts toward the lifetime **star score**.

## Retention

- **Tonight's Sky:** a date-seeded night, the same for everyone. The mechanic rotates through the week (guided, chart card, one stroke). Streak and best streak are kept; +1 lantern per day.
- **Lanterns:** start with 3, max 9. +1 for each first flawless seal and each daily sky. A lantern lights the next star or a working start. Never sold.
- **Seals:** 12 local achievements (see `lib/data/seals.dart`).
- **Star Atlas:** all plates, flawless marks, best scores, seals.
- **Hub sky:** sealed figures appear faintly in gold.

## Screens

| Screen | Material | Notes |
|---|---|---|
| Splash (First Light) | sky | One star wakes, three lines draw, title fades in; tap to skip |
| Observatory (hub) | sky | Painted rooftop scene; six star-cluster menu items; ledger of charted / score / lanterns |
| Observation Log | paper | Chapter tabs I–IV down the edge; one ruled line per night with glyph and wax seal |
| Observatory Deck | sky | Name, pause, lantern, star pips, messages, chart card (Ch III) |
| Stargaze Pause | veil | Return to the Sky / Begin this night again / Leave the Deck |
| Constellation Sealed | paper | Figure inks in, name, myth, ledger, notes, next night |
| Star Atlas | paper | Constellations grid by chapter; Seals list |
| Apprentice's Guide | paper | Three playable practice skies + rules |
| Observatory Tools | paper | Sounds, ambience, haptics, Still Sky, pledge, font licences, reset progress (confirm) |
| Stargazer's Pledge | paper | In-game privacy text; no publisher details |

## Feedback

- **Sound** (all synthesised in `tool/make_sfx.py`): star chimes climb a D-major pentatonic scale; a soft falling pair for a broken line; a dull tick for a loose star; an arpeggio for the seal; unlock, lantern, page and tap sounds; a 22-second night ambience loop.
- **Haptics:** selection on each link, light on a break, medium on the seal.
- **Still Sky** (or the system's reduce-motion setting) removes drift, pulses, shakes and falling lines.

## Accessibility

- State is never shown by colour alone: shape, position, pips, wax marks and text all carry it.
- Every control has a Semantics label, and touch targets are at least 48dp (sky stars ≈ 52dp).
- Text uses Crimson Pro at 16–18sp; Cinzel is only for titles.
