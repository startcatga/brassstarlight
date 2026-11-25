# Phase 04 — Level Progression

- **Status:** pending
- **Depends on:** 03
- **Can run in parallel with:** none

## What

Define all 15 constellations with star coordinates, wire them into gameplay, implement chapter unlock rules and local save via `shared_preferences`.

## Why

The mechanic needs real level data; the game needs persistence so players resume progress across sessions.

## Scope (build only this)

1. Create `lib/data/constellation_levels.dart`:
   - Models: `ConstellationLevel` (id, chapterIndex, indexInChapter, displayName, mythLine, stars, decoys, rotationDegrees).
   - Const list of all 15 levels from GDD (normalized coordinates — hand-tune for pleasing shapes).
   - Helpers: `ConstellationLevel.byId(int)`, `levelsInChapter(int)`.
2. Apply `rotationDegrees` around constellation centroid in `world_coords.dart` before rendering.
3. Create `lib/data/progress_repository.dart`:
   - Keys: `highest_unlocked_level_id`, `completed_levels` (JSON list of ids), `level_scores` (map id→int), `flawless_levels` (list), `lifetime_score`, settings toggles (placeholders for phase 08).
   - Methods: `isLevelUnlocked(id)`, `completeLevel(id, score, flawless)`, `getNextPlayableLevel()`, `getCompletedCount()`.
   - **Unlock rule:** level 1 open; completing id N unlocks N+1; completing id 5/10 unlocks next chapter first level.
4. Update `StarCartographerGame` to accept `ConstellationLevel` in `loadLevel(level)`.
5. Update `GameplayScreen` to read level id from route args (`/deck?level=3` or `ModalRoute settings.arguments`).
6. Score calculation on complete (in repository or small `score_calculator.dart`):
   - Base: `100 * starCount`
   - Flawless: `+50 * starCount` if zero failed strokes this attempt (track counter in game, pass on complete).
   - Chapter bonus: `+200` if id is 5, 10, or 15.

**Simplest approach:** `shared_preferences` only — skip hive_ce unless list size becomes unwieldy (it won't for 15 levels).

## Out of scope

- UI for chapter select, atlas display, complete overlay (phase 06–07), haptics (phase 09).

## References

- docs/GDD.md — Level Structure (all 15 names, chapters, unlock rules, scoring)
- docs/DESIGN_LANGUAGE.md — Star rendering specs
- docs/COMPLIANCE.md — Local-only storage, no cloud

## Verify

- Complete level 1 → level 2 unlocks; restart app → progress persists.
- Level 15 data loads with rotation applied (stars visually tilted).
- Decoys appear from chapter II onward.
- Score writes to preferences and increments lifetime total.

```bash
flutter run
# Play through or hot-reload with debug complete button
```

## On completion

- Update this file's Status to done and add brief notes (key decisions, file paths added).
- Update the row for this phase in docs/IMPLEMENTATION_PLAN.md.
