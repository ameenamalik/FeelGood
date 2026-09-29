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
    private static let setRestSeconds = 45

    let session: Session
    let onFinish: (PlayerResult) -> Void
    /// Offered on the end screen as one tap, applied when the screen closes.
    /// `nil` hides the option — somebody's own routine is removed, not hidden.
    let onHide: (() -> Void)?
    /// Persists the exact point where playback stopped and starts the paused
    /// session Journey even if the app is backgrounded before Leave is tapped.
    let onPause: (SessionProgress) -> Void
    /// Cancels the matching paused-session Journey when playback continues.
    let onResume: (SessionProgress) -> Void
    /// When Start was tapped, so the record reflects real elapsed time.
    let startedAt: Date
    private let narrationService: any BreathingNarrationPlaying

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
    /// A small between-set guide, not workout history. It exists only while
    /// this player is open and clears as soon as the next set starts.
    @State private var setRestRemaining = 0
    /// How far the newly completed set has filled the waterline during rest.
    /// Advancing this one beat at a time makes the rise last for the whole
    /// countdown, including extra rest someone adds along the way.
    @State private var setRestFillFraction = 0.0
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
    @State private var isRunning = true
    @State private var isDone = false
    @State private var haveFeelChoicesLanded = false
    @State private var selectedFeel: Feel?
    @State private var isHidingSession = false
    @State private var breathingStartedAt = Date()
    @State private var breathingPausedAt: Date?
    @State private var breathingAnchorIndex: Int?
    /// Prevents Pause followed by Leave from reporting the same interruption
    /// twice (and potentially entering the Journey twice when re-entry is on).
    @State private var hasReportedPause = false

    /// Authored steps as written; a custom routine's steps matched to the
    /// glossary and breathing vocabulary, so what somebody typed as "Box
    /// breathing" gets the same orb the catalog's does.
    private let steps: [Step]
    private var step: Step? { steps.indices.contains(index) ? steps[index] : nil }
    private var isUntimed: Bool { session.durationMin == 0 || (step?.seconds == 0 && step?.isCounted == false) }

    init(
        session: Session,
        progress: SessionProgress? = nil,
        glossary: [ExerciseTerm] = [],
        onFinish: @escaping (PlayerResult) -> Void,
        onHide: (() -> Void)? = nil,
        onPause: @escaping (SessionProgress) -> Void,
        onResume: @escaping (SessionProgress) -> Void,
        startedAt: Date,
        narrationService: any BreathingNarrationPlaying = AVAudioPlayerNarrationService.shared
    ) {
        self.session = session
        self.onFinish = onFinish
        self.onHide = onHide
        self.onPause = onPause
        self.onResume = onResume
        self.startedAt = startedAt
        self.narrationService = narrationService

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
                        isActive: readingRemaining == 0 && (step.isCounted || (isRunning && !isSwitchingSides)),
                        animatesProgressChanges: !step.isCounted || setRestRemaining > 0
                    )
                }
                running(step)
                    .transition(.opacity)
            } else {
                emptyStepView
                    .transition(.opacity)
            }
        }
        // The full player surface accepts horizontal navigation while every
        // existing control remains tappable. A deliberate horizontal bias and
        // distance threshold keep vertical movement and slightly messy button
        // taps from changing exercises.
        .simultaneousGesture(routineSwipeGesture)
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
                setRestRemaining = 0
                setRestFillFraction = 0
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

            // Counted or untimed rest exercises advance through user action ("Done"), not a hidden countdown timer.
            guard !step.isCounted, !isUntimed else { return }
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
        .task(id: setRestRemaining > 0) {
            guard setRestRemaining > 0 else { return }

            while setRestRemaining > 0 && !isDone {
                let secondsLeft = max(setRestRemaining, 1)
                let unfilled = max(1 - setRestFillFraction, 0)
                setRestFillFraction = min(
                    setRestFillFraction + (unfilled / Double(secondsLeft)),
                    1
                )

                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
                guard !Task.isCancelled, setRestRemaining > 0 else { return }
                let restIsEnding = setRestRemaining == 1
                setRestRemaining -= 1
                if restIsEnding {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    withAnimation(.none) {
                        setRestFillFraction = 0
                    }
                    return
                }
            }
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
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.75)

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

            FGPrimaryButton(title: "Complete session") {
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
                Text("Nothing to play")
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.ink)
                Text("This one doesn't have steps to walk through — mark it done whenever you're ready.")
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.inkMuted)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            FGPrimaryButton(title: "Complete session") {
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
        Button {
            if let watchURL = URL(string: "https://www.youtube.com/watch?v=\(videoID)") {
                openURL(watchURL)
            }
        } label: {
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
            } else if step.isCounted, setRestRemaining > 0 {
                setRestIndicator(step)
            } else if step.isCounted, let perSet = step.reps {
                counterInfo(step, perSet: perSet)
            } else if isUntimed {
                untimedRestIndicator
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
    /// bare on the page rather than boxed in a card. The aura still spreads
    /// across the session's steps by index, driving the breathing orb's own
    /// glow, so neighbouring exercises don't repeat the same hue.
    ///
    /// `ink`, not `inkOnAccent`: there's no accent-colored fill behind the
    /// title anymore, so it needs to flip with the appearance like normal
    /// page text — see `FGColor.ink`.
    private func exerciseCard(_ step: Step) -> some View {
        let aura = FGAura.allCases[index % FGAura.allCases.count]
        return VStack(spacing: FGSpace.s) {
            Text(step.name)
                .font(FGFont.display)
                .foregroundStyle(FGColor.ink)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.75)

            StepVisualView(
                step: step,
                aura: aura,
                isBreathingActive: readingRemaining == 0 && isRunning && !isSwitchingSides,
                breathingStartedAt: breathingStartedAt,
                breathingPausedAt: breathingPausedAt
            )
        }
        .padding(.horizontal, FGSpace.s)
        .padding(.vertical, FGSpace.s)
        .frame(maxWidth: .infinity)
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
                    if isReadingPaused {
                        reportResume()
                    }
                    readingRemaining = 0
                    isReadingPaused = false
                    if isBreathingStep(step) { restartBreathingCycle() }
                }
            } else if step.isCounted {
                // No tap-per-rep: a body in the middle of a set has no hand
                // free to count with, and the running tally used to eat the
                // vertical space this screen wants for the exercise's own
                // animation. One tap closes the whole set instead.
                VStack(spacing: FGSpace.s) {
                    if setRestRemaining > 0 {
                        FGPrimaryButton(title: "Start set \(setsDone + 1) now") {
                            finishSetRest()
                        }
                        FGQuietButton("Add 15 sec", systemImage: "plus") {
                            setRestRemaining += 15
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                    } else {
                        FGPrimaryButton(
                            title: setsDone + 1 < step.setCount
                                ? "Done with this set"
                                : (index == steps.count - 1 ? "Finish session" : "Done with this step")
                        ) {
                            completeSet(step)
                        }
                    }
                    if setsDone > 0 {
                        // A thumb catches the card twice and a set is worse
                        // than useless without a way back — including back
                        // into the set before this one.
                        FGQuietButton("Back one set", systemImage: "arrow.uturn.backward") {
                            backOneSet()
                        }
                    }
                }
            } else if isUntimed && !step.isCounted {
                FGPrimaryButton(title: index == steps.count - 1 ? "Finish session" : "Done with this step") {
                    advance()
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

                // No pause concept mid-count or during untimed rest: a counted
                // set advances by tapping Done with this set, and untimed rest
                // finishes by tapping Done. It still appears during that
                // step's own get-ready countdown, which is a timer like any other.
                if !isSwitchingSides, (!step.isCounted && !isUntimed) || readingRemaining > 0 {
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

    private var untimedRestIndicator: some View {
        HStack(spacing: FGSpace.xs) {
            Image(systemName: "bed.double")
                .font(.system(size: 20, weight: .medium))
            Text("Untimed · Rest")
                .font(FGFont.body.weight(.semibold))
        }
        .foregroundStyle(FGColor.sageDeep)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(FGColor.sage.opacity(0.35))
        )
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
        let wasPaused = isPaused
        if readingRemaining > 0 {
            isReadingPaused.toggle()
        } else {
            toggleRunning(for: step)
        }

        if wasPaused {
            reportResume()
        } else {
            reportPause()
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

                    if let selectedFeel {
                        feedbackConfirmation(for: selectedFeel)
                            .padding(.top, FGSpace.m)
                            .transition(
                                reduceMotion
                                    ? .opacity
                                    : .move(edge: .bottom).combined(with: .opacity)
                            )
                    }

                    if onHide != nil {
                        hideChoice
                            .padding(.top, FGSpace.l)
                    }

                    Spacer(minLength: FGSpace.xl)

                    HStack(spacing: FGSpace.m) {
                        FGQuietButton("Back", systemImage: "arrow.left") {
                            goBack()
                        }

                        Spacer(minLength: FGSpace.s)

                        if let selectedFeel {
                            FGQuietButton("Done") {
                                finish(feel: selectedFeel)
                            }
                        } else {
                            FGQuietButton("Skip feedback") {
                                finish(feel: nil)
                            }
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
        let isSelected = selectedFeel == feel

        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(reduceMotion ? .none : FGMotion.gentle) {
                selectedFeel = feel
            }
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
                    .fill(isSelected ? completionAura.core.opacity(0.72) : FGColor.surface.opacity(0.92))
                    .shadow(
                        color: completionAura.edge.opacity(0.12),
                        radius: 16,
                        x: 0,
                        y: 8
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                            .stroke(
                                isSelected ? completionAura.edge.opacity(0.72) : .clear,
                                lineWidth: 2
                            )
                    }
            )
            .contentShape(RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityLabel(label(for: feel))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func feedbackConfirmation(for feel: Feel) -> some View {
        HStack(alignment: .top, spacing: FGSpace.s) {
            Image(systemName: "sparkles")
                .font(FGFont.itemTitle)
                .foregroundStyle(completionAura.edge)

            VStack(alignment: .leading, spacing: 2) {
                Text("We'll remember that.")
                    .font(FGFont.label)
                    .foregroundStyle(FGColor.ink)

                Text(feedbackConsequence(for: feel))
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(FGSpace.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .fill(completionAura.core.opacity(0.32))
                .overlay {
                    RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                        .stroke(completionAura.edge.opacity(0.24), lineWidth: 1)
                }
        )
        .accessibilityElement(children: .combine)
    }

    /// One tap, no dialog, and an Undo in place of the button. Asking twice
    /// would turn a quick "not for me" into a form.
    @ViewBuilder
    private var hideChoice: some View {
        if isHidingSession {
            HStack(spacing: FGSpace.s) {
                Image(systemName: "eye.slash")
                    .foregroundStyle(FGColor.inkMuted)
                Text("We won’t suggest this again.")
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
                FGQuietButton("Undo") {
                    withAnimation(FGMotion.gentle) { isHidingSession = false }
                }
            }
            .transition(.opacity)
        } else {
            FGQuietButton("Don't suggest this again", systemImage: "eye.slash") {
                withAnimation(FGMotion.gentle) { isHidingSession = true }
            }
            .transition(.opacity)
        }
    }

    private func finish(feel: Feel?) {
        onFinish(.completed(feel))
        if isHidingSession { onHide?() }
    }

    private func feedbackConsequence(for feel: Feel) -> String {
        switch feel {
        case .lovedIt:
            "We'll bring you more movement like this."
        case .fine:
            "We'll use this when shaping your next menu."
        case .tooMuch:
            "We'll use this to make future picks gentler."
        }
    }

    /// What a counted step is *for*, not something to tap through. Reps are
    /// felt, not counted on screen — a body in the middle of a set has no
    /// hand free to tap with, and nobody doing push-ups needs a number to
    /// tell them they're on their eighth. This is a plain readout, sized to
    /// leave the exercise's own animation the room the timer display gets,
    /// not the tall tap target the old per-rep counter needed.
    private func counterInfo(_ step: Step, perSet: Int) -> some View {
        VStack(spacing: FGSpace.xs) {
            if step.setCount > 1 {
                Text("Set \(setsDone + 1) of \(step.setCount)")
                    .font(FGFont.label)
                    .foregroundStyle(FGColor.inkMuted)
            }
            Text("\(perSet) reps")
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(FGColor.goldDeep)
        }
        .animation(FGMotion.gentle, value: setsDone)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(step.setCount > 1
            ? "\(step.name), set \(setsDone + 1) of \(step.setCount), \(perSet) reps"
            : "\(step.name), \(perSet) reps")
    }

    private func setRestIndicator(_ step: Step) -> some View {
        VStack(spacing: FGSpace.xs) {
            Text("Set \(setsDone + 1) of \(step.setCount)")
                .font(FGFont.label)
                .foregroundStyle(FGColor.inkMuted)
            Text("Rest \(setRestTimeString)")
                .font(.system(size: timerFontSize, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(FGColor.sageDeep)
                .contentTransition(.numericText())
                .animation(.linear(duration: 0.2), value: setRestRemaining)
                .minimumScaleFactor(0.7)
            if let reps = step.reps {
                Text("Next · \(reps) reps")
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Rest \(setRestRemaining) seconds. Set \(setsDone + 1) of \(step.setCount) is next."
        )
    }

    /// Closes out the set someone just did. One tap, whatever they actually
    /// felt like inside it — the app was never the one counting.
    private func completeSet(_ step: Step) {
        withAnimation(FGMotion.gentle) {
            if setsDone + 1 < step.setCount {
                setsDone += 1
                repsDone = 0
                setRestRemaining = Self.setRestSeconds
                setRestFillFraction = 0
            } else {
                repsDone = step.reps ?? 0
                setRestRemaining = 0
                setRestFillFraction = 0
                advance()
            }
        }
    }

    /// Steps back into the set before this one, for the thumb that caught
    /// "Done with this set" a beat too eager.
    private func backOneSet() {
        withAnimation(FGMotion.gentle) {
            guard setsDone > 0 else { return }
            setsDone -= 1
            repsDone = 0
            setRestRemaining = 0
            setRestFillFraction = 0
        }
    }

    private func finishSetRest() {
        withAnimation(.none) {
            setRestFillFraction = 0
            setRestRemaining = 0
        }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private var timeString: String {
        String(format: "%d:%02d", remaining / 60, remaining % 60)
    }

    private var setRestTimeString: String {
        String(format: "%d:%02d", setRestRemaining / 60, setRestRemaining % 60)
    }

    private func completionProgress(for step: Step) -> Double {
        guard readingRemaining == 0, timerIndex == index else { return 0 }

        if step.isCounted {
            return setRestRemaining > 0 ? setRestFillFraction : 0
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
        if let narrationID = step?.narrationID {
            narrationService.play(narrationID: narrationID)
        }
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
            narrationService.pause()
        } else {
            let resumedAt = Date()
            if let breathingPausedAt {
                breathingStartedAt = breathingStartedAt.addingTimeInterval(
                    resumedAt.timeIntervalSince(breathingPausedAt)
                )
            }
            self.breathingPausedAt = nil
            isRunning = true
            narrationService.resume()
        }
    }

    private func advance() {
        narrationService.stop()
        setRestRemaining = 0
        setRestFillFraction = 0
        if index + 1 < steps.count {
            withAnimation(reduceMotion ? .none : FGMotion.gentle) { index += 1 }
        } else {
            withAnimation(reduceMotion ? .none : FGMotion.gentle) {
                // Move beyond the last valid index so going back changes the
                // task identity and restarts that exercise's timer.
                index = steps.endIndex
                isDone = true
            }
        }
    }

    private func leave() {
        narrationService.stop()
        let saved = currentProgress
        if !hasReportedPause {
            hasReportedPause = true
            onPause(saved)
        }
        onFinish(.paused(saved))
    }

    private var currentProgress: SessionProgress {
        SessionProgress(
            stepIndex: index,
            remainingSeconds: max(remaining, 1),
            startedAt: startedAt,
            repsDone: repsDone,
            setsDone: setsDone
        )
    }

    private func reportPause() {
        guard !hasReportedPause else { return }
        hasReportedPause = true
        onPause(currentProgress)
    }

    private func reportResume() {
        guard hasReportedPause else { return }
        hasReportedPause = false
        onResume(currentProgress)
    }

    private func goBack() {
        guard !steps.isEmpty else { return }
        narrationService.stop()
        setRestRemaining = 0
        setRestFillFraction = 0
        withAnimation(reduceMotion ? .none : FGMotion.gentle) {
            if isDone {
                let previousIndex = steps.index(before: steps.endIndex)
                index = previousIndex
                remaining = steps[previousIndex].seconds
                timerIndex = previousIndex
                readingRemaining = Self.readingSeconds
                repsDone = 0
                setsDone = 0
                setRestRemaining = 0
                setRestFillFraction = 0
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

    /// Swipe left advances; swipe right returns to the previous exercise.
    /// The completion screen also accepts a right swipe, matching its Back
    /// button. Bottom controls remain available for precision and VoiceOver.
    private var routineSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 24, coordinateSpace: .local)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical) * 1.25 else { return }

                let projected = value.predictedEndTranslation.width
                let distance = abs(projected) > abs(horizontal) ? projected : horizontal
                guard abs(distance) >= 72 else { return }

                if distance < 0 {
                    guard !isDone, !steps.isEmpty else { return }
                    advance()
                } else {
                    guard isDone || index > steps.startIndex else { return }
                    goBack()
                }

                UISelectionFeedbackGenerator().selectionChanged()
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
    let animatesProgressChanges: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let clampedProgress = min(max(progress, 0), 1)
            let progressAnimation: Animation = animatesProgressChanges
                ? .linear(duration: 1)
                : .linear(duration: 0.01)
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
                .fgAnimation(progressAnimation, value: clampedProgress)
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
nonisolated private struct LiquidWaveShape: Shape {
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
nonisolated private struct LiquidSurfaceShape: Shape {
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
