//
//  DopamineMenuTourView.swift
//  FeelGood
//
//  An interactive first-run tour introducing the Dopamine Menu concept,
//  the 4 courses, swipe-to-swap, and zero-guilt philosophy when a user
//  lands on the screen for the first time.
//

import SwiftUI

struct DopamineMenuTourView: View {
    var onComplete: () -> Void

    @State private var currentStep = 0
    @Environment(\.dismiss) private var dismiss

    private let totalSteps = 4

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            FGBrandWash(reach: 0.65).ignoresSafeArea()

            VStack(spacing: FGSpace.l) {
                topBar

                TabView(selection: $currentStep) {
                    stepOne
                        .tag(0)

                    stepTwo
                        .tag(1)

                    stepThree
                        .tag(2)

                    stepFour
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                footer
            }
            .padding(.horizontal, FGSpace.page)
            .padding(.vertical, FGSpace.m)
        }
    }

    private var topBar: some View {
        HStack {
            // Page indicator dots
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index == currentStep ? FGColor.ink : FGColor.lineStrong)
                        .frame(width: index == currentStep ? 20 : 6, height: 6)
                        .animation(FGMotion.gentle, value: currentStep)
                }
            }

            Spacer()

            Button("Skip") {
                finish()
            }
            .font(FGFont.label.weight(.medium))
            .foregroundStyle(FGColor.inkMuted)
        }
        .padding(.top, FGSpace.xs)
    }

    // MARK: - Slides

    private var stepOne: some View {
        VStack(spacing: FGSpace.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(FGAura.apricot.core)
                    .frame(width: 130, height: 130)
                    .overlay {
                        Circle()
                            .strokeBorder(FGAura.apricot.mid.opacity(0.7), lineWidth: 1)
                    }

                Image("IntentEnergyClementine")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 108, height: 108)
            }

            VStack(spacing: FGSpace.m) {
                Text("Meet your Dopamine Menu")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(FGColor.ink)
                    .multilineTextAlignment(.center)

                Text("Movement picked for your energy and time. Choose one thing — that counts.")
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.inkMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, FGSpace.s)
            }

            Spacer()
        }
    }

    private var stepTwo: some View {
        VStack(spacing: FGSpace.m) {
            Text("The 4 Courses")
                .font(FGFont.title)
                .foregroundStyle(FGColor.ink)
                .padding(.top, FGSpace.s)

            VStack(spacing: FGSpace.s) {
                courseRow(
                    title: "Appetizers",
                    time: "3–5 min",
                    subtitle: "Quick starts that break inertia.",
                    icon: "sun.max.fill",
                    aura: .apricot
                )

                courseRow(
                    title: "Mains",
                    time: "10–25 min",
                    subtitle: "Pilates, yoga, or steady strength.",
                    icon: "figure.cross.training",
                    aura: .lilac
                )

                courseRow(
                    title: "Sides",
                    time: "5–15 min",
                    subtitle: "Stretches and desk resets.",
                    icon: "figure.flexibility",
                    aura: .sage
                )

                courseRow(
                    title: "Desserts",
                    time: "5–10 min",
                    subtitle: "Breathwork and wind-downs.",
                    icon: "sparkles",
                    aura: .butter
                )
            }

            Text("Pick one or two. Leave the rest.")
                .font(FGFont.caption)
                .foregroundStyle(FGColor.inkMuted)
                .multilineTextAlignment(.center)
                .padding(.top, FGSpace.xs)
        }
    }

    private var stepThree: some View {
        VStack(spacing: FGSpace.l) {
            Spacer()

            ZStack {
                Circle()
                    .fill(FGAura.apricot.core.opacity(0.35))
                    .frame(width: 120, height: 120)

                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(FGColor.ink)
            }

            VStack(spacing: FGSpace.s) {
                Text("Swipe to swap anytime")
                    .font(FGFont.display)
                    .foregroundStyle(FGColor.ink)
                    .multilineTextAlignment(.center)

                Text("Not feeling a suggestion? Swipe left or tap Swap.")
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.inkMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, FGSpace.s)

                Text("Tap + Routine to add your own.")
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.inkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, FGSpace.s)
            }

            Spacer()
        }
    }

    private var stepFour: some View {
        VStack(spacing: FGSpace.l) {
            Spacer()

            ZStack {
                Circle()
                    .fill(FGAura.butter.core)
                    .frame(width: 150, height: 150)
                    .overlay {
                        Circle()
                            .strokeBorder(FGAura.butter.mid.opacity(0.7), lineWidth: 1)
                    }

                Image("IntentShowingUpBanana")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
            }

            VStack(spacing: FGSpace.s) {
                Text("Zero guilt, zero streaks")
                    .font(FGFont.display)
                    .foregroundStyle(FGColor.ink)
                    .multilineTextAlignment(.center)

                Text("No guilt and no broken-streak alerts. FeelGood notices what helps — not how long you’ve been away.")
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.inkMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, FGSpace.s)

                Text("Your body. Your pace. Always.")
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.ink)
                    .padding(.top, 4)
            }

            Spacer()
        }
    }

    // MARK: - Footer & Helpers

    private var footer: some View {
        Button {
            if currentStep < totalSteps - 1 {
                withAnimation(FGMotion.gentle) {
                    currentStep += 1
                }
            } else {
                finish()
            }
        } label: {
            Text(currentStep == totalSteps - 1 ? "Let's move!" : "Next")
                .font(FGFont.itemTitle)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(FGColor.actionFill)
                .foregroundStyle(FGColor.onActionFill)
                .clipShape(RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous))
        }
        .buttonStyle(.feelGoodPress)
        .padding(.bottom, FGSpace.s)
    }

    private func courseRow(
        title: String,
        time: String,
        subtitle: String,
        icon: String,
        aura: FGAura
    ) -> some View {
        HStack(spacing: FGSpace.m) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(aura.mid)
                .frame(width: 34, height: 34)
                .background(aura.core.opacity(0.4))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(FGFont.itemTitle)
                        .foregroundStyle(FGColor.ink)

                    Spacer()

                    Text(time)
                        .font(FGFont.label)
                        .foregroundStyle(FGColor.inkMuted)
                }

                Text(subtitle)
                    .font(FGFont.reason)
                    .foregroundStyle(FGColor.inkMuted)
            }
        }
        .padding(FGSpace.m)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .fill(FGColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .strokeBorder(FGColor.line, lineWidth: 1)
        )
    }

    private func finish() {
        dismiss()
        onComplete()
    }
}
