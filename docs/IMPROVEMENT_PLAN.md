# Brass & Starlight — Improvement Plan

> Working title was "Star Cartographer"; renamed on 12 Nov 2026 because a similar Play app already uses that name. Package changed to `com.brassandstarlight.game` (never uploaded).

Date: 2026-11-12

## 1. Audit (starting point)

| Area | Found | Action |
|------|-------|--------|
| Concept | Calm constellation tracing on a rooftop observatory. Strong theme, original names. | Keep. |
| Puzzle depth | 15 levels; you follow a pulsing "next star" and that is all. Mostly dexterity. | Add three new mechanics across four chapters (below). |
| Engine | Flame used only as a canvas; input already via `GestureDetector`; rules mixed with rendering. | Pure-Dart `TraceEngine` + `CustomPainter`. Remove `flame` and `cupertino_icons`. |
| Content | 15 levels, 3 chapters; `/15` and finale ids hard-coded. | 40 levels, 4 chapters, all counts derived from data. |
| Retention | None. | Daily sky + streak, Seals (local achievements), lantern hints earned by flawless play, atlas stats. |
| Feedback | System click only. | Synthesised SFX (pitched star chimes, seal arpeggio…) and an ambient night loop. |
| Art | Flat gradients, no launcher icon (Flutter default). | Painted chapter skies, observatory hub art, logo + adaptive icon, all from scripts in `tool/`. |
| Typography | Cinzel (all caps) used for body text — hard to read. | Cinzel for titles, Crimson Pro for reading. |
| Privacy screen | Gradient panel; no reset option in settings. | Plain in-game privacy text; reset progress with confirm. |
| Android | Template Gradle; debug signing; no proguard. | Match the Flutter 3.47 template, key.properties signing, proguard rules. |
| Docs | Boilerplate README; phase docs of the v1 build. | Archived to `docs/archive-v1/`; GDD/README rewritten. |
| Names | App label, title, package all "Star Cartographer" / `star_cartographer`. No trademark risk found. | Keep `com.starcartographer.star_cartographer`. |

Baseline: Flutter 3.47.9, `flutter analyze` clean, 3 tests passing.

## 2. Improved concept

You are an apprentice on a rooftop observatory, charting the night sky into
your Star Atlas. Each night is a sky to chart. The skill you learn changes
chapter by chapter, from following a guide star to drawing a whole figure in
one unbroken line.

## 3. How it plays — 40 nights in 4 chapters

Counts were chosen for a slow, contemplative puzzle: fewer, richer levels;
chapters grow in length as the mechanic deepens, and the last is shorter but
harder, ending in a large finale.

| Chapter | Nights | Mechanic | Why |
|---------|-------|----------|-----|
| I · First Light | 8 | **Guided tracing.** The next star pulses; drag through them in order. No decoys. | Teaches the gesture. |
| II · Wandering Stars | 10 | **Decoys.** Loose stars sit between the real ones; touching one breaks the line. Guide pulse stays. | Precision and route reading. |
| III · Turning Skies | 12 | **Chart card.** The sky no longer marks your stars. A brass chart card shows the figure upright; in the sky it is rotated and hidden among decoys. Find it, then trace it from either end. | The real "cartographer" puzzle: pattern recognition under rotation. |
| IV · The Unbroken Line | 10 | **One stroke.** Faint chart lines show a branching figure. Draw every line in one continuous stroke without retracing any. Start anywhere — but only some starts work. Finale: *The Master Chart*. | Logic puzzle (path through every line exactly once). |

- 23 hand-placed nights (the 15 originals + 8 new) and 17 generated from fixed
  seeds, all named by hand.
- A solver proves each night solvable: ordered paths are clear of decoys and
  other stars at three phone/tablet sizes; one-stroke figures are connected
  with 0 or 2 odd-degree stars and the solver returns a full stroke.
- Difficulty ramps: star count and decoys rise per chapter (tested).

## 4. Retention

- **Tonight's Sky (daily):** a date-seeded night, mechanic rotates through the
  week; streak counter, best streak. Fully offline.
- **Seals:** 12 local achievements (first seal, each chapter, flawless runs,
  streaks, no-lantern chapter, full atlas).
- **Lanterns:** hints earned — start with 3, +1 for every flawless first seal
  (cap 9). A lantern lights the next star / a working start. Never sold.
- **Star Atlas:** every sealed constellation drawn in gold with its myth line,
  score, flawless mark; header stats (nights charted, flawless, best streak).
- **The hub sky fills:** each sealed constellation appears faintly in gold in
  the observatory sky.
- Restart is free and instant; no timers, no lives.

## 5. Screens

Splash (First Light) · Observatory (hub) · Observation Log (level select,
chapter rail) · Observatory Deck (play) · Stargaze Pause · Constellation
Sealed (result) · Star Atlas · Seals · Apprentice's Guide (interactive demo)
· Observatory Tools (haptics, sounds, night ambience, reduce motion, reset
progress, Stargazer's Pledge) · Stargazer's Pledge (privacy).

## 6. Play readiness checklist

- [x] No ads, IAP, accounts, network, analytics or permissions.
- [x] Launcher icon + adaptive icon from the game's logo.
- [x] Store kit in `store/` (icon 512, feature graphic, 7 screenshots, listing).
- [x] Website privacy policy (`docs/PRIVACY_POLICY.md`) + Terms of Service (`docs/TERMS_OF_SERVICE.md`) + in-game pledge without publisher details.
- [x] Compliance (14 × NO) and privacy audit.
- [x] Bug hunt (`docs/BUG_HUNT_REPORT.md`) and Play hardware-feature declarations (portrait, touchscreen optional).
- [ ] Signed AAB from GitHub Actions (secrets prefix `STARCART_`). Workflow and `docs/CI.md` ready; needs the push and the four secrets.
- [ ] GitHub repo — not connected yet; local git only for now.

## 7. Roadmap

1. Engine + solver + 40 nights + tests.
2. Screens, hub, log, atlas, seals, daily, lanterns.
3. Art, SFX, ambience, motion, reduce motion.
4. Icon, Android toolchain, store kit, policies.
5. Compliance/privacy/CI, commit; push when the GitHub account is ready.
6. Website (WordPress) after the AAB is green.
