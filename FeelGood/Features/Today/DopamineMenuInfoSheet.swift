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
                                subtitle: "3–5 min quick wins",
                                description: "Gentle warm-ups and micro-movements to break inertia when starting feels heavy.",
                                aura: .apricot,
                                icon: "sun.max.fill"
                            )

                            courseCard(
                                title: "Mains",
                                subtitle: "10–30 min core sessions",
                                description: "Pilates, strength, dance, or steady movement to build strength and shift your energy.",
                                aura: .lilac,
                                icon: "figure.cross.training"
                            )

                            courseCard(
                                title: "Sides",
                                subtitle: "5–15 min resets",
                                description: "Stretches, posture breaks, and mobility to ease tension throughout your day.",
                                aura: .sage,
                                icon: "figure.flexibility"
                            )

                            courseCard(
                                title: "Desserts",
                                subtitle: "Pure joy & relaxation",
                                description: "Breathwork, meditation, and gentle wind-downs that feel like a soothing reward.",
                                aura: .butter,
                                icon: "sparkles"
                            )
                        }

                        philosophyCard

                        if let onOpenCustomRoutines {
                            Button {
                                dismiss()
                                onOpenCustomRoutines()
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add your own custom routines")
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

            Text("Borrowed from ADHD and executive function design, a dopamine menu offers easy options without the pressure of deciding. You never have to finish every item — picking just one is a complete win.")
                .font(FGFont.body)
                .foregroundStyle(FGColor.inkMuted)
                .lineSpacing(3)
        }
    }

    private func courseCard(
        title: String,
        subtitle: String,
        description: String,
        aura: FGAura,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.xs) {
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

            Text(description)
                .font(FGFont.reason)
                .foregroundStyle(FGColor.inkMuted)
                .lineSpacing(2)
                .padding(.top, 2)
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

    private var philosophyCard: some View {
        HStack(alignment: .top, spacing: FGSpace.m) {
            Image(systemName: "heart.fill")
                .font(.system(size: 20))
                .foregroundStyle(FGAura.blush.mid)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Zero guilt, zero streaks")
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.ink)

                Text("Whether you do 3 minutes of stretching or a full 25-minute flow, you showed up for yourself. FeelGood gently notices your patterns, never your pauses.")
                    .font(FGFont.reason)
                    .foregroundStyle(FGColor.inkMuted)
                    .lineSpacing(2)
            }
        }
        .padding(FGSpace.m)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .fill(FGAura.blush.core.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .strokeBorder(FGAura.blush.edge.opacity(0.3), lineWidth: 1)
        )
    }
}
