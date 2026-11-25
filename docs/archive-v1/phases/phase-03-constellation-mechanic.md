# Phase 03 — Constellation Mechanic

- **Status:** pending
- **Depends on:** 02
- **Can run in parallel with:** none (05 may run in parallel elsewhere)

## What

Implement core gameplay: interactive stars, drag-to-trace lines, ordered validation, locked gold lines on success, wrong-stroke reset.

## Why

This is the heart of the game. Level data and UI wrap around this mechanic in later phases.

## Scope (build only this)

1. Create `lib/game/models/star_point.dart` — `x`, `y` (normalized), `order` (1-based sequence), `isDecoy`.
2. Create `lib/game/components/constellation_stars.dart`:
   - Renders target stars with pulse animation (scale ring per DESIGN_LANGUAGE).
   - Decoys render dimmer, no pulse.
   - Hit test radius 24dp (convert to game units).
3. Create `lib/game/components/trace_line.dart`:
   - Holds list of connected screen positions for current stroke.
   - Draw active line (Chart Blue) from last star to finger position while dragging.
   - Draw locked segments (Brass Gold) for completed attempts within same run (if design allows — GDD says full clean trace wins; locked lines only after full completion).
4. Input handling in `StarCartographerGame`:
   - Use `TapCallbacks` + drag via `PanDetector` or Flame `DragCallbacks` on a `PositionComponent` overlay.
   - **State machine:** `idle` → `tracing` (after valid start on order-1 star) → `complete` or `error`.
   - On drag move: if finger within hit radius of next expected order star, append to path.
   - On wrong star or decoy touch: emit `onStrokeFailed` callback, clear path, return to `idle`.
   - On reaching final star with full sequence: emit `onConstellationComplete`, lock all lines gold.
5. Wire hardcoded test constellation (5 stars, Silver Ladle shape) in game for dev until phase 04.
6. Expose callbacks `VoidCallback? onComplete` and `VoidCallback? onStrokeFailed` on game class for Flutter overlays (phase 06).

**Simplest approach:** Single drag gesture from first star; do not require lifting between stars mid-trace — continuous drag through all stars. Release on final star triggers completion check.

## Out of scope

- Level/chapter loading, persistence, score calculation, Flutter overlays (pause, HUD text), rotation (add hook in phase 04).

## References

- docs/GDD.md — Gameplay loop, interaction rules, fail feedback
- docs/DESIGN_LANGUAGE.md — Star sizes, line colors, pulse animation
- docs/COMPLIANCE.md — No violence/stress content

## Verify

On `/deck` with test constellation:
- Can trace stars 1→N in order; gold lock on finish.
- Touch decoy (add 1 in test data) → stroke clears.
- Wrong order star → stroke clears.
- No crashes on rapid input.

## On completion

- Update this file's Status to done and add brief notes (key decisions, file paths added).
- Update the row for this phase in docs/IMPLEMENTATION_PLAN.md.
