//
//  ExploreView.swift
//  FeelGood
//
//  The Chat / Explore tab. A stateful, schema-driven conversational companion
//  that handles multi-turn context, intent classification, dynamic routine
//  recommendation cards, and interactive quick-reply action chips.
//

import SwiftUI
import PostHog

struct ExploreView: View {
    let model: TodayModel

    @State private var messages: [ConversationMessage] = []
    @State private var quickReplies: [QuickReplyAction] = []
    @State private var threads: [ConversationThread] = []
    @State private var activeThreadID: UUID?
    @State private var isShowingHistory: Bool = false
    @State private var inputText: String = ""
    @State private var isProcessing: Bool = false
    @State private var service: any ChatProviding = ChatService()
    @State private var selectedSession: Session?
    @State private var selectedSessionReason: String?
    @FocusState private var isFieldFocused: Bool
    @Environment(AuthService.self) private var authService
    @Environment(PurchasesManager.self) private var purchasesManager
    @Environment(\.fgTheme) private var theme
    @AppStorage("hasShownExploreAuthPrompt") private var hasShownExploreAuthPrompt = false
    /// A free user gets one complete user/assistant exchange. This is separate
    /// from chat history so clearing the thread cannot reset the trial.
    @AppStorage("hasUsedFreeChatExchange") private var hasUsedFreeChatExchange = false
    @State private var isShowingAuthPrompt = false
    @State private var isShowingPaywall = false
    @AppStorage(ChatConsent.key) private var chatConsentRaw = ChatConsent.Status.notAsked.rawValue
    @State private var isShowingChatConsent = false
    @State private var routineDraft: RoutineDraft?
    /// The message whose routine card opened the builder, so saving can mark
    /// that card as done.
    @State private var routineDraftMessageID: UUID?

    /// Whether the next message could be answered by the language model.
    private var canReachAI: Bool {
        purchasesManager.isProUnlocked || !hasUsedFreeChatExchange
    }

    /// Answers "am I chatting with an AI?" before anyone has to ask.
    private var headerSubtitle: String {
        canReachAI && chatConsentRaw == ChatConsent.Status.granted.rawValue
            ? "Replies written by AI"
            : "Replies from your phone"
    }

    private let threadsPersistenceKey = "FeelGood.ChatThreads.v1"
    private let activeThreadKey = "FeelGood.ActiveThreadID.v1"
    private let legacyPersistenceKey = "FeelGood.ChatHistory.v2"

    private let defaultStarters: [QuickReplyAction] = [
        QuickReplyAction(id: "starter_why", label: "Why today's plan?", symbol: "questionmark.circle", actionType: .askWhy),
        QuickReplyAction(id: "starter_shorter", label: "10 min reset", symbol: "clock", actionType: .customPrompt, payload: "I need a quick 10 min reset"),
        QuickReplyAction(id: "starter_back", label: "Lower back & hips", symbol: "figure.walk", actionType: .customPrompt, payload: "My lower back and hips feel tight"),
        QuickReplyAction(id: "starter_tired", label: "Tired & low energy", symbol: "battery.25", actionType: .customPrompt, payload: "Feeling tired, need something very gentle"),
        QuickReplyAction(id: "starter_energy", label: "Morning energy", symbol: "sun.max", actionType: .customPrompt, payload: "Want an energizing morning flow"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                FGColor.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Custom Header Bar matching design
                    headerBar

                    // Chat Stream
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 18) {
                                if messages.isEmpty {
                                    initialCuratedThread
                                } else {
                                    ForEach(messages) { message in
                                        messageRow(for: message)
                                            .id(message.id)
                                            .transition(
                                                .opacity.combined(with: .move(edge: .bottom))
                                            )
                                    }
                                }

                                if isProcessing {
                                    typingIndicator
                                        .id("typingIndicator")
                                        .transition(
                                            .opacity.combined(with: .scale(scale: 0.9, anchor: .leading))
                                        )
                                }

                                Color.clear
                                    .frame(height: 16)
                                    .id("chatBottomAnchor")
                            }
                            .animation(FGMotion.gentle, value: isProcessing)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .postHogMask()
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onChange(of: messages.count) { _, _ in
                            scrollToBottom(proxy)
                        }
                        .onChange(of: isProcessing) { _, _ in
                            scrollToBottom(proxy)
                        }
                        .onChange(of: isFieldFocused) { _, _ in
                            scrollToBottom(proxy)
                        }
                        .onAppear {
                            if !messages.isEmpty {
                                scrollToBottom(proxy, animated: false)
                            }
                        }
                    }

                    // Sticky Quick Reply Action Chips Carousel
                    quickRepliesBar

                    // Input Bar
                    bottomInputBar
                }
                // Inside the NavigationStack: an inset applied outside it never
                // reaches this VStack, and the composer sat under the tab bar.
                .fgTabBarInset()
            }
            .navigationBarHidden(true)
        }
        // TabView keeps inactive tabs alive. Rebuild Chat's cached UIKit-backed
        // navigation hierarchy when the look changes so every dynamic color is
        // resolved from one theme. State remains owned by ExploreView, so the
        // conversation and composer are preserved across this refresh.
        .id(theme)
        .sheet(item: $selectedSession) { session in
            SessionDetailView(session: session, model: model, reason: selectedSessionReason)
        }
        .sheet(isPresented: $isShowingAuthPrompt) {
            AuthSheetView(
                title: "Save your routine",
                subtitle: "Create an account to keep this recommendation across devices."
            )
        }
        .sheet(isPresented: $isShowingHistory) {
            ChatHistorySheet(
                threads: threads,
                activeThreadID: activeThreadID,
                onSelectThread: { thread in
                    selectThread(thread)
                },
                onNewChat: {
                    startNewConversation()
                },
                onDeleteThread: { id in
                    deleteThread(id)
                }
            )
        }
        .sheet(isPresented: $isShowingPaywall) {
            FeelGoodPaywallView(context: .chatLimit)
        }
        .sheet(item: $routineDraft) { draft in
            AddRoutineSheet(model: model, initialCourse: draft.course, draft: draft) { session in
                // Close the loop in the conversation: the saved routine comes
                // back as a card, and Chat offers it next time it's asked.
                let saved = ConversationMessage(
                    role: .assistant,
                    text: "Saved. It's on your menu, and I'll offer it next time you ask.",
                    recommendation: LocalStatefulChatEngine.structuredRecommendation(for: session, reason: "One of your own routines.")
                )
                if let id = routineDraftMessageID, let index = messages.firstIndex(where: { $0.id == id }) {
                    messages[index].isRoutineOfferSaved = true
                }
                routineDraftMessageID = nil
                withAnimation(FGMotion.settle) { messages.append(saved) }
                savePersistedHistory()
            }
        }
        .sheet(isPresented: $isShowingChatConsent) {
            ChatConsentSheet { agreed in
                chatConsentRaw = (agreed ? ChatConsent.Status.granted : .declined).rawValue
                Analytics.capture(
                    EngagementAnalytics.aiConsentChangedEvent,
                    properties: EngagementAnalytics.aiConsentChanged(granted: agreed, source: .sheet)
                )
                isShowingChatConsent = false
                // The message they wrote is still in the composer.
                submitText()
            }
        }
        .onAppear {
            loadPersistedHistory()
        }
        .task {
            await purchasesManager.refreshCustomerInfo()
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool = true) {
        let performScroll = {
            if animated {
                withAnimation(FGMotion.gentle) {
                    proxy.scrollTo("chatBottomAnchor", anchor: .bottom)
                }
            } else {
                proxy.scrollTo("chatBottomAnchor", anchor: .bottom)
            }
        }

        performScroll()

        DispatchQueue.main.async {
            performScroll()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            performScroll()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            performScroll()
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        ZStack {
            // Centered Title
            VStack(spacing: 1) {
                Text("Chat")
                    .font(.custom("SFProRounded-Semibold", size: 18))
                    .foregroundStyle(FGColor.ink)
                Text(headerSubtitle)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(FGColor.inkMuted)
            }
            .accessibilityElement(children: .combine)

            HStack(alignment: .center) {
                // Previous Conversation History Button
                Button {
                    isShowingHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(FGColor.ink)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Chat History")

                Spacer()

                // New Chat Button
                Button {
                    startNewConversation()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(FGColor.ink)
                        .frame(width: 36, height: 36)
                        .background(FGColor.panelRaised)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("New Chat")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(FGColor.bg)
    }

    // MARK: - Initial Curated Conversation State

    /// Text-only on purpose — the menu itself already has a visual home on
    /// Today, cards here just repeated it. Chat's opener now only needs to
    /// invite the conversation, not restate the whole menu.
    private var initialCuratedThread: some View {
        VStack(alignment: .leading, spacing: 18) {
            if model.menu.items.isEmpty {
                assistantTextBubble(text: "How is your body feeling today? Tell me what you need, or tap an option below.")
            } else {
                assistantTextBubble(text: "Your \(todaysMenuMinutes)-minute menu is ready on Today. Tell me how it's going, or what you need instead.")
            }
        }
    }

    // MARK: - Message Rows

    @ViewBuilder
    private func messageRow(for message: ConversationMessage) -> some View {
        switch message.role {
        case .user:
            userTextBubble(text: message.text)

        case .assistant:
            VStack(alignment: .leading, spacing: 14) {
                if !message.text.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        assistantTextBubble(text: message.text)
                        if message.isFromAI == true {
                            Label("AI reply", systemImage: "sparkles")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(FGColor.inkMuted)
                                .padding(.leading, 6)
                                .accessibilityLabel("Written by AI")
                        }
                    }
                }

                if let recommendation = message.recommendation {
                    recommendationCard(
                        recommendation: recommendation,
                        messageID: message.id,
                        isCommitted: message.isCommittedToToday
                    )
                }

                if let request = message.routineOfferPrompt, let draft = RoutineDraft.from(prompt: request) {
                    routineOfferCard(draft: draft, messageID: message.id, isSaved: message.isRoutineOfferSaved == true)
                }
            }
        }
    }

    /// "We don't have that" becomes "make it yours": a card in the thread,
    /// right under the reply, that opens the builder already filled in.
    private func routineOfferCard(draft: RoutineDraft, messageID: UUID, isSaved: Bool) -> some View {
        Button {
            guard !isSaved else { return }
            routineDraftMessageID = messageID
            routineDraft = draft
        } label: {
            HStack(spacing: 14) {
                // Deep fill with its paired type, so the glyph holds its
                // contrast in every look and in dark mode.
                Image(systemName: isSaved ? "checkmark" : "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isSaved ? FGColor.sageDeep : FGColor.onDeepFill)
                    .frame(width: 40, height: 40)
                    .background(isSaved ? FGColor.sagePanel : FGColor.userBubble, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(isSaved ? "Saved to your menu" : "Make it your own routine")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(FGColor.ink)
                    Text(isSaved
                         ? "\(draft.title) · I'll offer it next time you ask."
                         : "\(draft.title) · \(draft.durationMin) min. I'll fill it in, you tweak and save.")
                        .font(.subheadline)
                        .foregroundStyle(FGColor.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !isSaved {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FGColor.inkMuted)
                }
            }
            .padding(16)
            .background(FGColor.surface, in: RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .strokeBorder(FGColor.line, lineWidth: 1)
            )
        }
        .buttonStyle(.feelGoodPress)
        .disabled(isSaved)
        .accessibilityLabel(isSaved ? "Saved: \(draft.title)" : "Make it your own routine: \(draft.title), \(draft.durationMin) minutes")
        .accessibilityHint(isSaved ? "" : "Opens the routine builder, already filled in")
    }

    private func assistantTextBubble(text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(FGColor.ink)
                .lineSpacing(4)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(FGColor.panel)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Spacer(minLength: 44)
        }
    }

    private func userTextBubble(text: String) -> some View {
        HStack {
            Spacer(minLength: 44)

            Text(text)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(FGColor.onDeepFill)
                .lineSpacing(4)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(FGColor.userBubble)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    // MARK: - Recommendation Card Component

    private func recommendationCard(
        recommendation: StructuredRecommendation,
        messageID: UUID?,
        isCommitted: Bool = false
    ) -> some View {
        // Reads the same shared taxonomy Today and My Menu use — this used to
        // be a second, hand-copied palette that could (and did) drift from
        // `Course.accentGradient`. One source of truth now, and the mascot
        // that goes with it.
        let course = recommendation.resolvedCourse

        return VStack(alignment: .leading, spacing: 14) {
            // Frosted Tags Row
            WrapRow(spacing: 6, lineSpacing: 6) {
                ForEach(recommendation.displayTags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(course.accentText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(FGColor.surface.opacity(0.68))
                        .clipShape(Capsule())
                }
            }

            // Title, with the course's mascot alongside — the same fruit this
            // course wears on Today and My Menu. The "why" waits behind
            // Start, on the session's own detail screen, rather than
            // repeating itself here.
            HStack(alignment: .center, spacing: FGSpace.m) {
                Text(recommendation.title)
                    .font(.custom("SFProRounded-Bold", size: 24))
                    .foregroundStyle(course.accentText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(course.menuMascotAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .accessibilityHidden(true)
            }

            // Prominent Action Button: Start ->
            Button {
                launchSession(recommendation: recommendation)
            } label: {
                HStack(spacing: 8) {
                    Spacer()
                    Text("Start")
                        .font(.custom("SFProRounded-Semibold", size: 17))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                    Spacer()
                }
                .foregroundStyle(FGColor.onActionFill)
                .padding(.vertical, 14)
                .background(FGColor.actionFill)
                .clipShape(.capsule)
            }
            .buttonStyle(.plain)

            // Secondary Action: Add to today
            Button {
                Analytics.capture(ChatAnalytics.cardCommittedEvent, properties: ChatAnalytics.cardCommitted(source: .card))
                commitRecommendationToToday(recommendation: recommendation, messageID: messageID)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: isCommitted ? "checkmark" : "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text(isCommitted ? "Added to today" : "Add to today")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(isCommitted ? FGColor.sageDeep : course.accentText)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(FGColor.surface.opacity(0.55))
                .clipShape(.capsule)
            }
            .buttonStyle(.plain)
            .disabled(isCommitted)
        }
        .padding(18)
        .background(course.accentGradient)
        .clipShape(.rect(cornerRadius: 24))
        .contentShape(Rectangle())
        .onTapGesture {
            launchSession(recommendation: recommendation)
        }
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        TypingDots()
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(FGColor.panel)
            .clipShape(Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Thinking")
    }

    // MARK: - Quick Replies Bar

    private var quickRepliesBar: some View {
        let replies = quickReplies.isEmpty ? defaultStarters : quickReplies

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(replies) { chip in
                    Button {
                        executeQuickReply(chip)
                    } label: {
                        HStack(spacing: 6) {
                            if let symbol = chip.symbol {
                                Image(systemName: symbol)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            Text(chip.label)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(FGColor.ink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(FGColor.surface)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(FGColor.line, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .animation(FGMotion.gentle, value: replies)
        }
    }

    // MARK: - Bottom Input Bar

    private var bottomInputBar: some View {
        HStack(spacing: 10) {
            TextField("Tell it how you're doing...", text: $inputText, axis: .vertical)
                .font(.system(size: 16))
                .foregroundStyle(FGColor.ink)
                .lineLimit(1...4)
                .focused($isFieldFocused)
                .postHogMask()
                .submitLabel(.send)
                .onSubmit {
                    submitText()
                }
                .onChange(of: inputText) { _, newValue in
                    if newValue.contains("\n") {
                        let cleanText = newValue.replacingOccurrences(of: "\n", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        inputText = ""
                        if !cleanText.isEmpty && !isProcessing {
                            submitText(explicitText: cleanText)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(FGColor.inputFill)
                .clipShape(Capsule())

            Button {
                submitText()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(FGColor.onSend)
                    .frame(width: 46, height: 46)
                    .background(
                        FGColor.sendGradient
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
            .opacity(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing ? 0.5 : 1.0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(FGColor.bg)
    }

    // MARK: - Actions

    private func submitText(explicitText: String? = nil) {
        let textToSend = explicitText ?? inputText
        let trimmed = textToSend.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isProcessing else { return }

        // Keep the attempted message in the composer. If the person upgrades,
        // they can close the paywall and send it without typing it again.
        if !purchasesManager.isProUnlocked && hasUsedFreeChatExchange {
            inputText = trimmed
            isFieldFocused = false
            isShowingPaywall = true
            Analytics.capture("chat_paywall_presented", properties: [
                "trigger": "second_message"
            ])
            return
        }

        // Only a message that can reach the server — a subscriber's, or a free
        // user's one AI exchange — needs asking about, and only once. The
        // answer is remembered either way.
        if canReachAI, chatConsentRaw == ChatConsent.Status.notAsked.rawValue {
            inputText = trimmed
            isFieldFocused = false
            isShowingChatConsent = true
            return
        }

        let userMsg = ConversationMessage(role: .user, text: trimmed)
        withAnimation(FGMotion.settle) { messages.append(userMsg) }
        savePersistedHistory()
        inputText = ""
        isProcessing = true

        let completedEntries = model.history.filter(\.wasCompleted)
        let liked = completedEntries.compactMap { entry -> String? in
            if case .completed(let feel) = entry.outcome, feel == .lovedIt {
                return entry.activity.rawValue
            }
            return nil
        }
        let lastFeel: String? = completedEntries.last.flatMap { entry in
            if case .completed(let feel) = entry.outcome {
                return feel?.rawValue
            }
            return nil
        }
        let recoveryOwed = completedEntries.suffix(3).contains { entry in
            if case .completed(let feel) = entry.outcome {
                return feel == .tooMuch
            }
            return false
        }
        let banditPrefs = model.banditCoarsenedPreferences
        // Same access Today uses, widened by anything said in this conversation.
        let availability = ChatAvailability(
            profile: model.profile,
            conversation: messages.filter { $0.role == .user }.map(\.text)
        )
        let userContext = ChatUserContext(
            likedActivities: Array(Set(liked)),
            lastFeel: lastFeel,
            recentCompletions: completedEntries.count,
            recoveryOwed: recoveryOwed,
            hiddenSessionIDs: Array(model.profile.hiddenSessionIDs),
            shownSessionIDs: Array(Set(messages.compactMap { $0.recommendation?.sessionID })),
            preferredIntensityTier: banditPrefs.preferredIntensityTier,
            topExploredActivities: banditPrefs.topExploredActivities,
            fatigueSensitivity: banditPrefs.fatigueSensitivity,
            availability: availability
        )
        let wireHistory = messages.suffix(4).map {
            ChatTurnPayload(role: $0.role == .user ? "user" : "model", text: $0.text)
        }

        let currentActiveID = messages.reversed().compactMap(\.recommendation?.sessionID).first ?? model.menu.main?.session.id
        let todaysMenu = model.menu.items.map {
            LocalStatefulChatEngine.structuredRecommendation(for: $0.session, reason: $0.reasonText)
        }

        let startedAt = Date()
        let workArounds = model.profile.workArounds
        let otherWorkAroundNote = model.profile.otherWorkAroundNote
        let lookupSession: (String) -> Session? = { id in model.everything.first { $0.id == id } }
        Task {
            let response = await service.describeDay(
                prompt: trimmed,
                history: wireHistory,
                activeSessionID: currentActiveID,
                userContext: userContext,
                todaysMenu: todaysMenu
            )

            await MainActor.run {
                isProcessing = false
                // The server never sees work-arounds, so the check that keeps a
                // conflicting session out of chat happens here, on the phone.
                let response = response.map { reply in
                    ChatSafety.apply(
                        to: reply,
                        workArounds: workArounds,
                        otherNote: otherWorkAroundNote,
                        availability: availability,
                        lookup: lookupSession,
                        replacement: { rejected in
                            LocalStatefulChatEngine.matchBestSession(
                                targetDuration: rejected.durationMin,
                                intensity: rejected.intensity,
                                excludeID: rejected.sessionID,
                                userContext: userContext,
                                workArounds: workArounds,
                                otherNote: otherWorkAroundNote,
                                availability: availability
                            )
                        }
                    )
                }
                let latencyMs = Int(Date().timeIntervalSince(startedAt) * 1000)
                guard let response else {
                    Analytics.capture(ChatAnalytics.replyFailedEvent, properties: ChatAnalytics.replyFailed(latencyMs: latencyMs))
                    withAnimation(FGMotion.settle) {
                        messages.append(ConversationMessage(
                            role: .assistant,
                            text: "Couldn't reach the companion just now — try again in a moment."
                        ))
                    }
                    return
                }

                Analytics.capture(ChatAnalytics.replyReceivedEvent, properties: ChatAnalytics.replyReceived(
                    mode: response.mode,
                    intent: response.intent,
                    phase: response.phase,
                    hasCard: response.recommendation != nil,
                    quickReplyCount: response.quickReplies.count,
                    latencyMs: latencyMs,
                    hadCheckInOverrides: response.overrides.hasAnyOverrides
                ))

                if response.overrides.hasAnyOverrides {
                    model.applyConversationalCheckIn(response)
                }

                var replyText = response.message
                var card = response.recommendation
                var isFromAI = response.isFromAI
                var routineOfferPrompt: String?
                // Boxing answered with a circuit is still "we don't have
                // boxing": a card for a different kind of movement counts as
                // no match, so their own routine or the builder is offered.
                let requestedActivity = RoutineDraft.activity(in: trimmed.lowercased())
                let cardActivity = card.flatMap { rec in model.everything.first { $0.id == rec.sessionID } }?.activity
                let isMissingWhatTheyAskedFor = requestedActivity != nil && cardActivity != requestedActivity
                if isMissingWhatTheyAskedFor, let own = RoutineDraft.savedMatch(
                    for: trimmed,
                    in: model.ownSessions,
                    isHidden: { model.isHidden($0) }
                ) {
                    // Their own routine beats "I don't have that". Matched on
                    // the phone, so routine titles never leave it.
                    replyText = "You've got your own for this: \(own.title)."
                    card = LocalStatefulChatEngine.structuredRecommendation(for: own, reason: "One of your own routines.")
                    isFromAI = false
                } else if isMissingWhatTheyAskedFor {
                    // In the conversation, not the chip row: it's the answer
                    // to what they asked, so it sits with the reply.
                    routineOfferPrompt = trimmed
                }

                let assistantMsg = ConversationMessage(
                    role: .assistant,
                    text: replyText,
                    recommendation: card,
                    isFromAI: isFromAI,
                    routineOfferPrompt: routineOfferPrompt
                )
                withAnimation(FGMotion.settle) { messages.append(assistantMsg) }
                quickReplies = response.quickReplies
                if !purchasesManager.isProUnlocked {
                    hasUsedFreeChatExchange = true
                }
                savePersistedHistory()
            }
        }
    }

    private func executeQuickReply(_ chip: QuickReplyAction) {
        Analytics.capture(ChatAnalytics.quickReplyTappedEvent, properties: ChatAnalytics.quickReplyTapped(chip.actionType))
        switch chip.actionType {
        case .filterShorter:
            inputText = "Something shorter"
            submitText()

        case .askWhy:
            inputText = "Why this?"
            submitText()

        case .swapRoutine:
            inputText = "Not today"
            submitText()

        case .filterGentler:
            inputText = "Gentler option"
            submitText()

        case .filterMoreEnergizing:
            inputText = "More energizing"
            submitText()

        case .filterStayingIn:
            inputText = "Staying in"
            submitText()

        case .startSession:
            if let lastRec = messages.reversed().compactMap(\.recommendation).first {
                launchSession(recommendation: lastRec)
            } else if let main = model.menu.main {
                selectedSessionReason = main.reasonText
                selectedSession = main.session
            }

        case .commitToToday:
            if let lastRec = messages.reversed().compactMap(\.recommendation).first {
                Analytics.capture(ChatAnalytics.cardCommittedEvent, properties: ChatAnalytics.cardCommitted(source: .chip))
                commitRecommendationToToday(recommendation: lastRec, messageID: nil)
            }

        case .customPrompt:
            inputText = chip.payload ?? chip.label
            submitText()

        case .buildRoutine:
            let request = chip.payload
                ?? messages.last(where: { $0.role == .user })?.text
                ?? ""
            routineDraft = RoutineDraft.from(prompt: request)
        }
    }

    private func commitRecommendationToToday(recommendation: StructuredRecommendation, messageID: UUID?) {
        if let session = resolveSession(from: recommendation) {
            model.commitSessionToToday(session)
        }

        if let messageID, let index = messages.firstIndex(where: { $0.id == messageID }) {
            messages[index].isCommittedToToday = true
            savePersistedHistory()
        }

        if !authService.isAuthenticated && !hasShownExploreAuthPrompt {
            hasShownExploreAuthPrompt = true
            isShowingAuthPrompt = true
        }
    }

    private func launchSession(recommendation: StructuredRecommendation) {
        let session = resolveSession(from: recommendation)
        selectedSessionReason = recommendation.reason
        selectedSession = session
    }

    private func resolveSession(from rec: StructuredRecommendation) -> Session? {
        if let match = model.everything.first(where: { $0.id == rec.sessionID }) {
            return match
        }
        if let match = model.everything.first(where: { $0.title.localizedCaseInsensitiveContains(rec.title) || rec.title.localizedCaseInsensitiveContains($0.title) }) {
            return match
        }
        return model.everything.first(where: { $0.durationMin == rec.durationMin }) ?? model.everything.first
    }

    /// The header pill and the opening bubble both read off this, so they
    /// can never disagree with each other — or with what the cards below
    /// actually add up to. A check-in's time budget is a ceiling the engine
    /// doesn't always fill (see `TodayView`'s "Room for X min"), so stating
    /// the budget here instead of the real total made the two look broken.
    private var todaysMenuMinutes: Int {
        model.menu.items.reduce(0) { $0 + $1.session.durationMin }
    }



    // MARK: - Thread Management & Persistence

    private func loadPersistedHistory() {
        if let data = UserDefaults.standard.data(forKey: threadsPersistenceKey),
           let decoded = try? JSONDecoder().decode([ConversationThread].self, from: data),
           !decoded.isEmpty {
            threads = decoded

            let savedActiveID = UserDefaults.standard.string(forKey: activeThreadKey).flatMap { UUID(uuidString: $0) }
            if let savedActiveID, let active = threads.first(where: { $0.id == savedActiveID }) {
                activeThreadID = active.id
                messages = active.messages
                quickReplies = active.quickReplies
            } else if let first = threads.first {
                activeThreadID = first.id
                messages = first.messages
                quickReplies = first.quickReplies
            }
            return
        }

        // Migrate legacy single-thread history if present
        if let legacyData = UserDefaults.standard.data(forKey: legacyPersistenceKey),
           let legacyMessages = try? JSONDecoder().decode([ConversationMessage].self, from: legacyData),
           !legacyMessages.isEmpty {
            let migratedThread = ConversationThread(
                title: "Previous Check-In",
                messages: legacyMessages,
                quickReplies: []
            )
            threads = [migratedThread]
            activeThreadID = migratedThread.id
            messages = migratedThread.messages
            quickReplies = []
            savePersistedHistory()
            UserDefaults.standard.removeObject(forKey: legacyPersistenceKey)
            return
        }

        // Fresh state: create initial thread
        let initialThread = ConversationThread()
        threads = [initialThread]
        activeThreadID = initialThread.id
        messages = []
        quickReplies = []
    }

    private func savePersistedHistory() {
        guard let currentID = activeThreadID else { return }

        if let index = threads.firstIndex(where: { $0.id == currentID }) {
            threads[index].messages = messages
            threads[index].quickReplies = quickReplies
            threads[index].updatedAt = Date()
            threads[index].title = threads[index].displayTitle
        } else {
            let newThread = ConversationThread(
                id: currentID,
                title: "New Check-In",
                messages: messages,
                quickReplies: quickReplies
            )
            threads.insert(newThread, at: 0)
        }

        if let data = try? JSONEncoder().encode(threads) {
            UserDefaults.standard.set(data, forKey: threadsPersistenceKey)
        }
        UserDefaults.standard.set(currentID.uuidString, forKey: activeThreadKey)
    }

    private func startNewConversation() {
        // If current thread has no messages, just reset inputs and stay on it
        if messages.isEmpty {
            inputText = ""
            isFieldFocused = false
            return
        }

        // Save current thread first
        savePersistedHistory()

        let newThread = ConversationThread()
        withAnimation(FGMotion.gentle) {
            threads.insert(newThread, at: 0)
            activeThreadID = newThread.id
            messages = []
            quickReplies = []
            inputText = ""
            isFieldFocused = false
        }
        savePersistedHistory()
    }

    private func selectThread(_ thread: ConversationThread) {
        // Save current thread before switching
        savePersistedHistory()

        withAnimation(FGMotion.gentle) {
            activeThreadID = thread.id
            messages = thread.messages
            quickReplies = thread.quickReplies
            inputText = ""
            isFieldFocused = false
        }
        UserDefaults.standard.set(thread.id.uuidString, forKey: activeThreadKey)
    }

    private func deleteThread(_ id: UUID) {
        withAnimation(FGMotion.gentle) {
            threads.removeAll(where: { $0.id == id })

            if activeThreadID == id {
                if let next = threads.first {
                    activeThreadID = next.id
                    messages = next.messages
                    quickReplies = next.quickReplies
                } else {
                    let fresh = ConversationThread()
                    threads = [fresh]
                    activeThreadID = fresh.id
                    messages = []
                    quickReplies = []
                }
            }
        }

        if let data = try? JSONEncoder().encode(threads) {
            UserDefaults.standard.set(data, forKey: threadsPersistenceKey)
        }
        if let currentActive = activeThreadID {
            UserDefaults.standard.set(currentActive.uuidString, forKey: activeThreadKey)
        }
    }
}

/// Three dots that rise in turn. Holds still under Reduce Motion.
private struct TypingDots: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            dots(phase: 0)
        } else {
            TimelineView(.animation) { context in
                dots(phase: context.date.timeIntervalSinceReferenceDate)
            }
        }
    }

    private func dots(phase: TimeInterval) -> some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                let lift = reduceMotion ? 0 : max(0, sin(phase * 6 - Double(index) * 0.7))
                Circle()
                    .fill(FGColor.inkMuted)
                    .frame(width: 7, height: 7)
                    .offset(y: -4 * lift)
                    .opacity(0.5 + 0.5 * lift)
            }
        }
    }
}
