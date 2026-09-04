//
//  HiddenExercisesView.swift
//  FeelGood
//
//  View and manage exercises marked with "Don't suggest this again".
//  Users can review everything they have hidden and restore them anytime.
//

import SwiftUI

struct HiddenExercisesView: View {
    let model: TodayModel
    @Environment(\.dismiss) private var dismiss

    private var hiddenSessions: [Session] {
        model.everything.filter { model.isHidden($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FGColor.bg.ignoresSafeArea()

                if hiddenSessions.isEmpty {
                    emptyState
                } else {
                    hiddenList
                }
            }
            .navigationTitle("Hidden exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(FGColor.ink)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: FGSpace.m) {
            Image(systemName: "eye.slash.circle")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(FGColor.inkMuted)

            Text("No hidden exercises")
                .font(FGFont.title)
                .foregroundStyle(FGColor.ink)

            Text("When you select \"Don't suggest this again\" on any exercise, it will appear here so you can bring it back anytime.")
                .font(FGFont.body)
                .foregroundStyle(FGColor.inkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, FGSpace.l)
        }
        .padding(FGSpace.page)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var hiddenList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FGSpace.m) {
                Text("Exercises you have hidden from your daily menu. Tap Unhide to allow them back into recommendations.")
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.inkMuted)
                    .padding(.bottom, FGSpace.xs)

                ForEach(hiddenSessions) { session in
                    FGCard {
                        VStack(alignment: .leading, spacing: FGSpace.s) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: FGSpace.xs) {
                                    Text(session.title)
                                        .font(FGFont.itemTitle)
                                        .foregroundStyle(FGColor.ink)

                                    if !session.subtitle.isEmpty {
                                        Text(session.subtitle)
                                            .font(FGFont.caption)
                                            .foregroundStyle(FGColor.inkMuted)
                                    }
                                }

                                Spacer()

                                FGQuietButton("Unhide", systemImage: "eye") {
                                    withAnimation(FGMotion.gentle) {
                                        model.unhide(sessionID: session.id)
                                    }
                                }
                            }

                            HStack(spacing: FGSpace.xs) {
                                FGChip(text: "\(session.durationMin) min")
                                FGChip(text: session.activity.label)
                            }
                        }
                    }
                }
            }
            .padding(FGSpace.page)
        }
    }
}
