> Latest: [complete glossary expansion](complete-library-expansion.md). Current catalog: 207 sessions, 340 entries, 311 linked sets, 11 blocked image mismatches. Earlier counts below are historical.

> Coverage snapshot below predates the library additions. See [current utilization](demo-utilization.md), [remaining unused demos](remaining-unused-demos.md), and [varied new sessions](varied-library-additions.md).

# Exercise demo audit — 2026-09-28

Scope: current local checkout, catalog, renderer, Xcode resource membership, and current upstream manifest. No app files changed. This is file coverage and PNG integrity verification, not a visual pose-quality review or a simulator build.

## Findings

- 167 glossary exercises: 138 have bundled frame sets, 29 do not.
- 311 local sets / 933 PNG files; all sets have frames 1–3. No Lottie JSON demos.
- All 302 upstream Workout Guide slugs have local PNG frame sets. No exact upstream matches for the 29 missing IDs. This does not rule out differently named or adapted poses.
- PNG signatures, chunk checksums and compressed pixel streams checked: 0 errors.
- No dangling glossary IDs. Xcode uses synchronized folder membership, with no demo-folder exclusions.
- Existing attribution and old animation-plan coverage counts are stale.
- Draft SVGs and Paper artboards are not bundled demos; the runtime resolves numbered PNGs or Lottie JSON by exact glossary ID.

## Session step coverage

| Status | Step occurrences |
|---|---:|
| Linked ID with no demo or orb | 135 |
| Breathing orb | 35 |
| No ID or declared visual | 288 |
| Demo | 225 |

The 288 unlinked steps include rest, setup, free activity and mixed sequences; they are not 288 distinct exercises requiring art. Full inventory: `unlinked-steps.csv`.

## Missing catalog demos

| ID | Name | Linked step occurrences | Local SVG draft frames |
|---|---|---:|---:|
| `deep-breath` | Mindful breathing | 46 | 0 |
| `double-leg-stretch` | Double leg stretch | 1 | 0 |
| `downward-dog` | Downward-Facing Dog | 2 | 0 |
| `figure-four-stretch` | Figure four | 14 | 0 |
| `forearm-stretch` | Forearm stretch | 5 | 0 |
| `full-body-shake` | Full-body shake | 11 | 0 |
| `legs-up-the-wall` | Legs up the wall | 6 | 0 |
| `low-lunge` | Low lunge | 8 | 0 |
| `neck-side-stretch` | Neck side stretch | 6 | 0 |
| `pelvic-tilt` | Pelvic tilt | 12 | 0 |
| `pilates-swimming` | Pilates swimming | 1 | 0 |
| `qigong-cloud-hands` | Cloud hands | 1 | 0 |
| `qigong-drawing-the-bow` | Drawing the bow | 2 | 0 |
| `qigong-holding-the-ball` | Holding the ball | 1 | 3 |
| `qigong-turning-the-waist` | Turning the waist | 1 | 3 |
| `roll-down` | Roll down | 1 | 3 |
| `roll-up` | Roll-up | 1 | 3 |
| `rolling-like-a-ball` | Rolling like a ball | 1 | 3 |
| `side-kick` | Side kick | 2 | 3 |
| `single-leg-circle` | Single leg circle | 1 | 3 |
| `single-leg-stand` | Single leg stand | 5 | 3 |
| `single-leg-stretch` | Single leg stretch | 5 | 0 |
| `spine-stretch-forward` | Spine stretch forward | 2 | 3 |
| `standing-leg-lift` | Standing leg lift | 1 | 3 |
| `supine-hamstring-stretch` | Hamstring stretch | 6 | 3 |
| `swan-prep` | Swan prep | 2 | 0 |
| `the-hundred` | The hundred | 5 | 0 |
| `thoracic-rotation` | Book opener | 8 | 0 |
| `tree-pose` | Tree pose | 2 | 0 |

Mindful breathing (`deep-breath`) is a special case: steps explicitly declaring a breathing cadence already use the orb. A separate figure demo may not be necessary.

## Missing links to existing glossary entries — examples

These require content review and linkage, even after artwork is added:

- `main-pilates-core-20` / Roll ups → `roll-up`.
- `main-pilates-full-30` / Roll ups → `roll-up`; Double leg stretch → `double-leg-stretch`; Leg lifts → `side-lying-leg-raise` (already bundled).
- `app-morning-qigong` and `main-qigong-20` / Turning the waist → `qigong-turning-the-waist`.
- `main-qigong-20` / Cloud hands → `qigong-cloud-hands`; Holding the ball → `qigong-holding-the-ball`.
- `app-loaded-carry-anything` and `app-farmers-carry` / Walk and Walk again → `farmers-carry` (already bundled).
- `app-jump-rope-ninety` / Thirty more → `jump-rope` (already bundled).

## Additional movement candidates outside the glossary

Named steps also lack IDs/art assignments. Review the cue and variant before selecting a demo; do not substitute a similar-sounding exercise automatically.

- Shoulder rolls / shoulder circles; ankle circles; wrist circles; finger fan and fist.
- Knees-to-chest rocking; lying spinal twist; seated spinal twist; thread the needle.
- Standing hip circles; standing hip-flexor reach; standing glute squeeze; supported deep squat / hip pry.
- Standing or seated side reach; standing knee-to-elbow; step jacks; easy marching.
- Pilates roll-over, scissors, side-lying leg circles, seated spine twist, and knee fold.
- Qigong drawing down; loose arm swings; body wave; golf swings; spiral reach; full-body tapping.

## Sources

- Local: `FeelGood/Content/catalog.json`, `FeelGood/Content/ExerciseDemos`, `ExerciseDemo.swift`, `StepVisualView.swift`, project.pbxproj.
- Upstream manifest: https://github.com/bryllim/workout-guide/blob/main/packages/workout-guide/manifest.json
- Upstream snapshot saved as `upstream-manifest.json`.

## Recommended order

1. Link unambiguous steps to existing demos.
2. Finish/import missing catalog artwork; prioritize frequently referenced moves such as figure-four stretch, pelvic tilt, low lunge and thoracic rotation.
3. Add glossary entries and artwork for the extra named movements after pose review.
4. Keep setup/rest/free-activity steps without demos where appropriate.
