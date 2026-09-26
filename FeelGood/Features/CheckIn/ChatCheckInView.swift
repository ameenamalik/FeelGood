//
//  ChatCheckInView.swift
//  FeelGood
//
//  Conversational check-in drawer. Allows the user to describe their day in
//  natural language, previews extracted state pills in real-time, and lets them
//  commit to building today's menu.
//

import SwiftUI
import PostHog

struct ChatCheckInView: View {
    @Binding var text: String
    @Binding var overrides: ConversationalOverrides
    var onCommit: (PlanCheckIn) -> Void

    @State private var isProcessing: Bool = false
    @State private var assistantMessage: String?
    @State private var turns: [ChatTurnPayload] = []
    @State private var service: any ChatProviding = ChatService()
    @FocusState private var isFieldFocused: Bool
    @AppStorage(ChatConsent.key) private var chatConsentRaw = ChatConsent.Status.notAsked.rawValue
    @State private var isShowingChatConsent = false

    private let quickPrompts = [
        "15 min, back is stiff, staying in",
        "Low energy, need a gentle reset",
        "30 min, feeling energized and strong",
        "Short floor work before a long day"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Editorial intro
            VStack(alignment: .leading, spacing: 6) {
                Text("Tell us about today")
                    .font(.custom("SFProRounded-Semibold", size: 20))
                    .foregroundStyle(FGColor.ink)

                Text("How you feel, how much time you have, or where you're at. We'll shape the menu to fit.")
                    .font(.system(size: 14))
                    .foregroundStyle(FGColor.inkMuted)
            }

            // Input card
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundStyle(FGColor.goldDeep)
                        .padding(.top, 2)

                    TextField("e.g. Tired, 15 min, lower back is tight...", text: $text, axis: .vertical)
                        .font(.system(size: 16))
                        .foregroundStyle(FGColor.ink)
                        .lineLimit(2...4)
                        .focused($isFieldFocused)
                        .postHogMask()
                        .submitLabel(.send)
                        .onSubmit {
                            submitText()
                        }
                        .onChange(of: text) { _, newValue in
                            if newValue.contains("\n") {
                                let cleanText = newValue.replacingOccurrences(of: "\n", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                text = cleanText
                                if !cleanText.isEmpty && !isProcessing {
                                    submitText(explicitText: cleanText)
                                }
                            }
                        }
                }
                .padding(14)
                .background(FGColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isFieldFocused ? FGColor.goldDeep : FGColor.line, lineWidth: 1)
                )

                // Quick suggestions
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickPrompts, id: \.self) { prompt in
                            Button {
                                text = prompt
                                submitText()
                            } label: {
                                Text(prompt)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(FGColor.ink)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(FGColor.bg)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(FGColor.line, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Assistant response & live pills
            if isProcessing {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(FGColor.goldDeep)
                        .scaleEffect(0.8)
                    Text("Shaping today's options...")
                        .font(.system(size: 14))
                        .foregroundStyle(FGColor.inkMuted)
                }
                .padding(.vertical, 4)
            } else if let assistantMessage {
                VStack(alignment: .leading, spacing: 12) {
                    Text(assistantMessage)
                        .font(.custom("SFProRounded-Medium", size: 15))
                        .foregroundStyle(FGColor.ink)
                        .padding(12)
                        .background(FGColor.sagePanel)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .postHogMask()

                    // Extracted pills
                    if overrides.hasAnyOverrides {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Extracted focus:")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(FGColor.inkMuted)

                            FlowRow(spacing: 8) {
                                if let energy = overrides.energy {
                                    pill(icon: energy.checkInSymbol, label: energy.checkInLabel, accent: energy.checkInAccent)
                                }
                                if let time = overrides.time {
                                    pill(icon: time.checkInSymbol, label: time.checkInLabel, accent: time.checkInAccent)
                                }
                                if let place = overrides.place {
                                    pill(icon: place.checkInSymbol, label: place.checkInLabel, accent: place.checkInAccent)
                                }
                                if let body = overrides.body {
                                    pill(icon: body.checkInSymbol, label: body.checkInLabel, accent: body.checkInAccent)
                                }
                                if let filter = overrides.quickFilter {
                                    pill(icon: filter.symbol, label: filter.label, accent: .gold)
                                }
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 12)

            // Submit / Build Menu CTA
            Button {
                if overrides.hasAnyOverrides {
                    let checkIn = overrides.toPlanCheckIn()
                    onCommit(checkIn)
                } else {
                    submitText()
                }
            } label: {
                HStack {
                    Spacer()
                    Text(overrides.hasAnyOverrides ? "Build Today's Menu" : "Find Options")
                        .font(.custom("SFProRounded-Semibold", size: 16))
                        .foregroundStyle(FGColor.inkOnAccent)
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(FGColor.clay)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !overrides.hasAnyOverrides)
            .opacity((text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !overrides.hasAnyOverrides) ? 0.6 : 1.0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .sheet(isPresented: $isShowingChatConsent) {
            ChatConsentSheet { agreed in
                chatConsentRaw = (agreed ? ChatConsent.Status.granted : .declined).rawValue
                isShowingChatConsent = false
                submitText()
            }
        }
    }

    private func submitText(explicitText: String? = nil) {
        let textToSend = explicitText ?? text
        let trimmed = textToSend.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let canReachAI = PurchasesManager.shared.isProUnlocked || FreeChatAllowance.standard.isAvailable()
        if canReachAI, chatConsentRaw == ChatConsent.Status.notAsked.rawValue {
            text = trimmed
            isFieldFocused = false
            isShowingChatConsent = true
            return
        }

        isFieldFocused = false
        isProcessing = true

        let userTurn = ChatTurnPayload(role: "user", text: trimmed)
        turns.append(userTurn)
        let historyToSend = Array(turns.dropLast().suffix(4))

        Task {
            let response = await service.describeDay(prompt: trimmed, history: historyToSend)
            await MainActor.run {
                isProcessing = false
                if let response {
                    assistantMessage = response.message
                    overrides = response.overrides
                    turns.append(ChatTurnPayload(role: "model", text: response.message))
                }
            }
        }
    }

    @ViewBuilder
    private func pill(icon: String, label: String, accent: FGAccent) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(accent.fill.opacity(0.2))
        .foregroundStyle(accent.text)
        .clipShape(Capsule())
    }
}
