//
//  PlayerView.swift
//  FeelGood
//
//  The step timer for authored sessions. Pausable, skippable, and impossible
//  to fail: leaving early is a perfectly good outcome.
//

import SwiftUI

struct PlayerView: View {
    let session: Session
    /// Called on finishing or leaving. `feel` is nil when the session was left
    /// early or the question was skipped — both are fine, and both still count
    /// as having shown up.
    let onFinish: (Feel?, Bool) -> Void
    /// When Start was tapped, so the record reflects real elapsed time.
    let startedAt: Date

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var remaining = 0
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

    private var steps: [Step] { session.source.steps }
    private var step: Step? { steps.indices.contains(index) ? steps[index] : nil }

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
            repsDone = 0
            setsDone = 0
            // A counted step has no clock to run: it advances on taps, not
            // on time, so the timer loop must not claim it.
            guard let step, !step.isCounted else { return }
            remaining = step.seconds
            while remaining > 0 && !isDone {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                if isRunning { remaining -= 1 }
            }
            if remaining <= 0 { advance() }
        }
    }

    private func videoPlayer(videoID: String, channel: String) -> some View {
        VStack(spacing: FGSpace.l) {
            HStack {
                FGQuietButton("Leave", systemImage: "xmark") { onFinish(nil, false) }
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
            FGColor.surface
            VStack(spacing: FGSpace.m) {
                Image(systemName: "play.rectangle")
                    .font(.largeTitle)
                    .foregroundStyle(FGColor.inkMuted)
                if let watchURL = URL(string: "https://www.youtube.com/watch?v=\(videoID)") {
                    Link("Watch on YouTube", destination: watchURL)
                        .font(FGFont.label)
                        .foregroundStyle(FGColor.ink)
                }
            }
            .padding(FGSpace.m)
        }
    }

    private func running(_ step: Step) -> some View {
        VStack(spacing: FGSpace.l) {
            HStack {
                FGQuietButton("Leave", systemImage: "xmark") { onFinish(nil, false) }
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
                        onFinish(feel, true)
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
            FGQuietButton("Skip") { onFinish(nil, true) }
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

    private func goBack() {
        guard !steps.isEmpty else { return }
        withAnimation(FGMotion.gentle) {
            if isDone {
                index = steps.index(before: steps.endIndex)
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
