//
//  OnboardingView.swift
//  FeelGood
//
//  One question per screen. Ends on a real menu, not a sign-up.
//

import SwiftUI
import PostHog

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

            GeometryReader { geometry in
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: FGSpace.l) {
                            progressBar
                                .id("onboarding-top")

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

                            answers
                                .postHogMask()
                        }
                        .frame(
                            minHeight: max(0, geometry.size.height - (FGSpace.page * 2)),
                            alignment: .top
                        )
                        .padding(FGSpace.page)
                        // Room for the footer. `.safeAreaInset` is applied to
                        // the reader rather than the scroll view, so it insets
                        // the container without reserving any scroll content —
                        // the last tile ended up under the Next button.
                        .padding(.bottom, FGSize.minTouchTarget + FGSpace.xl)
                        .fgAnimation(FGMotion.gentle, value: model.card)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .onChange(of: model.card) { _, _ in
                        scrollProxy.scrollTo("onboarding-top", anchor: .top)
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    footer
                        .padding(.horizontal, FGSpace.page)
                        .padding(.vertical, FGSpace.s)
                }
            }
        }
    }

    // MARK: Progress

    private var progressBar: some View {
        // A quiet position indicator, not a score.
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
                places: $model.places,
                showsSymbols: true,
                usesAura: true
            )

        case .cadence:
            VStack(alignment: .leading, spacing: FGSpace.l) {
                answerGroup("Each week") {
                    ForEach(Cadence.allCases, id: \.self) { option in
                        FGAuraTile(
                            title: option.label,
                            systemImage: option.onboardingSymbol,
                            aura: .apricot,
                            isSelected: model.cadence == option
                        ) {
                            withAnimation(FGMotion.gentle) { model.cadence = option }
                        }
                    }
                }
                answerGroup("Each day") {
                    ForEach(MovementMoments.allCases, id: \.self) { option in
                        FGAuraTile(
                            title: option.label,
                            systemImage: option.onboardingSymbol,
                            aura: .sage,
                            isSelected: model.moments == option
                        ) {
                            withAnimation(FGMotion.gentle) { model.moments = option }
                        }
                    }
                }
            }

        case .intent:
            FlowRow.choices(isAccessibilitySize: typeSize.isAccessibilitySize) {
                ForEach(Intent.allCases, id: \.self) { intent in
                    FGAuraTile(
                        title: intent.label,
                        systemImage: intent.onboardingSymbol,
                        aura: .lilac,
                        isSelected: model.intents.contains(intent)
                    ) {
                        toggle(intent, in: \.intents)
                    }
                }
            }

        case .workArounds:
            // Pills, not tiles. This question is a list of things to rule out,
            // and the artboard makes it the quietest thing on the page —
            // ruling something out should not feel like a bigger decision than
            // everything asked before it.
            WrapRow(spacing: FGSpace.s, lineSpacing: FGSpace.s) {
                ForEach(WorkAround.allCases, id: \.self) { workAround in
                    FGPill(
                        title: workAround.label,
                        isSelected: model.workArounds.contains(workAround)
                    ) {
                        toggle(workAround, in: \.workArounds)
                    }
                }
                FGPill(title: "None of these", isSelected: model.workArounds.isEmpty) {
                    withAnimation(FGMotion.gentle) { model.workArounds = [] }
                }
            }
        }
    }


    private func answerGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            Text(title)
                .font(FGFont.body.weight(.medium))
                .foregroundStyle(FGColor.ink)

            FlowRow.choices(isAccessibilitySize: typeSize.isAccessibilitySize) { content() }
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
            if !model.canAdvance {
                Text("Pick at least one thing to get started.")
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
            }

            if !model.isFirstCard {
                FGQuietButton("Back", systemImage: "chevron.left") {
                    model.goBack()
                }
            }

            FGPrimaryButton(
                title: model.isLastCard ? "Show me today" : "Next",
                isEnabled: model.canAdvance
            ) {
                if model.isLastCard {
                    Analytics.capture("onboarding_completed")
                    onFinish(model)
                } else {
                    model.advance()
                }
            }

        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    OnboardingView { _ in }
}
