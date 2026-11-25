# Phase 07 — Atlas & Chapters

- **Status:** pending
- **Depends on:** 04, 05
- **Can run in parallel with:** 08

## What

Build **Night Chapters** selection and **Star Atlas** collection screens with unlock states tied to progress.

## Why

Progression and collection are core to the GDD promise — 15 constellations in an atlas with chapter structure.

## Scope (build only this)

1. Create `lib/screens/night_chapters_screen.dart`:
   - Horizontal `PageView` of 3 chapter cards (First Light, Wandering Stars, Turning Skies).
   - Each card: 5 star slots (filled/outline), locked chapter dimming.
   - Tap constellation row → navigate `/deck` with level id (only if unlocked).
2. Create `lib/widgets/atlas_cell.dart`:
   - Mini constellation painter (scale normalized coords into cell rect).
   - Myth name, flavor line (max 2 lines ellipsis), score, flawless badge.
   - Locked state: gray dots + "?" pattern.
3. Create `lib/screens/star_atlas_screen.dart`:
   - Header: completed count, Lifetime Star Score.
   - `GridView` 2 columns (1 on narrow) of `AtlasCell`.
   - Data from `constellation_levels.dart` + `progress_repository.dart`.
4. Wire menu clusters (phase 05) to these real screens instead of stubs.
5. Update menu **Stars Charted: n/15** from repository.

**Simplest approach:** Reuse one `MiniConstellationPainter` class for both atlas cells and sealed screen thumbnail.

## Out of scope

- Settings, guide, privacy (phase 08), haptic on cell tap (phase 09).

## References

- docs/GDD.md — Night Chapters, Star Atlas layouts, unlock rules
- docs/DESIGN_LANGUAGE.md — Atlas grid, cards, locked styling
- docs/COMPLIANCE.md — All content family-friendly

## Verify

- With 0 progress: only level 1 playable from chapters; atlas shows 1 unlocked entry slot pattern.
- After completing 3 levels: atlas shows 3 entries with scores; menu count updates.
- Chapter II locked until level 5 complete.

## On completion

- Update this file's Status to done and add brief notes (key decisions, file paths added).
- Update the row for this phase in docs/IMPLEMENTATION_PLAN.md.
