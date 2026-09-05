# FeelGood Engineering Roadmap & Tasks (TODO)

This document tracks upcoming engineering milestones and architectural enhancements for FeelGood. It serves as the single source of truth for in-flight and planned engineering tasks.

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
