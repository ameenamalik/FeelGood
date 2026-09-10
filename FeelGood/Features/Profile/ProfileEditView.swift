//
//  ProfileEditView.swift
//  FeelGood
//
//  The same six answers, asked again. Lives here rather than in a settings
//  screen full of switches: nothing on it is a setting, it is all just what is
//  true for you now. See PRD §7.1.
//

import SwiftUI
import PostHog

struct ProfileEditView: View {
    let onShowHiddenExercises: (() -> Void)?
    let onSave: (ProfileAnswers) -> Void

    @State private var answers: ProfileAnswers
    @Environment(\.dismiss) private var dismiss

    init(
        answers: ProfileAnswers,
        onShowHiddenExercises: (() -> Void)? = nil,
        onSave: @escaping (ProfileAnswers) -> Void
    ) {
        _answers = State(initialValue: answers)
        self.onShowHiddenExercises = onShowHiddenExercises
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            FGBrandWash(reach: 0.28)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    VStack(alignment: .leading, spacing: FGSpace.s) {
                        Text("What's true now")
                            .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                            .foregroundStyle(FGColor.ink)
                        Text("Change anything. Today's menu follows.")
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                    }

                    section("What do you have access to?") {
                        AccessChoices(
                            activities: $answers.activities,
                            sports: $answers.sports,
                            equipment: $answers.equipment,
                            places: $answers.places,
                            showsSymbols: false,
                            usesAura: false,
                            usesPills: true
                        )
                    }

                    section("How often do you want to move?") {
                        VStack(alignment: .leading, spacing: FGSpace.m) {
                            choices(Cadence.allCases, label: \.label, selection: $answers.cadence)
                            Text("Within a day")
                                .font(FGFont.label)
                                .foregroundStyle(FGColor.inkMuted)
                            choices(MovementMoments.allCases, label: \.label, selection: $answers.moments)
                        }
                    }

                    section("On a normal day, how much time is realistic?") {
                        choices([10, 20, 30, 45], label: { $0 == 45 ? "45+ min" : "\($0) min" },
                                selection: $answers.realisticMinutes)
                    }

                    section("When do you have the most in you?") {
                        choices(TimeOfDay.allCases, label: \.label, selection: $answers.bestTimeOfDay)
                    }

                    section("What are you moving toward?") {
                        WrapRow(spacing: FGSpace.s, lineSpacing: FGSpace.s) {
                            ForEach(Array(Intent.allCases.enumerated()), id: \.element) { index, intent in
                                FGPill(
                                    title: intent.label,
                                    selectedAura: pillAura(at: index),
                                    isSelected: answers.intents.contains(intent)
                                ) {
                                    withAnimation(FGMotion.gentle) {
                                        if answers.intents.contains(intent) {
                                            answers.intents.remove(intent)
                                        } else {
                                            answers.intents.insert(intent)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    section("Anything to work around?") {
                        VStack(alignment: .leading, spacing: FGSpace.s) {
                            WrapRow(spacing: FGSpace.s, lineSpacing: FGSpace.s) {
                                ForEach(Array(WorkAround.allCases.enumerated()), id: \.element) { index, workAround in
                                    FGPill(
                                        title: workAround.label,
                                        selectedAura: pillAura(at: index),
                                        isSelected: answers.workArounds.contains(workAround)
                                    ) {
                                        withAnimation(FGMotion.gentle) {
                                            if answers.workArounds.contains(workAround) {
                                                answers.workArounds.remove(workAround)
                                            } else {
                                                answers.workArounds.insert(workAround)
                                            }
                                        }
                                    }
                                }
                                FGPill(
                                    title: "None of these",
                                    selectedAura: .butter,
                                    isSelected: answers.workArounds.isEmpty
                                ) {
                                    withAnimation(FGMotion.gentle) { answers.workArounds = [] }
                                }
                            }
                        }
                        // `pregnancy`, `postpartum` and `pelvicFloor` are on this
                        // chip list, and which ones are selected is visible in the
                        // screenshot. Onboarding masks the same chips; this screen
                        // is the other place they can be set. The section heading
                        // stays legible — the question isn't sensitive, the answer is.
                        .postHogMask()
                    }

                    if let onShowHiddenExercises {
                        section("Exercise preferences") {
                            Button(action: onShowHiddenExercises) {
                                HStack(spacing: FGSpace.m) {
                                    Image(systemName: "eye.slash")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(FGColor.inkMuted)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Hidden exercises")
                                            .font(FGFont.body.weight(.semibold))
                                            .foregroundStyle(FGColor.ink)
                                        Text("Review anything you chose not to see.")
                                            .font(FGFont.caption)
                                            .foregroundStyle(FGColor.inkMuted)
                                    }

                                    Spacer(minLength: FGSpace.s)

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(FGColor.inkMuted)
                                }
                                .padding(FGSpace.m)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(FGColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                                        .strokeBorder(FGColor.line, lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                }
                .padding(FGSpace.page)
                .padding(.bottom, FGSpace.xl)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .presentationDragIndicator(.visible)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: FGSpace.xs) {
                if !answers.isAnswered {
                    Text("Keep at least one thing — the menu is built from it.")
                        .font(FGFont.caption)
                        .foregroundStyle(FGColor.inkMuted)
                }

                FGPrimaryButton(title: "Save", isEnabled: answers.isAnswered) {
                    Analytics.capture("profile_updated")
                    onSave(answers)
                    dismiss()
                }
            }
            .padding(.horizontal, FGSpace.page)
            .padding(.top, FGSpace.s)
            .padding(.bottom, FGSpace.xs)
            .background(FGColor.bg.opacity(0.96))
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            Text(title)
                .font(FGFont.itemTitle)
                .foregroundStyle(FGColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            content()
        }
    }

    private func choices<Option: Hashable>(
        _ options: [Option],
        label: @escaping (Option) -> String,
        selection: Binding<Option>
    ) -> some View {
        WrapRow(spacing: FGSpace.s, lineSpacing: FGSpace.s) {
            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                FGPill(
                    title: label(option),
                    selectedAura: pillAura(at: index),
                    isSelected: selection.wrappedValue == option
                ) {
                    withAnimation(FGMotion.gentle) { selection.wrappedValue = option }
                }
            }
        }
    }

    private func pillAura(at index: Int) -> FGAura {
        let palette: [FGAura] = [.apricot, .lilac, .blush, .sage, .butter]
        return palette[index % palette.count]
    }
}

#Preview {
    ProfileEditView(answers: ProfileAnswers(activities: [.pilates], equipment: [.none, .mat])) { _ in }
}
