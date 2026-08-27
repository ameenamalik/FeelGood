//
//  LookBackView.swift
//  FeelGood
//
//  PRD §7.4. Recent patterns presented as editorial notes: no chart, ring,
//  streak, target, comparison, or praise. A quieter fortnight simply produces
//  fewer cards, which is the whole point.
//

import SwiftUI

struct LookBackView: View {
    let reflection: Reflection

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            if reflection.isEarly {
                early
            } else {
                notes
            }
        }
    }

    private var notes: some View {
        VStack(spacing: FGSpace.m) {
            ForEach(Array(reflection.notes.enumerated()), id: \.offset) { _, note in
                ReflectionCard(note: note)
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// Nothing has happened yet. This is the only place the app could have
    /// rendered an empty state, and it refuses to: no zero, no "you haven't",
    /// no encouragement to catch up on anything.
    private var early: some View {
        FGCard {
            VStack(alignment: .leading, spacing: FGSpace.s) {
                Text("This page fills in as you go.")
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.ink)
                Text("There's nothing you need to do about it.")
                    .font(FGFont.reason)
                    .foregroundStyle(FGColor.inkMuted)
            }
        }
    }
}

private struct ReflectionCard: View {
    let note: Reflection.Note
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        FGCard {
            Group {
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: FGSpace.m) {
                        copy
                        tag
                    }
                } else {
                    HStack(alignment: .center, spacing: FGSpace.m) {
                        copy
                        tag
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(note.line) \(note.contextLine)")
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            Text(note.line)
                .font(FGFont.itemTitle)
                .foregroundStyle(FGColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(note.contextLine)
                .font(FGFont.reason)
                .foregroundStyle(FGColor.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tag: some View {
        Text(note.tag)
            .font(FGFont.label.weight(.bold))
            .foregroundStyle(FGColor.inkOnAccent)
            .padding(.horizontal, FGSpace.s)
            .padding(.vertical, FGSpace.s)
            .background(Capsule().fill(note.accent))
    }
}

private extension Reflection.Note {
    var contextLine: String {
        switch self {
        case .moved: "A simple look at what happened."
        case .mostly: "The time of day movement has fit."
        case .activities: "The kinds of movement showing up lately."
        case .keepsReturningTo: "Something familiar you choose again."
        case .madeRoomForRest: "Recovery is part of the balance."
        }
    }

    var tag: String {
        switch self {
        case .moved: "lately"
        case .mostly: "rhythm"
        case .activities: "mix"
        case .keepsReturningTo: "returning"
        case .madeRoomForRest: "rest"
        }
    }

    var accent: Color {
        switch self {
        case .moved: FGColor.sky
        case .mostly: FGColor.lavender
        case .activities: FGColor.lime
        case .keepsReturningTo: FGColor.pink
        case .madeRoomForRest: FGColor.lavender
        }
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
