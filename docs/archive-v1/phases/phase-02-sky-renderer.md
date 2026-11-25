# Phase 02 — Sky Renderer

- **Status:** pending
- **Depends on:** 01
- **Can run in parallel with:** 05

## What

Build the Flame game canvas that draws the night sky: gradient background, procedural background stars, and resize-safe coordinate system.

## Why

The constellation mechanic (phase 03) needs a live Flame world with known size and a place to render stars. Separating sky rendering keeps phase 03 focused on input logic.

## Scope (build only this)

1. Create `lib/game/star_cartographer_game.dart` — extends `FlameGame`:
   - Set `backgroundColor()` to transparent (Flutter stack provides gradient behind).
   - Implement `onGameResize` to store `gameSize`.
2. Create `lib/game/components/sky_background.dart` — `PositionComponent` or custom `Component`:
   - Draw linear gradient rect (Midnight Ink → Horizon Haze) via `Canvas`.
   - Generate 80–120 fixed pseudo-random background star positions (seeded `Random(42)` so stable across runs).
   - Two parallax layers: slow drift using `update(dt)` — translate x by `dt * 2` and `dt * 5` wrap-around.
3. Create helper `lib/game/world_coords.dart`:
   - `Offset normalizedToScreen(double nx, double ny, Vector2 size)` — maps 0–1 to game pixels with padding margin (8% inset from edges).
   - `Offset rotateAround(Offset point, Offset center, double radians)` — for phase 04 rotation support (stub now).
4. Create `lib/screens/gameplay_screen.dart` stub hosting:
   - `Stack`: bottom = `Container` gradient (fallback); middle = `GameWidget(game: StarCartographerGame())`; top = empty `SafeArea` placeholder for HUD (phase 06).
5. Register route `/deck` → `GameplayScreen`.

**Simplest approach:** One `CustomPainter` component for background rather than individual star components — fewer nodes.

## Out of scope

- Interactive constellation stars, drag input, HUD, level loading, scoring.

## References

- docs/GDD.md — Observatory Deck layout, sky description
- docs/DESIGN_LANGUAGE.md — Sky gradients, background star specs, motion (parallax)
- docs/COMPLIANCE.md — Code-only graphics

## Verify

Navigate to `/deck` (temporary debug button on stub splash OK). Observe:
- Full-screen gradient sky.
- Tiny stars drifting slowly.
- Rotating device / resizing window recomputes layout without crash.

```bash
flutter run
```

## On completion

- Update this file's Status to done and add brief notes (key decisions, file paths added).
- Update the row for this phase in docs/IMPLEMENTATION_PLAN.md.
