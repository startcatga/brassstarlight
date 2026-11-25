# Phase 08 — Guide, Privacy & Tools

- **Status:** pending
- **Depends on:** 05
- **Can run in parallel with:** 06, 07

## What

Build **Apprentice's Guide**, **Stargazer's Pledge** (privacy), and **Observatory Tools** (settings) screens with persistence for toggles.

## Why

Play Store expects a privacy disclosure for any app; the GDD requires how-to-play and settings. All are reachable from the observatory menu.

## Scope (build only this)

1. Create `lib/screens/apprentice_guide_screen.dart`:
   - Cream parchment panel on dark sky.
   - 3 code-drawn step diagrams (mini constellations + captions from GDD).
   - Decoy + rotation notes.
   - Return to Observatory button.
2. Create `lib/screens/privacy_screen.dart` — **Stargazer's Pledge**:
   - Scrollable cream panel text:

     *"Star Cartographer works entirely on your device. We do not collect, store, or share personal information. Your chart progress is saved locally on this device only. The app does not connect to the internet, show advertisements, or include in-app purchases. No account is required to map the sky."*

   - Return to Observatory.
3. Create `lib/screens/observatory_tools_screen.dart`:
   - Bottom sheet style panel (or full screen): toggles **Hearth Haptics** and **Deck Sounds** (default on).
   - Link to Stargazer's Pledge.
   - Persist via `progress_repository` / shared_preferences keys `haptics_enabled`, `sounds_enabled`.
4. Wire menu routes from phase 05.

**Simplest approach:** Settings as a modal bottom sheet invoked from menu instead of separate route — optional if route `/tools` already stubbed.

## Out of scope

- Actually gating haptics/sounds (wired in phase 09), gameplay changes.

## References

- docs/GDD.md — Guide, Privacy, Observatory Tools sections; copy sheet
- docs/DESIGN_LANGUAGE.md — Parchment panel colors, toggles
- docs/COMPLIANCE.md — Items 8–10 (no data collection — copy must match)

## Verify

- All three screens reachable from menu.
- Toggle settings → kill app → relaunch → settings retained.
- Privacy text present and accurate (offline, no collection).
- No generic "Settings" or "Privacy Policy" titles — theme-native only.

## On completion

- Update this file's Status to done and add brief notes (key decisions, file paths added).
- Update the row for this phase in docs/IMPLEMENTATION_PLAN.md.
