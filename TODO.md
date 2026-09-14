# FeelGood Engineering Roadmap & Tasks (TODO)

This document tracks upcoming engineering milestones and architectural enhancements for FeelGood. It serves as the single source of truth for in-flight and planned engineering tasks.

---

## 🚀 Next Up — v2

- [ ] **Tighten the paywall copy and value prop.** `FeelGoodPaywallView` wraps RevenueCat's `PaywallView`, so this is a dashboard content edit, not a code change — cut wordiness and sharpen why Pro is worth it.
- [ ] **Admin — add Ameena's card to App Store Connect** to cover the upcoming Apple Developer Program renewal fee. (Account/billing task, not engineering — flagging here so it doesn't get lost.)

### PlayerView feedback (handwritten notes, 2026-09-14)

**Owned by Ameena.**

- [ ] **Mid-hold "switch sides" alert.** For timed exercises done on both
  sides, add an explicit alert partway through the hold (haptic/visual, not
  just a silent timer, and not something buried at the end of the cue
  paragraph) telling someone to switch sides — right now `PlayerView` has
  no concept of a side switch mid-step, so the only way to know is to have
  already read to the end of `step.cue`.
- [ ] **Bigger countdown digits.** The running timer (`timeString` in
  `PlayerView.running(_:)`) is too small to read at a glance mid-movement.
- [ ] **Let the 5-second "get ready" countdown be paused, skipped, or made
  longer.** `readingCountdown` currently only offers "Start now" (skip) —
  no way to pause it, and 5 seconds is too short to actually get ready.
- [ ] **Make the exercise cue easier to digest mid-workout.** `step.cue` renders
  as one body-text paragraph; nobody reads a paragraph while working out —
  needs a shorter/more scannable format.

Open questions to resolve with Ameena before scoping further (unclear from
notes, don't guess):
- [ ] Audit exercise step lengths — are current durations right?
- [ ] Why does starting/running a session take multiple screens — can it be
  consolidated?
- [ ] What does "exercises listed above" refer to — a preview list of
  upcoming exercises before/during a session?

### Voice notes feedback, 2026-09-14 (new)

- [ ] **Fix "5 minutes available" producing 3-4 items instead of a ~5-minute
  menu.** Root cause confirmed: [`PlanEngine.swift`](FeelGood/Engine/PlanEngine.swift:282)'s
  `isEligible` only checks each candidate session individually against
  `checkIn.time.maxMinutes` — there's no running total. `makeMenu` then
  independently adds a main, `sideCount` sides (default 1), a guaranteed
  appetizer, and a guaranteed dessert regardless of how much time is left,
  so a 5-minute budget can yield 3-4 separate ~5-minute items (15-20+ min
  total). Fix: track cumulative `durationMin` across selected items in
  `makeMenu` and stop adding courses once the running total meets/exceeds
  the budget, instead of bounding each item in isolation.
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
  session with others around or who just don't want audio.
- [ ] **Split combined exercise steps in the catalog.** **Owned by Yusra**
  (after the custom-routine cluster below). Some catalog steps
  merge two distinct exercises into one step/cue, e.g. in
  `main-desk-worker-posture-flow` ([`catalog.json:3004`](FeelGood/Content/catalog.json:3004)):
  "Chest opener & wall angels" (`catalog.json:3043`), "Low lunge pulses &
  thoracic twists" (`catalog.json:3053`), "Standing quad stretch & side
  body reach" (`catalog.json:3064`). This is a content fix, not a
  `PlayerView` rendering fix — each should become two separate `Step`
  entries with proportioned durations. Needs a pass over the rest of
  `catalog.json` for the same pattern, not just this one session.
- [ ] **Let a custom ("own") session take an optional description**, **Owned
  by Yusra**, instead
  of always showing the literal word "Yours". Root cause confirmed:
  [`OwnSession.swift:87`](FeelGood/Content/OwnSession.swift:87) hardcodes
  `subtitle: "Yours"` on every session `Session.own(...)` builds — there's
  no description field anywhere in the creation flow (`LoggedWorkout` /
  the "I did something else" form in `TodayModel.swift`). Add an optional
  note field to the form and `LoggedWorkout`, thread it through as the
  session's subtitle, falling back to something better than a bare
  "Yours" when left blank.
  - [ ] **Later version:** let a custom session also take an optional photo.
- [ ] **A custom routine added to today's menu has no "Start" button and no
  internal timed parts — only "I did this."** **Owned by Yusra.** Two pieces
  of the same gap:
  - Root cause confirmed: [`SessionDetailView.swift:84-100`](FeelGood/Features/Session/SessionDetailView.swift:84)
    deliberately shows "I did this" instead of "Start"/"Resume" whenever
    `session.isOwn` is true, and `isOwn` ([`OwnSession.swift:108`](FeelGood/Content/OwnSession.swift:108))
    is defined as *having no steps* (`source.steps.isEmpty`). This is
    intentional today — "Somebody's own workout has no steps to play,
    because nobody wrote any" — but it means picking a duration for a
    custom routine (e.g. a 5-minute "morning stretch") never gets a real
    running timer, only an honesty-system log-after-the-fact button.
  - What's actually wanted: let a custom routine be built from parts, the
    way authored sessions already are (`Step` — name + `seconds` + cue,
    [`ContentTypes.swift:147`](FeelGood/Content/ContentTypes.swift:147)),
    e.g. "1 min lunges, 2 min arm stretch, 1 min walking" inside one
    "morning stretch" appetizer, each part getting its own time the same
    way `SessionDetailView`'s `lineup`/`firstUpSection` shows authored
    session steps today.
  - UI shape requested: no upfront "how many parts?" question — a simple
    add-as-you-go flow, Reminders-app style: name the routine, then
    repeatedly add one item at a time (title + duration), each appearing
    in a running list as it's added, done whenever.
  - Once a custom session has real steps, `isOwn` naturally becomes
    `false` and the existing Start/Resume → `PlayerView` path in
    `SessionDetailView` should just work — this doesn't need new
    start/resume branching, only a step-authoring flow that populates
    `source.steps` for custom sessions instead of leaving it empty.
- [ ] **Rework the "You" page's insights/metrics section.** Badges and the
  top section are working; the metrics section reads flat and needs a
  redesign — but it has to stay inside the no-tracking/no-guilt rules
  already locked in `CLAUDE.md` ("No data visualisation — no charts,
  rings, or bars," "Never render a gap"). **Resolved direction:** a
  generated text-based pattern summary — e.g. "You've been leaning into
  strength and stretching lately" — built from recent session qualities.
  No numbers, no chart shape, no axis; reads as an observation, not a
  score or a streak.

### Microanimations

`DesignSystem/Motion.swift` already has a reduce-motion-aware token set
(`FGMotion.settle`, `.swap`, `.gentle`, `.settleWarm`) and a few screens
(Today's menu entrance/stagger, the check-in aura pulse, `PlayerView`'s
step-start/final-stretch flashes) already use it well. Extend that same
restrained, purposeful language rather than introducing a new one:

### Polish — make it perfect to share

Aimed at both App Store screenshots and Shipaton build-in-public posts —
things that make the app look finished in a still frame or a 15-second clip,
not just functionally correct:

- [ ] **Audit dark mode on every screen**, not just the ones built with
  `FGColor` tokens. The case-study audit already flagged `ExploreView` as
  hardcoding its own light-only hex palette instead of `FGColor`/
  `Course.accentGradient` — that's the first place dark mode will look wrong
  in a screenshot.
- [ ] **Confirm every debug-only affordance is gone from Release** — the
  long-press-for-debug-menu hooks in `TodayView`/`YouView` are already
  commented out/`#if DEBUG`-gated; double check nothing similar slipped into
  newer screens (Chat, MenuBuilder).
- [ ] **A shareable moment — completed session.** Same treatment still needed
  for a just-finished session, not just Little Win badges. Gives people
  something to post from their daily practice too, not only milestones.
- [ ] **Finish `docs/BUILD_IN_PUBLIC_LOG.md`** — still empty with 3 drafts
  queued unposted (already flagged above under Admin-adjacent work). Screenshots/clips of the above polish are natural post material.
- [ ] **Sanity-pass empty and first-run states** for "looks intentional, not
  half-built": `LookBackView`'s early state is already designed for this —
  confirm Chat's empty state and a first-time Little Wins grid read the same
  way.

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
