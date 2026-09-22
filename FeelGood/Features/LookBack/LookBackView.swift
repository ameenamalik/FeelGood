//
//  LookBackView.swift
//  FeelGood
//
//  PRD §7.4. One editorial observation, not a report card: no chart, ring,
//  streak, target, comparison, or praise — and no naming of how long it's
//  been, ever. A quieter fortnight simply produces a quieter note, which is
//  the whole point.
//

import SwiftUI

struct LookBackView: View {
    let reflection: Reflection
    var onSelectSession: ((String) -> Void)? = nil
    var onSelectActivity: ((Activity) -> Void)? = nil
    var onOpenLibrary: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            if reflection.isEarly {
                early
            } else if let headline = reflection.headline {
                InsightCard(
                    note: headline,
                    onTap: {
                        switch headline {
                        case .keepsReturningToSession(let id, _, _):
                            if let onSelectSession {
                                onSelectSession(id)
                            } else {
                                onOpenLibrary?()
                            }
                        case .keepsReturningTo(let activity):
                            if let onSelectActivity {
                                onSelectActivity(activity)
                            } else {
                                onOpenLibrary?()
                            }
                        case .activities(let activities):
                            if let first = activities.first, let onSelectActivity {
                                onSelectActivity(first)
                            } else {
                                onOpenLibrary?()
                            }
                        case .mostly, .moved, .madeRoomForRest:
                            onOpenLibrary?()
                        }
                    }
                )
            }
        }
    }

    /// Nothing has happened yet. This is the only place the app could have
    /// rendered an empty state, and it refuses to: no zero, no "you haven't",
    /// no encouragement to catch up on anything.
    private var early: some View {
        Button {
            onOpenLibrary?()
        } label: {
            FGCard {
                HStack(alignment: .center, spacing: FGSpace.m) {
                    VStack(alignment: .leading, spacing: FGSpace.s) {
                        Text("Your patterns will appear here")
                            .font(FGFont.itemTitle)
                            .foregroundStyle(FGColor.ink)
                        Text("Complete a few sessions and FeelGood will gently notice what works for you.")
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image("IntentShowingUpPear")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Explore the library")
    }
}

/// One card: the single most interesting true thing, actionable with a single tap.
private struct InsightCard: View {
    let note: Reflection.Note
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: FGSpace.m) {
                Text(note.line)
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.inkOnAccent)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: FGSpace.xs) {
                    Text(note.actionLabel)
                        .font(FGFont.label.weight(.bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(FGColor.inkOnAccent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(FGSpace.m)
            .background(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .fill(note.aura.core)
            )
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityLabel(note.line)
        .accessibilityHint(note.actionLabel)
    }
}

private extension Reflection.Note {
    /// Which of the app's five pastel washes this note gets. No meaning
    /// beyond "this card has colour" — same spread rule as the check-in
    /// tiles: nobody should read anything into which one shows up.
    var aura: FGAura {
        switch self {
        case .moved: .butter
        case .mostly: .apricot
        case .activities: .lilac
        case .keepsReturningToSession, .keepsReturningTo: .blush
        case .madeRoomForRest: .sage
        }
    }
}

#Preview("Keeps returning to session") {
    LookBackView(
        reflection: Reflection(notes: [
            .moved(times: 5),
            .keepsReturningToSession(sessionID: "s1", title: "Morning Stretch", activity: .stretching)
        ])
    )
}

#Preview("Keeps returning to activity") {
    LookBackView(
        reflection: Reflection(notes: [
            .moved(times: 7),
            .mostly(.morning),
            .activities([.pilates, .walking]),
            .keepsReturningTo(.stretching),
            .madeRoomForRest,
        ])
    )
}

#Preview("Just a count so far") {
    LookBackView(
        reflection: Reflection(notes: [.moved(times: 1)])
    )
}

#Preview("Nothing yet") {
    LookBackView(reflection: Reflection(notes: []))
}
