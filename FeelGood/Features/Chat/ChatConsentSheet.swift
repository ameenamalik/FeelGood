//
//  ChatConsentSheet.swift
//  FeelGood
//
//  Shown once, before the first Chat message that would leave the device.
//  Both answers are fine: "Keep it on my phone" is not a lesser path.
//

import SwiftUI

struct ChatConsentSheet: View {
    /// `true` when the person agreed to send messages to the language model.
    let onDecision: (Bool) -> Void

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            FGBrandWash(reach: 0.65).ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: FGSpace.l) {
                        intro
                        privacySummary
                        privacyLink
                    }
                    .padding(.horizontal, FGSpace.page)
                    .padding(.top, FGSpace.l)
                    .padding(.bottom, FGSpace.m)
                }
                .scrollBounceBehavior(.basedOnSize)

                choices
                    .padding(.horizontal, FGSpace.page)
                    .padding(.top, FGSpace.s)
                    .padding(.bottom, FGSpace.m)
                    .overlay(alignment: .top) {
                        Divider().overlay(FGColor.line)
                    }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled()
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(FGColor.inkOnAccent)
                .frame(width: 64, height: 64)
                .background(FGAura.apricot.core, in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(FGAura.apricot.mid.opacity(0.75), lineWidth: 1)
                }
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: FGSpace.xs) {
                Text("Choose how we chat")
                    .font(FGFont.display)
                    .foregroundStyle(FGColor.ink)

                Text("Use richer AI replies, or keep every message on your device. You can change this later in My account.")
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var privacySummary: some View {
        VStack(alignment: .leading, spacing: 0) {
            privacyRow(
                icon: "sparkles",
                title: "If you use AI replies",
                detail: "What you type is sent to Google Gemini through FeelGood’s server."
            )

            Divider().overlay(FGColor.line)

            privacyRow(
                icon: "hand.raised.fill",
                title: "Private details are filtered first",
                detail: "We filter contact details, links and some health terms, but filtering isn’t perfect."
            )

            Divider().overlay(FGColor.line)

            privacyRow(
                icon: "checkmark.shield.fill",
                title: "Your check-ins stay private",
                detail: "Check-in answers and work-arounds are never sent."
            )
        }
        .padding(.horizontal, FGSpace.m)
        .background(FGColor.surface.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                .strokeBorder(FGColor.lineStrong.opacity(0.65), lineWidth: 1)
        }
    }

    private func privacyRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: FGSpace.m) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(FGColor.clayDeep)
                .frame(width: 28, height: 28)
                .background(FGAura.apricot.core, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.ink)

                Text(detail)
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, FGSpace.m)
    }

    private var privacyLink: some View {
        Link(destination: LegalLinks.privacyPolicy) {
            HStack(spacing: FGSpace.xs) {
                Image(systemName: "doc.text")
                Text("Read the privacy policy")
                Spacer()
                Image(systemName: "arrow.up.right")
            }
            .font(FGFont.label.weight(.semibold))
            .foregroundStyle(FGColor.ink)
            .frame(minHeight: FGSize.minTouchTarget)
            .padding(.horizontal, FGSpace.m)
            .background(FGColor.surface.opacity(0.72), in: Capsule())
            .overlay {
                Capsule().strokeBorder(FGColor.lineStrong, lineWidth: 1)
            }
        }
    }

    private var choices: some View {
        VStack(spacing: FGSpace.s) {
            FGPrimaryButton(title: "Use AI replies") { onDecision(true) }

            Button {
                onDecision(false)
            } label: {
                Text("Keep replies on this device")
                    .font(FGFont.body.weight(.semibold))
                    .foregroundStyle(FGColor.ink)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(FGColor.surface.opacity(0.86), in: Capsule())
                    .overlay {
                        Capsule().strokeBorder(FGColor.lineStrong, lineWidth: 1)
                    }
            }
            .buttonStyle(.feelGoodPress)
        }
    }
}

#Preview("Chat consent") {
    ChatConsentSheet { _ in }
        .preferredColorScheme(.dark)
}
