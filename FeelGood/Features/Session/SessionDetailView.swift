//
//  SessionDetailView.swift
//  FeelGood
//
//  What it is, why it was picked, what you need. One action.
//

import SwiftUI

struct SessionDetailView: View {
    let item: MenuItem
    let model: TodayModel

    @Environment(\.dismiss) private var dismiss
    @State private var isPlaying = false
    @State private var startedAt = Date()
    @State private var explaining: ExerciseTerm?

    private var session: Session { item.session }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    VStack(alignment: .leading, spacing: FGSpace.s) {
                        CourseTag(course: item.course)
                        Text(session.title)
                            .font(FGFont.title)
                            .foregroundStyle(FGColor.ink)
                        if !session.subtitle.isEmpty {
                            Text(session.subtitle)
                                .font(FGFont.body)
                                .foregroundStyle(FGColor.inkMuted)
                        }
                    }

                    FGCard {
                        VStack(alignment: .leading, spacing: FGSpace.xs) {
                            Text("Why this")
                                .font(FGFont.label)
                                .foregroundStyle(FGColor.skyDeep)
                                .textCase(.uppercase)
                                .tracking(1.1)
                            Text(item.reasonText)
                                .font(FGFont.body)
                                .foregroundStyle(FGColor.ink)
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

                    FGPrimaryButton(title: "Start") {
                        startedAt = Date()
                        isPlaying = true
                    }
                }
                .padding(FGSpace.page)
            }
        }
        .fullScreenCover(isPresented: $isPlaying) {
            PlayerView(
                session: session,
                onFinish: { feel in
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
