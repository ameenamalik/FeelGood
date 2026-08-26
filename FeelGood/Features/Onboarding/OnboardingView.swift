//
//  OnboardingView.swift
//  FeelGood
//
//  One question per screen. Ends on a real menu, not a sign-up.
//

import SwiftUI

struct OnboardingView: View {
    @State private var model = OnboardingModel()
    @Environment(\.dynamicTypeSize) private var typeSize
    /// Handed the finished profile; persistence and routing happen upstream.
    let onFinish: (OnboardingModel) -> Void

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            // The app's first impression, since there is no account screen to
            // make one on. Low enough to sit behind the footer, not the
            // question.
            FGBrandWash(reach: 0.5)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: FGSpace.l) {
                progressBar

                VStack(alignment: .leading, spacing: FGSpace.s) {
                    Text(model.card.title)
                        .font(FGFont.title)
                        .foregroundStyle(FGColor.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    if let detail = model.card.detail {
                        Text(detail)
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)

                ScrollView {
                    answers
                        .padding(.bottom, FGSpace.m)
                }
                .scrollBounceBehavior(.basedOnSize)

                footer
            }
            .padding(FGSpace.page)
            .fgAnimation(FGMotion.gentle, value: model.card)
        }
    }

    // MARK: Progress

    private var progressBar: some View {
        // A quiet position indicator, not a score. Six short questions is
        // worth showing; anything more would need a different app.
        HStack(spacing: FGSpace.xs) {
            ForEach(OnboardingModel.Card.allCases, id: \.self) { card in
                Capsule()
                    .fill(card.rawValue <= model.card.rawValue ? FGColor.ink : FGColor.line)
                    .frame(height: 4)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Question \(model.card.rawValue + 1) of \(OnboardingModel.Card.allCases.count)")
    }

    // MARK: Answers

    @ViewBuilder
    private var answers: some View {
        switch model.card {
        case .access:
            AccessChoices(
                activities: $model.activities,
                equipment: $model.equipment,
                places: $model.places
            )

        case .cadence:
            VStack(alignment: .leading, spacing: FGSpace.l) {
                answerGroup("Across the week") {
                    ForEach(Cadence.allCases, id: \.self) { option in
                        FGChoice(title: option.label, isSelected: model.cadence == option) {
                            withAnimation(FGMotion.gentle) { model.cadence = option }
                        }
                    }
                }
                answerGroup("Within a day") {
                    ForEach(MovementMoments.allCases, id: \.self) { option in
                        FGChoice(title: option.label, isSelected: model.moments == option) {
                            withAnimation(FGMotion.gentle) { model.moments = option }
                        }
                    }
                }
            }

        case .time:
            VStack(alignment: .leading, spacing: FGSpace.l) {
                answerGroup("On a normal day") {
                    ForEach([10, 20, 30, 45], id: \.self) { minutes in
                        FGChoice(title: minutes == 45 ? "45+ min" : "\(minutes) min", isSelected: model.realisticMinutes == minutes) {
                            withAnimation(FGMotion.gentle) { model.realisticMinutes = minutes }
                        }
                    }
                }
                answerGroup("When you have the most in you") {
                    ForEach(TimeOfDay.allCases, id: \.self) { option in
                        FGChoice(title: option.label, isSelected: model.timeOfDay == option) {
                            withAnimation(FGMotion.gentle) { model.timeOfDay = option }
                        }
                    }
                }
            }

        case .intent:
            VStack(spacing: FGSpace.s) {
                ForEach(Intent.allCases, id: \.self) { intent in
                    FGChoice(title: intent.label, isSelected: model.intents.contains(intent)) {
                        toggle(intent, in: \.intents)
                    }
                }
            }

        case .workArounds:
            VStack(alignment: .leading, spacing: FGSpace.s) {
                FlowRow(spacing: FGSpace.s, maxPerRow: typeSize.isAccessibilitySize ? 1 : 3) {
                    ForEach(WorkAround.allCases, id: \.self) { workAround in
                        FGChoice(title: workAround.label, isSelected: model.workArounds.contains(workAround)) {
                            toggle(workAround, in: \.workArounds)
                        }
                    }
                }
                FGChoice(title: "None of these", isSelected: model.workArounds.isEmpty) {
                    withAnimation(FGMotion.gentle) { model.workArounds = [] }
                }
            }
        }
    }


    private func answerGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            Text(title)
                .font(FGFont.label)
                .foregroundStyle(FGColor.inkMuted)
                .textCase(.uppercase)
                .tracking(1.1)
            FlowRow(spacing: FGSpace.s, maxPerRow: typeSize.isAccessibilitySize ? 1 : 3) { content() }
        }
    }

    private func toggle<T: Hashable>(_ value: T, in keyPath: ReferenceWritableKeyPath<OnboardingModel, Set<T>>) {
        withAnimation(FGMotion.gentle) {
            if model[keyPath: keyPath].contains(value) {
                model[keyPath: keyPath].remove(value)
            } else {
                model[keyPath: keyPath].insert(value)
            }
        }
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: FGSpace.s) {
            FGPrimaryButton(
                title: model.isLastCard ? "Show me today" : "Next",
                isEnabled: model.canAdvance
            ) {
                if model.isLastCard {
                    onFinish(model)
                } else {
                    model.advance()
                }
            }

            if !model.isFirstCard {
                FGQuietButton("Back", systemImage: "chevron.left") { model.goBack() }
            }

            if !model.canAdvance {
                // Only `.access` is `isRequired`, so this can only ever render
                // there — a single, always-correct message rather than a
                // per-card ternary implying an enforcement that doesn't exist
                // on any other card.
                Text("Pick at least one thing to get started.")
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    OnboardingView { _ in }
}
