//
//  OnboardingView.swift
//  FeelGood
//
//  One question per screen. Ends on a real menu; account creation remains out
//  of the way until the person has completed their first session.
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
                                    .font(onboardingTitleFont)
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
                        .fgAnimation(FGMotion.gentle, value: model.card)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    // The footer's real, dynamic height is reserved by the
                    // scroll view. This stays correct when Back or validation
                    // copy appears, on short screens, and at larger text sizes.
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        footer
                            .padding(.horizontal, FGSpace.page)
                            .padding(.top, FGSpace.s)
                            .padding(.bottom, FGSpace.s)
                    }
                    .onChange(of: model.card) { _, _ in
                        scrollProxy.scrollTo("onboarding-top", anchor: .top)
                    }
                }
            }
        }
    }

    // MARK: Progress

    private var onboardingTitleFont: Font {
        .system(.largeTitle, design: .rounded).weight(.semibold)
    }

    private var progressBar: some View {
        // A quiet position indicator, not a score. Each segment is its own
        // small track so the newly-reached one visibly fills left-to-right
        // on transition instead of the whole capsule snapping to `ink`.
        HStack(spacing: FGSpace.xs) {
            ForEach(OnboardingModel.Card.allCases, id: \.self) { card in
                GeometryReader { geometry in
                    Capsule()
                        .fill(FGColor.line)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(FGColor.ink)
                                .frame(width: card.rawValue <= model.card.rawValue ? geometry.size.width : 0)
                        }
                }
                .frame(height: 4)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Question \(model.card.rawValue + 1) of \(OnboardingModel.Card.allCases.count)")
        .fgAnimation(FGMotion.gentle, value: model.card)
    }

    // MARK: Answers

    @ViewBuilder
    private var answers: some View {
        switch model.card {
        case .guidance:
            VStack(spacing: FGSpace.m) {
                ForEach(GuidancePreference.allCases, id: \.self) { preference in
                    GuidancePreferenceCard(
                        preference: preference,
                        isSelected: model.selectedGuidancePreference == preference
                    ) {
                        // An immediate state change avoids a dark-mode flash
                        // while one card loses its fill and another gains it.
                        model.selectedGuidancePreference = preference
                    }
                }
            }

        case .access:
            AccessChoices(
                activities: $model.activities,
                sports: $model.sports,
                equipment: $model.equipment,
                places: $model.places,
                showsSymbols: false,
                usesAura: false,
                usesPills: true
            )

        case .intent:
            FlowRow(
                spacing: FGSpace.choiceGutter,
                maxPerRow: typeSize.isAccessibilitySize ? 1 : 2,
                minimumItemWidth: 140
            ) {
                ForEach(Intent.allCases, id: \.self) { intent in
                    intentCard(intent)
                }
            }

        case .workArounds:
            // Pills, not tiles. This question is a list of things to rule out,
            // and the artboard makes it the quietest thing on the page —
            // ruling something out should not feel like a bigger decision than
            // everything asked before it.
            VStack(alignment: .leading, spacing: FGSpace.m) {
                WrapRow(spacing: FGSpace.s, lineSpacing: FGSpace.s) {
                    ForEach(Array(WorkAround.allCases.enumerated()), id: \.element) { index, workAround in
                        FGPill(
                            title: workAround.label,
                            selectedAura: pillAura(at: index),
                            isSelected: model.workArounds.contains(workAround)
                        ) {
                            toggle(workAround, in: \.workArounds)
                        }
                    }
                    FGPill(
                        title: "None of these",
                        selectedAura: .lilac,
                        isSelected: model.workArounds.isEmpty
                    ) {
                        withAnimation(FGMotion.gentle) { model.workArounds = [] }
                    }
                }

                Text("FeelGood provides general wellness recommendations and is not a substitute for medical advice or physical therapy.")
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
                    .padding(.top, FGSpace.s)

                if model.workArounds.contains(.other) {
                    Text("We can’t tailor an unspecified need. Skip anything that doesn’t feel right.")
                        .font(FGFont.caption)
                        .foregroundStyle(FGColor.inkMuted)
                }
            }
        }
    }

    private func intentCard(_ intent: Intent) -> some View {
        FGAuraTile(
            title: intent.label,
            detail: intentDetail(intent),
            artworkName: intentArtworkName(intent),
            artworkSize: intent == .joy ? 104 : 92,
            artworkAlignment: .top,
            contentPlacement: .bottomLeading,
            preferredHeight: 156,
            showsAuraAtRest: false,
            aura: intentAura(intent),
            isSelected: model.intents.contains(intent)
        ) {
            toggle(intent, in: \.intents)
        }
    }

    private func intentDetail(_ intent: Intent) -> String {
        switch intent {
        case .energize: "Feel more awake"
        case .strengthen: "Build steady power"
        case .calm: "Settle your system"
        case .mobilize: "Move more freely"
        case .joy: "Keep it gentle"
        case .play: "Move for the fun of it"
        }
    }

    private func intentArtworkName(_ intent: Intent) -> String {
        switch intent {
        case .energize: "IntentEnergyClementine"
        case .strengthen: "IntentStrengthPlum"
        case .calm: "IntentCalmPeach"
        case .mobilize: "IntentMobilityPear"
        case .joy: "IntentShowingUpBanana"
        case .play: "IntentPlayLime"
        }
    }

    private func intentAura(_ intent: Intent) -> FGAura {
        switch intent {
        case .energize: .apricot
        case .strengthen: .lilac
        case .calm: .blush
        case .mobilize: .sage
        case .joy: .butter
        case .play: .blush
        }
    }

    private func pillAura(at index: Int) -> FGAura {
        let palette: [FGAura] = [.apricot, .lilac, .blush, .sage]
        return palette[index % palette.count]
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
            HStack(spacing: FGSpace.s) {
                if !model.isFirstCard {
                    Button {
                        model.goBack()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(FGFont.body.weight(.medium))
                            .foregroundStyle(FGColor.ink)
                            .frame(minWidth: 92, minHeight: 56)
                            .padding(.horizontal, FGSpace.s)
                            .background(FGColor.surface, in: Capsule())
                            .overlay {
                                Capsule()
                                    .strokeBorder(FGColor.lineStrong, lineWidth: 1.5)
                            }
                    }
                    .buttonStyle(.feelGoodPress)
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

        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    OnboardingView { _ in }
}

private struct GuidancePreferenceCard: View {
    let preference: GuidancePreference
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var colorScheme

    private var aura: FGAura {
        switch preference {
        case .gettingStarted: .blush
        case .knowsWhatTheyEnjoy: .sage
        case .hasOwnRoutine: .apricot
        }
    }

    private var artworkName: String {
        switch preference {
        case .gettingStarted: "IntentShowingUpBanana"
        case .knowsWhatTheyEnjoy: "IntentMobilityPear"
        case .hasOwnRoutine: "IntentStrengthPlum"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: FGSpace.m) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(preference.label)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(FGColor.inkOnAccent)
                        .multilineTextAlignment(.leading)

                    Text(preference.detail)
                        .font(FGFont.reason)
                        .foregroundStyle(FGColor.inkOnAccent)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !typeSize.isAccessibilitySize {
                    Image(artworkName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 94, height: 94)
                        .accessibilityHidden(true)
                }
            }
            .padding(.leading, FGSpace.l)
            .padding(.trailing, FGSpace.m)
            .padding(.vertical, FGSpace.s)
            .frame(
                maxWidth: .infinity,
                minHeight: typeSize.isAccessibilitySize ? nil : 120,
                alignment: .leading
            )
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: cardColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(
                        isSelected ? selectedBorder : FGColor.inkOnAccent.opacity(0.24),
                        lineWidth: isSelected ? 5 : 1.5
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preference.label), \(preference.detail)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var selectedBorder: Color {
        colorScheme == .dark ? FGColor.ink : FGColor.inkOnAccent
    }

    private var cardColors: [Color] {
        if isSelected {
            [aura.mid, aura.edge.opacity(0.9)]
        } else {
            [FGColor.neutralChoiceFill, FGColor.neutralChoiceFill]
        }
    }
}
