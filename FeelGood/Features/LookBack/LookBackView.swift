//
//  LookBackView.swift
//  FeelGood
//
//  PRD §7.4. A page of plain sentences, and nothing else: no chart, no ring,
//  no bar, no count-up, no comparison to last week. The screen is allowed to
//  be short — a quieter fortnight simply produces fewer lines, which is the
//  whole point.
//

import SwiftUI

struct LookBackView: View {
    let reflection: Reflection

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            FGBrandWash(reach: 0.62).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    Text("You, lately")
                        .font(FGFont.title)
                        .foregroundStyle(FGColor.ink)
                        .accessibilityAddTraits(.isHeader)

                    if reflection.isEarly {
                        early
                    } else {
                        notes
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(FGSpace.page)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private var notes: some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            ForEach(Array(reflection.notes.enumerated()), id: \.offset) { index, note in
                Text(note.line)
                    // The opening line carries; the rest are asides.
                    .font(index == 0 ? FGFont.body.weight(.medium) : FGFont.body)
                    .foregroundStyle(index == 0 ? FGColor.ink : FGColor.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        // One sentence at a time under VoiceOver, in the order they read.
        .accessibilityElement(children: .contain)
    }

    /// Nothing has happened yet. This is the only place the app could have
    /// rendered an empty state, and it refuses to: no zero, no "you haven't",
    /// no encouragement to catch up on anything.
    private var early: some View {
        Text("This page fills in as you go. There's nothing you need to do about it.")
            .font(FGFont.body)
            .foregroundStyle(FGColor.inkMuted)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("A full fortnight") {
    LookBackView(reflection: Reflection(notes: [
        .moved(times: 7),
        .mostly(.morning),
        .activities([.pilates, .walking]),
        .keepsReturningTo(.stretching),
        .madeRoomForRest,
    ]))
}

#Preview("Just started") {
    LookBackView(reflection: Reflection(notes: [.moved(times: 1)]))
}

#Preview("Nothing yet") {
    LookBackView(reflection: Reflection(notes: []))
}
