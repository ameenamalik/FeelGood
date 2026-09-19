# Player animation plan

Audit date: 2026-09-15. Numbers come from `Content/catalog.json` and
`Content/ExerciseDemos/` and should be re-run (script at the bottom) before
anything here is quoted.

## What is wrong today

There are two unrelated animation systems on the running screen, and they
behave differently:

| Step type | Where the motion lives | Placement |
|---|---|---|
| Exercise with a bundled demo (`glossaryID` + PNG frames) | `ExerciseDemoView` **inside** the aura card, under the step name | Reserved 220pt slot; never touches the cue |
| Breathing step (detected by name/cue heuristic) | `SessionBreathingProgress`, a **full-screen background layer** with the orb positioned at screen centre | Sits behind the card and the cue text; the "Box breathing" screenshot is this overlap |
| Everything else | `SessionLiquidProgress` waterline, full-screen background | Background wash, no shape, fine |

Three specific defects:

1. **The orb overlaps the text** because it is a background layer, not card
   content. Nothing about its position is aware of the card.
2. **The orb ignores the cue's own rhythm.** It is hard-coded to 4 s in /
   6 s out with no hold, so "Inhale 4, hold 4, exhale 4, hold 4" is animated
   as a 10-second wave. The label says "Breathe out" while the cue says hold.
3. **The orb's thin progress arc is a ring.** CLAUDE.md says no rings. The
   waterline already carries step progress for every other step.

Smaller things the audit turned up:

- `isBreathingStep` is a string heuristic. It fires on "Catch your breath"
  (a rest between jumping-jack bursts) and "Splash & breathe", and misses
  `app-box-breathing` entirely (its steps are named "Round one" and the cue
  says "In for four", which matches none of the strings). Content should
  declare its own visual, not be sniffed.
- Lottie support exists in code but **zero** Lottie files are bundled. Every
  demo on screen is a 2–3 frame PNG crossfade at 600 ms, which reads as a
  slideshow rather than movement.
- 951 PNG files (32 MB) ship in the bundle; **290 exercise sets are
  unreferenced** by any glossary entry.

## Coverage

339 steps across 77 sessions.

| Bucket | Steps | What shows today |
|---|---|---|
| Has `glossaryID` and a bundled PNG set | **80** | Line-art flipbook in the card |
| Has `glossaryID` but no asset | 0 | — |
| Breathing step (heuristic) with no `glossaryID` | **23** | Full-screen orb behind the text |
| No `glossaryID`, no breathing match | **236** | Name on a plain aura card |

### Glossary entries that have a demo (all 32, all PNG, none Lottie)

bent-over-row, calf-stretch, cat-cow, chest-press, childs-pose, chin-tuck,
dead-bug, doorway-chest-stretch, farmers-carry, figure-four-stretch,
forearm-stretch, glute-bridge, goblet-squat, jump-rope, lat-pulldown,
leg-press, legs-up-the-wall, low-lunge, neck-side-stretch, overhead-press,
pelvic-tilt, plank, romanian-deadlift, seated-cable-row, side-plank,
single-leg-stand, single-leg-stretch, skater-bound, supine-hamstring-stretch,
the-hundred, thoracic-rotation, tree-pose.

Most-used on screen: farmers-carry (6 steps), figure-four-stretch (5),
calf-stretch (5), neck-side-stretch (4), glute-bridge (4), childs-pose (4),
doorway-chest-stretch (4).

### Sessions by how much of them is animated

Fully or mostly covered (demo on every movement step): `app-hip-openers`,
`side-calf-stretch-kettle`, `side-gym-pull-8`, `main-mobility-20`,
`main-gym-floor-30`, `main-strength-full-30`, `main-pilates-core-20`,
`main-pilates-full-30`, `side-desk-shoulder-reset`, `app-neck-shoulder-release`.

Zero animation, but they are real movement sessions (highest-value gaps):
`app-desk-chair-squats`, `side-desk-micro-squats`, `app-desk-hip-glute-reset`,
`app-jumping-jacks-two`, `app-shake-out-five`, `app-power-explosions`,
`main-mindful-yoga-flow`, `app-morning-qigong`, `main-qigong-20`,
`side-stretch-and-breathe`, `side-aromatherapy-reset`, `dessert-pmr-ten`,
`app-box-breathing`, `dessert-gratitude-scan-five`.

Zero animation and that is probably correct (the step is "go do the thing"):
all 11 walking sessions, the 5 dance sessions, biking, swimming, skating,
racquet, climbing, `spec-spa-sauna-cycles`, `des-luxury-recovery-soak`,
`special-reformer-class`, `main-local-studio-session`,
`spec-performance-coaching`, `main-sweat-investment`.

### Unlinked steps that already have a matching PNG set on disk

These need only a `glossaryID` on the step, a glossary entry, and a line in
`ATTRIBUTION.md`. No new art. Hand-checked against the unused sets:

| PNG set (exists, unused) | Steps it would cover |
|---|---|
| `bodyweight-squat` | app-desk-chair-squats / Hover squats ×2; side-desk-micro-squats / Counter-tap tempo squats |
| `calf-raise` | side-toothbrush-calf-raises / Slow calf raises; side-desk-micro-squats / Calf raise pumps |
| `jumping-jack` | app-jumping-jacks-two / Burst interval one, Burst interval two |
| `cat-cow` (already in glossary) | main-mindful-yoga-flow / Cat-cow & gentle spinal waves |
| `standing-quad-stretch` | main-desk-worker-posture-flow / Standing quad stretch & side body reach |
| `kneeling-hip-flexor-stretch` | app-desk-hip-glute-reset / Standing hip flexor reach (R, L). Pose differs (kneeling vs standing); check before wiring |
| `figure-four-stretch` (in glossary) | app-desk-hip-glute-reset / Seated figure-4 hip stretch |
| `forearm-stretch` (in glossary) | side-desk-wrist-reset / Forearm flexor stretch; app-desk-escape-stretch / Wrist circles & forearm stretch |
| `side-lying-leg-raise` | main-pilates-gentle-10 / Side-lying leg lifts (R, L) |
| `reverse-crunch` | main-pilates-gentle-10 and dessert-living-room-floor-unwind / Knees to chest |
| `seated-forward-fold-stretch` | main-pilates-core-20 / Spine stretch; main-pilates-full-30 / Spine stretch and twist |
| `crunch` | main-pilates-core-20 / Roll ups; main-pilates-full-30 / Roll ups and roll overs. Loose match, a Pilates roll-up is not a crunch |
| `torso-twist-stretch` | side-aromatherapy-reset / Gentle standing twists |
| `toe-touch` | side-stretch-and-breathe / Soft forward fold |
| `thoracic-rotation` (in glossary) | main-mindful-yoga-flow / Reclined spinal twists |
| `step-up` | side-stairs-step-ups / Rhythm step-ups, Side step-ups |
| `arm-circles` | side-stretch-and-breathe / Shoulder circles |
| `shrug` | app-neck-shoulder-release and side-doorway-chest-opener / Shoulder rolls. Shrug is a hold, rolls are a circle; weak match |
| `wall-sit` | main-desk-worker-posture-flow / Supported deep squat hold |
| `doorway-chest-stretch` (in glossary) | main-desk-worker-posture-flow / Chest opener & wall angels |
| `high-knees` | app-shake-out-five / Shake legs & hips. Weak, only if nothing better |

That is roughly **30 more steps** animated with existing licensed art, taking
coverage from 80 to about 110 movement steps.

### Unlinked steps that need new art

No PNG set exists, and these are the movements people actually do in the
"zero animation" sessions above:

- **Qigong** (12 steps, 2 sessions): Lifting the sky, Turning the waist,
  Drawing down, Cloud hands, Holding the ball, Standing. One drawn set of
  five poses covers both sessions.
- **Shake-outs** (7 steps): Shake arms & wrists, Shake legs & hips, Full body
  shake, Rest & shake out ×3, Set down and shake out.
- **Progressive muscle relaxation** (`dessert-pmr-ten`, 6 body-part steps) and
  **gratitude scan** (4 steps): a lying figure with a highlighted region.
  One asset with a parameter, not ten assets.
- **Yoga flow** (`main-yoga-flow-20`, `main-mindful-yoga-flow`): Standing
  sequence, Twists, Down dog and lunges, Vinyasa & warriors, Yin hip openers,
  Savasana.
- **Neck / shoulder release**: Slow neck rolls, Thread the needle,
  Chest opener, Ankle circles, Wrist circles.
- **Power pose** (`app-power-pose-two`): Take up space, Ground & soften.

### Breathing steps (23 by heuristic, plus `app-box-breathing`'s four rounds)

All get the orb once it lives in the card. The ones whose cue names a
cadence need that cadence in data:

- dessert-barefoot-breath / Box breathing: 4-4-4-4
- app-box-breathing / Round one to four: 4-4-4-4 (currently not detected as
  breathing at all)
- app-cold-water-splash / Long slow exhale: short in, long out
- app-sunlight-strut / Deep rhythmic breathing
- everything else: the default 4 in / 6 out is right

Steps the heuristic catches that should probably **not** get the orb:
`app-shake-out-five` / Catch your breath ×2 and `app-jumping-jacks-two` /
Breathe & recover are recovery gaps in a cardio session, not a breathing
exercise. A declared visual fixes this for free.

## The plan

### Phase 1: one slot, one rule (fixes the screenshot) — DONE 2026-09-15

Shipped as described below. `Step.visual` (`StepVisual` / `BreathingCadence`
in `ContentTypes.swift`), `StepVisualView` owns the card's slot,
`BreathingOrbView.swift` holds the orb, label, and the pure
`BreathingCycleState`; `SessionBreathingProgress` and `isBreathingStep`'s
name heuristic are gone. 20 steps are tagged in `catalog.json`. Covered by
five new `CatalogTests` cases and `BreathingCycleTests`. Verified on an
iPhone 16 simulator on the "Box breathing" step: orb under the name, cue
under the card, "Hold" label during the holds.

Every step's card is `name` + optional visual slot + nothing else. The cue
always sits below the card. Nothing full-screen except the waterline.

1. **Declare the visual in content.** Add an optional `visual` object to
   `Step` in `catalog.json`:

   ```json
   "visual": { "type": "breathing", "inhale": 4, "holdIn": 4, "exhale": 4, "holdOut": 4 }
   ```

   Types: `breathing` (with optional cadence, default 4/0/6/0) and, later,
   `region` for PMR. Movement demos keep using `glossaryID`; no change.
   Delete `isBreathingStep` once every breathing step is tagged. This is a
   `Content/` change plus a `Models/` decode change; `CatalogTests` gets a
   case that every breathing step has a positive cadence and that the four
   `app-box-breathing` rounds carry one.

2. **Move the orb into the card.** `ExerciseDemoView` becomes
   `StepVisualView` with one resolution order: bundled Lottie → PNG
   flipbook → breathing orb (from `step.visual`) → nothing. Same 220pt slot
   the demos already reserve, so the card is the same height whether it
   shows a figure or an orb. The orb keeps its aura colour, its
   `TimelineView` clock, and pause/resume behaviour; it loses the progress
   arc. `BreathingPhaseLabel` stays where it is (under the cue) and reads
   the same cadence, so "Hold" becomes a real phase with a real label.

3. **Delete `SessionBreathingProgress`.** Breathing steps get
   `SessionLiquidProgress` behind them like every other step. One
   background, one card, one cue.

4. **Reduce Motion:** orb rests at its mid scale, label reads "Breathe
   slowly". Already the behaviour, just carried across.

Estimated size: one focused session. Touches `PlayerView.swift`,
`ExerciseDemoView.swift`, the `Step` model, `catalog.json`,
`CatalogTests.swift`.

### Phase 1b: custom routines — DONE 2026-09-15

Routines built in My Menu turn each typed part into a step with context-aware
cues (e.g. steady movement or breathing) and no glossary id or visual, so they
never had a drawing or an orb on any build. `Step.inferringVisual(from:)`
(`Content/OwnSession.swift`) now matches a typed title against glossary
names and aliases (whole words, longest wins, plural-tolerant) and against a
small breathing vocabulary (box/square → 4-4-4-4, 4-7-8 → 4-7-8, any other
"breath" → default). Applied by `PlayerView` at play time for `.custom`
sources only, so already-saved routines get it too. Authored steps never
pass through it. Covered by `CustomStepMatcherTests`.

Also by Ameena's call the same day: breathing steps show the orb alone, with
no waterline behind them.

### Phase 2: glossary breadth — DONE 2026-09-15

Decision (Ameena, 2026-09-15): **nothing gets pruned.** The app covers gym,
Pilates, yoga, recovery, and rest, so the bundled drawings stay for sessions
not yet written. Instead:

- The glossary grew from 32 to 149 entries, each with a plain-language
  name, four instructions, and muscles in everyday words. Selection leaned
  toward what FeelGood sessions would actually name: home bodyweight moves,
  stretches, bands, dumbbell and kettlebell basics, the common machines,
  and gym cardio. Left out on purpose: heavy barbell variants, advanced
  calisthenics (pistol squats, dragon flags, handstand push-ups), and
  near-duplicate cable and Smith machine variants.
- 22 catalog steps now link to a drawing that genuinely matches their pose.
  Rows from the table above that were marked weak (shoulder rolls → shrug,
  roll-ups → crunch, knees to chest → reverse crunch, deep squat hold →
  wall sit, standing hip flexor reach → kneeling stretch) were not linked.
- `ATTRIBUTION.md` now lists every bundled frame set, since the files ship
  either way and CC BY-SA applies to distribution.

The remaining 173 sets without a glossary entry have no glossary entry yet. Adding one
is a `catalog.json` edit; `workout-guide-metadata.json` has the name,
equipment, and muscle data for all of them.

### Phase 3: a way to make new animations

Two formats are already supported; the question is only which to author in.

**Recommended: keep PNG flipbooks as the coverage format, and raise the
frame count.** The system is licensed, shipped, and adding a demo is
dropping files in a folder. What makes it read as a slideshow is 2–3 frames
at 600 ms. Options, cheapest first:

- Author new sets at **4–6 frames** and let `ExerciseDemoView` pick its
  interval from the frame count (600 ms for 3 frames, about 350 ms for 6) so
  the bounce reads as a movement.
- For the "needs new art" list, generate frame sets in the house line-art
  style (white strokes, transparent field, one figure, no props) with an
  image model, using the existing Everkinetic frames as the style
  reference. Generate the start and end pose first, approve those, then
  ask for the in-betweens so the figure stays consistent. Own art, no
  attribution burden, same pipeline. The prompt format in
  `docs/design/character-candidates-2026-08-31/README.md` is the template.

**Lottie, for the few that matter most.** `ExerciseDemoView` already plays
`{glossaryID}.json` and recolours it to the ink token at runtime. The
LottieFiles Creator MCP is configured in this environment but was not
connected during this audit ("No Creator tab is connected"). Open
creator.lottiefiles.com, enable MCP, and simple stroke-based figures can be
built with tool calls (shapes, motion paths, keyframes, `vectorize_image`
to bring an existing PNG frame in as a starting silhouette). Export is from
Creator's own UI, not the MCP. Worth it for the whole-body loops where a
smooth continuous motion matters: Shake-out, Cloud hands, the PMR lying
figure, Savasana. Not worth it for 30 stretches.

**Not recommended:** a rigged SwiftUI stick figure, or Rive. Both are a new
system for a problem the existing two already solve.

### Phase 4: activity-level fallbacks (optional, after Shipaton)

For the roughly 190 "go do the thing" steps (walk, dance, shower, sauna,
song one/two/three), a single gentle loop per `Activity` (a walking figure,
a swaying figure, water) keyed off `session.activity` when the step has no
visual of its own. Restrained, six or seven assets total, and the card
stops looking empty on a 20-minute walk. Explicitly not a priority over
Phases 1 to 3.

## Re-running the audit

Save as `scripts/audit_demos.py` if it is worth keeping:

```python
import json, os, re
c = json.load(open('FeelGood/Content/catalog.json'))
a = os.listdir('FeelGood/Content/ExerciseDemos')
ids = {re.sub(r'-\d+\.png$', '', f) for f in a if f.endswith('.png')} | {f[:-5] for f in a if f.endswith('.json')}
with_ = without = 0
for s in c['sessions']:
    for st in s['source'].get('steps', []):
        if st.get('glossaryID') in ids: with_ += 1
        else: without += 1
unused = ids - {g['id'] for g in c['glossary']}
print(f"steps with demo {with_}, without {without}, unused sets {len(unused)}")
```
