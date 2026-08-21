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
            VStack(alignment: .leading, spacing: FGSpace.l) {
                answerGroup("Movement") {
                    ForEach(Activity.allCases, id: \.self) { activity in
                        FGChoice(title: activity.label, isSelected: model.activities.contains(activity)) {
                            toggle(activity, in: \.activities)
                        }
                    }
                }
                answerGroup("Equipment") {
                    ForEach(Equipment.allCases.filter { $0 != .none }, id: \.self) { item in
                        FGChoice(title: item.label ?? "", isSelected: model.equipment.contains(item)) {
                            toggle(item, in: \.equipment)
                        }
                    }
                }
                answerGroup("Where") {
                    ForEach(Place.allCases, id: \.self) { place in
                        FGChoice(title: place.label, isSelected: model.places.contains(place)) {
                            toggle(place, in: \.places)
                        }
                    }
                }
            }

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
            choiceGrid([10, 20, 30, 45], label: { $0 == 45 ? "45+ min" : "\($0) min" }, selection: $model.realisticMinutes)

        case .timeOfDay:
            choiceGrid(TimeOfDay.allCases, label: \.label, selection: $model.timeOfDay)

        case .intent:
            choiceGrid(Intent.allCases, label: \.label, selection: $model.intent)

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
            } else if model.activities.isEmpty {
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
