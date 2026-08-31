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
    @State private var index: Int
    @State private var remaining: Int
    @State private var timerIndex: Int
    /// Reps tapped in the current set, never across the whole exercise.
    @State private var repsDone: Int
    /// Sets already finished in the current exercise.
    @State private var setsDone: Int
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
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

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
            if timerIndex != index {
                remaining = step.seconds
                timerIndex = index
                repsDone = 0
                setsDone = 0
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

                YouTubeWebView(videoID: videoID)
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
                        .foregroundStyle(FGColor.skyDeep)
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
                    .foregroundStyle(FGColor.skyDeep)
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
