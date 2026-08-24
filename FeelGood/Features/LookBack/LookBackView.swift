//
//  LookBackView.swift
//  FeelGood
//
//  Consistency without streaks (PRD §7.4). Sentences, not numbers on a chart —
//  there is no data visualisation in this app, and nothing here can be broken,
//  lost, or restored.
//

import SwiftUI

struct LookBackView: View {
    let lookBack: LookBack

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    Text("The last couple of weeks")
                        .font(FGFont.title)
                        .foregroundStyle(FGColor.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    if lookBack.isEmpty {
                        FGCard {
                            Text(LookBack.openingLine)
                                .font(FGFont.body)
                                .foregroundStyle(FGColor.inkMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } else {
                        VStack(spacing: FGSpace.s) {
                            ForEach(lookBack.observations) { observation in
                                FGCard {
                                    Text(observation.text)
                                        .font(FGFont.body)
                                        .foregroundStyle(FGColor.ink)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
                .padding(FGSpace.page)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    LookBackView(
        lookBack: LookBack(
            history: (1...6).map { day in
                HistoryEntry(
                    sessionID: "m-pilates",
                    activity: day.isMultiple(of: 2) ? .pilates : .walking,
                    qualities: [.strength],
                    intensity: 3,
                    course: .main,
                    date: Calendar.current.date(byAdding: .day, value: -day, to: Date())!,
                    outcome: .completed(feel: .lovedIt)
                )
            },
            affinity: ["m-pilates": 0.75],
            calendar: .current,
            now: Date()
        )
    )
}
