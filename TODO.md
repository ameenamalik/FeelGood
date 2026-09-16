# FeelGood Engineering Roadmap & Tasks (TODO)

This document tracks upcoming engineering milestones and architectural enhancements for FeelGood. It serves as the single source of truth for in-flight and planned engineering tasks.

---

## 🚀 Next Up — v2

- [x] **Fix `aps-environment` for release.** [`FeelGood.entitlements`](FeelGood/FeelGood.entitlements) was
  set to `development`, which would have silently broken push notifications
  for real users. Flipped to `production` (2026-09-15). Note: the same
  entitlements file is shared by both the Debug and Release build configs
  (`CODE_SIGN_ENTITLEMENTS` in `project.pbxproj`), so local Debug runs from
  Xcode will no longer receive dev-environment pushes — if that's needed
  again, split into `FeelGood-Debug.entitlements` /
  `FeelGood-Release.entitlements` and wire them per config instead of
  flipping this back.
- [ ] **Tighten the paywall copy and value prop.** `FeelGoodPaywallView` wraps RevenueCat's `PaywallView`, so this is a dashboard content edit, not a code change — cut wordiness and sharpen why Pro is worth it.
- [ ] **Admin — add Ameena's card to App Store Connect** to cover the upcoming Apple Developer Program renewal fee. (Account/billing task, not engineering — flagging here so it doesn't get lost.)
- [ ] **Configure the OneSignal dashboard side of gentle re-engagement**, 2026-09-16. Client-side plumbing is done (`OneSignalManager.setEngagementTrigger`, wired from `TodayModel.requestCopyUpgrade` off the same `HistoryStats.daysSinceLastCompleted` `CopyPayload` already sends). Two dashboard pieces remain, both content/config, not code:
  1. **Push (Automated Message / Journey)** targeting OneSignal's built-in "Last Session" condition — no client trigger needed for this half, OneSignal tracks it natively per subscribed device.
  2. **In-App Message** gated on the local trigger key `days_since_last_session >= 5` (`OneSignalManager.engagementTriggerKey`; `5` matches `PlanEngine.reentryGapDays`, the same threshold the engine already uses for a shorter/warmer re-entry menu — one definition of "gap" everywhere).
  Copy for both, confirmed with Ameena: no reference to absence at all (no "we miss you" / "it's been a while") — per `CLAUDE.md`'s no-gap rule, an invitation, not a callout of time passed.

### Pre-submission polish pass (product review feedback, 2026-09-16)

Scoped with Ameena via AskUserQuestion, 2026-09-16. Three independent items —
UI, catalog/copy microcopy, and check-in — kept separate below since they
touch different layers (view, content, Engine types).

- [x] **Replace the completed-item strikethrough with opacity + checkmark
  badge.** (2026-09-16) `TodayView.swift:808` dropped
  `.strikethrough(isDone, color: FGColor.clayDeep)` on the session title.
  `MenuItemBody` already had a checkmark badge (`DoneMark`, a
  checkmark.circle.fill + "Done" pair) sitting in the top metadata row, so
  no new component was needed there — added `.opacity(isDone ? 0.6 : 1)` on
  the whole card instead for the "quieter, not crossed off" read.
- [x] **Microcopy/catalog audit pass — hustle-culture language and
  countdown-anxiety phrasing.** (2026-09-16) Ran a full grep pass over
  `catalog.json` titles/subtitles/step names/cues for
  circuit/sweat/grind/crush/burn/beast/hardcore/shred/killer/intense/
  brutal/torch/blast/smash/destroy/hustle/grit-type language. Two real
  hits, both fixed; everything else that matched ("Blast your favorite
  track" — literally playing music loud; "Core & lunge burn" and sauna
  "sweating" — accurate physical-sensation language inside a session
  someone chose at "Energized"/strong intensity, not guilt framing) was
  left alone as correctly describing real content, not hustle-coding it.
  - `catalog.json:3982` `main-sweat-investment` → title now **"Full-body
    strength circuit"** (was "Sweat investment circuit"). Checked the
    session's actual steps first — it's a real 30-min kettlebell/bodyweight
    circuit (intensity 4, `energyFit: strong`, full/lowerBody/core focus),
    not low-impact, so the reviewer's "Low-impact core & sculpt" suggestion
    didn't fit the content; kept a name that's still accurate. `id` left
    unchanged (not referenced elsewhere, but no reason to churn it).
  - `catalog.json:341` `app-farmers-carry` → title now **"Farmer's carry"**
    (was "Carry something heavy"). Judgment call: this is a real,
    distinct exercise (grip/strength `qualities`, its own subtitle "Three
    minutes that your grip will thank you for") — not a desk-strain
    catalog gap, so it was renamed for clarity rather than swapped out for
    "Shoulder & neck drop"/"Wall angels", which are a different movement
    pattern and already exist in `main-desk-worker-posture-flow`. Flagging
    in case Ameena actually meant "delete this exercise, add those two
    instead" rather than "this title reads gym-bro."
  - `Display.swift:424` `detailedSummaryPhrase` — "target" → **"window"**.
  - `TodayView.swift:341` — `"\(min) min left"` → **"Room for \(min) min"**.
  - Out of scope, left untouched: `ChatService.swift`'s `QuickFilter
    .canNotLeave` chip also reads "Staying in" — that's a different type
    (chat quick-pivot, not the check-in's `PlaceIntent`) in a more casual
    context; not touched since the ask was about the check-in screen.
- [x] **Check-in copy pass — energy label, location labels, no engine
  changes.** (2026-09-16) `Energy` ([`PlanTypes.swift`](FeelGood/Engine/PlanTypes.swift))
  was already a 3-case enum (`.low`/`.steady`/`.strong`) matching the
  chosen 3-point scale — no new case needed. Relabeled in
  [`Display.swift:208`](FeelGood/Features/Display.swift:208):
  `checkInLabel` `"Empty"` → **"Depleted"** (`.steady`/`.strong` labels
  already matched "Steady"/"Energized"). Also fixed the
  `ChoiceGridPreview` in `Components.swift` which had stale/inconsistent
  preview labels ("Empty"/"Strong") — now "Depleted"/"Steady"/"Energized"
  to match.
  - **"Where are you" relabel — done for the 3 labels, one gap left open.**
    `PlaceIntent` ([`Display.swift:286`](FeelGood/Features/Display.swift:286))
    relabeled: `.stayingIn` → **"Living room / Mat"**, `.happyToGoOut` →
    **"Outdoors"**, `.atTheGym` → **"Gym / Studio"**. **Still open, needs
    Ameena's call:** the requested 4th category "Desk / Office" has no
    existing `PlaceIntent` case — decide whether to fold it into
    `.stayingIn`'s label (lose the desk-specific tag) or add a genuine 4th
    case (touches `PlaceIntent.places`, `PlanEngine` matching, and
    `EngineBoundaryTests`/`PlanEngineTests`, not just a label). Not
    implemented either way yet.
  - **Body check-in granularity — deferred, separate Engine ticket.**
    `BodyState` ([`PlanTypes.swift:179`](FeelGood/Engine/PlanTypes.swift:179))
    is `sore, stiff, stressed, cramping, good` — no distinct
    neck/shoulders, low-back/pelvic, overstimulated, or low-sleep cases.
    `cramping` already exists and, per `CLAUDE.md`'s allow-list rule, must
    stay filtered as a work-around and never surface as a `ReasonCode` —
    any new case (esp. anything pelvic-floor-adjacent) needs the same
    privacy review before it ships, not just a UI add. Do **not** bundle
    this into the pre-submission pass; track separately once the allow-list
    impact is scoped.

### PlayerView feedback (handwritten notes, 2026-09-14)

**Owned by Ameena.**

- [x] **Mid-hold "switch sides" alert.** For timed exercises done on both
  sides, add an explicit alert partway through the hold (haptic/visual, not
  just a silent timer, and not something buried at the end of the cue
  paragraph) telling someone to switch sides — right now `PlayerView` has
  no concept of a side switch mid-step, so the only way to know is to have
  already read to the end of `step.cue`.
- [x] **Bigger countdown digits.** The running timer (`timeString` in
  `PlayerView.running(_:)`) is too small to read at a glance mid-movement.
- [x] **Let the 5-second "get ready" countdown be paused, skipped, or made
  longer.** `readingCountdown` currently only offers "Start now" (skip) —
  no way to pause it, and 5 seconds is too short to actually get ready.
- [x] **Make the exercise cue easier to digest mid-workout.** `step.cue` renders
  as one body-text paragraph; nobody reads a paragraph while working out —
  needs a shorter/more scannable format.

Resolved with Ameena, 2026-09-15:
- [x] Session-start flow (Today → `SessionDetailView` → `PlayerView`) stays
  as multiple screens — intentional, `SessionDetailView` (steps preview,
  rename/hide, start/resume) is doing real work distinct from the player.
  No change.
- [x] "Exercises listed above" confirmed to mean `SessionDetailView`'s
  preview list of steps before starting — already exists, nothing to build.
- [x] **Cap/split held steps over ~2 minutes.** Ameena, verbatim: "the ones
  that are longer than 2 min, bc i keep looking at the screen to see if
  its done. its not rlly normal for someone to do an exercise STRAIGHT for
  3 min." Scoped to static holds/exercises only (confirmed with Ameena) —
  continuous cardio/activity blocks (walk, bike, swim, climb, hike) and
  passive soaks (sauna, shower) keep their long single steps by design, and
  rep-counted strength/gym sets (`reps`/`sets` present) were left alone
  since `PlayerView` already renders those as a tap-through counter, not a
  countdown clock, so the "staring at the screen" complaint doesn't apply.
  Split 45 steps across 14 sessions (`main-pilates-core-20`,
  `main-pilates-full-30`, `main-mobility-20`, `main-yoga-flow-20`,
  `main-desk-worker-posture-flow`, `main-sweat-investment`,
  `des-guided-foam-rolling`, and standalone dessert/side stretch steps) so
  every timed step is ≤120s, preserving `glossaryID` per sub-step and
  setting `switchSides: false` explicitly on the new steps to avoid
  double-firing the existing mid-hold switch-sides alert. Splitting
  `main-desk-worker-posture-flow`'s combined-name steps ("Chest opener &
  wall angels", "Low lunge pulses & thoracic twists", "Glute bridge holds &
  pelvic tilts") also incidentally does half of Yusra's separate "split
  combined exercise steps" item below for this session — "Standing quad
  stretch & side body reach" (`catalog.json:3064`) is untouched since it
  was already under 120s, still Yusra's to split. All 275 `FeelGoodTests`
  pass.

### Voice notes feedback, 2026-09-14 (new)

- [x] **Fix menus exceeding the time budget.** Reported three times as the
  same underlying bug got progressively narrowed: "5 minutes available"
  giving 3-4 items; a 30-minute target giving 55 minutes (appetizer 5 +
  main 30 + side 20); and after the first round of fixes, a 35-minute
  target still giving 48 minutes. Two distinct root causes, both in
  `makeMenu` ([`PlanEngine.swift`](FeelGood/Engine/PlanEngine.swift:61)):
  1. `isEligible` only ever checked each candidate individually against
     `checkIn.time.maxMinutes`, so a main, `sideCount` sides, a guaranteed
     appetizer, and a guaranteed dessert that each fit alone could stack
     past the budget combined. Fixed with a running `usedMinutes` total
     that bounds sides and course selection against what's actually left.
  2. Once that was fixed, the "always something to offer" floor fallback
     for the appetizer/dessert (`guaranteedAppetizer`/`guaranteedDessert`)
     still reached for the *first* catalog match (or, briefly, the
     top-scored match with no duration cap at all) rather than the
     *shortest* eligible one — so hitting that fallback could add up to a
     whole dessert's worth of unrelated overshoot. Fixed: the fallback now
     picks the shortest eligible item under a ceiling of the *whole*
     check-in budget (never the original ceiling, but allowed to exceed
     what's merely left of it — that's the guarantee's whole point).
  Specials still ignore the budget entirely (intentional — planned ahead).
  `alwaysOffersAnAppetizer` and `neverFailsAcrossTheCheckInMatrix` still
  hold (an appetizer is always offered); dessert has no such promise and
  can now legitimately be absent when nothing fits. Locked in with a new
  regression test, `totalMenuDurationStaysNearBudget` — all 43
  `PlanEngineTests` pass.
- [ ] **Allow "0 minutes available" as a check-in option**, for rest/recovery
  days. `TimeBudget` ([`PlanTypes.swift:125`](FeelGood/Engine/PlanTypes.swift:125))
  has no zero case — `.fiveMinutes` is the floor — so the picker at
  [`CheckInSheet.swift:609`](FeelGood/Features/CheckIn/CheckInSheet.swift:609)
  can't offer it. Needs a `.none`/zero-minute `TimeBudget` case that
  short-circuits `makeMenu` to an empty/rest-day menu rather than forcing
  a 5-minute floor.
- [ ] **Optional sound/voice cues in `PlayerView`**, off by default or
  user-toggleable — a mute/unmute affordance like Google Maps' voice
  toggle (tap to cancel, icon reflects on/off state), for people doing a
  session with others around or who just don't want audio. Confirmed
  2026-09-15: still wanted, not urgent — keep queued, no rush.
- [ ] **Split combined exercise steps in the catalog.** **Owned by Yusra** —
  next up now that the custom-routine cluster above is done. Some catalog steps
  merge two distinct exercises into one step/cue, e.g. in
  `main-desk-worker-posture-flow` ([`catalog.json:3004`](FeelGood/Content/catalog.json:3004)):
  "Chest opener & wall angels" (`catalog.json:3043`), "Low lunge pulses &
  thoracic twists" (`catalog.json:3053`), "Standing quad stretch & side
  body reach" (`catalog.json:3064`). This is a content fix, not a
  `PlayerView` rendering fix — each should become two separate `Step`
  entries with proportioned durations. Needs a pass over the rest of
  `catalog.json` for the same pattern, not just this one session.
- [x] **Let a custom ("own") session take an optional description**, **Owned
  by Yusra.** Done in `5664143` (2026-09-14) — `Session.own(...)` takes a
  `description` param that becomes the subtitle, falling back to an empty
  string instead of the hardcoded "Yours".
  - [ ] **Later version:** let a custom session also take an optional photo.
- [x] **A custom routine added to today's menu has no "Start" button and no
  internal timed parts — only "I did this."** **Owned by Yusra.** Done in
  `5664143` (2026-09-14): added `CustomRoutinePart` and a new
  `SessionSource.custom(steps:)` case ([`OwnSession.swift`](FeelGood/Content/OwnSession.swift)),
  so `isOwn` now means "editable by its author," not "has no steps."
  `AddRoutineSheet.swift` got the requested add-as-you-go flow (name the
  routine, add one timed part at a time, Reminders-style), and
  `SessionDetailView` now shows Start/Resume → `PlayerView` for a custom
  routine with parts, keeping "I did this" only for the old zero-step log.
  Covered by new tests in `OwnWorkoutTests.swift` and `PersistenceTests.swift`.
- [ ] **Rework the "You" page's insights/metrics section**, discussed
  2026-09-15. This isn't unbuilt — `LookBackView`/`Reflection`
  ([`LookBack.swift`](FeelGood/Engine/LookBack.swift),
  [`LookBackView.swift`](FeelGood/Features/LookBack/LookBackView.swift))
  already does the "generated text observation, no numbers/charts" thing
  and is fully wired, just hidden from `YouView` since `318dad5`
  (2026-09-14, "temporarily remove insights/LookBackView section").
  Ameena's read on the real copy ("Seven times in the last two weeks." /
  "You move in the morning, mostly." / "Pilates and stretching, mostly." /
  "You keep coming back to the stretching sessions." / "And you make room
  for the gentle ones."), verbatim: **"literally all of those [problems] —
  these are so vague I hate it. users try tapping on them, it does
  nothing, too much reading. most of them are vague and do not add
  value."**
  - **Resolved direction (supersedes the old one):**
    1. **One consolidated insight, not five cards.** Pick the single most
       interesting true thing from `Reflection.notes` and show only that —
       needs a "best note" ranking, not the current "show everything
       `reflect()` found" behavior in `LookBackView.notes`.
    2. **Name real things, not just activity categories.** "Pilates and
       stretching, mostly" is still a category-level statement — prefer
       referencing an actual session (title from `HistoryEntry.sessionID`)
       where the underlying note supports it, e.g. `keepsReturningTo`
       naming the specific session rather than the `Activity` case.
    3. **Make it actionable.** People already try tapping the card and
       nothing happens — that mismatch is worse than a flat card would be.
       Wire a tap to go somewhere real (e.g. `keepsReturningTo` opens that
       activity/session in the Library), rather than flattening the
       styling to look less tappable.
  - Still has to stay inside `CLAUDE.md`'s no-tracking/no-guilt rules — no
    charts, rings, bars, streaks, scores, or rendered gaps. All of that
    holds; only the copy, cardinality, and interactivity are changing.

### Microanimations

`DesignSystem/Motion.swift` already has a reduce-motion-aware token set
(`FGMotion.settle`, `.swap`, `.gentle`, `.settleWarm`) and a few screens
(Today's menu entrance/stagger, the check-in aura pulse, `PlayerView`'s
step-start/final-stretch flashes) already use it well. Extend that same
restrained, purposeful language rather than introducing a new one:

- [x] **Player visuals: one slot, one rule.** (2026-09-15) The breathing
  orb was a full-screen background layer that overlapped the card and cue;
  it now lives in the card's visual slot like the drawn demos, breathing
  steps declare themselves (and their cadence, so box breathing is
  4-4-4-4 rather than 4-in/6-out) via `visual` in `catalog.json`, the
  name-sniffing heuristic and the orb's progress ring are gone.
- [x] **Player visuals, phase 2: glossary breadth.** (2026-09-15) Glossary
  went from 32 to 149 entries with plain-language instructions; 22 catalog
  steps now link to a drawing that matches their pose; `ATTRIBUTION.md`
  lists every bundled set. Nothing pruned — Ameena's call, the gym art
  stays for sessions not yet written.
- [x] **Custom routines get visuals too.** (2026-09-15) Typed part titles
  are matched to the glossary and breathing vocabulary when played, so a
  My Menu "Box breathing" routine gets the orb and "Push-ups" gets the
  drawing. Touches custom-routine territory (Yusra's) but only at play
  time in `PlayerView`; the builder and persistence are untouched.
- [x] **Show the "what's this?" sheet for matched custom steps.** (2026-09-15)
  `TodayModel.term(for:)` now falls back to `CustomStepMatcher` when a step
  has no authored `glossaryID`, so a custom "Push-ups" part gets the same
  explanation sheet on the detail screen that it already got in the player.
- [ ] **Player visuals, phase 3: new art for qigong, shake-outs, yoga flow,
  PMR.** Authoring plan (4–6 frame PNG sets in the house line-art style,
  Lottie only for a few whole-body loops) is in
  `docs/PLAYER_ANIMATION_PLAN.md`.

### Polish — make it perfect to share

Aimed at both App Store screenshots and Shipaton build-in-public posts —
things that make the app look finished in a still frame or a 15-second clip,
not just functionally correct:

- [ ] **Audit dark mode on every screen**, not just the ones built with
  `FGColor` tokens. The case-study audit already flagged `ExploreView` as
  hardcoding its own light-only hex palette instead of `FGColor`/
  `Course.accentGradient` — that's the first place dark mode will look wrong
  in a screenshot. Confirmed 2026-09-15: still wanted, not urgent.
- [ ] **Confirm every debug-only affordance is gone from Release** — the
  long-press-for-debug-menu hooks in `TodayView`/`YouView` are already
  commented out/`#if DEBUG`-gated; double check nothing similar slipped into
  newer screens (Chat, MenuBuilder). Confirmed 2026-09-15: worth doing.
- [ ] **A shareable moment — completed session.** Same treatment still needed
  for a just-finished session, not just Little Win badges. Gives people
  something to post from their daily practice too, not only milestones.
  Confirmed 2026-09-15: worth building.
- [ ] **Finish `docs/BUILD_IN_PUBLIC_LOG.md`** — still empty with 3 drafts
  queued unposted (already flagged above under Admin-adjacent work). Screenshots/clips of the above polish are natural post material.
  Confirmed 2026-09-15: worth finishing.
- [ ] **Sanity-pass empty and first-run states** for "looks intentional, not
  half-built": `LookBackView`'s early state is already designed for this —
  confirm Chat's empty state and a first-time Little Wins grid read the same
  way. Confirmed 2026-09-15: worth doing.

---

## 🎯 Next Priority Milestone: Adaptive Contextual Bandit Recommendation Loop

### Background & Objective
Today, FeelGood utilizes a deterministic heuristic scoring engine (`PlanEngine.swift`) that combines check-in inputs, a 14-day history window, and rolled-up affinity scores to rank candidate sessions. 

The goal of this milestone is to elevate this system into a **Dual-Objective Adaptive Contextual Bandit** that dynamically learns user preferences, balances engagement with burnout prevention, and aligns on-device selection with the AI companion on Cloudflare Edge.

---

### Key Architectural Tenets (Non-Negotiable)
1. **Privacy-First & On-Device Autonomy**:
   - The contextual bandit model, weight tensors, and user interaction histories reside **100% on-device** within SwiftData / local memory.
   - No personal health metrics or raw workout timestamps are sent to external analytics.
2. **Pure Engine Isolation**:
   - Bandit scoring and state updates must remain pure functions in `FeelGood/Engine/` (importing only `Foundation`), keeping them fast, deterministic in unit tests, and fully offline-capable.
3. **Guilt-Free Absence Philosophy**:
   - In accordance with PRD §7.4 and `CLAUDE.md`, skipping is **never penalized** ($r = 0.0$). Absence triggers gentle re-entry support rather than degradation of learned affinities.
4. **Hybrid Edge Alignment**:
   - High-level learned preference vectors (e.g., preference weights across intensity, duration, and body focus) are passed coarsened through `ChatUserContext` to the Cloudflare Edge Worker (`/chat`) to ensure the LLM's conversational recommendations match the engine's current bandit state.

---

## 📋 Phased Implementation Plan

### Phase 1: Reward Function & Mathematical Specification
- [ ] **Dual-Objective Reward Modeling**:
  - Implement a dual-objective reward formulation:
    $$R(s, o) = R_{\text{satisfaction}}(o) - \lambda \cdot R_{\text{overexertion}}(s, o)$$
  - **Satisfaction Reward $R_{\text{satisfaction}}$**:
    - Completed with `.lovedIt`: $+1.0$
    - Completed with `.fine` or unrated: $+0.6$
    - Swapped away ("Not today"): $-0.2$ (treated as exploration feedback)
    - Skipped / no workout on day: $0.0$ (neutral, zero penalty)
  - **Overexertion Penalty $R_{\text{overexertion}}$**:
    - Completed with `.tooMuch`: $-0.5$ + activates recovery balance
    - Successive high-intensity sessions ($\ge 4$): scaled penalty to suppress burnout
- [ ] **Feature Representation Vector ($x_t$)**:
  - Contextual feature vector mapping: Check-in energy, available time, body state, day of week, time of day, and recent movement density.
  - Candidate session feature vector: Duration, intensity tier, activity category, movement qualities, and equipment needs.

### Phase 2: On-Device Contextual Bandit Engine (`FeelGood/Engine/Bandit.swift`)
- [ ] **Create `BanditEngine` in `Engine/`**:
  - Implement a pure Swift, lightweight Contextual Bandit (e.g., LinUCB with upper confidence bounds or Bayesian Ridge Regression / Thompson Sampling).
  - Maintains covariance matrix $A_a \in \mathbb{R}^{d \times d}$ and bias vector $b_a \in \mathbb{R}^d$ per activity or latent cluster.
  - Generates exploration bonus $\alpha \sqrt{x^T A^{-1} x}$ alongside predicted score $\theta^T x$.
- [ ] **Integrate with `PlanEngine.swift`**:
  - Augment `PlanWeights` to incorporate bandit score component without overriding safety hard filters (e.g., equipment match, physical workarounds).
  - Guarantee deterministic seed / mockable state for Swift Testing test suites.
- [ ] **Add Persistence Schema**:
  - Create `BanditStateRecord` in `FeelGood/Models/Persistence.swift` storing compact model matrices locally in SwiftData.
  - Update `SessionLog.swift` to invoke `BanditEngine.update()` upon `recordCompletion` and `recordSwap`.

### Phase 3: Hybrid Edge Worker Synchronization
- [ ] **Extend `ChatUserContext`**:
  - Add coarsened bandit weights (e.g., `preferredIntensityTier`, `topExploredActivities`, `fatigueSensitivity`) to `ChatUserContext` in `FeelGood/Services/ChatService.swift`.
- [ ] **Update Cloudflare Worker (`worker/src/chat.ts`)**:
  - Ingest coarsened bandit weights into `buildSystemPrompt()`.
  - Align `matchBestSession()` scoring coefficients in `worker/src/catalog_index.ts` with the on-device bandit's preference distribution.

### Phase 4: Verification, Simulation & Unit Tests
- [ ] **Offline Simulation Tests**:
  - Add `BanditSimulationTests.swift` testing 30-day, 60-day, and 90-day synthetic user trajectories.
  - Verify that:
    1. A user who consistently rates `.lovedIt` on 10-minute restorative yoga experiences healthy convergence without starving exploration.
    2. A user who rates `.tooMuch` experiences rapid, guaranteed de-escalation of session intensity within 24 hours.
    3. Long gaps (5+ days) smoothly transition into re-entry mode without negative weight swings.
- [ ] **Edge Compatibility Tests**:
  - Validate TypeScript compilation (`npx tsc --noEmit`) and mock worker test runs.

---

## 🔮 Future Backlog
- [ ] **Apple Watch / HealthKit Biometric Prior**: Passive sleep and resting heart rate data feeding initial baseline energy prior to check-in.
- [ ] **Dynamic Time-of-Day Context Clustering**: Automatic clustering of weekday vs weekend movement patterns.

---

## ✅ Completed

- [x] **Redesign `PlayerView`'s running screen.** **Owned by Ameena**, `90ddc60`
  (2026-09-14): countdown/counter moved to its own centered row under the
  top bar instead of sitting mid-screen; the exercise illustration replaced
  with a warm aura-gradient card (same soft pastel language as check-in
  tiles) that cycles color per step; Pause/Back/Next redone as three
  evenly-weighted circular buttons instead of a full-width Pause button
  plus a separate Back/Next row; one pause control now covers both the
  get-ready countdown and the hold, so the separate +5s button is gone.
  Also added crossfade transitions between steps and into the completion
  screen — folds into the Microanimations work below.
- [x] **Fix and relocate "I did something else."** Prominent rounded capsule button below the menu cards matching the new clean design reference. Keeps the "+" button next to "Your menu" for the dopamine menu / routine builder, shows remaining minutes inline ("14 min left"), and transitions to a completion state card with checkmark and log adjustments once an activity is recorded.
- [x] **Add profile picture support.** `YouView` currently only shows a placeholder person icon in a solid-color circle. **Owned by Yusra.**
- [x] **Let Chat show the full menu, not one routine at a time.** `ExploreView` currently surfaces a single `recommendationCard` per turn. Extend it so someone can see today's whole menu and ask questions about any item in it, rather than being limited to whatever the last recommendation was.
- [x] **Write 2-3 posts in Simone's-audience voice, not indie-dev voice.** Everything queued in `content-drafts.md` right now (origin story, submission story, paywall admission) is pitched to an ADHD/indie-dev/build-in-public audience — good for Shipaton judging, but not the "woman with 47 tabs open" persona from her brief (PRD §5). Drafts #3 ("you don't need a workout plan") and #5 (the settings tour) are the closest templates: decision fatigue, guilt-free consistency, real-life scheduling — no dopamine-menu/ADHD framing. Done as `content-drafts.md` §6 (6a–6c) — needs your read before posting, and 6b specifically waits on the paywall copy fix above so the post stays true.
- [x] **Tab switches (Today/Chat/You)** now settle in with opacity + a small
  scale/rise (`TabSettleIn` in `Motion.swift`) instead of a flat fade, and it
  re-arms on every switch rather than firing once. **Needs a visual pass on
  a physical device/simulator tap-through** — could only verify by build +
  static screenshot, not interactively (no Accessibility/Screen Recording
  permission for computer control in this session).
- [x] **Marking a menu item "Done"** — `DoneMark`'s checkmark now has a
  `.symbolEffect(.bounce)` on insertion, layered onto the existing
  scale/opacity capsule transition.
- [x] **Little Wins unlocking** — the card's existing pulse now pairs with a
  quick tilt-and-settle spring on the mascot image itself
  (`LittleWinsView.swift`), timed just under the pulse so they read as one
  gesture.
- [x] **Chat messages and the recommendation card** already transitioned in;
  added transitions for the typing indicator (scale+fade) and quick-reply
  chips (scale+fade when the set changes) in `ExploreView.swift`.
- [x] **Onboarding progress bar** (`OnboardingView.swift`) now fills
  left-to-right per segment instead of snapping.
- [x] **A shareable moment — Little Win card.** `LittleWinsView.swift` now
  wraps `UIActivityViewController` to share an unlocked badge as a clean,
  on-brand image. **Owned by Yusra.**
