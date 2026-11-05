//
//  SettingUpMenuView.swift
//  FeelGood
//
//  Replaces the timed transition with a readable summary of the person's
//  choices. They can review, edit, and enter their first menu at their own pace.
//

import SwiftUI
import PostHog

struct SettingUpMenuView: View {
    var answers = ProfileAnswers()
    var onEdit: (() -> Void)? = nil
    var onComplete: () -> Void

    @State private var isCompleted = false

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: FGSpace.l) {
                    Image("IntentEnergyClementine")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .accessibilityHidden(true)

                    VStack(spacing: FGSpace.s) {
                        Text("Your starting point")
                            .font(.system(.title, design: .rounded).weight(.medium))
                            .foregroundStyle(FGColor.ink)
                            .accessibilityAddTraits(.isHeader)

                        Text("Here’s what we’ll use to shape your first menu.")
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 0) {
                        ForEach(Array(OnboardingSummary(answers: answers).rows.enumerated()), id: \.element.id) { index, row in
                            if index > 0 {
                                Divider().overlay(FGColor.line)
                            }
                            HStack(alignment: .top, spacing: FGSpace.m) {
                                Image(systemName: row.symbol)
                                    .font(.body)
                                    .foregroundStyle(FGColor.inkMuted)
                                    .frame(width: 24)
                                    .padding(.top, 2)
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: FGSpace.xs) {
                                    Text(row.title)
                                        .font(FGFont.caption)
                                        .foregroundStyle(FGColor.inkMuted)
                                    Text(row.value)
                                        .font(FGFont.body)
                                        .foregroundStyle(FGColor.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(FGSpace.m)
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .background(FGColor.surface, in: RoundedRectangle(cornerRadius: FGRadius.card))
                    .postHogMask()
                }
                .padding(FGSpace.page)
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: FGSpace.s) {
                    FGPrimaryButton(title: "See my first menu") {
                        guard !isCompleted else { return }
                        isCompleted = true
                        onComplete()
                    }
                    if let onEdit {
                        FGQuietButton("Edit my answers", systemImage: "pencil", action: onEdit)
                    }
                }
                .padding(.horizontal, FGSpace.page)
                .padding(.vertical, FGSpace.s)
                .background(FGColor.bg)
            }
            .fgReadableWidth()
        }
        .onAppear {
            Analytics.capture("onboarding_summary_viewed", properties: ["flow_version": 2])
        }
    }
}

#Preview {
    SettingUpMenuView(
        answers: ProfileAnswers(activities: [.yoga, .walking], equipment: [.mat], intents: [.calm, .mobilize]),
        onEdit: {},
        onComplete: {}
    )
}
