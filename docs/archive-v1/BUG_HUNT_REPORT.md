# Bug Hunt Report — Star Cartographer — 2026-06-03

## Summary

Full bug-hunt pass on the built game. **flutter analyze** reports zero errors; **flutter test** passes (3 tests). Fixed gameplay logic, menu stale state, layout overflows, and lifecycle/timer hygiene. Game is stable for manual play on Android and web.

## Fixed

| Issue | Severity | Location | Fix |
|-------|----------|----------|-----|
| Constellation sealed on drag-over last star, not release | high | `lib/game/components/constellation_trace.dart` | Added `_pendingRelease`; completion fires on pan-up while finger remains on final star (matches GDD) |
| Menu progress/score stale after returning from gameplay | medium | `lib/screens/observatory_menu_screen.dart`, `lib/navigation.dart` | Added `RouteObserver` + `RouteAware.didPopNext`; refresh after `Navigator.pushNamed` returns |
| `LateInitializationError` for `_sky`/`_trace` on web resize | critical | `lib/game/star_cartographer_game.dart` | Lazy `_ensureComponents()` (fixed in prior session; verified) |
| Sky navigation cluster overflow on web | medium | `lib/widgets/sky_navigation_cluster.dart` | Flexible column layout, smaller diagram, 2-line labels (fixed in prior session; verified) |
| Locked levels playable via direct route args | medium | `lib/screens/gameplay_screen.dart` | Redirect to next playable level when locked |
| Decoy stars could lose to overlapping real-star hits | medium | `lib/game/components/constellation_trace.dart` | Split hit tests; decoys checked before targets via `_resolveTouch` |
| Brass Pause below 48dp touch target | low | `lib/screens/gameplay_screen.dart` | Increased control to 48×48 |
| Star Atlas header overflow on narrow widths | medium | `lib/screens/star_atlas_screen.dart` | Replaced `Row` with `Wrap` |
| Splash navigation timer not cancelled on dispose | low | `lib/screens/splash_screen.dart` | Use `Timer` + cancel in `dispose` |
| Analyzer info: unnecessary imports / underscores | low | multiple files | Removed unused `dart:ui` imports; cleaned lint nits |

## Open / needs user decision

| Issue | Why not auto-fixed | Suggested fix |
|-------|-------------------|---------------|
| Custom launcher icon not generated | Checklist item; not blocking gameplay | Run `flutter_launcher_icons` with a generated star-on-indigo icon when ready to ship |
| `IMPLEMENTATION_PLAN.md` phases still `pending` | Doc sync only; build is complete | Mark phases done in a future docs pass or during `game-ci` |
| Variable Cinzel font may ignore `FontWeight.w600` on some platforms | Single `.ttf` variable file bundled | Split into Regular + SemiBold static files if bold headings look wrong on device |

## Verification

- flutter analyze: **pass** (0 errors, 0 warnings; info-only style hints)
- flutter test: **pass** (3 tests: splash smoke, score math, level data integrity)
- Manual checks performed:
  - Route map matches GDD flow (splash → menu → deck → sealed → menu)
  - Theme-native copy (no generic Play/Settings)
  - `debugShowCheckedModeBanner: false`
  - No `flame_audio` / runtime `google_fonts`
  - Cinzel bundled at `assets/fonts/Cinzel.ttf`
  - No INTERNET permission in main `AndroidManifest.xml`
  - Pause overlay freezes Flame engine
  - Progress unlock chain (level N completes → N+1 unlocked)
