//
//  PlayerView.swift
//  FeelGood
//
//  The step timer for authored sessions. Pausable, resumable, and impossible
//  to fail: leaving early saves progress but is not a completion.
//

import SwiftUI
import UIKit

struct PlayerView: View {
    private static let readingSeconds = 10

    let session: Session
    let onFinish: (PlayerResult) -> Void
    /// When Start was tapped, so the record reflects real elapsed time.
    let startedAt: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var index = 0
    @State private var remaining = 0
    /// A short buffer at the start of each new step. This is separate from the
    /// exercise timer so reading the cue never consumes movement time.
    @State private var readingRemaining: Int
    /// Whether the "get ready" countdown is currently paused.
    @State private var isReadingPaused = false
    /// Which exercise `remaining` currently belongs to. A resumed exercise
    /// keeps its saved time; moving to another one resets to its full time.
    @State private var timerIndex: Int
    /// Reps tapped so far **in the current set**, never across the step.
    @State private var repsDone = 0
    /// Sets already finished in this step. `setsDone + 1` is the set someone
    /// is standing in the middle of.
    @State private var setsDone = 0
    /// True once a timed hold has entered its last stretch (see
    /// `finalStretchThreshold`). Drives a slow warmth over the whole screen —
    /// never a shrinking shape, never a percentage.
    @State private var isInFinalStretch = false
    /// A held step gets exactly one flash marking the moment it enters the
    /// final stretch. This is what makes the warmth that follows legible —
    /// without it, the held colour shift alone is too subtle to notice.
    @State private var hasFiredFinalStretchFlash = false
    @State private var flashOpacity = 0.0
    /// Tracks if the mid-hold side switch alert has already fired for this step.
    @State private var hasFiredSideSwitchAlert = false
    /// Active while the 3-second transition buffer between sides counts down.
    @State private var isSwitchingSides = false
    @State private var switchCountdown = 3
    /// 1 for the first side, 2 for the second side.
    @State private var currentSide = 1
    /// A separate, cooler pulse marking that a step has begun — every step,
    /// counted or timed. Deliberately a different hue from the ending flash
    /// (sage, not gold) so the two moments never read as the same event.
    @State private var stepStartOpacity = 0.0
    /// Large, glanceable countdown digits scalable with Dynamic Type.
    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize = 68.0
    /// The counter is the whole tap target, and it grows with Dynamic Type —
    /// this is used mid-movement, often without looking straight at it.
    @ScaledMetric(relativeTo: .largeTitle) private var counterHeight = 180.0
    @State private var isRunning = true
    @State private var isDone = false
    @State private var haveFeelChoicesLanded = false
    @State private var breathingStartedAt = Date()
    @State private var breathingPausedAt: Date?
    @State private var breathingAnchorIndex: Int?

    /// Authored steps as written; a custom routine's steps matched to the
    /// glossary and breathing vocabulary, so what somebody typed as "Box
    /// breathing" gets the same orb the catalog's does.
    private let steps: [Step]
    private var step: Step? { steps.indices.contains(index) ? steps[index] : nil }

    init(
        session: Session,
        progress: SessionProgress? = nil,
        glossary: [ExerciseTerm] = [],
        onFinish: @escaping (PlayerResult) -> Void,
        startedAt: Date
    ) {
        self.session = session
        self.onFinish = onFinish
        self.startedAt = startedAt

        let steps = session.isOwn
            ? session.source.steps.map { $0.inferringVisual(from: glossary) }
            : session.source.steps
        self.steps = steps

        let validIndex = progress.map { min(max($0.stepIndex, 0), max(steps.count - 1, 0)) } ?? 0
        let fullDuration = steps.indices.contains(validIndex)
            ? steps[validIndex].seconds
            : 0
        let initialRemaining = progress.map { min(max($0.remainingSeconds, 1), max(fullDuration, 1)) }
            ?? fullDuration
        _index = State(initialValue: validIndex)
        _remaining = State(initialValue: initialRemaining)
        _readingRemaining = State(
            initialValue: progress == nil && !steps.isEmpty
                ? Self.readingSeconds
                : 0
        )
        _timerIndex = State(initialValue: validIndex)
        _repsDone = State(initialValue: max(progress?.repsDone ?? 0, 0))
        _setsDone = State(initialValue: max(progress?.setsDone ?? 0, 0))

        // Resuming already inside the final stretch shows the settled warmth
        // straight away rather than flashing again — the flash marks entering
        // the moment, and a resume isn't that.
        let resumedIntoFinalStretch = Self.finalStretchThreshold(for: fullDuration)
            .map { initialRemaining <= $0 } ?? false
        _isInFinalStretch = State(initialValue: resumedIntoFinalStretch)
        _hasFiredFinalStretchFlash = State(initialValue: resumedIntoFinalStretch)

        // Resuming already past the halfway side switch point keeps side 2
        let activeStep = steps.indices.contains(validIndex)
            ? steps[validIndex]
            : nil
        let requiresSwitch = activeStep?.requiresSideSwitch ?? false
        let switchThreshold = activeStep.map { $0.seconds - $0.sideSwitchThresholdSeconds } ?? 0
        let resumedPastSwitch = requiresSwitch && initialRemaining <= switchThreshold
        _hasFiredSideSwitchAlert = State(initialValue: resumedPastSwitch)
        _currentSide = State(initialValue: resumedPastSwitch ? 2 : 1)
    }

    /// The last-fifth of a held step, capped at 10 seconds so a long hold's
    /// ending still reads as final rather than lasting a full minute. `nil`
    /// under 20 seconds — too short for a flash and a settled hold to read as
    /// two different things.
    private static func finalStretchThreshold(for duration: Int) -> Int? {
        guard duration >= 20 else { return nil }
        return min(duration / 5, 10)
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            if !isDone {
                // A cool, quick pulse marking that this step has begun —
                // every step, counted or timed. Sage rather than gold so it
                // never reads as the same moment as the ending flash below.
                FGAura.sage.mid
                    .opacity(stepStartOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // Two layers: a slow settle into warmth that lasts the rest
                // of the step, and a brief brighter pulse that fires once, on
                // entry, so the settle afterward is legible rather than a
                // background shift nobody clocked. Never a shape, never a
                // percentage — see the project's "no rings, no bars" rule.
                //
                // `butter.core` is nearly the same pale value as `bg` itself
                // (this palette's page colour is already warm), so blending
                // it in at low opacity was invisible in practice — measured
                // under 5% of channel range. `butter.mid` carries enough of
                // its own hue to actually read as "warmer," even held back.
                // No `.animation(value:)` here on purpose: that would ease
                // *both* directions equally, so leaving a warm final stretch
                // for a fresh step would fade the warmth out over a second —
                // reading as the new exercise starting warm. Entering warmth
                // eases in (see `updateFinalStretch`); leaving it is instant.
                FGAura.butter.mid
                    .opacity(isInFinalStretch ? 0.3 : 0)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                FGAura.butter.edge
                    .opacity(flashOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            if isDone {
                completion
                    .transition(.opacity)
            } else if case .youtube(let videoID, let channel) = session.source {
                videoPlayer(videoID: videoID, channel: channel)
                    .transition(.opacity)
            } else if let step {
                // The one full-screen layer. Anything with a shape — a
                // figure, the breathing orb — lives inside the card's visual
                // slot instead (see `StepVisualView`), so it can never end up
                // drawn behind the cue. A breathing step is the orb alone:
                // two things moving at once is the opposite of the point.
                if !isBreathingStep(step) {
                    SessionLiquidProgress(
                        progress: completionProgress(for: step),
                        aura: FGAura.allCases[index % FGAura.allCases.count],
                        isActive: readingRemaining == 0 && (step.isCounted || (isRunning && !isSwitchingSides))
                    )
                }
                running(step)
                    .transition(.opacity)
            } else {
                emptyStepView
                    .transition(.opacity)
            }
        }
        .task(id: index) {
            guard let step else { return }
            // Runs exactly once per distinct `index` — including the very
            // first step — so every step gets its start cue regardless of
            // how someone arrived at it (start, Next, Back, or resume).
            fireStepStartCue()
            if timerIndex != index {
                remaining = step.seconds
                readingRemaining = Self.readingSeconds
                isReadingPaused = false
                timerIndex = index
                repsDone = 0
                setsDone = 0
                isInFinalStretch = false
                hasFiredFinalStretchFlash = false
                flashOpacity = 0
                hasFiredSideSwitchAlert = false
                isSwitchingSides = false
                switchCountdown = 3
                currentSide = 1
            }

            while readingRemaining > 0 && !isDone {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                guard readingRemaining > 0 else { break }
                if !isReadingPaused {
                    readingRemaining -= 1
                }
            }

            if isBreathingStep(step), breathingAnchorIndex != index {
                restartBreathingCycle()
            }

            // Counted exercises advance through taps, not a hidden timer.
            guard !step.isCounted else { return }
            while remaining > 0 && !isDone {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }

                if isSwitchingSides {
                    if switchCountdown > 0 {
                        switchCountdown -= 1
                    }
                    if switchCountdown <= 0 {
                        withAnimation(FGMotion.gentle) {
                            isSwitchingSides = false
                            currentSide = 2
                        }
                    }
                    continue
                }

                if isRunning {
                    remaining -= 1
                    checkSideSwitch(for: step)
                    updateFinalStretch(for: step)
                }
            }
            if remaining <= 0 { advance() }
        }
        // Every intentional exit goes through Leave so the current timer can
        // be saved before this full-screen player disappears.
        .interactiveDismissDisabled()
    }

    /// One soft sage pulse marking a step's start. No hold state follows it —
    /// unlike the ending cue, beginning a step isn't something to linger on.
    private func fireStepStartCue() {
        guard !reduceMotion else { return }
        withAnimation(.easeOut(duration: 0.3)) { stepStartOpacity = 0.5 }
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(.easeIn(duration: 0.6)) { stepStartOpacity = 0 }
        }
    }

    /// Checked once per tick of the countdown. Fires the one-time flash the
    /// moment a step crosses into its final stretch, then leaves the settled
    /// warmth (`isInFinalStretch`) in place for the rest of the hold.
    private func updateFinalStretch(for step: Step) {
        guard !step.isCounted,
              let threshold = Self.finalStretchThreshold(for: step.seconds),
              remaining <= threshold,
              !isInFinalStretch
        else { return }

        withAnimation(reduceMotion ? nil : FGMotion.settleWarm) {
            isInFinalStretch = true
        }
        guard !hasFiredFinalStretchFlash else { return }
        hasFiredFinalStretchFlash = true
        fireFinalStretchFlash()
    }

    /// Checked once per tick of the countdown. Fires the switch-sides alert
    /// at the configured threshold (defaulting to halfway), pausing the hold
    /// timer for a 3-second transition.
    private func checkSideSwitch(for step: Step) {
        guard step.requiresSideSwitch, !hasFiredSideSwitchAlert else { return }
        let switchRemaining = step.seconds - step.sideSwitchThresholdSeconds
        guard remaining <= switchRemaining else { return }

        hasFiredSideSwitchAlert = true
        fireSideSwitchAlert()
    }

    private func fireSideSwitchAlert() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)

        fireFinalStretchFlash()

        withAnimation(reduceMotion ? nil : FGMotion.gentle) {
            switchCountdown = 3
            isSwitchingSides = true
        }
    }

    /// A photosensitivity-safe single pulse: one smooth rise, one smoother
    /// fall, never repeated. Skipped under Reduce Motion — the slower settle
    /// into warmth still plays and still carries the signal on its own.
    private func fireFinalStretchFlash() {
        guard !reduceMotion else { return }
        withAnimation(.easeOut(duration: 0.35)) { flashOpacity = 0.7 }
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.easeIn(duration: 0.7)) { flashOpacity = 0 }
        }
    }

    private func videoPlayer(videoID: String, channel: String) -> some View {
        VStack(spacing: FGSpace.l) {
            HStack {
                FGQuietButton("Leave", systemImage: "xmark") { leave() }
                Spacer()
                Text(channel)
                    .font(FGFont.label)
                    .foregroundStyle(FGColor.inkMuted)
            }

            Spacer()

            VStack(spacing: FGSpace.m) {
                Text(session.title)
                    .font(FGFont.display)
                    .foregroundStyle(FGColor.ink)
                    .multilineTextAlignment(.center)

                Group {
                    if let playerURL = WorkerConstants.playerURL(videoID: videoID) {
                        YouTubeWebView(playerURL: playerURL)
                    } else {
                        // The embed cannot be made to work without the Worker
                        // (see YouTubeWebView), so an unconfigured build offers
                        // the video where it does play rather than a frame that
                        // will sit there refusing.
                        watchElsewhere(videoID: videoID)
                    }
                }
                .aspectRatio(16/9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)

                if !session.subtitle.isEmpty {
                    Text(session.subtitle)
                        .font(FGFont.body)
                        .foregroundStyle(FGColor.inkMuted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            FGPrimaryButton(title: "Complete Workout") {
                withAnimation(FGMotion.gentle) {
                    isDone = true
                }
            }
        }
        .padding(FGSpace.page)
    }

    private var emptyStepView: some View {
        VStack(spacing: FGSpace.l) {
            HStack {
                FGQuietButton("Leave", systemImage: "xmark") { leave() }
                Spacer()
            }

            Spacer()

            VStack(spacing: FGSpace.m) {
                Text("No steps to play")
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.ink)
                Text("This session does not contain any timed or counted exercises.")
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.inkMuted)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            FGPrimaryButton(title: "Complete Workout") {
                withAnimation(FGMotion.gentle) {
                    isDone = true
                }
            }
        }
        .padding(FGSpace.page)
    }

    /// Shown instead of the player when `WORKER_BASE_URL` is unset, so a build
    /// without a deployed Worker still gets the person to the session rather
    /// than to an error frame. Watching on YouTube is a supported path, not a
    /// failure state, so it reads as an offer rather than an apology.
    private func watchElsewhere(videoID: String) -> some View {
        ZStack {
            YouTubeThumbnail(videoID: videoID)

            // The poster is somebody's living room at whatever exposure they
            // filmed it — the scrim is what makes one label legible over all
            // of them, in either colour scheme.
            LinearGradient(
                colors: [.black.opacity(0.15), .black.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )

            watchElsewhereLabel
        }
        // White-on-scrim rather than the ink tokens: this sits on a photograph,
        // so it is the one place in the app where the palette can't do the
        // work. Deliberately not YouTube's red play button — FGColor has no
        // red and this shouldn't introduce one.
        .contentShape(Rectangle())
        .onTapGesture {
            if let watchURL = URL(string: "https://www.youtube.com/watch?v=\(videoID)") {
                openURL(watchURL)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Watch \(session.title) on YouTube")
        .accessibilityAddTraits(.isLink)
    }

    /// The scrim and shadow keep the action legible over an arbitrary photo.
    private var watchElsewhereLabel: some View {
        VStack(spacing: FGSpace.s) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white)
            Text("Watch on YouTube")
                .font(FGFont.label)
                .foregroundStyle(.white)
        }
        .padding(FGSpace.m)
        .shadow(color: .black.opacity(0.4), radius: 6, y: 1)
    }

    private func running(_ step: Step) -> some View {
        VStack(spacing: FGSpace.l) {
            HStack {
                FGQuietButton("Leave", systemImage: "xmark") { leave() }
                Spacer()
                Text("\(index + 1) of \(steps.count)")
                    .font(FGFont.label)
                    .foregroundStyle(FGColor.inkMuted)
            }

            // The countdown/counter/switch-sides status is the one thing
            // worth glancing at without looking away from the movement, so
            // it gets its own row right under the top bar rather than being
            // buried mid-scroll behind the cue text.
            //
            // `.id(index)` + `.transition(.opacity)`: without a distinct
            // identity per step, SwiftUI just mutates the existing text in
            // place and there is nothing to cross-fade. `advance`/`goBack`
            // already wrap the index change in `withAnimation`, so the old
            // step's identity fades out as the new one fades in.
            statusHero(step)
                .id(index)
                .transition(.opacity)

            Spacer()

            VStack(spacing: FGSpace.m) {
                exerciseCard(step)

                ScannableCueView(cue: step.cue, requiresSideSwitch: step.requiresSideSwitch)

                if readingRemaining == 0, let cadence = step.visual?.breathingCadence {
                    BreathingPhaseLabel(
                        cadence: cadence,
                        isActive: isRunning && !isSwitchingSides,
                        startedAt: breathingStartedAt,
                        pausedAt: breathingPausedAt
                    )
                }
            }
            .id(index)
            .transition(.opacity)

            Spacer()

            controls(step)
        }
        .padding(FGSpace.page)
    }

    /// The countdown, rep counter, or side-switch card — whichever is the
    /// current step's one live number. Pulled out of `running` so it can sit
    /// in its own row at the top instead of the bottom.
    private func statusHero(_ step: Step) -> some View {
        Group {
            if isSwitchingSides {
                switchSidesTransitionCard
            } else if readingRemaining > 0 {
                readingCountdown
            } else if step.isCounted, let perSet = step.reps {
                counter(step, perSet: perSet)
            } else {
                VStack(spacing: FGSpace.xs) {
                    if step.requiresSideSwitch {
                        sideIndicatorBadge
                    }
                    Text(timeString)
                        .font(.system(size: timerFontSize, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(FGColor.goldDeep)
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }

    /// The exercise's name and its visual — a looping line-art demo if one
    /// is bundled, the paced orb for a breathing step, otherwise nothing —
    /// on a warm aura card rather than bare on the page — the same soft
    /// gradient language as a check-in tile, spread across the session's
    /// steps by index so neighbouring exercises don't repeat the same hue.
    ///
    /// `inkOnAccent`, not `ink`: the card fill doesn't flip with the
    /// appearance, so the title on it can't either — see `FGColor.inkOnAccent`.
    private func exerciseCard(_ step: Step) -> some View {
        let aura = FGAura.allCases[index % FGAura.allCases.count]
        return VStack(spacing: FGSpace.s) {
            Text(step.name)
                .font(FGFont.display)
                .foregroundStyle(FGColor.inkOnAccent)
                .multilineTextAlignment(.center)

            StepVisualView(
                step: step,
                aura: aura,
                isBreathingActive: readingRemaining == 0 && isRunning && !isSwitchingSides,
                breathingStartedAt: breathingStartedAt,
                breathingPausedAt: breathingPausedAt
            )
        }
        .padding(FGSpace.l)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .fill(LinearGradient(colors: [aura.core, aura.mid], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }

    /// Back / pause / next as three evenly-weighted circles rather than a
    /// full-width primary button plus a separate row underneath — the three
    /// things someone can do mid-step read as one family of actions instead
    /// of one important one and two afterthoughts.
    private func controls(_ step: Step) -> some View {
        VStack(spacing: FGSpace.m) {
            if isSwitchingSides {
                FGPrimaryButton(title: "Ready for side 2") {
                    withAnimation(FGMotion.gentle) {
                        switchCountdown = 0
                        isSwitchingSides = false
                        currentSide = 2
                    }
                }
            } else if readingRemaining > 0 {
                FGPrimaryButton(title: "Start now") {
                    readingRemaining = 0
                    isReadingPaused = false
                    if isBreathingStep(step) { restartBreathingCycle() }
                }
            } else if step.isCounted, repsDone > 0 || setsDone > 0 {
                // Counting is only trustworthy if it is reversible. A
                // thumb catches the card twice and the count is worse
                // than useless without a way back — including back into
                // the set before this one.
                FGQuietButton("Undo one", systemImage: "arrow.uturn.backward") {
                    undoOne(step)
                }
            }

            HStack(spacing: FGSpace.l) {
                if index > steps.startIndex {
                    circleButton(systemImage: "chevron.left", accessibilityLabel: "Back") { goBack() }
                } else {
                    // A fixed-size placeholder, not an absent view: keeps the
                    // pause circle centred on step one the same as everywhere
                    // else, instead of drifting toward Next.
                    Color.clear.frame(width: 52, height: 52)
                }

                Spacer()

                // No pause concept mid-count: reps advance by tapping the
                // counter itself, not a running timer. It still appears
                // during that step's own get-ready countdown, which is a
                // timer like any other.
                if !isSwitchingSides, !step.isCounted || readingRemaining > 0 {
                    primaryCircleButton(
                        systemImage: isPaused ? "play.fill" : "pause.fill",
                        accessibilityLabel: isPaused ? "Resume" : "Pause"
                    ) {
                        togglePause(for: step)
                    }
                }

                Spacer()

                circleButton(systemImage: "chevron.right", accessibilityLabel: "Next") { advance() }
            }
        }
    }

    /// A secondary circular control — Back and Next.
    private func circleButton(systemImage: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(FGColor.ink)
                .frame(width: 52, height: 52)
                .background(Circle().fill(FGColor.surface))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    /// The one primary circular control — Pause/Resume, larger and filled so
    /// it still reads as the default action among three equal-looking circles.
    private func primaryCircleButton(systemImage: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(FGColor.bg)
                .frame(width: 80, height: 80)
                .background(Circle().fill(FGColor.ink))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    /// Whichever clock is currently live — the get-ready buffer before a step
    /// starts, or the step's own hold — is what "paused" means right now.
    /// There is deliberately one pause control for both rather than the
    /// get-ready countdown owning a separate pause of its own.
    private var isPaused: Bool {
        readingRemaining > 0 ? isReadingPaused : !isRunning
    }

    private func togglePause(for step: Step) {
        if readingRemaining > 0 {
            isReadingPaused.toggle()
        } else {
            toggleRunning(for: step)
        }
    }

    private var readingCountdown: some View {
        VStack(spacing: FGSpace.xs) {
            Text(isReadingPaused ? "Paused" : "Get ready")
                .font(FGFont.label)
                .foregroundStyle(FGColor.inkMuted)

            Text("\(readingRemaining)")
                .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(FGColor.goldDeep)
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Starting in \(readingRemaining) seconds\(isReadingPaused ? ", paused" : "")")
    }

    private var sideIndicatorBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.left.and.right")
                .font(.caption2)
            Text("Side \(currentSide) of 2")
                .font(FGFont.label)
        }
        .foregroundStyle(FGColor.inkMuted)
        .padding(.horizontal, FGSpace.s)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(FGColor.surface)
        )
    }

    private var switchSidesTransitionCard: some View {
        VStack(spacing: FGSpace.s) {
            HStack(spacing: FGSpace.xs) {
                Image(systemName: "arrow.left.and.right")
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.goldDeep)
                Text("Switch sides")
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.ink)
            }

            Text("\(switchCountdown)")
                .font(.system(size: 52, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(FGColor.goldDeep)
                .contentTransition(.numericText())

            Button {
                withAnimation(FGMotion.gentle) {
                    switchCountdown = 0
                    isSwitchingSides = false
                    currentSide = 2
                }
            } label: {
                Text("Ready now")
                    .font(FGFont.label)
                    .foregroundStyle(FGColor.ink)
                    .padding(.horizontal, FGSpace.m)
                    .padding(.vertical, FGSpace.xs + 2)
                    .background(
                        Capsule().fill(FGColor.surface)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(FGSpace.m)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .fill(FGColor.surface.opacity(0.85))
        )
        .transition(.scale.combined(with: .opacity))
    }

    /// This session's completion tint, or the screen's long-standing butter
    /// glow for activities with no single clear family — see
    /// `Activity.completionAura`.
    private var completionAura: FGAura { session.activity.completionAura ?? .butter }

    private var completion: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(
                            height: typeSize.isAccessibilitySize
                                ? FGSpace.l
                                : max(96, proxy.size.height * 0.24)
                        )
                        .accessibilityHidden(true)

                    ZStack {
                        // The echo of the final-stretch flash, settling out for
                        // good. It stays with the headline rather than sitting
                        // behind any response and biasing an answer.
                        completionAura.core
                            .opacity(0.62)
                            .frame(width: 240, height: 120)
                            .blur(radius: 42)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)

                        VStack(spacing: FGSpace.m) {
                            Text(session.activity.completionHeadline)
                                .font(FGFont.display)
                                .foregroundStyle(FGColor.ink)
                                .multilineTextAlignment(.center)

                            Text("How did that feel?")
                                .font(FGFont.body)
                                .foregroundStyle(FGColor.inkMuted)
                                .multilineTextAlignment(.center)
                        }
                    }

                    feelChoices
                        .padding(.top, typeSize.isAccessibilitySize ? FGSpace.m : FGSpace.l)

                    Spacer(minLength: FGSpace.xl)

                    HStack(spacing: FGSpace.m) {
                        FGQuietButton("Back", systemImage: "arrow.left") {
                            goBack()
                        }

                        Spacer(minLength: FGSpace.s)

                        FGQuietButton("Skip feedback") {
                            onFinish(.completed(nil))
                        }
                    }
                    .padding(.bottom, FGSpace.l)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height)
                .padding(.horizontal, FGSpace.page)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(FGBrandWash().ignoresSafeArea())
    }

    /// Three equal choices at ordinary sizes, one per row for accessibility
    /// Dynamic Type so neither labels nor tap targets get squeezed.
    private var feelChoices: some View {
        FlowRow.choices(isAccessibilitySize: typeSize.isAccessibilitySize) {
            ForEach(Array(Feel.allCases.enumerated()), id: \.element) { index, feel in
                feelChoiceLabel(feel)
                    .opacity(reduceMotion || haveFeelChoicesLanded ? 1 : 0)
                    .scaleEffect(reduceMotion || haveFeelChoicesLanded ? 1 : 0.88)
                    .offset(y: reduceMotion || haveFeelChoicesLanded ? 0 : 18)
                    .animation(
                        reduceMotion
                            ? .none
                            : .spring(response: 0.48, dampingFraction: 0.68)
                                .delay(Double(index) * 0.08),
                        value: haveFeelChoicesLanded
                    )
            }
        }
        .onAppear {
            guard !reduceMotion else {
                haveFeelChoicesLanded = true
                return
            }
            haveFeelChoicesLanded = false
            Task { @MainActor in
                await Task.yield()
                haveFeelChoicesLanded = true
            }
        }
    }

    private func feelChoiceLabel(_ feel: Feel) -> some View {
        Button {
            onFinish(.completed(feel))
        } label: {
            VStack(spacing: FGSpace.s) {
                Image(systemName: symbol(for: feel))
                    .font(.system(size: 26, weight: .medium))
                Text(label(for: feel))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: typeSize.isAccessibilitySize ? 76 : 92)
            .padding(.horizontal, FGSpace.s)
            .foregroundStyle(FGColor.ink)
            .background(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .fill(FGColor.surface.opacity(0.92))
                    .shadow(
                        color: completionAura.edge.opacity(0.12),
                        radius: 16,
                        x: 0,
                        y: 8
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityLabel(label(for: feel))
    }

    /// Counting reps, not counting down. Deliberately not a progress bar:
    /// the number is a place-keeper for a working memory that is busy holding
    /// a plank, not a score to finish. Nothing here renders a percentage.
    ///
    /// The number counts the set someone is actually in. Three sets of ten is
    /// three tens, never a thirty — a counter running to thirty is arithmetic
    /// nobody asked for in the middle of a lift.
    private func counter(_ step: Step, perSet: Int) -> some View {
        Button {
            guard repsDone < perSet else { return }
            repsDone += 1
            guard repsDone >= perSet else { return }
            // Let the last rep land on screen before the set turns over —
            // moving on the instant of the tap means never seeing it.
            let countedStep = index
            let countedSet = setsDone
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                guard index == countedStep, setsDone == countedSet else { return }
                withAnimation(FGMotion.gentle) {
                    if setsDone + 1 < step.setCount {
                        setsDone += 1
                        repsDone = 0
                    } else {
                        advance()
                    }
                }
            }
        } label: {
            VStack(spacing: FGSpace.xs) {
                if step.setCount > 1 {
                    Text("Set \(setsDone + 1) of \(step.setCount)")
                        .font(FGFont.label)
                        .foregroundStyle(FGColor.inkMuted)
                }
                Text("\(repsDone)/\(perSet)")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold).monospacedDigit())
                    .contentTransition(.numericText())
                    .foregroundStyle(FGColor.goldDeep)
                Text(setLabel(step, perSet: perSet))
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
            }
            .frame(maxWidth: .infinity, minHeight: counterHeight)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(repsDone >= perSet)
        .animation(FGMotion.gentle, value: repsDone)
        // The haptic is the point: "don't lose count" means being sure a tap
        // registered without looking down to check.
        .sensoryFeedback(.increase, trigger: repsDone)
        .accessibilityElement()
        .accessibilityLabel(step.setCount > 1
            ? "\(step.name), set \(setsDone + 1) of \(step.setCount)"
            : step.name)
        .accessibilityValue("\(repsDone) of \(perSet)")
        .accessibilityHint("Counts one rep")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: if repsDone < perSet { repsDone += 1 }
            case .decrement: undoOne(step)
            @unknown default: break
            }
        }
    }

    /// What to say under the number. The last rep of a set is worth marking,
    /// and "rest" is the instruction that actually follows it.
    private func setLabel(_ step: Step, perSet: Int) -> String {
        guard repsDone >= perSet else { return "tap as you go" }
        return setsDone + 1 < step.setCount ? "rest, then the next set" : "that's the last set"
    }

    /// Steps the count back one rep, over the boundary into the previous set
    /// when the thumb was one tap too eager at the start of a new one.
    private func undoOne(_ step: Step) {
        withAnimation(FGMotion.gentle) {
            if repsDone > 0 {
                repsDone -= 1
            } else if setsDone > 0 {
                setsDone -= 1
                repsDone = max(0, (step.reps ?? 1) - 1)
            }
        }
    }

    private var timeString: String {
        String(format: "%d:%02d", remaining / 60, remaining % 60)
    }

    private func completionProgress(for step: Step) -> Double {
        guard readingRemaining == 0, timerIndex == index else { return 0 }

        if step.isCounted, let reps = step.reps {
            let total = max(reps * step.setCount, 1)
            let completed = min((setsDone * reps) + repsDone, total)
            return Double(completed) / Double(total)
        }

        let duration = max(step.seconds, 1)
        return min(max(1 - (Double(remaining) / Double(duration)), 0), 1)
    }

    /// Breathing is paced only when the content says the step *is* the
    /// breathing — never guessed from wording. Plenty of stretches say "keep
    /// breathing", and "catch your breath" between two bursts is a rest.
    private func isBreathingStep(_ step: Step) -> Bool {
        step.visual?.breathingCadence != nil
    }

    private func restartBreathingCycle() {
        breathingStartedAt = Date()
        breathingPausedAt = nil
        breathingAnchorIndex = index
    }

    /// Move the cycle's origin forward by the paused duration. Resuming then
    /// continues the same breath instead of visibly jumping to another phase.
    private func toggleRunning(for step: Step) {
        guard isBreathingStep(step) else {
            isRunning.toggle()
            return
        }

        if isRunning {
            breathingPausedAt = Date()
            isRunning = false
        } else {
            let resumedAt = Date()
            if let breathingPausedAt {
                breathingStartedAt = breathingStartedAt.addingTimeInterval(
                    resumedAt.timeIntervalSince(breathingPausedAt)
                )
            }
            self.breathingPausedAt = nil
            isRunning = true
        }
    }

    private func advance() {
        if index + 1 < steps.count {
            withAnimation(FGMotion.gentle) { index += 1 }
        } else {
            withAnimation(FGMotion.gentle) {
                // Move beyond the last valid index so going back changes the
                // task identity and restarts that exercise's timer.
                index = steps.endIndex
                isDone = true
            }
        }
    }

    private func leave() {
        let saved = SessionProgress(
            stepIndex: index,
            remainingSeconds: max(remaining, 1),
            startedAt: startedAt,
            repsDone: repsDone,
            setsDone: setsDone
        )
        onFinish(.paused(saved))
    }

    private func goBack() {
        guard !steps.isEmpty else { return }
        withAnimation(FGMotion.gentle) {
            if isDone {
                let previousIndex = steps.index(before: steps.endIndex)
                index = previousIndex
                remaining = steps[previousIndex].seconds
                timerIndex = previousIndex
                readingRemaining = Self.readingSeconds
                repsDone = 0
                setsDone = 0
                // Instant, not eased with the rest of this transaction —
                // leaving warmth behind should never look like a fade.
                withAnimation(.none) {
                    isInFinalStretch = false
                    hasFiredFinalStretchFlash = false
                    flashOpacity = 0
                    hasFiredSideSwitchAlert = false
                    isSwitchingSides = false
                    switchCountdown = 3
                    currentSide = 1
                    isReadingPaused = false
                }
                isDone = false
            } else if index > steps.startIndex {
                index -= 1
            }
        }
    }

    private func symbol(for feel: Feel) -> String {
        switch feel {
        case .lovedIt: "heart"
        case .fine: "hand.thumbsup"
        case .tooMuch: "hand.raised"
        }
    }

    private func label(for feel: Feel) -> String {
        switch feel {
        case .lovedIt: "Loved it"
        case .fine: "Fine"
        case .tooMuch: "Too much"
        }
    }
}

/// A quiet, full-screen progress signal that can be understood without
/// watching a number. Its waterline rises directly with completion, so the
/// unfilled space always communicates how much of the step remains.
private struct SessionLiquidProgress: View {
    let progress: Double
    let aura: FGAura
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let clampedProgress = min(max(progress, 0), 1)
            TimelineView(
                .animation(
                    minimumInterval: 1.0 / 60.0,
                    paused: reduceMotion || !isActive
                )
            ) { timeline in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                // Keep the value small for stable CGFloat rendering and wrap
                // at exactly one sine cycle so there is no visible phase jump.
                let phase = reduceMotion
                    ? 0
                    : (elapsed * 0.52).truncatingRemainder(dividingBy: .pi * 2)

                ZStack {
                    LiquidWaveShape(
                        progress: min(clampedProgress + 0.018, 1),
                        amplitude: 24,
                        frequency: 1.32,
                        phase: CGFloat(phase)
                    )
                    .fill(aura.edge.opacity(0.18))

                    LiquidWaveShape(
                        progress: clampedProgress,
                        amplitude: 18,
                        frequency: 1.05,
                        phase: CGFloat(-phase + 2.1)
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                aura.core.opacity(0.40),
                                aura.mid.opacity(0.32),
                                aura.edge.opacity(0.24),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // A submerged ripple gives the water body refraction and
                    // makes the surface feel like it has thickness.
                    LiquidSurfaceShape(
                        progress: max(clampedProgress - 0.032, 0),
                        amplitude: 12,
                        frequency: 1.48,
                        phase: CGFloat(phase + 0.8)
                    )
                    .stroke(aura.core.opacity(0.20), lineWidth: 5)
                    .blur(radius: 2.5)

                    // A diffuse shadow under a crisp highlight gives the crest
                    // its liquid depth without adding a hard outline.
                    LiquidSurfaceShape(
                        progress: clampedProgress,
                        amplitude: 18,
                        frequency: 1.05,
                        phase: CGFloat(-phase + 2.1)
                    )
                    .stroke(aura.edge.opacity(0.30), lineWidth: 8)
                    .blur(radius: 5)

                    LiquidSurfaceShape(
                        progress: clampedProgress,
                        amplitude: 18,
                        frequency: 1.05,
                        phase: CGFloat(-phase + 2.1)
                    )
                    .stroke(FGColor.surface.opacity(0.58), lineWidth: 2.5)

                    LiquidSurfaceShape(
                        progress: clampedProgress,
                        amplitude: 18,
                        frequency: 1.05,
                        phase: CGFloat(-phase + 2.1)
                    )
                    .stroke(
                        FGColor.surface.opacity(0.25),
                        style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [26, 34])
                    )
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .fgAnimation(.linear(duration: 1), value: clampedProgress)
                .compositingGroup()
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The liquid body and its animated surface. Wave height only eases near the
/// exact empty/full edges, keeping visible swells throughout the session while
/// still letting a completed step fully cover the top corners.
private struct LiquidWaveShape: Shape {
    var progress: Double
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat

    var animatableData: AnimatablePair<Double, CGFloat> {
        get { AnimatablePair(progress, phase) }
        set {
            progress = newValue.first
            phase = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let clampedProgress = min(max(progress, 0), 1)
        let surfaceY = rect.maxY - (rect.height * CGFloat(clampedProgress))
        let waveStrength = CGFloat(
            min(clampedProgress * 12, (1 - clampedProgress) * 12, 1)
        )
        let effectiveAmplitude = amplitude * waveStrength

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: surfaceY))

        let sampleCount = max(Int(rect.width / 2), 1)
        for sample in 0...sampleCount {
            let fraction = CGFloat(sample) / CGFloat(sampleCount)
            let x = rect.minX + (rect.width * fraction)
            let angle = (fraction * .pi * 2 * frequency) + phase
            // A smaller counter-moving ripple keeps the surface from reading
            // as one mechanically perfect sine wave. Both phases use whole
            // multiples, so wrapping remains seamless.
            let primaryRipple = sin(angle) * effectiveAmplitude * 0.78
            let secondaryAngle = (fraction * .pi * 4.4 * frequency) - (phase * 2)
            let secondaryRipple = sin(secondaryAngle) * effectiveAmplitude * 0.22
            let y = surfaceY + primaryRipple + secondaryRipple
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// The open waterline used for highlights, depth shadows, and underwater
/// refraction. Keeping it separate avoids drawing an outline around the sides
/// and bottom of the full liquid body.
private struct LiquidSurfaceShape: Shape {
    var progress: Double
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat

    var animatableData: AnimatablePair<Double, CGFloat> {
        get { AnimatablePair(progress, phase) }
        set {
            progress = newValue.first
            phase = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let clampedProgress = min(max(progress, 0), 1)
        let surfaceY = rect.maxY - (rect.height * CGFloat(clampedProgress))
        let waveStrength = CGFloat(
            min(clampedProgress * 12, (1 - clampedProgress) * 12, 1)
        )
        let effectiveAmplitude = amplitude * waveStrength
        let sampleCount = max(Int(rect.width / 2), 1)

        var path = Path()
        for sample in 0...sampleCount {
            let fraction = CGFloat(sample) / CGFloat(sampleCount)
            let x = rect.minX + (rect.width * fraction)
            let angle = (fraction * .pi * 2 * frequency) + phase
            let primaryRipple = sin(angle) * effectiveAmplitude * 0.78
            let secondaryAngle = (fraction * .pi * 4.4 * frequency) - (phase * 2)
            let secondaryRipple = sin(secondaryAngle) * effectiveAmplitude * 0.22
            let point = CGPoint(x: x, y: surfaceY + primaryRipple + secondaryRipple)

            if sample == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
}

nonisolated enum PlayerResult: Equatable, Sendable {
    case paused(SessionProgress)
    case completed(Feel?)
}
