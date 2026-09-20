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
        VStack(alignment: .leading, spacing: FGSpace.m) {
            Text("Before we chat")
                .font(FGFont.title)
                .foregroundStyle(FGColor.ink)

            Text("To write replies, FeelGood can send your messages to an AI language model (Google Gemini) through our server. We remove emails, phone numbers, links and some health words on your phone first, but the scrub isn't perfect, so please keep private details out of your messages.")
                .font(FGFont.body)
                .foregroundStyle(FGColor.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("Your check-in answers and work-arounds are never sent. Or keep it on your phone: Chat still works, with simpler replies and nothing leaving your device. You can change this any time under My account.")
                .font(FGFont.caption)
                .foregroundStyle(FGColor.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

            Link("Read the privacy policy", destination: LegalLinks.privacyPolicy)
                .font(FGFont.caption.weight(.medium))
                .foregroundStyle(FGColor.ink)

            Spacer(minLength: FGSpace.s)

            FGPrimaryButton(title: "Use AI replies") { onDecision(true) }
            FGPrimaryButton(title: "Keep it on my phone") { onDecision(false) }
        }
        .padding(FGSpace.page)
        .background(FGColor.bg.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled()
    }
}
