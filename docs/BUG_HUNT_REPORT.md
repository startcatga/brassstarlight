# Bug Hunt Report — Brass & Starlight — 25 November 2026

## Summary

The game is in good health. `flutter analyze` is clean and all 114 tests
pass: the earlier 113 plus one new regression test. One medium bug was found
and fixed. Pausing in the middle of a stroke left the stroke stuck. Two
low-impact items are left open because they don't affect play.

## Fixed

| Issue | Severity | Location | Fix |
|---|---|---|---|
| Pausing mid-stroke (pause button, back gesture, or the app going to the background) left the half-drawn stroke in the trace engine. The finger-lift is ignored while the sky is veiled, so after resuming, a lantern lit the "next star" of a stroke that could no longer continue, which wasted a lantern. The stale line also stayed on screen. | medium | `lib/screens/deck_screen.dart` (`_pause`) | All three pause paths now go through `_pause()`. It drops the unfinished stroke without counting it as a mistake, and points a lit lantern back at the starting star. Covered by the new test "leaving the app mid-stroke drops the unfinished stroke" in `test/widget_flow_test.dart`. The test fails without the fix. |

## Open / needs a decision

| Issue | Why not fixed | Suggested fix |
|---|---|---|
| The sky ticker in `TraceSky` (and the hub's ticker) repaints every frame, even under the pause veil and with Still Sky on. | low: costs a little battery, and the sky looks right. Stopping it needs care, because the seal bloom runs while input is disabled. | Stop the ticker when paused and no bloom or seal animation is active, and restart it on resume. |
| The 8-second lantern-glow timer keeps running during a pause, so a long pause can use up the glow. | low: the starting star is still shown by the ringed or glowing marker in guided and chart modes. | Cancel the timer on pause and restart it on resume. |

## Audit

| Area | Result | Notes |
|---|---|---|
| Assets and fonts referenced in code exist and are declared | pass | 4 chapter skies, hub, paper, 21 sounds (star index clamped to 0–11), Cinzel and Crimson Pro with their OFL licences registered |
| No unused or network dependencies | pass | `shared_preferences` and `audioplayers` only. Audio plays bundled files. |
| `debugShowCheckedModeBanner: false` | pass | `lib/app.dart` |
| Every GDD screen exists and is reachable | pass | splash, Observatory, Log, Deck, Sealed, Atlas, Guide, Tools, Pledge |
| Back navigation never traps or stacks duplicate screens | pass | Deck back opens the pause veil. Sealed back returns to the hub. A fast double tap opens only one screen (checked with a probe test). |
| No generic "Play" or "Settings" labels | pass | All labels are theme-native. |
| Every night loads and is winnable | pass | `test/nights_test.dart` checks fairness and traces all 40 nights. `test/engine_test.dart` does the same for 21 consecutive daily skies. |
| Win fires once, with no double navigation | pass | The `_sealing` guard in `DeckScreen._seal`, and the seal moves to the Sealed screen with `pushReplacement`. |
| Pause freezes play, and backgrounding pauses | pass after fix | See the fixed bug above. The game has no timers or lives. |
| Saving, unlocks, streaks, daily sky and reset | pass | Keys are consistent (`v2_*`). Reset asks first and clears every progress key but keeps settings. |
| Sound, ambience, vibration and Still Sky persist | pass | `ProgressStore` settings, and ambience follows the setting. |
| No overflow at 360×640 and 430×930 | pass | A probe test walked every screen, all three trace modes, the pause veil, the daily sky and two Sealed variants, at text scale 1.0 and 1.3. No overflow. |
| Tap targets ≥48dp, semantics, never colour alone | pass | Octagon buttons and plates have labels. Pips show filled/empty shape plus "n of N". |
| Controllers, tickers, timers and listeners disposed | pass | Deck timers, the TraceSky and hub tickers, and the Sealed and splash controllers. `SkyFeedback` lives for the whole app. |
| Heavy work in per-frame paths | pass | The sky paints inside a `RepaintBoundary`. Blooms are capped at 12. |
| Name and content | pass | Original constellation figures and names. No recreation of an existing game. |

## Verification

- flutter analyze: No issues found
- flutter test: 114 passing
- Manual checks: this session checked the screens by script with widget
  probes (every screen, every trace mode, both phone sizes, larger text). It
  didn't replay the web build in a browser. The web build was played in the
  game-make stage. No Android device was connected, so the back gesture,
  vibration and orientation lock weren't checked on hardware.
