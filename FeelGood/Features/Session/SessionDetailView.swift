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
    let item: MenuItem
    let model: TodayModel

    @Environment(\.dismiss) private var dismiss
    @State private var isPlaying = false
    @State private var startedAt = Date()
    @State private var explaining: ExerciseTerm?
    @State private var isShowingSteps = false

    private var session: Session { item.session }

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

    /// The title is the screen. Display weight, and everything under it quiet.
    private var heading: some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            CourseTag(course: item.course)
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
