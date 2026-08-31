//
//  SessionDetailView.swift
//  FeelGood
//
//  What it is, what you need, one action. The title carries the screen; the
//  detail waits behind a disclosure for whoever actually wants it.
//
//  The "why" is deliberately absent here. It is not missing from the product —
//  the menu card on Today already carries `reasonText`, so principle 4 is
//  answered at the point the recommendation is made. Repeating it in a
//  bordered box one tap later was saying the same sentence twice.
//

import SwiftUI

struct SessionDetailView: View {
    let session: Session
    let course: Course
    let model: TodayModel

    @Environment(\.dismiss) private var dismiss
    @State private var isPlaying = false
    @State private var startedAt = Date()
    @State private var explaining: ExerciseTerm?
    @State private var isShowingSteps = false
    @State private var isRenaming = false
    @State private var newTitle = ""
    @State private var isConfirmingRemoval = false

    /// From the menu, where something chose it.
    init(item: MenuItem, model: TodayModel) {
        session = item.session
        course = item.course
        self.model = model
    }

    /// From the Library, where nobody chose it and somebody went looking.
    init(session: Session, model: TodayModel) {
        self.session = session
        course = session.course
        self.model = model
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    heading

                    // The chips say what they are — "Mat", "20 min" — so the
                    // "What you need" label above them was a word about words.
                    HStack(spacing: FGSpace.s) {
                        ForEach(session.chips, id: \.self) { FGChip(text: $0) }
                    }

                    if !session.source.steps.isEmpty {
                        lineup
                    }

                    // Somebody's own workout has no steps to play, because
                    // nobody wrote any. It gets the honest button instead.
                    if session.isOwn {
                        VStack(spacing: FGSpace.s) {
                            FGPrimaryButton(title: "I did this") {
                                Analytics.capture("workout_completed", properties: workoutProperties)
                                model.complete(session, startedAt: Date(), feel: nil)
                                dismiss()
                            }
                            HStack(spacing: FGSpace.m) {
                                FGQuietButton("Rename", systemImage: "pencil") {
                                    newTitle = session.title
                                    isRenaming = true
                                }
                                FGQuietButton("Remove", systemImage: "minus.circle") {
                                    isConfirmingRemoval = true
                                }
                            }
                        }
                    } else {
                        FGPrimaryButton(title: "Start") {
                            Analytics.capture("workout_started", properties: workoutProperties)
                            startedAt = Date()
                            isPlaying = true
                        }
                    }
                }
                .padding(FGSpace.page)
            }
        }
        .fullScreenCover(isPresented: $isPlaying) {
            PlayerView(
                session: session,
                onFinish: { feel, didComplete in
                    if didComplete {
                        Analytics.capture("workout_completed", properties: workoutProperties)
                    }
                    model.complete(session, startedAt: startedAt, feel: feel)
                    isPlaying = false
                    dismiss()
                },
                startedAt: startedAt
            )
        }
        .sheet(item: $explaining) { term in
            GlossarySheet(term: term)
        }
        .alert("Name this one", isPresented: $isRenaming) {
            TextField("Name", text: $newTitle)
            Button("Save") { model.rename(session, to: newTitle) }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Remove \(session.title)?",
            isPresented: $isConfirmingRemoval,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                model.forget(session)
                dismiss()
            }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("It stops being offered. The times you did it still count.")
        }
        .presentationDragIndicator(.visible)
    }

    private var workoutProperties: [String: Any] {
        [
            "session_id": session.id,
            "activity": session.activity.rawValue,
            "course": course.rawValue,
            "duration_minutes": session.durationMin,
            "is_saved_workout": session.isOwn
        ]
    }

    /// The title is the screen. Display weight, and everything under it quiet.
    private var heading: some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            CourseTag(course: course)
            Text(session.title)
                .font(FGFont.display)
                .foregroundStyle(FGColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            if !session.subtitle.isEmpty {
                Text(session.subtitle)
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    /// Closed by default. Someone deciding whether to start needs the title and
    /// the length; the breakdown is for whoever wants to know before they say
    /// yes, and it should cost them one tap rather than everyone else a screen.
    private var lineup: some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            Button {
                isShowingSteps.toggle()
            } label: {
                HStack(spacing: FGSpace.s) {
                    Text("What you'll do")
                        .font(FGFont.body.weight(.medium))
                        .foregroundStyle(FGColor.ink)
                    Spacer(minLength: FGSpace.s)
                    Text(partsLabel)
                        .font(FGFont.label)
                        .foregroundStyle(FGColor.inkMuted)
                    Image(systemName: "chevron.down")
                        .font(FGFont.label)
                        .foregroundStyle(FGColor.inkMuted)
                        .rotationEffect(.degrees(isShowingSteps ? 0 : -90))
                }
                .frame(minHeight: FGSize.minTouchTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("What you'll do, \(partsLabel)")
            .accessibilityValue(isShowingSteps ? "Expanded" : "Collapsed")
            .accessibilityHint(isShowingSteps ? "Hides the steps" : "Shows the steps")

            if isShowingSteps { steps }
        }
        .fgAnimation(FGMotion.gentle, value: isShowingSteps)
    }

    private func stepCost(_ step: Step) -> String {
        if step.isCounted, let reps = step.reps {
            return step.setCount > 1 ? "\(step.setCount) × \(reps)" : "\(reps) reps"
        }
        return "\(max(1, step.seconds / 60)) min"
    }

    private var partsLabel: String {
        let count = session.source.steps.count
        return count == 1 ? "1 part" : "\(count) parts"
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            ForEach(Array(session.source.steps.enumerated()), id: \.offset) { _, step in
                HStack(alignment: .firstTextBaseline, spacing: FGSpace.s) {
                    Text(step.name)
                        .font(FGFont.body)
                        .foregroundStyle(FGColor.ink)
                    // The only route into the glossary is a step already
                    // on screen. It is never browsable.
                    if let term = model.term(for: step) {
                        Button {
                            explaining = term
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(FGColor.skyDeep)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("What is \(step.name)?")
                    }
                    Spacer(minLength: FGSpace.s)
                    // A counted step is measured in reps, not minutes — the
                    // number is what somebody is deciding about before they
                    // start, so it is what the preview shows.
                    Text(stepCost(step))
                        .font(FGFont.label)
                        .foregroundStyle(FGColor.inkMuted)
                }
            }
        }
    }
}

/// Plain steps, plain language. No gym taxonomy, no photography.
struct GlossarySheet: View {
    let term: ExerciseTerm

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.m) {
                    Text(term.name)
                        .font(FGFont.title)
                        .foregroundStyle(FGColor.ink)

                    VStack(alignment: .leading, spacing: FGSpace.s) {
                        ForEach(Array(term.instructions.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(FGFont.body)
                                .foregroundStyle(FGColor.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if !term.muscles.isEmpty {
                        Text("Works: \(term.muscles.joined(separator: ", "))")
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                    }
                }
                .padding(FGSpace.page)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
