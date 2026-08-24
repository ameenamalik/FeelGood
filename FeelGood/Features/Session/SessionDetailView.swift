//
//  SessionDetailView.swift
//  FeelGood
//
//  What it is, why it was picked, what you need. One action.
//

import SwiftUI

struct SessionDetailView: View {
    let session: Session
    let course: Course
    /// Why this was picked, when it was picked. The Library has no reason to
    /// give — nothing chose it, somebody went looking for it — so the "why
    /// this" card simply isn't there.
    let reason: String?
    let model: TodayModel

    @Environment(\.dismiss) private var dismiss
    @State private var isPlaying = false
    @State private var startedAt: Date?
    @State private var explaining: ExerciseTerm?
    @State private var isRenaming = false
    @State private var newTitle = ""
    @State private var isConfirmingRemoval = false

    init(item: MenuItem, model: TodayModel) {
        session = item.session
        course = item.course
        reason = item.reasonText
        self.model = model
    }

    init(session: Session, model: TodayModel) {
        self.session = session
        course = session.course
        reason = nil
        self.model = model
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    VStack(alignment: .leading, spacing: FGSpace.s) {
                        CourseTag(course: course)
                        Text(session.title)
                            .font(FGFont.title)
                            .foregroundStyle(FGColor.ink)
                        if !session.subtitle.isEmpty {
                            Text(session.subtitle)
                                .font(FGFont.body)
                                .foregroundStyle(FGColor.inkMuted)
                        }
                    }

                    if let reason {
                        FGCard {
                            VStack(alignment: .leading, spacing: FGSpace.xs) {
                                Text("Why this")
                                    .font(FGFont.label)
                                    .foregroundStyle(FGColor.skyDeep)
                                    .textCase(.uppercase)
                                    .tracking(1.1)
                                Text(reason)
                                    .font(FGFont.body)
                                    .foregroundStyle(FGColor.ink)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: FGSpace.s) {
                        Text("What you need")
                            .font(FGFont.body.weight(.medium))
                            .foregroundStyle(FGColor.ink)
                        HStack(spacing: FGSpace.s) {
                            ForEach(session.chips, id: \.self) { FGChip(text: $0) }
                        }
                    }

                    if !session.source.steps.isEmpty {
                        steps
                    }

                    // Somebody's own workout has no steps to play, because
                    // nobody wrote any. It gets the honest button instead.
                    if session.isOwn {
                        VStack(spacing: FGSpace.s) {
                            FGPrimaryButton(title: "I did this") {
                                model.record(.finished(nil), for: session, startedAt: Date())
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
                            startedAt = Date()
                            isPlaying = true
                        }
                    }
                }
                .padding(FGSpace.page)
            }
        }
        .fullScreenCover(isPresented: $isPlaying) {
            PlayerView(session: session) { outcome in
                model.record(outcome, for: session, startedAt: startedAt ?? Date())
                dismiss()
            }
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

    private var steps: some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            Text("How it goes")
                .font(FGFont.body.weight(.medium))
                .foregroundStyle(FGColor.ink)

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
                    Text("\(max(1, step.seconds / 60)) min")
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
