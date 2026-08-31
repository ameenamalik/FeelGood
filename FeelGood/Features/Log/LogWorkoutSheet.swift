//
//  LogWorkoutSheet.swift
//  FeelGood
//
//  Something you did that wasn't on the menu. Three taps, because a form is
//  not a menu — everything else the engine needs is inferred from them.
//  Keeping it is optional and reversible; logging it is the point.
//

import SwiftUI
import PostHog

/// What somebody says they did. `title` only matters when it is kept.
nonisolated struct LoggedWorkout: Hashable, Sendable {
    var activity: Activity
    var durationMin: Int
    var intensity: Int
    var isKept: Bool
    var title: String

    /// "Strength, 30 min" — a name nobody has to think about.
    static func defaultTitle(for activity: Activity, durationMin: Int) -> String {
        "\(activity.label), \(durationMin) min"
    }
}

struct LogWorkoutSheet: View {
    let onDone: (LoggedWorkout) -> Void

    @State private var activity: Activity?
    @State private var durationMin = 30
    @State private var intensity = 3
    @State private var isKept = false
    @State private var title = ""
    @FocusState private var isNamingIt: Bool
    @Environment(\.dismiss) private var dismiss

    private static let durations = [10, 20, 30, 45, 60]
    private static let efforts: [(label: String, intensity: Int)] = [
        ("Easy", 2), ("Steady", 3), ("Hard", 4)
    ]

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    VStack(alignment: .leading, spacing: FGSpace.s) {
                        Text("What did you do?")
                            .font(FGFont.title)
                            .foregroundStyle(FGColor.ink)
                        Text("It counts the same as anything off the menu.")
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                    }

                    FlowRow(spacing: FGSpace.s) {
                        ForEach(Activity.allCases, id: \.self) { option in
                            FGChoice(title: option.label, isSelected: activity == option) {
                                withAnimation(FGMotion.gentle) { activity = option }
                            }
                        }
                    }

                    question("How long?") {
                        ForEach(Self.durations, id: \.self) { minutes in
                            FGChoice(title: "\(minutes) min", isSelected: durationMin == minutes) {
                                withAnimation(FGMotion.gentle) { durationMin = minutes }
                            }
                        }
                    }

                    question("How hard?") {
                        ForEach(Self.efforts, id: \.intensity) { effort in
                            FGChoice(title: effort.label, isSelected: intensity == effort.intensity) {
                                withAnimation(FGMotion.gentle) { intensity = effort.intensity }
                            }
                        }
                    }

                    keepIt

                    FGPrimaryButton(title: "Log it") { done() }
                        .opacity(activity == nil ? 0.4 : 1)
                        .disabled(activity == nil)
                }
                .padding(FGSpace.page)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var keepIt: some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            FGChoice(title: "Keep this one so it can come back", isSelected: isKept) {
                withAnimation(FGMotion.gentle) {
                    isKept.toggle()
                    if isKept && title.isEmpty, let activity {
                        title = LoggedWorkout.defaultTitle(for: activity, durationMin: durationMin)
                    }
                }
            }

            if isKept {
                TextField("Name it", text: $title)
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.ink)
                    .textFieldStyle(.plain)
                    .focused($isNamingIt)
                    .submitLabel(.done)
                    .onSubmit { isNamingIt = false }
                    .padding(FGSpace.m)
                    .background(
                        RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                            .fill(FGColor.surface)
                    )
                    .accessibilityLabel("Name for this workout")
                    .postHogMask()
            }
        }
    }

    private func question<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            Text(title)
                .font(FGFont.label)
                .foregroundStyle(FGColor.inkMuted)
            FlowRow(spacing: FGSpace.s) { content() }
        }
    }

    private func done() {
        guard let activity else { return }
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        Analytics.capture("workout_logged", properties: [
            "activity": activity.rawValue,
            "duration_minutes": durationMin,
            "intensity": intensity,
            "saved_for_later": isKept
        ])
        onDone(
            LoggedWorkout(
                activity: activity,
                durationMin: durationMin,
                intensity: intensity,
                isKept: isKept,
                title: name.isEmpty ? LoggedWorkout.defaultTitle(for: activity, durationMin: durationMin) : name
            )
        )
        dismiss()
    }
}

#Preview {
    LogWorkoutSheet { _ in }
}
