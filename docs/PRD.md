# FeelGood — Product Requirements Document

**A daily wellness companion that answers one question: what should I do today?**

| | |
|---|---|
| **Version** | 0.1 (pre-build) |
| **Date** | 2026-08-20 |
| **Owner** | Ameena Malik |
| **Creator partner** | Simone Sharice (@sundaiolivepilates) |
| **Competition** | RevenueCat Shipaton 2026 — Influencer Award track |
| **Platform** | iOS (SwiftUI), App Store |
| **Ship deadline** | Live on the App Store by 2026-09-30 |

---

## 1. The problem

Simone said it precisely in her brief:

> "It's not that women don't care about their health. It's that wellness has become super overwhelming... Women don't need more wellness advice. They need help knowing what actually applies to them."

Her audience — 94.8% women, 70%+ aged 25–44, professionals, entrepreneurs, moms, caregivers, "47 tabs open in her brain at all times" — is not short on information. They are short on **decisions already made for them**.

The failure mode of every existing wellness app is that it hands the user *more* to decide: a library to scroll, a program to commit to, rings to close, a streak to protect. Each of those is another tab open in an already-full brain.

**The gap:** nobody has built the thing that opens and says *here is today, it's small, it fits, start here.*

---

## 2. The product in one paragraph

FeelGood opens to **today's menu** — not a library, not a feed, not a dashboard. A ten-second check-in (how's your energy, how much time do you actually have) produces a short, warm, personalized menu of movement and recovery drawn from what *you* have available: a Pilates flow, a qi gong sequence, a walk, a stretch, a dance break, a swim. One main thing. A couple of small things. And always a two-minute option for the days that are a lot. You pick, you do it, you tell it how that felt, and tomorrow's menu is better because of it.

---

## 3. The core metaphor: the wellness menu

The structure is borrowed from the **ADHD dopamine menu** — a technique for people whose executive function is taxed. Instead of a to-do list (which demands decisions), you get a *menu* (which offers a small set of pre-approved options at different effort levels). It reduces the cost of starting, which is the actual bottleneck.

Mapped to wellness:

| Menu course | What it is | Effort | Example |
|---|---|---|---|
| **Appetizer** | The two-minute version. Always present. Never optional-feeling. | 2–5 min | Four rounds of box breathing. Neck and shoulder release. |
| **Main** | The one real thing for today. | 15–45 min | A Pilates class, a qi gong sequence, a strength session, a bike ride. |
| **Sides** | Pairs with something you're already doing. | 5–10 min | Calf stretch while the kettle boils. Walk the call instead of sitting it. |
| **Dessert** | Purely for the joy of it. Counts as much as anything else. | Any | Dance to three songs. Skate. A long shower and legs up the wall. |
| **Specials** | Needs planning, so it's surfaced *ahead* of the day. | Any | Swim on Saturday. The 8am reformer class Thursday. |

**The rule that makes this work: the menu is never longer than one screen and never scrolls.** Three to five items, maximum. If we ever need to add a "see more," we have failed the brief.

---

## 4. Principles (and explicit anti-goals)

### Principles
1. **One decision, already narrowed.** The app's job is to remove options, not present them.
2. **The smallest version always exists.** A day where you did two minutes is a day you showed up.
3. **Fits the life you actually have.** Ten minutes with a toddler on the mat is a first-class input, not a compromise.
4. **Say why.** Every recommendation carries a plain-language reason. Trust comes from legibility, not magic.
5. **Warm, never clinical.** The voice is a friend who knows your week, not a coach with a clipboard.

### Anti-goals — things we deliberately will not build
- ❌ **No streaks.** No flame, no counter, no "don't break the chain."
- ❌ **No guilt mechanics.** No missed-day badges, no "you haven't been here in 6 days," no red.
- ❌ **No rings, scores, or completion percentages.**
- ❌ **No calorie, weight, or body-composition tracking.**
- ❌ **No leaderboards, no social comparison.**
- ❌ **No infinite library as the home screen.**
- ❌ **No 30-day programs** that fail the moment life interrupts them.

> Most fitness apps run on shame. This one explicitly does not. The absence of streaks is not a missing feature — **it is the wedge.** After a two-week gap, competitors say "your streak is gone." FeelGood says "welcome back — here's something small." That moment is the single most important interaction in the product, and we design for it on purpose.

---

## 5. Target user

**Primary persona — "the woman with 47 tabs open"**
35–44 (37.2% of Simone's audience) or 25–34 (33.6%), US-based (76.6%). Works, or runs something, or parents, or all three. Owns a mat. Maybe owns weights. Has followed Simone for years and trusts her. Has downloaded four fitness apps and deleted four fitness apps — not because they were bad, but because each one asked her to become a different person with more free time.

**What she needs from us:** to open the app at 7:14am with fifteen minutes and a kid asking for cereal, and be told exactly what to do, and have it be doable, and have it not make her feel behind.

**Secondary:** 45–54 (18%) — same needs, more emphasis on mobility, joints, recovery, and lower-intensity modalities like qi gong and walking. The activity mix must serve her without ever labeling anything "beginner" or "modified."

---

## 6. Activities & content

### Activity taxonomy (v1)
Pilates · Yoga · Qi gong · Strength training · Stretching / mobility · Walking · Biking · Swimming · Skating · Dance · Jump rope & plyometrics · Agility drills · Carries & hangs · Racquet sports · Climbing · Martial arts / tai chi · Breathwork & recovery (legs-up-the-wall, wind-down, sunlight, forest walking, grounding, bath/sauna)

### Movement qualities — the cross-cutting dimension

Activities answer *what you do*. **Qualities** answer *what it develops* — and they're what the engine actually balances across. Every session is tagged with one to three:

| Quality | Develops | Typical sessions |
|---|---|---|
| `strength` | Load-bearing capacity | Weights, resistance Pilates |
| `mobility` | Range and tissue quality | Stretching, yoga, qi gong |
| `endurance` | Sustained output | Walking, biking, swimming |
| **`impact`** | Bone loading | Jump rope, plyometrics, short run intervals, skater bounds |
| **`agility`** | Reactive, multi-directional movement | Ladder drills, racquet sports, footwork |
| **`coordination`** | New motor patterns, neuroplasticity | Dance, martial arts, climbing, skating |
| **`grip`** | Carry capacity and hand strength | Farmer's carries, rucking, bar hangs |
| `balance` | Proprioception | Single-leg work, tai chi |
| **`downRegulation`** | Nervous-system recovery | Breathwork, forest walking, grounding, legs-up-the-wall |

The four bolded rows are the genuine gaps in a Pilates-and-walking-centred routine — the things a controlled, linear, low-impact practice never touches. Adding them as *qualities* rather than as five more app sections is the whole trick: **the user never sees a taxonomy.** She sees one extra line, occasionally:

> *"Your last two weeks have been all low-impact. Ninety seconds of jump rope?"*

That is the anti-overwhelm version of the longevity conversation — not a lecture, not a new tab, just one small thing surfaced at the right moment. See §7.3 for the coverage signal that drives it.

**Two guardrails on this:**
- **Safety gating is mandatory.** `impact` and `grip` sessions are hard-filtered by the work-arounds from onboarding. For this audience specifically — women 35–54, many postpartum — pelvic floor, joints, and pregnancy are not edge cases. Nothing bouncy is ever surfaced to someone who flagged them.
- **Education, not medical claims.** We can say impact loading is how bones stay strong. We cannot say it prevents or treats osteoporosis, and we never diagnose. Copy stays in wellness register, never clinical.

**The sport-shaped ones** — pickleball, climbing, jiu-jitsu — are **Specials**, not Mains. You don't get handed rock climbing at 7:14am; you plan it. The Specials course already exists for exactly this, so they slot in with no new machinery.

### Place — the dimension that decides whether a menu is usable at all

Equipment answers *what you have*. **Place answers where you are, and where you
are willing to go** — which on a real Tuesday is the difference between a menu
that gets used and one that gets closed.

| Place | What it means |
|---|---|
| `home` | The mat, the floor, the kitchen counter. Needs nothing but the room you're in. |
| `outdoors` | You're willing to put shoes on and leave: walking, biking, sunlight, a park. |
| `gym` | Equipment you don't own — racks, machines, a lap pool in a leisure centre. |
| `studio` | Somebody else's class, at somebody else's time. Reformer, mat classes, martial arts. |
| `pool` | Its own place because access is binary and rarely spontaneous. |

Most sessions are tagged with more than one — a walk is `outdoors`, a bodyweight
strength session is `home` *and* `gym`. **Every appetizer is `home`**, without
exception, because the two-minute option must survive the worst possible day.

Place is both a profile answer ("what's realistically available to me") and a
daily one ("today, I am not leaving the house"). The engine treats it as a hard
filter in exactly the same way it treats time and equipment: a gym session
offered to somebody who has already decided not to leave is not a suggestion,
it's noise.

### Two content sources

1. **Simone's YouTube library** — her real Pilates and wellness videos, embedded via the official YouTube player. These are the **Mains**: the substantial 15–45 minute sessions. This is the brief taken literally ("It might bring together Pilates classes, recovery, and other parts of a person's journey"), it requires no content deal to start, and it sends her views.
2. **Authored micro-sessions** — the 2–10 minute Appetizers, Sides, Desserts, and recovery blocks that don't exist as videos and shouldn't. These are ours: structured steps driven by an in-app timer. They're also the **offline path**, which matters because YouTube isn't one.

### A third layer: the movement glossary

Sessions tell her *what* to do. A glossary answers *"what even is a dead bug?"* — the question that quietly ends a session for anyone who didn't grow up in gyms.

**Source: [`yuhonas/free-exercise-db`](https://github.com/yuhonas/free-exercise-db)** — 873 exercises, **Unlicense (public domain)**, no attribution required, commercial use fine. Each entry carries a name, step-by-step instructions, muscles worked, and two photos.

**We take the text. We leave the photos.**

The instructions are genuinely good. The photography is a dark gym, dramatic lighting, visible abs, sports bra, performance register — a beautifully shot image of exactly the thing this app is positioned against. A woman standing in her kitchen at 7am with fifteen minutes does not need a comparison trigger next to the instruction. That image is the aesthetic of every app she has already deleted.

So v1 ships the glossary **text-only**: name, plain-language steps, plain-language muscles.

The step-timer player separately shows a looping line-art animation where one exists, sourced from Everkinetic (CC BY-SA 4.0, via Bryl Lim) rather than drawn in-house — this shipped ahead of schedule and supersedes the "stretch goal, v2" framing this section used to carry. Coverage is partial by design: dead bug, glute bridge, goblet squat, plank, and side plank so far, added by dropping numbered PNGs into `Content/ExerciseDemos/` with no code change, growing toward the ~80-ish moves as time allows. See `Content/ExerciseDemos/ATTRIBUTION.md` for the license terms this carries forward.

**Three rules keep it from becoming the problem it solves:**

1. **It is a glossary, not a library.** No tab, no browse, no search on the home screen. The only way to reach a glossary entry is by tapping a step name inside a session she is already doing. 873 browsable exercises is precisely the overwhelm the app exists to remove.
2. **We ingest only what we reference.** Not 873, not the 546 that are plausibly at-home — the ~80–120 moves our authored micro-sessions actually name. A `Step` that doesn't resolve simply shows no "what's this?" affordance.
3. **Its vocabulary never surfaces.** The dataset labels moves `beginner` / `intermediate` / `expert` and tags `force: pull`, `mechanic: compound`. None of that reaches the screen. "Expert" next to a move she was about to try is a shame vector, and gym taxonomy is the register we are deliberately not writing in.

**What it does not cover:** zero Pilates entries, zero qi gong. It cannot touch the Mains. Where it earns its place is strength, stretching, plyometrics, and carries — which is exactly where the newly added `impact` and `grip` qualities live, and exactly where a Pilates-first audience has the least vocabulary.

**Bonus, and not a small one:** it gives us a *vetted naming vocabulary* for authoring. Writing 35 micro-sessions against canonical move names that already resolve to an explanation is meaningfully faster than inventing names and then having to explain them — and that matters in a 4.5-week window.

### Content model
Every recommendation is a `Session` — one unit, two possible sources.

```
Session
  id, title, subtitle
  activity            (pilates | qigong | strength | jumpRope | ...)
  qualities           [impact, grip, coordination, ...]   ← drives coverage
  durationMin         (2 | 5 | 10 | 15 | 20 | 30 | 45)
  intensity           1...5
  energyFit           [low, steady, strong]
  equipment           [none, mat, weights, band, rope, bike, pool, skates, outdoor, gym, reformer]
  places              [home, outdoors, gym, studio, pool]   ← where it can happen
  bodyFocus           [full, core, lowerBody, upperBody, back, hips, neckShoulders]
  contraindications   [pregnancy, postpartum, pelvicFloor, knees, wrists, lowBack]
  intent              [energize, strengthen, calm, mobilize, joy, play]
  course              [appetizer, main, side, dessert, special]
  source              .authored(steps: [Step])
                    | .youtube(videoID: String, channel: String)

Step
  name, seconds, cue
  glossaryID          String?   ← resolves to an ExerciseTerm; nil = no affordance

ExerciseTerm          (public-domain glossary, text only)
  id, name, aka[]
  instructions[]      plain steps
  muscles[]           plain language, not gym taxonomy
  creator             Creator?    ← name + channel link, shown on every video session
```

**v1 ships ~40 curated YouTube sessions + ~35 authored micro-sessions**, both as bundled JSON seeded into SwiftData on first launch and versioned for later remote delivery. Curating her library means watching and tagging: duration, activity, qualities, intensity, equipment, contraindications, and — critically — verifying `status.embeddable` is true per video.

### ⚠️ YouTube compliance — the constraint that shapes monetization

Embedding public YouTube videos is explicitly permitted. Four rules come with it, and one of them is load-bearing:

| Rule | What it means for us |
|---|---|
| **"You cannot charge people a fee for services that are offered free of charge on YouTube."** | **Her videos can never sit behind the Pro paywall.** Not one of them. |
| No downloading or offline caching | Video sessions require a connection. The authored micro-sessions carry offline. |
| Don't block, modify, or replace ads | Standard embedded player, ads intact, playback controls unmodified. |
| Must add independent value | The plan *is* the independent value — see §10. |

This does not damage the business model; it confirms the one already chosen. **We sell the decision, not the video.** The policy's own standard — that a service must add value beyond what YouTube provides free — is a fair description of what FeelGood does: YouTube has her whole library and no opinion about which one you need this morning. We supply the opinion.

**Marketing is a separate question from embedding.** Embedding public videos needs no permission; implying partnership does. Until Simone says otherwise, the app and store listing describe FeelGood as *built for her community*, never as made with, endorsed by, or in partnership with her. In-app, every video session carries her name and a link to her channel — proper attribution, and it drives traffic back to her.

**Content authoring is on the critical path.** 50 sessions × ~8 steps each is real writing work, budgeted explicitly in the timeline (§13).

**Attribution guardrail.** Simone said in her brief that her library *might* be included one day. Until that is confirmed in writing, v1 content is **authored by us, attributed to no one, and worded generically.** The `attribution` field stays `nil`. Nowhere in the app, the store listing, or the demo video do we state or imply that Simone wrote, taught, endorsed, or reviewed a session — that would be a false endorsement claim about a real, named professional and an App Store metadata violation. The app is built *for* her audience and *from* her brief; that is the honest framing and it is a strong one. The moment she signs off, `attribution` and `video` populate and the app gets meaningfully better with zero code changes.

### Accessibility, Adaptive Movement & Global Diversity Roadmap (Post-Hackathon)

While the v1 catalog provides non-clinical contraindication filtering (`lowBack`, `knees`, `wrists`, `pregnancy`, `postpartum`, `pelvicFloor`, `fatigue`) and low-barrier equipment/location accessibility, broader physical disability suites and global movement traditions are planned for subsequent milestones:

1. **Adaptive & Seated Movement Taxonomy (v2)**
   - **Seated & Chair-Only Flows:** Dedicated authored session tracks for users with limited standing tolerance, wheelchair users, and post-surgery rehabilitation.
   - **Upper-Body & Core Isolation:** Explicit tags for non-weight-bearing lower limbs, eliminating floor-transfer friction.
   - **Audio-Only & High-Contrast Mode:** Enhanced voice cues and screen-reader accessibility for visually impaired users without requiring screen glance during movement.

2. **Global & Cross-Cultural Movement Traditions (v2+)**
   - Expanding beyond Western fitness and contemporary Pilates to embrace traditional mind-body systems (e.g., expanded Qi Gong, Tai Chi, Ayurveda-inspired mobility, traditional African dance, and folkloric somatic recovery).
   - Multi-generational pacing: specialized low-impact flows crafted for older adults and postnatal recovery that never use clinical, patronizing, or "modified" labels.

---

## 7. Personalization

### 7.0 Product introduction — three screens, then onboarding

Before the first profile questions, a one-time three-screen introduction tells
one continuous story in the same warm wash and typography as onboarding:

1. **What FeelGood is:** “A menu for whatever kind of day you’re having.” No
   streaks, scores, guilt, account prompt, or sign-in link.
2. **What the person tells us:** energy, time, and place—the small amount of
   daily context needed to make a useful decision.
3. **What FeelGood gives back:** one Main, a few Sides, and something small
   enough to begin.

“Make it mine” moves directly into the availability-first onboarding below.
Completing the introduction is remembered on-device, so abandoning the profile
questions does not replay the marketing screens on every launch.

### 7.1 Onboarding — "what's available to you?" (≤ 90 seconds, 4 cards)

Framed around *availability and reality*, never around goals-as-metrics.

1. **What do you have access to?** Multi-select activities + equipment **+ places** (home · outdoors · gym · studio · pool). Only movement that genuinely depends on owning something or going somewhere is offered — a pool, a bike, skates, a mat, somewhere to be outside. Movement that needs nothing but a body and a floor (**qi gong, breathwork, carries, footwork**) is deliberately *not* on this card: nobody should have to recognise the word "carries" before they have seen a single session. Those stay in the candidate pool permanently and are recommended on merit — qi gong on a stressed evening, carries when the intent is strength. **A place implies what is in it:** ticking *a gym* stands in for the mat, weights, bands and bikes inside it and for having somewhere to lift, so it is never asked twice as a separate equipment chip. A pool is deliberately not implied by a gym — plenty of gyms have none, and a session that can't happen is worse than one that was never offered. See `Activity.isAlwaysAvailable` and `Place.impliedEquipment`. (Determines the entire candidate pool. The single most important question.)
2. **How often do you want to move?** Two rows on one card, because they are different questions and both are cheap to answer:
   - *Across the week:* Every day · Most days · A few times a week · When I can. *(Cadence target — used for gentle balancing, never for grading.)*
   - ***Within a day: how many times would you like intentional movement?*** Once, properly · A couple of times · Sprinkled through the day. *(Shapes the menu, not the workload — see below.)*
3. **What are you moving toward?** Strength · Calm · Mobility · Energy · Just showing up · Play. *(Pick one or more. A session matching any selected direction gets the `intent` weighting.)*
4. **Anything to work around?** Free-text-lite chips: lower back, knees, wrists, pregnancy/postpartum, low iron/fatigue, none. *(Filters, never diagnoses.)*

Available time is intentionally not asked during onboarding. It changes day to
day and already belongs to the daily check-in; asking it here would duplicate
the stronger, more current signal.

**Why "how many times a day" is a real question and not a second cadence slider.**
It changes the *shape* of the menu rather than its size. Somebody who wants one
proper session gets a hero Main and very little else. Somebody who wants
movement sprinkled through the day gets the same total minutes rearranged — two
or three Sides and an Appetizer, each attached to something already happening
(the kettle, the school run, the call). Same person, same twenty minutes,
completely different menu.

This matters for the target user specifically: "47 tabs open" rarely means one
free 30-minute block. It usually means five loose five-minute ones, and no
existing app is shaped for that.

It is never a target and never counted back. Asking for three moments and doing
one is not a partial anything — the day still just shows what fits.

No account required. No email gate. No paywall in onboarding. First menu appears before any ask.

### 7.2 The daily check-in — two taps, ten seconds

This is the ritual the whole product hangs on.

- **Energy:** running on empty · steady · strong
- **Time:** a little (≤10) · some (~20–30) · plenty (45+)
- *(optional)* **Where:** staying in · happy to go out · at the gym
- *(optional)* **Body:** sore · stiff · stressed · cramping · good

The two required taps stay two. **Where** and **Body** are both optional and both
default to the profile — the ritual is still ten seconds for anyone who wants it
to be. But *where* carries more signal than almost anything else on a bad day:
"twenty minutes, running on empty, staying in" is a complete brief, and it is
exactly the sentence this product exists to answer.

Then the menu regenerates in place with a warm one-liner. If she skips the check-in, we infer from history + time of day and show a menu anyway — **the app never blocks on input.**

### 7.2a What actually happened — the loop that makes it personal

The engine's history signals (variety, recovery balance, quality gaps, coming
back after a gap) are only worth having if something feeds them. Three things do:

- **Finishing or leaving a session.** Both are recorded; leaving early is a
  `skipped` outcome and is held against nothing. The optional "how did that
  feel?" tap moves a **long-memory affinity score** that outlives the
  fourteen-day history window, so "loved it" keeps counting quietly. Its deltas
  are deliberately smaller than the in-window ones — for the first fortnight
  both signals count the same event.
- **Turning something down.** A swap nudges affinity down a little, so the same
  card stops arriving. It is not a verdict.
- **Movement that happened without us.** "I did something else" logs a workout
  in three taps — what, how long, how hard — and everything the engine needs
  beyond that is inferred (`Session.own`): what it develops, what it needs, what
  energy it fits, which course it belongs to, and the same impact safety gate
  the authored catalog holds to. Optionally it is **kept**, which puts it in the
  candidate pool permanently, scored exactly like an authored session. The
  engine has no notion of "yours" versus "ours".

**Today's menu never rearranges itself underneath the person looking at it.**
Recording something changes the next menu, not the one on screen. Anything else
would mean the thing you just did vanishing as a reward for doing it.

**The profile is editable, always.** The same profile choices are reachable from
the menu. Answers are stored as given and their implications derived on read, so
unticking the gym takes the weights with it.

### 7.3 The planning engine — deterministic rules, LLM voice

**Architecture decision: the rules engine picks; Claude only writes the framing.** The engine is pure, offline, instant, and unit-testable. The language model never chooses what she does with her body — it makes the choice feel warm. This keeps us fast, cheap, safe, and demo-proof.

**`PlanEngine` inputs**
- Profile: available activities, equipment, cadence target, realistic time, intent, work-arounds
- Today's check-in: energy, time, body
- History: last 14 days of logs — what was done, what was swapped away, what was skipped, how each felt
- Context: time of day, day of week, whether a Special is scheduled

**Scoring** — each candidate session gets a score from weighted signals:

| Signal | Effect |
|---|---|
| Time fit | Hard filter. Never recommend 30 min when she said 10. |
| Equipment fit | Hard filter. Never recommend what she doesn't have. |
| **Place fit** | Hard filter. Nothing that needs leaving the house is ever offered to somebody who said they're staying in — and nothing gym-shaped reaches somebody without a gym. Every appetizer is home-safe, so the floor of the menu never disappears. |
| **Moments per day** | Shapes the menu rather than scoring it. One-a-day weights the Main heavily and trims sides; sprinkled promotes Sides and Appetizers that attach to something already happening. Total load is unchanged. |
| Work-around safety | Hard filter (e.g. no loaded flexion for a flagged lower back). |
| Energy match | `energyFit` alignment; low energy pushes toward qi gong, walking, stretching, breathwork. |
| Recovery balance | Two consecutive high-intensity days → strongly downweight a third. |
| Variety | Same activity 3 days running → downweight. Prevents monotony without banning favorites. |
| Intent | Boosts sessions matching her chosen direction. |
| Affinity | "Loved it" boosts; "swapped away" downweights — quietly, over time. |
| **Quality coverage** | A movement quality absent for 14+ days gets a boost — surfaced as one small entry point, never a program. This is where `impact`, `grip`, `agility`, and `coordination` earn their place. |
| Cadence nudge | Below her own stated cadence → prefer shorter, easier entry points. *Never a penalty, only a gentler suggestion.* |
| Connectivity | Offline or on cellular with data saver → authored sessions only; YouTube Mains are filtered out silently. |

**Outputs:** one Main, one Appetizer, one–two Sides, one Dessert, plus any Special — each with a machine-readable **reason code** (`recoveryBalance`, `lowEnergy`, `timeConstrained`, `varietyBreak`, `returningAfterGap`, `matchesIntent`, `qualityGap`).

**Swapping is a first-class action, not a rejection.** "Not today" on any item returns the next-best candidate instantly and feeds affinity. A swap is a *success signal* — she's engaging with the decision instead of closing the app.

**The LLM copy layer** takes `{picks, reason codes, coarse state}` and returns the one-line human framing:

> *"Third day in a row you've shown up — today's a lighter one on purpose."*
> *"You've got fifteen minutes and not much left in the tank. This one's mostly floor work."*

Non-negotiable constraints:
- The screen **renders immediately** with deterministic template copy; LLM text upgrades in place when it arrives. Never a spinner, never a blocked render.
- Responses cached per `(picks + state)` signature; identical state doesn't re-bill.
- Offline / error / timeout → template copy. The user cannot tell anything failed.
- **The API key never ships in the binary.** Calls route through a minimal serverless proxy (Cloudflare Worker) holding the key server-side, with per-install rate limiting. Separate keys for dev and prod.
- Payload is coarse state only — no name, no free text, no identifiers.
- System prompt hard-bans medical claims, diagnosis, weight/body talk, and any shame framing.

### 7.4 Consistency without streaks — "The Look Back"

A soft, non-judgmental reflection available anytime:

> *You've moved 7 times in the last two weeks. Mostly mornings. Mostly Pilates and walking. The stretching sessions are the ones you keep coming back to.*

Observations, not scores. Nothing to break, nothing to lose, nothing to restore. **Gaps are not rendered.** There is no visual language in this app for "you weren't here."

The **You** tab gives those observations an editorial card treatment beneath a
quiet profile mark. It uses sentence case throughout, with no eyebrow text or
plan badge. Small labels describe the kind of observation (rhythm, mix, rest);
they never display a score, target, comparison, or streak. Account, subscription,
and profile controls remain secondary to the reflection.

**Re-entry design (critical):** returning after 5+ days triggers the `returningAfterGap` reason code, which produces a shorter, easier menu and copy in the register of *"good to see you — let's start small."* We will test this path explicitly in the demo video, because it is the clearest possible statement of what makes this app different.

---

## 8. Screens (v1)

| # | Screen | Purpose |
|---|---|---|
| 1 | **Onboarding** | 4 cards, ≤90s, ends on a real generated menu (§7.1). |
| 2 | **Today** *(home)* | The menu. Appetizer → hero Main → Sides → Dessert. One screen, no scroll. |
| 3 | **Check-in sheet** | Two-tap energy/time, optional body. Regenerates in place. |
| 4 | **Session detail** | What it is, why it was picked, what you need. Start. |
| 5 | **Player** | Step timer with cues, or video player when `video != nil`. Pausable, backgroundable. |
| 6 | **Complete** | "How did that feel?" — three faces. Feeds affinity. No score. |
| 7 | **You / Look Back** | Quiet profile header and gentle recent-pattern cards (§7.4). |
| 8 | **Library** | Browse everything, free. Deliberately *not* the home screen. |
| 9 | **Paywall** | RevenueCat remote-configured. |
| 10 | **Settings** | "What's available to you" (editable anytime), cadence, reminder time, restore purchases, privacy. |

**Notifications:** one optional daily invitation at a chosen time. Opt-in, phrased as an offer (*"Your menu's ready when you are"*), never a reprimand. No re-engagement guilt pushes, ever.

---

## 9. Design direction

Aimed squarely at the **RevenueCat Design Award** as a secondary target.

**Designed fresh, in the spirit of calm — not borrowed.** We do not use Sunday Olive's logo, type, or photography. We build an original identity that would sit comfortably beside her work. This is both the right creative call and the clean legal one: nothing in the app can be read as her brand endorsing it.

- **Mood:** warm, editorial, unhurried. Closer to a beautifully printed cookbook than to a fitness tracker. Calm is the brief — the app should feel like the quietest thing on the home screen.
- **Palette:** muted and low-contrast-warm. Soft sage/olive-adjacent green, warm cream and oat, a clay accent, deep ink for type. No neon, no black-and-lime "performance" tropes, no red anywhere (red is the color of being behind).
- **Type:** a soft serif for headlines (the menu reads like a menu), a clean humanist sans for UI.
- **Layout:** generous whitespace, large touch targets, one idea per screen.
- **Motion:** the menu items settle in gently on generation; the swap animation is a soft card exchange. Motion sells "this was chosen for you."
- **No data visualization anywhere.** No charts, no rings, no bars. This is a stated design constraint.
- Full accessibility pass: Dynamic Type to XXL, VoiceOver labels on every menu item including its reason, contrast ≥ 4.5:1, reduced-motion honored.

---

## 10. Monetization (RevenueCat)

**Model: free app; Pro unlocks the personalization engine itself.**

The free tier is genuinely useful and never crippled — this matches the brand and avoids the "judges can't get past the wall" risk. What you pay for is the app *knowing you.*

**This is also the only model YouTube's policies permit**, which is a useful forcing function. Every video is free forever; the paywall sits on the engine, the memory, and the voice. A subscriber isn't buying access to content that was already free — she's buying the thing that decides, out of a hundred options and a life with no slack in it, which one is right for this particular Tuesday.

| | Free | **Pro** |
|---|---|---|
| **Simone's full video library, browsable and playable** | ✅ *(always free — YouTube policy, §6)* | ✅ |
| Authored micro-sessions | ✅ | ✅ |
| A daily menu | ✅ *(today's answers, no memory of any other day)* | ✅ |
| Guided player, logging | ✅ | ✅ |
| **Daily check-in → menu adapts to today** | ✅ *(free forever — see below)* | ✅ |
| **History-aware balancing & recovery awareness** | — | ✅ |
| **Affinity — "loved it" / "too much" carrying forward** | — | ✅ |
| Unlimited swaps | 1/day | ✅ |
| **Warm, written-for-you coaching voice** | — | ✅ |
| Look Back reflections | ✅ *(free — see below)* | ✅ |
| Custom menus (build your own Desserts/Appetizers) | — | ✅ |
| Specials — plan ahead for the week | — | ✅ |
| Home screen widget *(if time allows)* | — | ✅ |

**The line, in one sentence: free adapts to *today*; Pro remembers *you* and
gets better at it.** Confirmed 2026-08-24.
*(Revised 2026-08-24. The original draft put the daily check-in behind the
paywall from day 2. That contradicted §7.2 — the check-in is "the ritual the
whole product hangs on," and a free tier without it is a static list
indistinguishable from every app in §1 that this one is a reaction against. The
check-in is the hook and stays free forever.)*

What Pro buys is **memory, and what memory compounds into**: the fourteen days
of history the engine balances across, recovery awareness, affinity that carries
"loved it" forward, unlimited swaps, Specials, and the written voice. A free
user gets a menu that fits this morning. A Pro user gets one that knows they
lifted on Tuesday, loved the stretching, and haven't done anything for their
bones in two weeks.

The distinction is worth stating precisely, because it is also the honest sales
line: **a free menu is as good on day 90 as it was on day 1. A paid one is
not — it is better.** Free is not a worse version of the same thing; it is the
same thing without a past. Every signal Pro adds needs history to mean anything,
which is why gating them costs the free tier nothing it could have had on day 1
and gives the paid tier something that cannot be demoed, only lived. It also
sets the honest expectation for a subscription: what is being paid for is not
access to content, it is an app that is still learning.

**The Look Back is free**, despite being made of memory. It was Pro in an
earlier draft and that was the wrong call. It is the churn mechanic, not an
engagement one — its whole job is to make returning after a lapse feel like
resuming rather than starting over. Gating it puts the antidote behind a wall
for exactly the people most likely to lapse, and it is now a whole tab, so a
gated tab is a visible wall on a free tier we have promised is "genuinely useful
and never crippled."

Mechanically this is a clean seam and costs the engine nothing: free menus are
generated with `history: []` and `affinity: [:]`. `PlanEngine` stays a pure
function either way — there is no `isPro` branch anywhere inside it.

**Pricing:** $6.99/mo · **$34.99/yr** (7-day free trial).

$34.99 is the deliberate middle: it reads as "under $35" and prices the annual at ~$2.92/mo, a 58% discount that makes the yearly plan the obvious pick. We don't have to guess forever, though — **RevenueCat Offerings let us A/B test $29.99 vs $34.99 vs $39.99 remotely, with no app update and no resubmission.** Ship at $34.99, watch the first two weeks of real conversion, adjust from the dashboard. That experiment is also the most concrete thing we can point at for the HAMM Award.
**RevenueCat:** entitlement `pro`, offering `default`, packages `monthly` / `annual`. No lifetime tier — subscription only. Paywall built with **RevenueCat Paywalls (remote config)** so pricing and copy can be tuned without a build — which is also the honest answer to the HAMM Award's "smartest use of RevenueCat."

**Paywall moments** (value first, always):
1. After her **first completed session** — the earliest point she has felt something work.
2. On any Pro-gated action (second swap of the day, scheduling a Special).
3. A quiet, permanent entry in Settings.

**Never** on launch, never in onboarding, never as a full-screen interrupt before she's done anything. No fake countdowns, no manipulative pre-selected plans.

**Shipaton requirement:** submission must include a free trial *or* a promo code for judges. The 7-day trial satisfies this; we generate promo codes as a backup.

### 10.1 What Pro actually is — the split

*Written 2026-08-31, and the reason it needed writing is uncomfortable:* **every
Pro row in the §10 table is currently free.** Not by decision — by omission.
`TodayModel` hands the engine the full history and affinity regardless of
entitlement, no swap limit exists, Specials and custom menus were never built,
and the widget ships to everyone. Exactly one Pro feature is genuinely gated:
the written coaching voice. There is nothing to put on a paywall, and no amount
of paywall copy fixes a missing build.

So this is not a pricing exercise. It is the list of seams to cut, in the order
to cut them.

**The pitch, restated: Pro is not more content.** It cannot be — every video is
free forever under YouTube's terms (§6), and the authored micro-sessions are the
free tier's spine. Pro is three things, and the *categories* matter more than
the features inside them, because a category is what someone can hold in their
head in the two seconds they spend deciding:

1. **Intelligence** — a menu that learns you.
2. **Flexibility** — change the plan in seconds.
3. **Real-life context** — works around your day.

Free is a good menu for this morning. Pro is a menu that knows you, bends when
you push on it, and accounts for the day already around you.

#### Category 1 — A menu that learns you

| Capability | Tier | State today | Note |
|---|---|---|---|
| History-aware balancing (14-day window) | Pro | Shipped, **ungated** | The seam is which memory the engine is handed |
| Recovery awareness | Pro | Shipped, **ungated** | Same seam |
| Affinity — "loved it" / "too much" carrying forward | Pro | Shipped, **ungated** | Same seam |
| **Returning after a gap** | **Free** | Shipped | Non-negotiable — see the gap problem below |
| Plain-language patterns | Pro | Not built | See the patterns rule below |
| Personalised weekly reflection | Pro | Not built | Distinct from the Look Back — see below |

#### Category 2 — Change the plan in seconds

This is the category that makes the upgrade feel useful in the first minute
rather than on day fourteen, and it is almost entirely unbuilt.

| Capability | Tier | State today | Note |
|---|---|---|---|
| First swap of the day | **Free** | Shipped (unlimited) | Needs a limit before it can be a Pro line |
| Unlimited swaps | Pro | Not built | No counter exists anywhere |
| "Make it shorter" | Pro | Not built | Re-plan against a smaller time budget |
| "Make it gentler" | Pro | Not built | Intensity ceiling |
| "Give me something more energizing" | Pro | Not built | Quality bias |
| "I can't leave the house" | Pro | Not built | Place override for today only |
| Rebuild today's menu in conversation | Pro | Not built | Depends on the conversational section (§7.6, unwritten) |
| Save / favourite a session | Pro | Not built | |
| Custom Appetizers / Desserts | Pro | Not built | On the §13 cut list |
| "Surprise me" / "keep it familiar" | Pro | Not built | A variety dial over existing scoring |
| Advanced filters, kept off the home screen | Pro | Not built | Library groups by course and nothing else today |
| **"Why this?"** | **Free** | Shipped | §4: *every* recommendation says why. Never gate the reason. |

Every row above is a *constraint applied to a re-plan*. None of them is a new
kind of thinking — they are the engine, given one more thing to honour. That is
why this category is cheap to build relative to how expensive it looks on a
paywall.

#### Category 3 — Works around your day

| Capability | Tier | State today | Note |
|---|---|---|---|
| Weekly Specials | Pro | **Engine-ready, no UI** | `PlanContext.scheduledSpecials` is read by the engine; nothing in the app ever writes it |
| Calendar-aware daily check-in | Pro | **Shipped** | The availability path reads only today's event times on-device, reduces them to anonymous busy intervals, and suggests a duration the person must confirm |
| Calendar movement recognition | Pro | **Shipped** | Separate opt-in; matches a conservative movement vocabulary against event names on-device, immediately discards the names, and never counts attendance without confirmation |
| Scheduling around your week | Pro | Not built | |
| "Busy day tomorrow" | Pro | Not built | |
| Travel mode | Pro | Not built | A place + equipment override with an end date |
| Weekend planning | Pro | Not built | |
| Reminders at your preferred movement time | Pro | Not built | Push entitlement exists; no notification code anywhere |
| **Offline sessions** | **Free** | Already true | See below — this must not become a Pro line |
| Home screen widget | **Free** | Shipped, ungated | §10 marked it "if time allows"; it shipped, and gating it now costs app-group work in the widget target for one row |
| Writing or moving Calendar events | — | Not built | The first version never changes a calendar |

---

#### Six things this split gets wrong if written carelessly

**⚠️ 1. The gap problem — this amends §10.** §10 states the seam mechanically:
*"free menus are generated with `history: []` and `affinity: [:]`."* **That line
is now wrong and must not be implemented as written.** `returningAfterGap` is a
`ReasonCode` the engine derives *from history*. A free tier with no history
cannot know somebody has been away, which makes "never render a gap" and the
shorter, warmer returning menu into paid features — the exact inversion §10
rejected when it moved the Look Back to free. Gating the antidote behind a wall
for the people most likely to lapse is the one thing this product must not do.

The fix is to make memory a *shape* rather than a flag, so the engine keeps no
`isPro` branch and the free tier keeps its warmth:

- `.recencyOnly(lastActive:)` — free. Enough to know it has been a while.
  Not enough to balance activities or honour affinity.
- `.full(history:affinity:)` — Pro.

The engine stays a pure function of what it is handed. What Pro buys is a richer
argument, not a different code path.

**⚠️ 2. The patterns rule.** "Shorter sessions work better for you in the
morning" is a causal claim wearing correlational clothes. It is the identical
construction §15 permanently bans for supplements ("your energy tends to be
better on the days you take it"), and the ban does not get weaker because the
subject is session length instead of iron. The rule for "Your patterns":

> Describe **what happened**. Never assert **what works**.

"You finished six of the eight short morning sessions" is an observation.
"Short mornings work better for you" is a finding, and we are not in a position
to make findings about anybody's body. Prose only — no charts, rings, or bars
(§4), and no percentages, which are scores wearing a different hat.

**⚠️ 3. The weekly reflection is not the Look Back.** The Look Back is free
forever and this section does not touch it. Its job is making a return feel like
resuming; it is a churn mechanic, not an engagement one. The Pro weekly
reflection is additive and different in kind: it is about a week you were
present for, and it says nothing about absence. If the two ever start reading
like the same feature, the free one is the one that stays.

**⚠️ 4. Voice check-ins are the free-text problem with a microphone on it.**
Decision 15 accepted on-device redaction and Worker parsing for *typed* text,
with named obligations (owned denylist, adversarial suite, explicit consent,
tap check-in retained). Speech adds a second exposure that decision did not
cover. Two hard requirements before this ships: transcription is **on-device**
(`requiresOnDeviceRecognition`), and **no audio is ever transmitted or
retained** — the transcript enters the same redaction path as typed text and the
audio is discarded. A convenience feature is not worth a new class of data
leaving the device.

**⚠️ 5. Offline already works for everyone, and must keep working.** The
authored catalog is bundled and plays with no network today. "Offline saved
routines" as a Pro line would be gating something that currently works, which
breaks §10's promise that the free tier is "genuinely useful and never
crippled." If offline appears on the paywall at all it is as *offline
**Specials***, which are Pro because planning ahead is Pro — not because the
files stopped being local.

**⚠️ 6. The paywall may only name features that exist in the binary.**
Advertising Specials, custom menus, or voice check-ins before they ship is a
Guideline 2.3.1 rejection and a refund liability, and it costs a review cycle
we do not have. Paywall copy is generated from the shipped list, and the list is
verified at submission — not from this section, which is a plan.

---

#### The paywall itself

Three rows. Not ten. The product is simple and the wall should read that way.

> **A menu that learns you**
> Remembers what works, what doesn't, and what fits different kinds of days.
>
> **Change the plan in seconds**
> Make it shorter, gentler, more energizing, or swap anything — without starting
> over.
>
> **Works around your day**
> Optionally considers today's Calendar openings before you choose how much
> time you really have.

Then one quiet line beneath, naming only what has shipped:

> *Plus weekly reflections, voice check-ins, and unlimited swaps.*

Built with RevenueCat Paywalls (remote config), so the rows and the plus-line
move as features land without a resubmission — which is also the honest answer
to "smartest use of RevenueCat."

#### Build order

Each phase leaves a coherent product, and the paywall copy is trimmed to match
whatever has actually shipped.

| Phase | Scope | Why this order |
|---|---|---|
| **1 — the seam** | `PlanMemory` shapes, `.recencyOnly` for free, swap limit, paywall moments 1 and 2 | Without this there is no paid tier at all. Everything else is decoration on an empty wall. |
| **2 — flexibility** | Shorter / gentler / more energizing / can't leave the house, as constraint chips under the menu | Cheapest visible value per hour of work; all four are re-plans. The free versions of these chips are also the honest test of whether anyone wants them. |
| **3 — real-life context** | Calendar-aware daily check-in first; Specials and reminders later | Makes the daily recommendation fit the day that already exists |
| **4 — memory made visible** | Weekly reflection, patterns in prose | Needs weeks of real history before it says anything true |
| **5 — conversation** | Voice and free-text refinement | Blocked on §7.6, which is unwritten |

**Cut line for 1.0: phase 1 only.** Phases 2–5 are each independently cuttable,
and shipping phase 1 alone still gives an honest paywall — a menu that learns
you, and unlimited swaps — because both are true of the binary.

#### Anti-goals for Pro

Restating §4 where a paywall creates specific temptation:

- No feature is gated by making the free version *worse* than it is today.
- No countdown, no fake scarcity, no pre-selected plan.
- The reason a session was chosen is never paid. Neither is the check-in, the
  Look Back, the video library, or a session that plays offline.
- Pro does not buy more content. It buys intelligence, flexibility and
  real-life context — and if a proposed feature is not one of those three, it does not
  belong behind the wall.

---

## 11. Technical architecture

**Stack:** SwiftUI + SwiftData, Swift 6, iOS. Existing project: `FeelGood.xcodeproj`, bundle `com.ameenamalik.FeelGood`.

> ⚠️ **Deployment target must be lowered.** The project is currently set to `IPHONEOS_DEPLOYMENT_TARGET = 26.5`, which restricts the app to devices on the newest OS only — a serious reach problem for a consumer launch and for judges' test devices. **Recommend iOS 18.0.** Also bump `SWIFT_VERSION` from 5.0 to 6.0.

```
FeelGood/
  App/              entry point, DI container, root routing
  Models/           SwiftData: Profile, CheckIn, PlanDay, PlanItem,
                    SessionRecord, Affinity, ContentVersion
  Content/          bundled JSON + seeding/migration
  Engine/           PlanEngine (pure Swift, zero UI/IO deps) — fully unit tested
  Services/         ContentStore · CopyService (Claude proxy) ·
                    PurchaseService (RevenueCat) · NotificationService ·
                    LogService · CrashReporting
  Features/         Onboarding · Today · CheckIn · Player · Complete ·
                    LookBack · Library · Paywall · Settings
  DesignSystem/     tokens, components, motion
```

**Deliberate architectural choices**
- `PlanEngine` is a pure function of `(Profile, CheckIn, [History], Date) → Menu`. No I/O, no networking, no SwiftData. This makes the core product logic exhaustively testable and is what lets us guarantee it never fails in a demo.
- Every external call (Claude, RevenueCat) sits behind a protocol-backed service with a fake implementation, so the whole app runs offline in tests and previews.
- Content is data, not code. Adding Simone's real classes later is a JSON change.
- Crash reporting and persistent logging from day one, per engineering standards.

### The Claude proxy — why it exists and what it does

**The problem:** anything shipped inside an iOS binary is readable. An `.ipa` is a zip; strings are extractable in minutes. An API key in the app — in source, in a plist, in the keychain, obfuscated, doesn't matter — is a published key. Someone finds it, points their own traffic at it, and bills it to us until we notice.

**The fix:** the key lives on a server we control, and the app never sees it.

```
iOS app                  Cloudflare Worker                 Anthropic API
   |                            |                                |
   |-- POST /copy ------------->|                                |
   |   { picks, reasonCodes,    | 1. verify RevenueCat receipt   |
   |     coarseState,           |    (is this install `pro`?)    |
   |     subscriberID }         | 2. rate limit by subscriber    |
   |                            | 3. validate payload shape      |
   |                            |-- messages.create ------------>|
   |                            |   (key from Worker secret)     |
   |<-- { line: "..." } --------|<-------------------------------|
```

**Cloudflare Worker** is just a small function that runs at the edge — one file, one deploy command, no server to maintain. Free tier covers 100,000 requests/day, which is far beyond anything this app will do during Shipaton.

```typescript
// worker/src/index.ts  (sketch — exact shapes verified at implementation)
import Anthropic from "@anthropic-ai/sdk";

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const body = await req.json();
    if (!isValidPayload(body)) return new Response("bad request", { status: 400 });
    if (!(await hasProEntitlement(body.subscriberID, env))) return new Response("forbidden", { status: 403 });
    if (await isRateLimited(body.subscriberID, env)) return new Response("slow down", { status: 429 });

    const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY }); // Worker secret, never in the app
    const res = await client.messages.create({
      model: "claude-opus-5",
      max_tokens: 300,
      output_config: { effort: "low" },
      system: [{ type: "text", text: COPY_SYSTEM_PROMPT, cache_control: { type: "ephemeral" } }],
      messages: [{ role: "user", content: JSON.stringify(body) }],
    });
    return Response.json({ line: firstText(res) });
  },
};
```

**Four things the proxy buys us beyond key safety:**

1. **Server-side entitlement check.** The Worker asks RevenueCat's REST API whether this install actually has `pro` before spending a token. Free users physically cannot reach the model — cost exposure is capped by paid users, not by downloads. (This is also the "validate everything server-side, never trust the client" rule applied properly.)
2. **Rate limiting** per anonymous install ID, so a single bad actor can't run up a bill.
3. **Prompt/model changes without an app update.** The system prompt lives in the Worker. If the coaching voice is off, we fix it and redeploy in seconds — no App Review round trip. During a 6-week competition that is worth a lot.
4. **Clean dev/prod separation.** Two Workers, two Anthropic keys, two RevenueCat environments. The dev key never touches a shipped build; if it leaks, we rotate one secret and nothing in production is affected.

**Cost.** Per call: ~600 input tokens, ~100 output. On `claude-opus-5` ($5/M in, $25/M out) that's roughly **half a cent a call**; budget a full cent to be safe since adaptive thinking bills as output. A Pro user generating ~1.5 menus a day costs **~$0.20–0.45/month** against ~$2.92/month of revenue — under 15% of revenue in the worst case, and only ever incurred for paying users. Caching the stable system prefix and the `(picks + state)` response cache both push it lower. If it ever needs to be cheaper, `claude-haiku-4-5` ($1/M in, $5/M out) is a one-line change — but Opus 5 writing genuinely warm copy is a large part of what the paid tier *is*, so we start there.

**What the app sends — the complete list, not an example.** The payload is an allow-list built as a `CopyPayload` struct, so anything not named here is structurally absent rather than filtered out at the call site:

| Sent | Never sent |
|---|---|
| `picks` — session ids | `PlanCheckIn.body` (`sore` / `stiff` / `stressed` / **`cramping`**) |
| `reasonCodes` — the seven `ReasonCode` cases | `PlanProfile.workArounds` (**`pregnancy`**, **`postpartum`**, **`pelvicFloor`**, `knees`, `wrists`, `lowBack`, `fatigue`) |
| coarse state — `energy`, `time`, `daysSinceLast` | name, location, device id, session history |
| `subscriberID` — RevenueCat's app user id | name, email, or any identifier we mint ourselves |

**Why the right-hand column is drawn where it is.** `cramping`, `pregnancy`, `postpartum`, and `pelvicFloor` are reproductive health data — the most scrutinised category there is, under both App Store review and GDPR Article 9. They are load-bearing for the engine and worthless to the copy layer, which is writing one warm sentence. There is no version of that sentence worth sending them for. A test asserts the encoded JSON keys exactly, so this stays true through a refactor.

Work-arounds are applied as a *filter* — `isDisjoint(with: input.profile.workArounds)` — and never surface as a `ReasonCode`. That is deliberate and worth preserving: it means the reason channel is clean by construction rather than by redaction. (The set of picked session ids is a weak statistical proxy for what was filtered out. Noted, accepted, not worth a mitigation.)

**On `subscriberID`** *(revised 2026-08-31 — supersedes the original `anonInstallID` design)***:** it is RevenueCat's own app user id, required so the Worker can check entitlement and rate-limit. It is *pseudonymous, not anonymous*, and the honest phrasing is that rather than "nothing that identifies a person".

The original design minted a random per-install UUID and described it as "verified against RevenueCat". It could not be: nothing ever told RevenueCat that id existed, so every lookup 404'd and every paying user was silently refused. The identifier has to be read from the SDK, because the Worker's only way to ask "is this person entitled" is to ask RevenueCat about an id RevenueCat assigned.

The cost is real and worth stating plainly. Before Apple Sign In this is RevenueCat's anonymous id and the pseudonymity is unchanged. After Sign In it is the Apple user id — an opaque Apple-issued string, never an email or a name, but stable across sessions and reinstalls in a way a per-install UUID was not. It already goes to RevenueCat; this sends it to our own Worker too. That is the price of checking entitlement server-side instead of trusting the client, and §11's rule is that the client is not trusted.

**Failure is invisible.** The proxy is on a 2-second timeout. Miss it — offline, cold start, rate limit, 500, anything — and the template copy that's already on screen simply stays there. The user never sees a spinner, an error, or a retry. **The product works completely with the proxy switched off**, which is exactly why it's the last item on the cut list.

**Testing — unhappy paths are mandatory**
First launch with no data · profile with zero equipment · 5 minutes and empty energy · every candidate filtered out (fallback: always at least one Appetizer exists that needs nothing) · offline · Claude timeout/malformed response · RevenueCat unreachable · purchase interrupted · returning after 30 days · clock changes and timezone shifts. **All timestamps stored UTC, rendered local.**

**Privacy:** all personal data on-device, with one named exception — the free-text check-in is redacted on device and parsed in the Worker (§16 decision 15). No account, no analytics SDK that collects health data. The app has no outbound network path at all until the copy layer lands in W4, and works completely with it switched off after that — the claim to make is the specific one ("the engine that decides runs on your phone; the only thing that ever leaves is a line of framing copy, for paying users"), never the vague one ("private-first"), because the specific one survives the follow-up question. `PrivacyInfo.xcprivacy` completed with required-reason API declarations. App Store health-app rules: **no medical claims, no diagnosis, no treatment language** anywhere in copy or metadata.

---

## 12. Success metrics

| Metric | Target | Why |
|---|---|---|
| **Time to decision** (open → session start) | **< 20 s** | The entire thesis, measured. |
| Check-in completion rate | > 60% of opens | Is the ritual actually two taps? |
| Menu → session start | > 45% | Are the picks right? |
| Session completion | > 70% | Did we size it to her real life? |
| Swap rate | 15–30% | Healthy engagement. Near-zero means she's not looking; very high means the engine is wrong. |
| D7 return | > 35% | Does it earn a place in the morning? |
| **Return-after-gap rate** | tracked | The anti-shame thesis, measured. |
| Trial start → paid | > 25% | HAMM Award evidence. |

---

## 13. Timeline — 6 weeks (Aug 20 → Sep 30)

**Hard constraint: the app must be publicly live on the App Store by Sep 30.** Working backwards from a realistic 3–7 day App Review, everything must be submitted by **Sep 18–20**, which makes the real build window **four and a half weeks, not six.**

| Week | Focus |
|---|---|
| **W1** (Aug 20–26) | Project setup, deployment target fix, design system, SwiftData models, `PlanEngine` v1 + unit tests, content schema locked. |
| **W2** (Aug 27–Sep 2) | Onboarding, Today/menu screen, check-in, swap. **Curate Simone's library — 40 videos watched, tagged, embeddability verified.** |
| **W3** (Sep 3–9) | YouTube player integration + authored step-timer player, completion/affinity, Library, Look Back. **Author 35 micro-sessions against glossary vocabulary; ingest + prune the glossary subset.** RevenueCat integrated, paywall built. |
| **W4** (Sep 10–16) | Claude proxy + copy layer with fallbacks. Polish, motion, accessibility, unhappy-path testing. TestFlight with real users from Simone's demographic. |
| **W5** (Sep 17–20) | Store listing, screenshots (1179×2556, no device frame), 1024 icon, privacy manifest. **Submit to App Review.** |
| **W5–6** (Sep 20–30) | Review response buffer. 2-minute demo video. Devpost submission. Build-in-public posts. |

**Cut list, in order, if we're behind:** widget → Custom Appetizers / Desserts → Specials → Look Back → LLM copy layer (falls back to templates, product still works).

---

## 14. Shipaton 2026 compliance checklist

- [ ] Brand-new app, first public release inside **Aug 1 – Sep 30, 2026** (no prior public version)
- [ ] **RevenueCat SDK powers at least one real in-app purchase**
- [ ] Published to the **Apple App Store**
- [ ] Devpost submission: description, public store URL, **1024×1024 icon**, **≥1 screenshot at 1179×2556 with no device frame**
- [ ] **Public demo video ≤ 2 minutes** (YouTube/Vimeo), shows the app running
- [ ] Free trial **or** promo code so judges can reach the paid experience
- [ ] Addresses Simone's brief directly (Influencer Award judging)
- [ ] *Secondary targets:* RevenueCat Design Award, HAMM Award, #BuildInPublic

**Influencer Award judging criteria → where we answer them**

| Judges want | We deliver |
|---|---|
| Turns a wellness journey into a clear plan for today | §3 the menu, §7.3 the engine |
| Personalizes without creating more decisions | §4 principle 1, ≤5 items, no scroll |
| Balances movement, classes, recovery, real life | §6 activity mix incl. recovery, §7.3 recovery balance |
| Supportive and achievable across different lives | §7.1 availability-first onboarding, §7.2 check-in |
| Helps people act consistently, not just advises | §7.4 consistency without shame, §4 anti-goals |

---

## 15. Where this goes next (v2+)

Called out in the submission because vision is rewarded and costs zero build time now:

1. **HealthKit-informed check-ins.** Sleep, workouts, and steps as quiet engine context — briefly speced for v1 as §7.5, then cut for scope (§16 decision 18). If revisited: resting heart rate and HRV stay out regardless, since they're Watch-only, need multi-week baselines, and "your resting heart rate is elevated" sits too close to a health claim to ship without a proper review.
1a. **Supplements, via the HealthKit Medications API (iOS 26).** FeelGood has no supplement feature today — no model, no log, no reminders — so supplement-aware framing ("you haven't logged today's iron") is a product feature to build first, not a HealthKit integration. When it exists, iOS 26's Medications API is the sync path. Note the hard line that comes with it: we may observe whether something was taken, and we may never suggest it caused an outcome. "Your energy tends to be better on the days you take it" is a causal claim wearing correlational clothes, and it is out of scope permanently, not just for v1.
2. **Simone's real Pilates classes.** The content schema is video-ready today; this is a data drop, not a rebuild.
3. **Cycle-aware planning.** Menus that shift across the menstrual cycle — high-signal for this exact audience, high-sensitivity, deserves proper research.
4. **A creator content pipeline** so Simone publishes sessions herself, and the model extends to other trusted creators.
5. Android, Apple Watch, widgets, and gentle non-competitive community.

---

## 16. Decisions & what's still open

### Decided (2026-08-20)

| # | Question | Decision |
|---|---|---|
| 1 | Name | **FeelGood.** Locked — bundle ID, store listing, and design system all key off it. |
| 3 | Brand assets | **Designed fresh, in the spirit of calm.** No Sunday Olive assets used. See §9. |
| 7 | Movement glossary | **Yes — text only.** `free-exercise-db` (Unlicense) supplies instructions for the ~80–120 moves our micro-sessions name. Photos rejected on brand grounds. Reachable only from a step inside a session, never as a browsable library. See §6. |
| 4 | Content | **Both sources.** Simone's public YouTube library supplies the Mains via the official embedded player, always free per YouTube policy; we author the 2–10 min micro-sessions that don't exist as videos and carry the offline path. Attribution and link-back on every video; no claim of partnership until she says so. See §6. |
| 5 | Pricing | **$34.99/yr, $6.99/mo, $69.99 lifetime**, with remote price testing via RevenueCat Offerings. See §10. |
| 10 *(2026-08-24)* | Where the paywall sits | **Free adapts to today; Pro remembers you and gets smarter over time.** The daily check-in and the Look Back are free forever; Pro buys history balancing, recovery awareness, affinity, unlimited swaps and Specials — everything that needs a past to work. Supersedes the original §10 table. Confirmed by the founder the same day. |
| 6 | Proxy hosting | **Cloudflare Worker**, dev/prod key separation, server-side entitlement check. Fully specced in §11. |
| 5 *(2026-08-27)* | Pricing — lifetime tier dropped | **$34.99/yr, $6.99/mo. No lifetime tier.** Subscription-only; supersedes the $69.99 lifetime line in row 5. |
| 11 *(2026-08-30)* | Apple Health — scope | **Read sleep, workouts, and steps; user picks which.** Each terminates in a defined engine behaviour (`shortSleep`, `recoveryBalance`, `quietDay`/`busyDay`) — we request nothing we don't act on. Resting HR, HRV, and cycle data are explicitly out of v1. Reverses the §15 deferral. See §7.5. |
| 12 *(2026-08-30)* | Apple Health — the ask | **Intent in onboarding (card 5, skippable, no system sheet); the iOS permission sheet deferred to the first moment the signal matters.** Keeps the §7.1 promise that a real menu precedes any ask, and keeps Apple's contextual-permission guidance. If nothing is ticked, we never ask again. |
| 13 *(2026-08-30)* | Apple Health — write-back | **Yes, as two separate off-by-default features:** `HKWorkout` for completed sessions and `.mindfulSession` for breathwork and recovery. Neither is bundled into the read permission. The write→read double-count in `recoveryBalance` is a named correctness risk with a required test. |
| 14 *(2026-08-30)* | Apple Health — the off switch | **Per-signal switches plus a master off.** Turning one off purges every on-device value derived from it. Samples we wrote to Health survive by default, with an explicitly separate opt-in to delete them. In-app switches govern whether *FeelGood uses* a signal, never system access — HIG requires that distinction hold. |
| 15 *(2026-08-30)* | Free-text check-in — where it's parsed | **On-device redaction, then parsed in the Worker.** ⚠️ This knowingly reverses §11's rule that free text never leaves the device and that reproductive terms are structurally absent rather than filtered. Accepted with eyes open, with named obligations: owned denylist, adversarial test suite, explicit consent, retained tap check-in. |
| 16 *(2026-08-31)* | What Pro actually is | **Three categories — intelligence, flexibility, continuity — specced in §10.1.** Written because every Pro row in §10 was still free in the binary: the entitlement seam was never built, so there was nothing to sell. §10.1 also **amends §10's mechanical claim** that free menus use `history: []` — that would make returning-after-a-gap a paid feature. Free gets recency-only memory; Pro gets full history and affinity. |
| 16 *(2026-08-31)* | Copy proxy — which id identifies the subscriber | **RevenueCat's app user id, read from the SDK.** Supersedes the `anonInstallID` design in §11. A locally minted UUID cannot be verified against RevenueCat because RevenueCat was never told it existed — the original wiring refused every paying user, silently, because failing closed looks identical to being misconfigured. After Apple Sign In the value is the Apple user id: opaque, never an email, but stable in a way a per-install UUID was not. Accepted as the cost of a server-side entitlement check. |
| 18 *(2026-09-01)* | Apple Health — cut from scope | **Reverses decisions 11–14 and the former §7.5 in full.** Too large for this timeline — five build phases (capability read, onboarding surface, per-signal switches, a copy-layer amendment, and write-back) for a feature that touches sleep, workouts, and steps across three separate `ReasonCode`s, none of which had shipped. No HealthKit code exists in the app, so this is a scope cut, not a removal. Restores the original §15 v2+ deferral. If revisited, re-litigate the free/Pro split from scratch rather than reusing the old §7.5 spec — the split itself (health shaping *today* free, *trends* Pro) is worth keeping if the feature ever returns, but the feature is out for now. |

### Still open

**2. Simone's involvement — the one thing we don't control.**
This stays open because it isn't ours to close, and it's worth being clear-eyed about: her promotion is the single largest lever on this project's outcome, and **we should plan as though we won't get it.** Every other decision above is deliberately built to stand alone — original branding, our own content, no dependency on her library, no claim of her endorsement. If she does engage, everything gets better and nothing gets rebuilt. Concretely, the asks worth making, in descending order of value and ascending order of effort for her:

1. **A post at launch.** 665K combined following against a traction-judged Grand Prize. Costs her one story.
2. **Sign-off to attribute a handful of Pilates sessions to her.** Unlocks the `attribution` field and a much stronger store listing.
3. **Real class videos.** The `video` field is waiting; this is a data drop.
4. **A voice pass on the coaching copy** — even 20 lines in her actual register would lift the whole product.

**7. Embeddability audit.** Some of her videos may have embedding disabled, and any of them can be taken down or made private after we ship. The catalog needs a `status.embeddable` check at curation time and the player needs a graceful "this one's unavailable — here's another" fallback. Cheap to build, ugly if skipped.

**8. TestFlight testers.** We need 5–10 women from the target demographic (busy, 30s–40s, tried and quit fitness apps) testing by week 4. Worth lining up now, since recruiting takes longer than building.

**9. App Store listing copy** must avoid any health, medical, or outcome claim. Needs a careful pass before submission, not the night before.

**10. The conversational check-in needs its own PRD section.** Decision 15 settles where the sentence is parsed. Everything else about it is unwritten: latency budget against §7.3's "never a spinner, never a blocked render", offline behaviour, parse-failure fallback, what the agent may say when intent isn't matched, and how it stays inside §7.3's rule that the engine picks. It is a larger change than the Health work and should not be scoped inside it.

**11. Redaction denylist ownership.** Decision 15 only works if somebody owns the list and reviews it on a cadence. Unassigned is the same as unmaintained, and here that has a privacy cost rather than a quality one.
