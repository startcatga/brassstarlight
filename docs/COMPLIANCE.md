# Brass & Starlight — Play Store compliance audit

Audited 12 November 2026 against the 14 pre-submission questions. Every answer
must be NO. Checked: all Dart source (`lib/`), all 40 night names and myth
lines (`lib/data/nights.dart`), daily-sky name lists (`lib/core/daily.dart`),
seal names (`lib/data/seals.dart`), all UI copy, generated art
(`assets/art/*`, `tool/make_art.py`, `tool/make_store_art.py`), all sounds
(`assets/sfx/*`, `tool/make_sfx.py`), the Android manifest and dependencies.

| # | Question | Answer | Evidence / where checked |
|---|----------|--------|--------------------------|
| 1 | Violence / gore | **NO** | No combat, damage, death or weapons. A failed trace fades the line; nothing is hurt. The one weapon-like name ("The Hunter's Bow, always aimed") was renamed to "The Fiddler's Bow" during this audit. |
| 2 | Scary / horrifying content | **NO** | Calm night-sky art and a quiet drone/wind ambience; no jump scares, creatures or horror audio. Error sounds are soft muted chimes. |
| 3 | Sexual content / nudity / revealing attire | **NO** | No characters or bodies are drawn; art is sky, rooftops and an observatory. No romance or dating content. |
| 4 | Gambling (real, simulated, themed) | **NO** | No loot boxes, slots, dice, betting or random paid rewards. Lanterns are earned only by fixed rules (start with 3, +1 per first flawless seal, +1 per daily sky). The daily sky is date-seeded, not a prize draw. |
| 5 | Offensive language | **NO** | All strings reviewed; theme-native, gentle wording. Daily-name word lists are neutral nouns and adjectives. |
| 6 | Drugs / alcohol / tobacco | **NO** | None. "The Silver Ladle" is a water dipper ("Shepherds drank from it"), "The Kettle Handle" is a kettle. Chimney pots in the hub art are architecture. |
| 7 | Crude humour | **NO** | No bodily-function jokes, sounds or animations. |
| 8 | Digital purchases / cash-convertible rewards / NFTs | **NO** | No IAP or billing library (`pubspec.yaml`: shared_preferences, audioplayers only). Score, lanterns and seals have no cash value and cannot be bought, sold or exchanged. |
| 9 | User communication | **NO** | Single-player, offline. No chat, sharing, networking or accounts. |
| 10 | Precise location sharing | **NO** | No location APIs or permissions; the release manifest declares no permissions, and neither plugin (audioplayers_android 5.3.0, shared_preferences_android 2.5.5) adds any. |
| 11 | Nazi symbols / propaganda | **NO** | No flags, insignia or historical references. Star shapes are 5-point seals and constellation figures. |
| 12 | Korean historical distortion / anti-national acts | **NO** | No historical or national content of any kind. |
| 13 | Terrorism advocacy | **NO** | No conflict, factions, missions or propaganda. |
| 14 | Realistic crime / criminal techniques | **NO** | No crime themes or instructions. |

**Result: PASS — all 14 answers are NO.**
