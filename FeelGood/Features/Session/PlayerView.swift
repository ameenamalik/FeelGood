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
    let onFinish: (Feel?) -> Void
    /// When Start was tapped, so the record reflects real elapsed time.
    let startedAt: Date

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var remaining = 0
    @State private var isRunning = true
    @State private var isDone = false

    private var steps: [Step] { session.source.steps }
    private var step: Step? { steps.indices.contains(index) ? steps[index] : nil }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            if isDone {
                completion
            } else if let step {
                running(step)
            }
        }
        .task(id: index) {
            guard let step else { return }
            remaining = step.seconds
            while remaining > 0 && !isDone {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                if isRunning { remaining -= 1 }
            }
            if remaining <= 0 { advance() }
        }
    }

    private func running(_ step: Step) -> some View {
        VStack(spacing: FGSpace.l) {
            HStack {
                FGQuietButton("Leave", systemImage: "xmark") { onFinish(nil) }
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

                Text(timeString)
                    .font(.system(.largeTitle, design: .serif).monospacedDigit())
                    .foregroundStyle(FGColor.skyDeep)

                Text(step.cue)
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.inkMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(spacing: FGSpace.s) {
                FGPrimaryButton(title: isRunning ? "Pause" : "Resume") {
                    isRunning.toggle()
                }
                FGQuietButton("Next", systemImage: "forward.end") { advance() }
                    .frame(maxWidth: .infinity)
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
                        onFinish(feel)
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
            FGQuietButton("Skip") { onFinish(nil) }
            Spacer()
        }
        .padding(FGSpace.page)
    }

    private var timeString: String {
        String(format: "%d:%02d", remaining / 60, remaining % 60)
    }

    private func advance() {
        if index + 1 < steps.count {
            withAnimation(FGMotion.gentle) { index += 1 }
        } else {
            withAnimation(FGMotion.gentle) { isDone = true }
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
