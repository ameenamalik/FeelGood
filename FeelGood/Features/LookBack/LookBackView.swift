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
    // Qualified: SwiftUI has its own generic `Menu` view, and this file
    // imports SwiftUI, so the bare name resolves to the wrong one.
    let menu: FeelGood.Menu
    let onSeeTodaysMenu: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            if reflection.isEarly {
                early
            } else if let headline = reflection.headline {
                InsightCard(note: headline, menu: menu, onSeeTodaysMenu: onSeeTodaysMenu)
            }
        }
    }

    /// Nothing has happened yet. This is the only place the app could have
    /// rendered an empty state, and it refuses to: no zero, no "you haven't",
    /// no encouragement to catch up on anything.
    private var early: some View {
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
        .accessibilityElement(children: .combine)
    }
}

/// One card: the single most interesting true thing, plus an open,
/// non-pushy nudge toward today. Never a report of how long it's been —
/// that's the one line this card is not allowed to say.
///
/// Washed like a check-in tile rather than boxed like a plain `FGCard` — a
/// bare white card next to the colourful preference pills and Little Wins
/// grid read as a form field, not a warm note. The whole card is the tap
/// target, same as the "Check in for today" prompt on Today.
private struct InsightCard: View {
    let note: Reflection.Note
    let menu: FeelGood.Menu
    let onSeeTodaysMenu: () -> Void

    var body: some View {
        Button(action: onSeeTodaysMenu) {
            VStack(alignment: .leading, spacing: FGSpace.m) {
                VStack(alignment: .leading, spacing: FGSpace.s) {
                    Text(note.line)
                        .font(FGFont.itemTitle)
                        .foregroundStyle(FGColor.inkOnAccent)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(note.invite(in: menu))
                        .font(FGFont.reason)
                        .foregroundStyle(FGColor.inkOnAccent.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: FGSpace.xs) {
                    Text("See today's menu")
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
        .accessibilityLabel("\(note.line) \(note.invite(in: menu))")
        .accessibilityHint("See today's menu")
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
        case .keepsReturningTo: .blush
        case .madeRoomForRest: .sage
        }
    }
}

#Preview("Keeps returning to something") {
    LookBackView(
        reflection: Reflection(notes: [
            .moved(times: 7),
            .mostly(.morning),
            .activities([.pilates, .walking]),
            .keepsReturningTo(.stretching),
            .madeRoomForRest,
        ]),
        menu: .preview(activity: .stretching),
        onSeeTodaysMenu: {}
    )
}

#Preview("Just a count so far") {
    LookBackView(
        reflection: Reflection(notes: [.moved(times: 1)]),
        menu: .preview(activity: .pilates),
        onSeeTodaysMenu: {}
    )
}

#Preview("Nothing yet") {
    LookBackView(reflection: Reflection(notes: []), menu: .preview(activity: .pilates), onSeeTodaysMenu: {})
}

private extension FeelGood.Menu {
    /// Preview-only: a real catalog session so the card's "there's a ...
    /// session on today's menu" line has something true to point at.
    static func preview(activity: Activity) -> FeelGood.Menu {
        let store = try! ContentStore.bundled()
        let session = store.sessions.first { $0.activity == activity } ?? store.sessions[0]
        let item = MenuItem(session: session, course: .main, reasons: [], reasonText: "Preview.")
        return FeelGood.Menu(
            dayStart: Date(),
            appetizer: nil,
            main: item,
            sides: [],
            dessert: nil,
            special: nil,
            headline: "Here's today.",
            assumedCheckIn: PlanCheckIn(energy: .steady, time: .some)
        )
    }
}
