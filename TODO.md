# FeelGood Engineering Roadmap & Tasks (TODO)

This document tracks upcoming engineering milestones and architectural enhancements for FeelGood. It serves as the single source of truth for in-flight and planned engineering tasks.

---

## 🚀 Next Up — v2

- [x] **Fix and relocate "I did something else."** Prominent rounded capsule button below the menu cards matching the new clean design reference. Keeps the "+" button next to "Your menu" for the dopamine menu / routine builder, shows remaining minutes inline ("14 min left"), and transitions to a completion state card with checkmark and log adjustments once an activity is recorded.
- [x] **Add profile picture support.** `YouView` currently only shows a placeholder person icon in a solid-color circle. **Owned by Yusra.**
- [ ] **Let Chat show the full menu, not one routine at a time.** `ExploreView` currently surfaces a single `recommendationCard` per turn. Extend it so someone can see today's whole menu and ask questions about any item in it, rather than being limited to whatever the last recommendation was.
- [ ] **Tighten the paywall copy and value prop.** `FeelGoodPaywallView` wraps RevenueCat's `PaywallView`, so this is a dashboard content edit, not a code change — cut wordiness and sharpen why Pro is worth it.
- [ ] **Admin — add Ameena's card to App Store Connect** to cover the upcoming Apple Developer Program renewal fee. (Account/billing task, not engineering — flagging here so it doesn't get lost.)
- [ ] **Write 2-3 posts in Simone's-audience voice, not indie-dev voice.** Everything queued in `content-drafts.md` right now (origin story, submission story, paywall admission) is pitched to an ADHD/indie-dev/build-in-public audience — good for Shipaton judging, but not the "woman with 47 tabs open" persona from her brief (PRD §4). Drafts #3 ("you don't need a workout plan") and #5 (the settings tour) are the closest templates: decision fatigue, guilt-free consistency, real-life scheduling — no dopamine-menu/ADHD framing. (Content task, not engineering — flagging here so it doesn't get lost the way the paywall copy almost did.)

### Microanimations

`DesignSystem/Motion.swift` already has a reduce-motion-aware token set
(`FGMotion.settle`, `.swap`, `.gentle`, `.settleWarm`) and a few screens
(Today's menu entrance/stagger, the check-in aura pulse, `PlayerView`'s
step-start/final-stretch flashes) already use it well. Extend that same
restrained, purposeful language rather than introducing a new one:

- [ ] **Tab switches (Today/Chat/You)** are an instant cut today. A soft
  cross-fade or gentle slide would match the rest of the app's settle-in
  feel.
- [ ] **Marking a menu item "Done"** currently just swaps in the strikethrough
  and `DoneMark` — no transition. Give it a small settle/checkmark moment
  consistent with `FGMotion.settle`.
- [ ] **Little Wins unlocking** — the grid (`LittleWinsView.swift`) has no
  distinct "just unlocked" moment beyond the existing celebration sheet.
  A brief in-place shimmer/pop on the card itself would sell the win before
  the sheet even opens.
- [ ] **Chat messages and the recommendation card** appear with no motion.
  A gentle slide/fade-in on new messages (the typing indicator already
  animates) would match the check-in and menu treatment.
- [ ] **Onboarding progress bar** (`OnboardingView.swift`) snaps between
  states instead of animating the fill — cheap, high-visibility polish.

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
- [ ] **A shareable moment**: a native Share Sheet for a completed session or
  a Little Win card as a clean, on-brand image. Gives people something to
  actually post, and doubles as free ASO/marketing content.
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
