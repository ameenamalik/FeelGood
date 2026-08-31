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
    let onSave: (ProfileAnswers) -> Void

    @State private var answers: ProfileAnswers
    @Environment(\.dismiss) private var dismiss

    init(answers: ProfileAnswers, onSave: @escaping (ProfileAnswers) -> Void) {
        _answers = State(initialValue: answers)
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.xl) {
                    VStack(alignment: .leading, spacing: FGSpace.s) {
                        Text("What's true now")
                            .font(FGFont.title)
                            .foregroundStyle(FGColor.ink)
                        Text("Change anything. Today's menu follows.")
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                    }

                    section("What do you have access to?") {
                        AccessChoices(
                            activities: $answers.activities,
                            equipment: $answers.equipment,
                            places: $answers.places
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
                        FlowRow(spacing: FGSpace.s) {
                            ForEach(Intent.allCases, id: \.self) { intent in
                                FGChoice(title: intent.label, isSelected: answers.intents.contains(intent)) {
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
                            FlowRow(spacing: FGSpace.s) {
                                ForEach(WorkAround.allCases, id: \.self) { workAround in
                                    FGChoice(
                                        title: workAround.label,
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
                            }
                            FGChoice(title: "None of these", isSelected: answers.workArounds.isEmpty) {
                                withAnimation(FGMotion.gentle) { answers.workArounds = [] }
                            }
                        }
                        // `pregnancy`, `postpartum` and `pelvicFloor` are on this
                        // chip list, and which ones are selected is visible in the
                        // screenshot. Onboarding masks the same chips; this screen
                        // is the other place they can be set. The section heading
                        // stays legible — the question isn't sensitive, the answer is.
                        .postHogMask()
                    }

                    VStack(spacing: FGSpace.s) {
                        FGPrimaryButton(title: "Save") {
                            Analytics.capture("profile_updated")
                            onSave(answers)
                            dismiss()
                        }
                        .opacity(answers.isAnswered ? 1 : 0.4)
                        .disabled(!answers.isAnswered)

                        if !answers.isAnswered {
                            Text("Keep at least one thing — the menu is built from it.")
                                .font(FGFont.caption)
                                .foregroundStyle(FGColor.inkMuted)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(FGSpace.page)
            }
        }
        .presentationDragIndicator(.visible)
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
        FlowRow(spacing: FGSpace.s) {
            ForEach(options, id: \.self) { option in
                FGChoice(title: label(option), isSelected: selection.wrappedValue == option) {
                    withAnimation(FGMotion.gentle) { selection.wrappedValue = option }
                }
            }
        }
    }
}

#Preview {
    ProfileEditView(answers: ProfileAnswers(activities: [.pilates], equipment: [.none, .mat])) { _ in }
}
