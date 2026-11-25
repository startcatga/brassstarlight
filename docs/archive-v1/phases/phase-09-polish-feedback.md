# Phase 09 — Polish & Feedback

- **Status:** pending
- **Depends on:** 06, 07, 08
- **Can run in parallel with:** none

## What

Apply haptics, system sounds, animation polish, and a full design-language pass across all screens.

## Why

The game must feel finished and cohesive — brass-gold ceremony, not a prototype.

## Scope (build only this)

1. Create `lib/services/feedback_service.dart`:
   - Reads `haptics_enabled` / `sounds_enabled` from repository.
   - Methods: `starTap()`, `strokeFail()`, `constellationSealed()`, `uiTap()`.
   - Map to `HapticFeedback.selectionClick`, `lightImpact`, `mediumImpact` and `SystemSound.play(SystemSoundType.click/alert)` per GDD table.
2. Call feedback service from game (star touch, fail, complete) and Flutter buttons (navigation).
3. **Constellation Sealed:** star particle burst (12–20 dots, radial velocity, 1s fade) — Flame overlay or Flutter `CustomPainter` animation.
4. **Seal shimmer:** one-shot gold opacity pulse on locked lines (600ms).
5. **Route transitions:** 400ms fade between major screens.
6. **Pause clouds:** animated horizontal rects on pause overlay (8s loop).
7. Design pass checklist:
   - All buttons use `gold_button.dart`.
   - All text uses Cinzel via `app_typography.dart`.
   - No default Material blue anywhere.
   - Touch targets ≥48dp.
8. Fix any layout overflow on 360×640.

**Simplest approach:** Central `FeedbackService` singleton via `InheritedWidget` or pass from `app.dart` — avoid over-abstracting.

## Out of scope

- New features, new levels, CI/signing (phase 10 / game-ci skill).

## References

- docs/GDD.md — Audio and Haptic Feedback table
- docs/DESIGN_LANGUAGE.md — Motion table, full visual system
- docs/COMPLIANCE.md — SystemSound/HapticFeedback only (no audio files)

## Verify

- With sounds on: hear click on UI tap, alert on seal.
- With haptics off: no vibration on trace.
- Seal screen shows particle burst.
- Full playthrough of 2 levels feels smooth with no visual glitches.

## On completion

- Update this file's Status to done and add brief notes (key decisions, file paths added).
- Update the row for this phase in docs/IMPLEMENTATION_PLAN.md.
