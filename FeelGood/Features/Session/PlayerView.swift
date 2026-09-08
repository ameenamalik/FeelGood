//
//  PlayerView.swift
//  FeelGood
//
//  The step timer for authored sessions. Pausable, resumable, and impossible
//  to fail: leaving early saves progress but is not a completion.
//

import SwiftUI

struct PlayerView: View {
    private static let readingSeconds = 5

    let session: Session
    let onFinish: (PlayerResult) -> Void
    /// When Start was tapped, so the record reflects real elapsed time.
    let startedAt: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var index = 0
    @State private var remaining = 0
    /// A short buffer at the start of each new step. This is separate from the
    /// exercise timer so reading the cue never consumes movement time.
    @State private var readingRemaining: Int
    /// Which exercise `remaining` currently belongs to. A resumed exercise
    /// keeps its saved time; moving to another one resets to its full time.
    @State private var timerIndex: Int
    /// Reps tapped so far **in the current set**, never across the step.
    @State private var repsDone = 0
    /// Sets already finished in this step. `setsDone + 1` is the set someone
    /// is standing in the middle of.
    @State private var setsDone = 0
    /// The counter is the whole tap target, and it grows with Dynamic Type —
    /// this is used mid-movement, often without looking straight at it.
    @ScaledMetric(relativeTo: .largeTitle) private var counterHeight = 180.0
    @State private var isRunning = true
    @State private var isDone = false
    @State private var breathingStartedAt = Date()
    @State private var breathingPausedAt: Date?
    @State private var breathingAnchorIndex: Int?

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
        _readingRemaining = State(
            initialValue: progress == nil && !session.source.steps.isEmpty
                ? Self.readingSeconds
                : 0
        )
        _timerIndex = State(initialValue: validIndex)
        _repsDone = State(initialValue: max(progress?.repsDone ?? 0, 0))
        _setsDone = State(initialValue: max(progress?.setsDone ?? 0, 0))
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            if isDone {
                completion
            } else if case .youtube(let videoID, let channel) = session.source {
                videoPlayer(videoID: videoID, channel: channel)
            } else if let step {
                if isBreathingStep(step) {
                    SessionBreathingProgress(
                        progress: completionProgress(for: step),
                        aura: FGAura.allCases[index % FGAura.allCases.count],
                        isActive: readingRemaining == 0 && isRunning,
                        startedAt: breathingStartedAt,
                        pausedAt: breathingPausedAt
                    )
                } else {
                    SessionLiquidProgress(
                        progress: completionProgress(for: step),
                        aura: FGAura.allCases[index % FGAura.allCases.count],
                        isActive: readingRemaining == 0 && (step.isCounted || isRunning)
                    )
                }
                running(step)
            }
        }
        .task(id: index) {
            guard let step else { return }
            if timerIndex != index {
                remaining = step.seconds
                readingRemaining = Self.readingSeconds
                timerIndex = index
                repsDone = 0
                setsDone = 0
            }

            while readingRemaining > 0 && !isDone {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                guard readingRemaining > 0 else { break }
                readingRemaining -= 1
            }

            if isBreathingStep(step), breathingAnchorIndex != index {
                restartBreathingCycle()
            }

            // Counted exercises advance through taps, not a hidden timer.
            guard !step.isCounted else { return }
            while remaining > 0 && !isDone {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                if isRunning { remaining -= 1 }
            }
            if remaining <= 0 { advance() }
        }
        // Every intentional exit goes through Leave so the current timer can
        // be saved before this full-screen player disappears.
        .interactiveDismissDisabled()
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

                Text(step.cue)
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.inkMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if readingRemaining == 0 && isBreathingStep(step) {
                    BreathingPhaseLabel(
                        isActive: isRunning,
                        startedAt: breathingStartedAt,
                        pausedAt: breathingPausedAt
                    )
                }

                if readingRemaining > 0 {
                    readingCountdown
                } else if step.isCounted, let perSet = step.reps {
                    counter(step, perSet: perSet)
                } else {
                    Text(timeString)
                        .font(.system(.largeTitle, design: .serif).monospacedDigit())
                        .foregroundStyle(FGColor.goldDeep)
                }

            }

            Spacer()

            VStack(spacing: FGSpace.s) {
                if readingRemaining > 0 {
                    FGPrimaryButton(title: "Start now") {
                        readingRemaining = 0
                        if isBreathingStep(step) { restartBreathingCycle() }
                    }
                } else if !step.isCounted {
                    FGPrimaryButton(title: isRunning ? "Pause" : "Resume") {
                        toggleRunning(for: step)
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

    private var readingCountdown: some View {
        VStack(spacing: FGSpace.xs) {
            Text("Get ready")
                .font(FGFont.label)
                .foregroundStyle(FGColor.inkMuted)

            Text("\(readingRemaining)")
                .font(.system(.largeTitle, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundStyle(FGColor.goldDeep)
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Starting in \(readingRemaining) seconds")
    }

    private var completion: some View {
        VStack(spacing: FGSpace.l) {
            Spacer()
            Text("Done.")
                .font(FGFont.display)
                .foregroundStyle(FGColor.ink)
            Text("How did that feel?")
                .font(FGFont.body)
                .foregroundStyle(FGColor.inkMuted)

            HStack(spacing: FGSpace.m) {
                ForEach(Feel.allCases, id: \.self) { feel in
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
                        .background(
                            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                                .fill(FGColor.surface)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
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

    /// Breathing gets a paced visual only when it is the exercise itself.
    /// Looking only at the cue would incorrectly turn ordinary stretches into
    /// breathing exercises because many of them casually say "keep breathing."
    private func isBreathingStep(_ step: Step) -> Bool {
        let name = step.name.lowercased()
        let breathingNames = ["breath", "breathe", "breathing", "inhale", "exhale"]
        if breathingNames.contains(where: name.contains) { return true }

        let cue = step.cue.lowercased()
        let explicitCadences = ["inhale for", "exhale for", "4-in", "4-out"]
        return explicitCadences.contains(where: cue.contains)
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

/// A breathing-specific alternative to the rising waterline. The orb grows
/// for a four-second inhale and softens back over a longer six-second exhale;
/// the asymmetry keeps it calm rather than feeling like a metronome. The thin
/// outer arc still shows overall exercise progress independently of each breath.
private struct SessionBreathingProgress: View {
    let progress: Double
    let aura: FGAura
    let isActive: Bool
    let startedAt: Date
    let pausedAt: Date?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            TimelineView(
                .animation(
                    minimumInterval: 1.0 / 60.0,
                    paused: reduceMotion || !isActive
                )
            ) { timeline in
                let state = breathingCycleState(
                    at: timeline.date,
                    isActive: isActive,
                    reduceMotion: reduceMotion,
                    startedAt: startedAt,
                    pausedAt: pausedAt
                )
                let diameter = min(geometry.size.width * 0.82, geometry.size.height * 0.46)

                ZStack {
                    Circle()
                        .fill(aura.edge.opacity(0.16))
                        .frame(width: diameter * 0.92, height: diameter * 0.92)
                        .blur(radius: 24)
                        .scaleEffect(state.scale * 1.08)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    aura.core.opacity(0.82),
                                    aura.mid.opacity(0.56),
                                    aura.edge.opacity(0.25),
                                ],
                                center: .topLeading,
                                startRadius: 8,
                                endRadius: diameter * 0.58
                            )
                        )
                        .overlay {
                            Circle()
                                .stroke(FGColor.surface.opacity(0.55), lineWidth: 2)
                                .blur(radius: 0.5)
                        }
                        .frame(width: diameter, height: diameter)
                        .scaleEffect(state.scale)
                        .shadow(color: aura.edge.opacity(0.24), radius: 24, y: 12)

                    Circle()
                        .trim(from: 0, to: min(max(progress, 0), 1))
                        .stroke(
                            aura.edge.opacity(0.72),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: diameter * 1.06, height: diameter * 1.06)
                        .rotationEffect(.degrees(-90))
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Text and animation share the same clock, so "Breathe in" always appears
/// while the orb is expanding and "Breathe out" while it is contracting.
private struct BreathingPhaseLabel: View {
    let isActive: Bool
    let startedAt: Date
    let pausedAt: Date?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: 1.0 / 30.0,
                paused: reduceMotion || !isActive
            )
        ) { timeline in
            let state = breathingCycleState(
                at: timeline.date,
                isActive: isActive,
                reduceMotion: reduceMotion,
                startedAt: startedAt,
                pausedAt: pausedAt
            )

            Label(
                isActive && !reduceMotion ? state.label : (isActive ? "Breathe slowly" : "Paused"),
                systemImage: state.isInhaling ? "arrow.up" : "arrow.down"
            )
            .font(FGFont.label)
            .foregroundStyle(FGColor.goldDeep)
            .contentTransition(.opacity)
            .accessibilityLabel(
                isActive && !reduceMotion ? state.label : (isActive ? "Breathe slowly" : "Paused")
            )
        }
    }
}

private struct BreathingCycleState {
    let scale: CGFloat
    let isInhaling: Bool

    var label: String { isInhaling ? "Breathe in" : "Breathe out" }
}

/// Four seconds in, six seconds out. Cosine easing has zero velocity at both
/// ends of the breath, avoiding the mechanical snap of a linear reversal.
private func breathingCycleState(
    at date: Date,
    isActive: Bool,
    reduceMotion: Bool,
    startedAt: Date,
    pausedAt: Date?
) -> BreathingCycleState {
    guard !reduceMotion else {
        return BreathingCycleState(scale: 0.62, isInhaling: true)
    }

    let sampleDate = isActive ? date : (pausedAt ?? date)
    let elapsed = max(sampleDate.timeIntervalSince(startedAt), 0)
        .truncatingRemainder(dividingBy: 10)
    let isInhaling = elapsed < 4
    let linearProgress = isInhaling ? elapsed / 4 : (elapsed - 4) / 6
    let easedProgress = 0.5 - (0.5 * cos(.pi * linearProgress))
    let fullness = isInhaling ? easedProgress : 1 - easedProgress
    let scale = 0.56 + (CGFloat(fullness) * 0.44)

    return BreathingCycleState(scale: scale, isInhaling: isInhaling)
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
