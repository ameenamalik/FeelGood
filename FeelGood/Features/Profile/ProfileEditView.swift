//
//  ProfileEditView.swift
//  FeelGood
//
//  The same onboarding answers, editable later. Lives here rather than in a settings
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
                        Text("My preferences")
                            .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                            .foregroundStyle(FGColor.ink)
                        Text("Change anything. Today's menu follows.")
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                    }

                    section("Which sounds most like you?") {
                        choices(
                            GuidancePreference.allCases,
                            label: \.label,
                            selection: $answers.guidancePreference
                        )
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
                                                if workAround == .other {
                                                    answers.otherWorkAroundNote = ""
                                                }
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
                                    withAnimation(FGMotion.gentle) {
                                        answers.workArounds = []
                                        answers.otherWorkAroundNote = ""
                                    }
                                }
                            }

                            if answers.workArounds.contains(.other) {
                                VStack(alignment: .leading, spacing: FGSpace.xs) {
                                    Text("What should we go easy on?")
                                        .font(FGFont.label)
                                        .foregroundStyle(FGColor.ink)

                                    TextField("e.g. Frozen shoulder, vertigo, no floor work...", text: $answers.otherWorkAroundNote)
                                        .font(FGFont.body)
                                        .padding(.horizontal, FGSpace.m)
                                        .padding(.vertical, 12)
                                        .background(FGColor.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(FGColor.line, lineWidth: 1)
                                        )

                                    Text("Your menu and AI coach will avoid movements that stress this.")
                                        .font(FGFont.caption)
                                        .foregroundStyle(FGColor.inkMuted)
                                }
                                .padding(.top, FGSpace.xs)
                                .transition(.opacity.combined(with: .move(edge: .top)))
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
