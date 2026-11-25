# Phase 05 — Observatory Menu

- **Status:** pending
- **Depends on:** 01
- **Can run in parallel with:** 02, 03

## What

Build **First Light** splash and **The Observatory** main menu with spatial sky navigation (not a vertical button list).

## Why

Players need an entry point and theme-first navigation before all gameplay UI is polished. This phase can run early because it only depends on the app shell.

## Scope (build only this)

1. Create `lib/screens/splash_screen.dart` — **First Light**:
   - Animated single star pulse + 3-line constellation draw (Flutter `AnimationController` or Flame overlay — Flutter is simpler here).
   - Title + subtitle fade in (Cinzel).
   - Auto-navigate to menu after 2.8s via `Navigator.pushReplacementNamed`.
2. Create `lib/widgets/sky_navigation_cluster.dart`:
   - Custom painter: 3–5 dots + connecting lines + optional label below.
   - Tap callback, min size 72×72.
3. Create `lib/screens/observatory_menu_screen.dart` — **The Observatory**:
   - Top 72%: `CustomPainter` star field (reuse logic from sky or simplified static version) + positioned clusters:
     - Trace Tonight's Sky → `/deck` with `getNextPlayableLevel()` id (stub `1` until phase 04 wires repository).
     - Night Chapters → `/chapters` (stub screen OK until phase 07).
     - Star Atlas → `/atlas` (stub).
     - Apprentice's Guide → `/guide` (stub).
     - Observatory Tools → `/tools` (stub).
   - Bottom 28%: rooftop parapet painter + telescope silhouette + progress text (`Stars Charted: n/15` — read from repository when available, else `0/15`).
4. Create `lib/painters/rooftop_painter.dart` and `lib/painters/telescope_silhouette_painter.dart` — pure canvas paths.
5. Set initial route splash → menu.

**Simplest approach:** Main menu is a Flutter `Stack` with `Positioned` clusters at fixed fractional offsets — no physics, no custom layout engine.

## Out of scope

- Full chapter/atlas/guide/tools screens (stubs only), gameplay HUD, polish animations (phase 09).

## References

- docs/GDD.md — Splash + Main Menu spatial layouts, copy sheet
- docs/DESIGN_LANGUAGE.md — Colors, typography, navigation cluster specs
- docs/COMPLIANCE.md — No external images

## Verify

- Cold start shows splash animation → menu.
- Menu shows sky clusters (not vertical button list), rooftop ledge, telescope.
- Tapping **Trace Tonight's Sky** navigates to gameplay deck.
- All labels use theme-native strings from copy sheet.

## On completion

- Update this file's Status to done and add brief notes (key decisions, file paths added).
- Update the row for this phase in docs/IMPLEMENTATION_PLAN.md.
