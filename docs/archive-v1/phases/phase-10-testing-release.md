# Phase 10 — Testing & Release Prep

- **Status:** pending
- **Depends on:** 09
- **Can run in parallel with:** none

## What

Manual test pass, launcher icon generation, final analyze/build check, and handoff to compliance/privacy/CI skills.

## Why

Last gate before `game-compliance`, `game-privacy`, and `game-ci` in the ship pipeline.

## Scope (build only this)

1. **Test matrix** — execute and note pass/fail:

   | Area | Check |
   |------|-------|
   | Splash | Auto-transitions; animation visible |
   | Menu | All 5 sky clusters navigate correctly |
   | Gameplay | Trace, fail, complete, pause, resume, leave |
   | Progress | Persists after force-close |
   | Chapters | Lock/unlock rules for all 3 chapters |
   | Atlas | 15 entries; locked/unlocked states |
   | Guide / Privacy / Tools | Readable; toggles persist |
   | Score | Base + flawless + chapter bonus math |
   | Rotation | Chapter III levels visually rotated |
   | Decoys | Chapter II+ decoys reject trace |
   | Responsive | 360dp width no overflow |
   | Offline | Airplane mode — full game works |

2. Run `flutter analyze` — zero errors.
3. Run `flutter test` — add minimal widget test if none exists (smoke: app pumps splash).
4. Generate launcher icon (code or `flutter_launcher_icons` with generated simple star-on-indigo — only permitted binary art besides fonts).
5. Confirm `AndroidManifest.xml` has no INTERNET permission unless accidentally added — remove if present.
6. Confirm `debugShowCheckedModeBanner: false`.
7. Document any known minor issues in this file's notes section.
8. Update all phase statuses in `IMPLEMENTATION_PLAN.md` to done.

## Out of scope

- GitHub Actions signing (game-ci skill), Play Console upload, store listing copy.

## References

- docs/GDD.md — Full flow
- docs/COMPLIANCE.md — All 14 NO checks
- docs/IMPLEMENTATION_PLAN.md — Status table

## Verify

```bash
flutter analyze
flutter test
flutter build apk --release
```

Release APK installs and runs on device/emulator. All test matrix rows pass.

## On completion

- Update this file's Status to done and add brief notes (key decisions, file paths added).
- Update the row for this phase in docs/IMPLEMENTATION_PLAN.md.
- Inform user: ready for `game-compliance` → `game-privacy` → `game-ci`.
