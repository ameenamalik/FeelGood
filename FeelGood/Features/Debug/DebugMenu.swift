//
//  DebugMenu.swift
//  FeelGood
//
//  Reachable by long-pressing the date above the menu. Debug builds only, so
//  there is nothing to hide in release and nothing a reviewer can stumble into.
//

#if DEBUG

import SwiftUI
import SwiftData

struct DebugMenu: View {
    let content: any ContentProviding
    /// Called after seeding so Today can rebuild against the new history.
    let onSeed: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var lastApplied: DebugScenario?

    private var seeder: DebugSeeder {
        DebugSeeder(context: context, content: content)
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    VStack(alignment: .leading, spacing: FGSpace.xs) {
                        Text("Time travel")
                            .font(FGFont.title)
                            .foregroundStyle(FGColor.ink)
                        Text("Writes real history through the real store. The engine then reacts to it exactly as it would for a real person.")
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    FGCard {
                        VStack(alignment: .leading, spacing: FGSpace.xs) {
                            Text("Right now")
                                .font(FGFont.label)
                                .foregroundStyle(FGColor.skyDeep)
                            Text(seeder.summary())
                                .font(FGFont.body)
                                .foregroundStyle(FGColor.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    VStack(spacing: FGSpace.s) {
                        ForEach(DebugScenario.allCases) { scenario in
                            Button {
                                seeder.apply(scenario)
                                lastApplied = scenario
                                onSeed()
                            } label: {
                                FGCard(isHighlighted: lastApplied == scenario) {
                                    VStack(alignment: .leading, spacing: FGSpace.xs) {
                                        Text(scenario.title)
                                            .font(FGFont.itemTitle)
                                            .foregroundStyle(FGColor.ink)
                                        Text(scenario.detail)
                                            .font(FGFont.caption)
                                            .foregroundStyle(FGColor.inkMuted)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    FGPrimaryButton(title: "Back to today") { dismiss() }
                }
                .padding(FGSpace.page)
            }
        }
        .presentationDragIndicator(.visible)
    }
}

#endif
