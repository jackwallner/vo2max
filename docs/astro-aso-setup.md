# Astro ASO setup, VO2 Max Daily Tracker

Last validated: 2026-07-19 with Astro MCP 2026.11.1.

## App

- App Store ID: `6791235742`
- Bundle ID: `com.jackwallner.vo2max`
- Astro temporary app ID: `117` (the app is pre-launch and is not searchable in the public store yet)
- Evidence: `scripts/aso-astro-evidence.json`
- Stores validated: 37, covering every ASC metadata locale through storefront mapping

## Decision rule

Astro popularity 5 and below is effectively zero. Keep a pop-5 term only when it is the exact category anchor or a deliberate phrase-combination component. Do not spend indexed fields on generic population-volume words merely because they are popular.

## US evidence

| Query | Popularity | Difficulty | Decision |
|---|---:|---:|---|
| VO2 max | 7 | 23 | Primary category anchor, lead in name |
| fitness age | 9 | 38 | Best relevant secondary opportunity, lead in subtitle |
| cardio tracker | 27 | 68 | Relevant but competitive, form through name plus keyword combinations |
| HealthKit | 19 | 66 | Relevant indexed keyword |
| athlete tracker | 6 | 49 | Small but above the zero-value floor |
| Apple Health | 60 | 56 | High-volume platform term, use once in subtitle |
| fitness tracker | 50 | 84 | Generic and extremely competitive, do not chase directly |
| workout tracker | 62 | 74 | Misleading because the app does not log workouts, reject |
| running tracker | 55 | 79 | Misleading because the app does not log runs, reject |
| VO2 Max widget and trend phrases | 5 | mixed | Effectively zero alone, useful only as combinations from indexed words |

Competitor extraction for `vo2 max` returned generic words such as calculator, coach, plans, AI, and training. These were rejected because the app reads Apple Health estimates and does not calculate VO2 max, coach workouts, or create training plans.

## English ASC fields

- Name: `VO2 Max & Cardio Fitness` (24)
- Subtitle: `Fitness Age & Apple Health` (26)
- Keywords: 94 to 100 characters, deduplicated against name and subtitle

Every locale targets 24 to 30 characters for name and subtitle and 94 to 100 characters for keywords. `scripts/validate-metadata.py` enforces these limits and catches duplicate indexed words.

## Cross-store validation

Astro confirmed storefront-specific demand differs substantially. Examples:

- Germany: `VO2 max` pop 9, difficulty 13
- Spain: `VO2 max` pop 9, difficulty 7
- Japan: `VO2 max` pop 9, difficulty 5
- Brazil: `VO2 max` pop 9, difficulty 9
- France: `VO2 max` pop 6, difficulty 11

Localized fields therefore keep the exact VO2 anchor and native cardio/fitness intent rather than copying a generic English portfolio to every store.

## Follow-up

The app cannot rank before release, so current rankings are 1000. Recheck at day 7, day 14, and day 30 after release. Promote queries that break into the top 100 and have popularity above 5. Remove unranked pop-5 terms unless they support an intentional phrase combination.

Run:

```bash
./scripts/aso-validate-astro.py
./scripts/validate-metadata.py
```
