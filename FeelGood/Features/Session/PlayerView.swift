//
//  PlayerView.swift
//  FeelGood
//
//  The step timer for authored sessions. Pausable, resumable, and impossible
//  to fail: leaving early saves progress but is not a completion.
//

import SwiftUI

struct PlayerView: View {
    let session: Session
    let onFinish: (PlayerResult) -> Void
    /// When Start was tapped, so the record reflects real elapsed time.
    let startedAt: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0
    @State private var remaining = 0
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
    /// A separate, cooler pulse marking that a step has begun — every step,
    /// counted or timed. Deliberately a different hue from the ending flash
    /// (sage, not gold) so the two moments never read as the same event.
    @State private var stepStartOpacity = 0.0
    /// The counter is the whole tap target, and it grows with Dynamic Type —
    /// this is used mid-movement, often without looking straight at it.
    @ScaledMetric(relativeTo: .largeTitle) private var counterHeight = 180.0
    @State private var isRunning = true
    @State private var isDone = false

    private var steps: [Step] { session.source.steps }
    private var step: Step? { steps.indices.contains(index) ? steps[index] : nil }

    init(
        session: Session,
        progress: SessionProgress? = nil,
        onFinish: @escaping (PlayerResult) -> Void,
        startedAt: Date
    ) {
        self.session = session
        self.onFinish = onFinish
        self.startedAt = startedAt

        let validIndex = progress.map { min(max($0.stepIndex, 0), max(session.source.steps.count - 1, 0)) } ?? 0
        let fullDuration = session.source.steps.indices.contains(validIndex)
            ? session.source.steps[validIndex].seconds
            : 0
        let initialRemaining = progress.map { min(max($0.remainingSeconds, 1), max(fullDuration, 1)) }
            ?? fullDuration
        _index = State(initialValue: validIndex)
        _remaining = State(initialValue: initialRemaining)
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
            } else if case .youtube(let videoID, let channel) = session.source {
                videoPlayer(videoID: videoID, channel: channel)
            } else if let step {
                running(step)
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
                timerIndex = index
                repsDone = 0
                setsDone = 0
                isInFinalStretch = false
                hasFiredFinalStretchFlash = false
                flashOpacity = 0
            }
            // Counted exercises advance through taps, not a hidden timer.
            guard !step.isCounted else { return }
            while remaining > 0 && !isDone {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                if isRunning {
                    remaining -= 1
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

    /// The label as a floating pill rather than loose icon-over-text. The
    /// scrim behind it already carries the legibility work for an arbitrary
    /// photo, so on 26 the pill can afford to be clear glass rather than a
    /// second, flatter dimming layer stacked on top of the first.
    private var watchElsewhereLabel: some View {
        Group {
            if #available(iOS 26, *) {
                HStack(spacing: FGSpace.xs) {
                    Image(systemName: "play.fill")
                    Text("Watch on YouTube")
                        .font(FGFont.label.weight(.medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, FGSpace.m)
                .padding(.vertical, FGSpace.s)
                .glassEffect(.clear.tint(.black.opacity(0.35)).interactive(), in: Capsule())
            } else {
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
        }
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

            Spacer()

            VStack(spacing: FGSpace.m) {
                Text(step.name)
                    .font(FGFont.display)
                    .foregroundStyle(FGColor.ink)
                    .multilineTextAlignment(.center)

                ExerciseDemoView(glossaryID: step.glossaryID)

                if step.isCounted, let perSet = step.reps {
                    counter(step, perSet: perSet)
                } else {
                    Text(timeString)
                        .font(.system(.largeTitle, design: .serif).monospacedDigit())
                        .foregroundStyle(FGColor.goldDeep)
                }

                Text(step.cue)
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.inkMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(spacing: FGSpace.s) {
                if !step.isCounted {
                    FGPrimaryButton(title: isRunning ? "Pause" : "Resume") {
                        isRunning.toggle()
                    }
                } else if repsDone > 0 || setsDone > 0 {
                    // Counting is only trustworthy if it is reversible. A
                    // thumb catches the card twice and the count is worse
                    // than useless without a way back — including back into
                    // the set before this one.
                    FGQuietButton("Undo one", systemImage: "arrow.uturn.backward") {
                        undoOne(step)
                    }
                }
                HStack {
                    if index > steps.startIndex {
                        FGQuietButton("Back", systemImage: "backward.end") { goBack() }
                    }
                    Spacer()
                    FGQuietButton("Next", systemImage: "forward.end") { advance() }
                }
            }
        }
        .padding(FGSpace.page)
    }

    private var completion: some View {
        VStack(spacing: FGSpace.l) {
            Spacer()
            ZStack {
                // The echo of the final-stretch flash, settling out for good.
                // Sits behind "Done." only — never behind any one Feel
                // choice below, so it can't read as nudging an answer.
                FGAura.butter.core
                    .opacity(0.55)
                    .frame(width: 280, height: 220)
                    .blur(radius: 46)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                VStack(spacing: FGSpace.l) {
                    Text("Done.")
                        .font(FGFont.display)
                        .foregroundStyle(FGColor.ink)
                    Text("How did that feel?")
                        .font(FGFont.body)
                        .foregroundStyle(FGColor.inkMuted)
                }
            }

            feelChoices
            FGQuietButton("Back to last exercise", systemImage: "backward.end") {
                goBack()
            }
            FGQuietButton("Skip") { onFinish(.completed(nil)) }
            Spacer()
        }
        .padding(FGSpace.page)
        // Full bleed here: this is the only screen empty enough to carry it,
        // and the only one where decoration is the point.
        .background(FGBrandWash().ignoresSafeArea())
    }

    /// Three real selection controls floating over the full-bleed wash —
    /// grouped so they blend into one glass shape the way related controls
    /// should, rather than three separate floating tiles.
    private var feelChoices: some View {
        Group {
            if #available(iOS 26, *) {
                GlassEffectContainer(spacing: FGSpace.m) {
                    HStack(spacing: FGSpace.m) {
                        ForEach(Feel.allCases, id: \.self) { feel in
                            feelChoiceLabel(feel)
                                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
                        }
                    }
                }
            } else {
                HStack(spacing: FGSpace.m) {
                    ForEach(Feel.allCases, id: \.self) { feel in
                        feelChoiceLabel(feel)
                            .background(
                                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                                    .fill(FGColor.surface)
                            )
                    }
                }
            }
        }
    }

    private func feelChoiceLabel(_ feel: Feel) -> some View {
        Button {
            onFinish(.completed(feel))
        } label: {
            VStack(spacing: FGSpace.xs) {
                Image(systemName: symbol(for: feel))
                    .font(.title)
                Text(label(for: feel))
                    .font(FGFont.caption)
            }
            .frame(maxWidth: .infinity, minHeight: FGSize.minTouchTarget + 24)
            .foregroundStyle(FGColor.ink)
        }
        .buttonStyle(.plain)
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
                repsDone = 0
                setsDone = 0
                // Instant, not eased with the rest of this transaction —
                // leaving warmth behind should never look like a fade.
                withAnimation(.none) {
                    isInFinalStretch = false
                    hasFiredFinalStretchFlash = false
                    flashOpacity = 0
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
        case .tooMuch: "tortoise"
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

nonisolated enum PlayerResult: Equatable, Sendable {
    case paused(SessionProgress)
    case completed(Feel?)
}
