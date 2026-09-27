//
//  DopamineMenuInfoSheet.swift
//  FeelGood
//
//  Explains the ADHD-friendly Dopamine Menu concept: four courses designed
//  to eliminate decision fatigue without creating a mandatory checklist.
//

import SwiftUI

struct DopamineMenuInfoSheet: View {
    let model: TodayModel
    var onOpenCustomRoutines: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                FGColor.bg.ignoresSafeArea()
                FGBrandWash(reach: 0.45).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: FGSpace.l) {
                        hero

                        VStack(spacing: FGSpace.m) {
                            courseCard(
                                title: "Appetizers",
                                subtitle: "3–5 min to get started",
                                aura: .apricot,
                                icon: "sun.max.fill"
                            )

                            courseCard(
                                title: "Mains",
                                subtitle: "10–30 min movement",
                                aura: .lilac,
                                icon: "figure.cross.training"
                            )

                            courseCard(
                                title: "Sides",
                                subtitle: "5–15 min reset",
                                aura: .sage,
                                icon: "figure.flexibility"
                            )

                            courseCard(
                                title: "Desserts",
                                subtitle: "Rest, breath, or joy",
                                aura: .butter,
                                icon: "sparkles"
                            )
                        }

                        if let onOpenCustomRoutines {
                            Button {
                                dismiss()
                                onOpenCustomRoutines()
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add a routine")
                                }
                                .font(FGFont.itemTitle)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, FGSpace.m)
                                .background(FGColor.surface)
                                .foregroundStyle(FGColor.ink)
                                .clipShape(RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                                        .strokeBorder(FGColor.line, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.feelGoodPress)
                        }
                    }
                    .padding(.horizontal, FGSpace.page)
                    .padding(.top, FGSpace.m)
                    .padding(.bottom, FGSpace.xl)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationTitle("The Dopamine Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(FGFont.body.weight(.semibold))
                        .foregroundStyle(FGColor.ink)
                }
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: FGSpace.xs) {
            Text("A menu, not a to-do list.")
                .font(FGFont.display)
                .foregroundStyle(FGColor.ink)

            Text("Pick one thing. Leave the rest.")
                .font(FGFont.body)
                .foregroundStyle(FGColor.inkMuted)
                .lineSpacing(3)
        }
    }

    private func courseCard(
        title: String,
        subtitle: String,
        aura: FGAura,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: FGSpace.s) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(aura.mid)
                    .frame(width: 32, height: 32)
                    .background(aura.core.opacity(0.4))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(FGFont.itemTitle)
                        .foregroundStyle(FGColor.ink)

                    Text(subtitle)
                        .font(FGFont.label)
                        .foregroundStyle(FGColor.inkMuted)
                }

                Spacer()
            }
        }
        .padding(FGSpace.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .fill(FGColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .strokeBorder(aura.edge.opacity(0.35), lineWidth: 1)
        )
    }

}
