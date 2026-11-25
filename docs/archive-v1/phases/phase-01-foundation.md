# Phase 01 — Foundation

- **Status:** pending
- **Depends on:** none
- **Can run in parallel with:** none

## What

Scaffold the Flutter + Flame project shell: dependencies, theme tokens, app routing, and folder structure. No gameplay yet.

## Why

Everything else needs a running app with consistent colors, typography, and navigation. This phase creates the skeleton.

## Scope (build only this)

1. Run `game-setup` or manually create Flutter project `star_cartographer` with package `com.starcartographer.app`.
2. Pin dependencies in `pubspec.yaml`:
   - `flame: ^1.37.0`
   - `shared_preferences: ^2.5.5`
   - No `flame_audio`, no image packages.
3. Download Cinzel Regular + SemiBold; add to `assets/fonts/`; declare in `pubspec.yaml` per `DESIGN_LANGUAGE.md`.
4. Create `lib/theme/app_colors.dart` — all hex constants from design language.
5. Create `lib/theme/app_typography.dart` — Cinzel text styles (display, heading, body, button, score).
6. Create `lib/theme/app_theme.dart` — `ThemeData` with dark scaffold `#0B0E2A`, transparent app bar, no Material 3 overscroll glow if distracting.
7. Create `lib/app.dart` — `MaterialApp` with:
   - `debugShowCheckedModeBanner: false`
   - Named routes placeholder map (strings from GDD copy sheet).
   - Initial route → splash (stub screen with text "First Light" is fine for now).
8. Create `lib/main.dart` — `runApp`, `WidgetsFlutterBinding.ensureInitialized()`.
9. Create empty folder structure per `IMPLEMENTATION_PLAN.md` key files list.
10. Stub screens as empty `StatelessWidget` returning `Scaffold` + route name text (replaced in later phases).

**Simplest approach:** Use `MaterialApp` + named `routes` map, not go_router — fewer dependencies for a small game.

## Out of scope

- Flame game logic, constellation data, persistence, real UI layouts.

## References

- docs/GDD.md — Copy sheet (route names), Technical Notes
- docs/DESIGN_LANGUAGE.md — Colors, typography, font bundling
- docs/COMPLIANCE.md — No network/analytics packages

## Verify

```bash
flutter pub get
flutter analyze
flutter run
```

App launches to stub splash with dark background and Cinzel font visible. No debug banner.

## On completion

- Update this file's Status to done and add brief notes (key decisions, file paths added).
- Update the row for this phase in docs/IMPLEMENTATION_PLAN.md.
