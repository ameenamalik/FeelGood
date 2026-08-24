//
//  OnboardingView.swift
//  FeelGood
//
//  One question per screen. Ends on a real menu, not a sign-up.
//

import SwiftUI

struct OnboardingView: View {
    @State private var model = OnboardingModel()
    /// Handed the finished profile; persistence and routing happen upstream.
    let onFinish: (OnboardingModel) -> Void

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

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
            AccessChoices(activities: $model.activities, equipment: $model.equipment)

        case .cadence:
            choiceGrid(Cadence.allCases, label: \.label, selection: $model.cadence)

        case .time:
            choiceGrid([10, 20, 30, 45], label: { $0 == 45 ? "45+ min" : "\($0) min" }, selection: $model.realisticMinutes)

        case .timeOfDay:
            choiceGrid(TimeOfDay.allCases, label: \.label, selection: $model.timeOfDay)

        case .intent:
            choiceGrid(Intent.allCases, label: \.label, selection: $model.intent)

        case .workArounds:
            VStack(alignment: .leading, spacing: FGSpace.s) {
                FlowRow(spacing: FGSpace.s) {
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

    private func choiceGrid<Option: Hashable>(
        _ options: [Option],
        label: @escaping (Option) -> String,
        selection: Binding<Option>
    ) -> some View {
        VStack(spacing: FGSpace.s) {
            ForEach(options, id: \.self) { option in
                FGChoice(title: label(option), isSelected: selection.wrappedValue == option) {
                    withAnimation(FGMotion.gentle) { selection.wrappedValue = option }
                }
            }
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
            FGPrimaryButton(title: model.isLastCard ? "Show me today" : "Next") {
                if model.isLastCard {
                    onFinish(model)
                } else {
                    model.advance()
                }
            }
            .opacity(model.canAdvance ? 1 : 0.4)
            .disabled(!model.canAdvance)

            if !model.isFirstCard {
                FGQuietButton("Back", systemImage: "chevron.left") { model.goBack() }
            } else if !model.canAdvance {
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
