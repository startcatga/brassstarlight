# Brass & Starlight — Documentation Index

**Pitch:** Trace constellations from a rooftop observatory and fill your Star
Atlas. A calm, offline puzzle in four chapters.

## Pillars

1. **Quiet skill.** No timers or lives; the challenge is reading the sky.
2. **One fiction.** The sky is where you play, paper is where you record. Wording fits the world everywhere.
3. **Offline and private.** Progress stays on the device. No network, no data, no permissions.
4. **Proven fair.** A solver checks every night: lines clear of other stars, every figure traceable.

## Documents

| Document | Purpose |
|----------|---------|
| [GDD.md](./GDD.md) | Game design: chapters, mechanics, screens, retention |
| [DESIGN_LANGUAGE.md](./DESIGN_LANGUAGE.md) | Palette, type, layout choices, motion |
| [IMPROVEMENT_PLAN.md](./IMPROVEMENT_PLAN.md) | Audit and plan from the v1 build |
| [COMPLIANCE.md](./COMPLIANCE.md) | 14 Play Store checks, all NO |
| [PRIVACY_POLICY.md](./PRIVACY_POLICY.md) | Website privacy policy (holds publisher details; never in the app) |
| [TERMS_OF_SERVICE.md](./TERMS_OF_SERVICE.md) | Website Terms of Service, for Play's trader-status form |
| [BUG_HUNT_REPORT.md](./BUG_HUNT_REPORT.md) | Pre-launch bug hunt: fixes, open items, audit |
| [CI.md](./CI.md) | Keystore, GitHub Secrets and the signed-build workflow |
| [../PRODUCT.md](../PRODUCT.md) | Product context for design work |
| [archive-v1/](./archive-v1/) | Documents from the earlier 15-level "Star Cartographer" build |

## Code map

| Path | What |
|------|------|
| `lib/core/` | Pure Dart rules: `TraceEngine`, `StrokeSolver`, geometry and generator, daily sky |
| `lib/data/` | The 40 nights, seals, `ProgressStore` (shared_preferences) |
| `lib/screens/` | Splash, Observatory (hub), Observation Log, Deck, Sealed, Atlas, Guide, Tools, Pledge |
| `lib/widgets/` | `TraceSky` (the interactive sky), figure glyphs, brass controls, paper pages |
| `lib/services/feedback.dart` | Sound, ambience, haptics |
| `tool/` | Art, sound and icon generators |
| `test/` | Engine, nights (fairness + solvable), progress, widget flows |

## Stack

Flutter 3.47.9 · shared_preferences · audioplayers · Cinzel + Crimson Pro (OFL, bundled)
