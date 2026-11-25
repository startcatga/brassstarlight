# Phase 06 — Gameplay UI

- **Status:** pending
- **Depends on:** 03, 04
- **Can run in parallel with:** 08 (after 05)

## What

Add Flutter overlays on the Observatory Deck: HUD, pause (**Cloud Passage**), completion (**Constellation Sealed**), and inline error feedback (**Fading Stroke**).

## Why

Core mechanic alone has no pause, progress display, or success flow. This phase connects gameplay to the rest of the app navigation.

## Scope (build only this)

1. Create `lib/widgets/gold_button.dart` — primary/secondary styles per DESIGN_LANGUAGE.
2. Update `lib/screens/gameplay_screen.dart`:
   - **Top HUD:** constellation name, progress dots, Brass Pause button.
   - **Bottom hint:** "Connect the stars in order" / "Star n of total" — auto-fade after 3s.
   - **Vignette:** `IgnorePointer` + `CustomPaint` radial gradient overlay.
3. Create `lib/screens/pause_overlay.dart` (or widget):
   - Modal route or `Stack` overlay: Cloud Passage title, Return to the Sky, Leave the Deck.
   - Pause: set `StarCartographerGame.pauseEngine()` / flag to ignore input.
   - Leave the Deck → confirm dialog → pop to menu (no mid-level save as complete).
4. Create `lib/screens/constellation_sealed_screen.dart`:
   - Show completed constellation miniature (reuse level star data + CustomPainter).
   - Myth name, flavor line, score breakdown, Next Sky / Return to Observatory.
   - On appear: call `progress_repository.completeLevel(...)`.
   - Next Sky → push replacement to `/deck` with next level id.
5. Wire game callbacks:
   - `onComplete` → navigate to sealed screen with level + flawless flag + stroke fail count.
   - `onStrokeFailed` → show transient snackbar-style text "The line broke — trace again" at bottom (1.5s).
6. Handle app lifecycle: `WidgetsBindingObserver` auto-pause on `paused`.

## Out of scope

- Chapter/atlas screens, settings toggles for sound/haptics (phase 08–09), particle burst polish (phase 09).

## References

- docs/GDD.md — Observatory Deck, Pause, Complete, Fail sections; scoring
- docs/DESIGN_LANGUAGE.md — HUD, buttons, overlay, motion durations
- docs/COMPLIANCE.md — No alarming content on fail state

## Verify

Full loop on level 1:
- HUD shows name and dots updating.
- Pause freezes game; resume continues partial trace.
- Wrong stroke shows fade message.
- Complete shows sealed screen with score; Next Sky loads level 2.
- Leave the Deck returns to menu without marking incomplete level done.

## On completion

- Update this file's Status to done and add brief notes (key decisions, file paths added).
- Update the row for this phase in docs/IMPLEMENTATION_PLAN.md.
