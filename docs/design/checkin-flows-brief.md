# Check-in flows: brief for Paper

Paste this into the Claude session that has the Paper MCP connected. It
describes six check-in flows, one per onboarding goal. **Play** already has an
artboard; match its layout, frame size, type and spacing exactly, and build
the other five alongside it. Redraw Play only if something below changes it.

---

## What's wrong with today's check-in

It reads like a form: four questions (energy, time, place, body), three
answers to the main one, and it asks how you feel *now* ("Depleted / Steady /
Energized"). People open the app wanting to feel a certain way, and three
answers is far too few to say which.

## The new shape

A check-in is **how you want to feel**, then **what kind of that**, then **how
long**. Three taps, no typing, nothing required beyond the first.

```
[1] How do you want to feel today?   → pick a goal (6 tiles, mascot on each)
[2] <goal-specific question>         → pick one of 6 feelings
[3] How long have you got?           → pick a length, or "Resting today"
    → today's menu
```

### Screen 1: "How do you want to feel today?" (shared by every flow)

- Six tiles, one per onboarding goal, each with its mascot:

  | Goal (onboarding label) | Mascot asset | Tile words |
  |---|---|---|
  | Energy | `IntentEnergyClementine` | Energised |
  | Strength | `IntentStrengthApple` | Strong |
  | Calm | `IntentCalmBlueberry` | Calm |
  | Mobility | `IntentMobilityBanana` | Loose |
  | Just showing up | `IntentShowingUpPear` | Like I showed up |
  | Play | `IntentPlayLime` | Playful |

- **It follows onboarding.** The goals picked in onboarding ("What are you
  moving toward?") come first, as larger tiles under the heading. The rest sit
  below a quiet "Or something different today" line, as smaller tiles. If
  someone picked all six, it's six equal tiles.
- Nothing is preselected. Tapping a tile moves straight to screen 2; there's
  no Next button.
- Small text link at the bottom: "Just show me my menu". It skips the check-in
  and uses yesterday's answers, or the onboarding defaults.

### Screen 2: one question per goal, six answers

Each flow's own question and six answers are below. Answers are **big tappable
cards in a 2×3 grid**: a short phrase in SF Rounded, plus a line of plain
detail in SF Pro underneath. Tapping one moves straight on. A back chevron
returns to screen 1.

### Screen 3: "How long have you got?" (shared, except Just showing up)

- Chips: **5 min · 10 · 15 · 20 · 30 · 45 · An hour**, plus a softer chip,
  **Resting today**, on its own line. Not a slider.
- Under the chips, one quiet line shows where they are, prefilled from last
  time: "At home ▾". Tapping it offers Home / Outside / Gym or studio. Only
  show it if onboarding listed more than one place.
- Under that, a text link: "Anything to go easy on?". It opens the existing
  body options (Sore / Stiff / Stressed / Cramping) as an optional sheet.
  Never on the main screen.
- Tapping a length goes straight to the menu.

---

## The six flows

Each answer lists what it feeds the engine: **energy** (derived, no longer
asked), **focus** (a body area), and the kind of session it should favour.
"Energy" is the existing `Energy` value (`low / steady / strong`), so the
engine keeps working unchanged.

### 1. Energy (Clementine): "What kind of energy?"

| Card | Detail line | Energy | Favours |
|---|---|---|---|
| Gently awake | Easing into the day | low | walking, qigong, light outside |
| Clear-headed | Fresh air and a bit of pace | steady | brisk walk, walk your call |
| Buzzing | Heart up, music on | strong | jump rope, dance, jumping jacks |
| Warm all over | Everything moving a little | steady | full-body mobility, standing strength |
| Out of a slump | Something short to shift it | low | shake-out, two-minute bursts (≤5 min) |
| Ready for a big day | A proper start | strong | morning energy, run |

### 2. Strength (Apple): "Where do you want to feel strong?"

| Card | Detail line | Energy | Focus / favours |
|---|---|---|---|
| Legs | Squats, lunges, stairs | steady | lower body |
| Middle | Core, slow and steady | steady | core, Pilates |
| Arms & shoulders | Push, pull, press | steady | upper body |
| All over | A bit of everything | steady | full body |
| Strong but kind | Nothing too heavy today | low | gentle core, standing strength |
| Properly worked | The full effort | strong | 30-min strength, gym floor |

### 3. Calm (Blueberry): "What kind of calm?"

| Card | Detail line | Energy | Favours |
|---|---|---|---|
| A quiet head | Just breathing | low | box breathing, breath pause |
| Unwound | Slow stretches on the floor | low | floor unwind, bed yoga |
| Ready for sleep | Soft and slow, lights down | low | muscle relaxation, legs up the wall |
| Grounded | Outside, feet on the ground | steady | barefoot breath, bench stretch |
| Soft shoulders | Neck and shoulders let go | low | focus: neck & shoulders |
| Back in my body | Shake it out, then settle | steady | shake-out, body scan |

### 4. Mobility (Banana): "Where do you want more room?"

| Card | Detail line | Energy | Focus |
|---|---|---|---|
| Hips | After a long sit | steady | hips |
| Back | Spine, twists, reaches | steady | back |
| Neck & shoulders | Screen-day stiffness | steady | neck & shoulders |
| Legs | Hamstrings, calves, ankles | steady | lower body |
| Wrists & hands | For after typing | low | upper body (wrist sessions) |
| Head to toe | A bit of everything | steady | full body |

### 5. Just showing up (Pear): "What would count today?"

No screen 3: every answer implies its own length. Lowest-effort flow in the
app. It should feel like permission, not a lesser option.

| Card | Detail line | Energy | Time | Favours |
|---|---|---|---|---|
| Two minutes | Tiny still counts | low | 5 | breath pause, shake-out |
| Without thinking | Just tell me what to do | low | 10 | the menu's gentlest pick |
| Lying down | Bed or floor is fine | low | 10 | bed yoga, legs up the wall |
| Some fresh air | Step outside | low | 10 | block loop, sunlight walk |
| While I do something else | Kettle, teeth, a call | low | 5 | kettle calf stretch, walk your call |
| You pick | Surprise me | steady | 15 | anything that fits |

### 6. Play (Lime): "What kind of play?"

(Reference only: the existing artboard wins where they differ.)

| Card | Detail line | Energy | Favours |
|---|---|---|---|
| Dance it out | Music on, no rules | steady | dance |
| Something bouncy | Jump, hop, skip | strong | jump rope, skater bounds |
| Explore outside | A new route, a skate | steady | discovery walk, skate |
| Quick feet | Fast and a bit silly | strong | agility, stairs |
| With someone | A game or a class | steady | pickleball, studio class |
| Surprise me | Something I wouldn't pick | steady | anything playful |

---

## Artboard layout

- One row per flow, in onboarding order: Energy, Strength, Calm, Mobility,
  Just showing up, Play. Each row is its phone frames left to right:
  screen 1 (with that goal's tile shown pressed) → screen 2 → screen 3 → the
  menu it leads to. Just showing up has three frames, not four.
- Label each row with the goal name and mascot.
- Screen 1 in each row shows the *same* onboarding state: say the person
  picked Calm and Mobility in onboarding, so those two are the big tiles at
  the top. That makes the "follows onboarding" rule visible.
- Screen 2 uses that goal's mascot small in the header and its aura colour as
  the card highlight.

## Rules the design must keep (from CLAUDE.md)

- No red anywhere, no scores, rings, streaks or progress bars.
- Nothing that implies being behind. "Resting today" is a real, warm choice.
- Every phrase is something a person would say about themselves. Address them
  as "you"; never assume gender.
- No medical claims or body outcomes in any label or detail line.
- SF Rounded for headings and card titles, SF Pro for detail lines.
- Dark mode and large Dynamic Type must still work: at accessibility sizes the
  2×3 grid becomes one column.

## What this needs from the engine (for later, not for Paper)

- `PlanCheckIn.todayIntent` already exists, so screen 1 maps directly.
- `energy`, `time`, `place` and `bodies` already exist; screen 2 sets `energy`
  instead of asking for it.
- **New:** a body-area preference on the check-in (`focus: BodyFocus?`) for
  the Strength and Mobility answers. Today `BodyFocus` is only on sessions.
- **New:** a light "favours" nudge per answer. The simplest version is a set
  of activities or qualities that get a scoring bonus, never a hard filter,
  so a thin catalog can't leave an empty menu.
