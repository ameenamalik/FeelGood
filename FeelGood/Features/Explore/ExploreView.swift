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
    @State private var activeTimeLabel: String = "15 min"
    @FocusState private var isFieldFocused: Bool
    @Environment(AuthService.self) private var authService
    @Environment(PurchasesManager.self) private var purchasesManager
    @AppStorage("hasShownExploreAuthPrompt") private var hasShownExploreAuthPrompt = false
    /// A free user gets one complete user/assistant exchange. This is separate
    /// from chat history so clearing the thread cannot reset the trial.
    @AppStorage("hasUsedFreeChatExchange") private var hasUsedFreeChatExchange = false
    @State private var isShowingAuthPrompt = false
    @State private var isShowingPaywall = false

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
                    }

                    // Sticky Quick Reply Action Chips Carousel
                    quickRepliesBar

                    // Input Bar
                    bottomInputBar
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(item: $selectedSession) { session in
            SessionDetailView(session: session, model: model)
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
            FeelGoodPaywallView()
        }
        .onAppear {
            loadPersistedHistory()
            updateActiveTimeLabel()
        }
        .task {
            await purchasesManager.refreshCustomerInfo()
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(FGMotion.gentle) {
            if isProcessing {
                proxy.scrollTo("typingIndicator", anchor: .bottom)
            } else if let last = messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
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

            // Title
            Text("Today's menu")
                .font(.custom("SFProRounded-Semibold", size: 18))
                .foregroundStyle(FGColor.ink)

            Spacer()

            // Right side: Active Time Pill Badge + New Chat Button
            HStack(spacing: 8) {
                Text(activeTimeLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FGColor.inkMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(light: 0xF3EEE7, dark: 0x2A2724))
                    .clipShape(Capsule())

                Button {
                    startNewConversation()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(FGColor.ink)
                        .frame(width: 32, height: 32)
                        .background(Color(light: 0xF3EEE7, dark: 0x2A2724))
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
                    assistantTextBubble(text: message.text)
                }

                if let recommendation = message.recommendation {
                    recommendationCard(
                        recommendation: recommendation,
                        messageID: message.id,
                        isCommitted: message.isCommittedToToday,
                        isReasonVisible: message.isReasonVisible
                    )
                }
            }
        }
    }

    private func assistantTextBubble(text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(FGColor.ink)
                .lineSpacing(4)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(light: 0xF3EEE7, dark: 0x262320))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Spacer(minLength: 44)
        }
    }

    private func userTextBubble(text: String) -> some View {
        HStack {
            Spacer(minLength: 44)

            Text(text)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.white)
                .lineSpacing(4)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(light: 0x26231F, dark: 0x36322E))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    // MARK: - Recommendation Card Component

    private func recommendationCard(
        recommendation: StructuredRecommendation,
        messageID: UUID?,
        isCommitted: Bool = false,
        isReasonVisible: Bool = false
    ) -> some View {
        let palette = cardPalette(for: recommendation.course)

        return VStack(alignment: .leading, spacing: 14) {
            // Frosted Tags Row
            WrapRow(spacing: 6, lineSpacing: 6) {
                ForEach(recommendation.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(palette.tagText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(FGColor.surface.opacity(0.68))
                        .clipShape(Capsule())
                }
            }

            // Title
            Text(recommendation.title)
                .font(.custom("SFProRounded-Bold", size: 24))
                .foregroundStyle(palette.titleText)

            // Subtitle
            Text(recommendation.subtitle)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(palette.subtitleText)
                .lineSpacing(3)

            // Inline Reason (if toggled)
            if isReasonVisible {
                Text(recommendation.reason)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.subtitleText.opacity(0.9))
                    .padding(10)
                    .background(FGColor.surface.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                .foregroundStyle(Color.white)
                .padding(.vertical, 14)
                .background(Color(light: 0x2C211C, dark: 0x1A1715))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            // Secondary Action Row: Add to today & Why this?
            HStack(spacing: 10) {
                Button {
                    commitRecommendationToToday(recommendation: recommendation, messageID: messageID)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: isCommitted ? "checkmark" : "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text(isCommitted ? "Added to today" : "Add to today")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(isCommitted ? FGColor.sageDeep : palette.titleText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(FGColor.surface.opacity(0.55))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isCommitted)

                if let messageID {
                    Button {
                        toggleReason(for: messageID)
                    } label: {
                        Text(isReasonVisible ? "Hide why" : "Why this?")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(palette.titleText.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(FGColor.surface.opacity(0.55))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .background(palette.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            launchSession(recommendation: recommendation)
        }
    }

    // MARK: - Palette Helper

    private struct CardPalette {
        let gradient: LinearGradient
        let titleText: Color
        let subtitleText: Color
        let tagText: Color
    }

    private func cardPalette(for course: String) -> CardPalette {
        switch course.lowercased() {
        case "appetizer":
            return CardPalette(
                gradient: LinearGradient(
                    colors: [Color(light: 0xFEE4D3, dark: 0x3D261C), Color(light: 0xF5B4AB, dark: 0x4A2222)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                titleText: Color(light: 0x241C15, dark: 0xF7F3EC),
                subtitleText: Color(light: 0x4A3B32, dark: 0xD8CCC0),
                tagText: Color(light: 0x241C15, dark: 0xF7F3EC)
            )

        case "side", "sides":
            return CardPalette(
                gradient: LinearGradient(
                    colors: [Color(light: 0xE8EEE4, dark: 0x202B1D), Color(light: 0xACC5AA, dark: 0x2E422C)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                titleText: Color(light: 0x1B2618, dark: 0xF7F3EC),
                subtitleText: Color(light: 0x374A33, dark: 0xD0DCD0),
                tagText: Color(light: 0x1B2618, dark: 0xF7F3EC)
            )

        case "dessert":
            return CardPalette(
                gradient: LinearGradient(
                    colors: [Color(light: 0xFCEEF3, dark: 0x381C26), Color(light: 0xE6B2BE, dark: 0x482330)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                titleText: Color(light: 0x2B1520, dark: 0xF7F3EC),
                subtitleText: Color(light: 0x4E2F3E, dark: 0xDCBFC9),
                tagText: Color(light: 0x2B1520, dark: 0xF7F3EC)
            )

        default: // Main
            return CardPalette(
                gradient: LinearGradient(
                    colors: [Color(light: 0xFDF1E2, dark: 0x3A2616), Color(light: 0xF3C89B, dark: 0x4A2F1B)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                titleText: Color(light: 0x281B0E, dark: 0xF7F3EC),
                subtitleText: Color(light: 0x4A3622, dark: 0xDBCAB8),
                tagText: Color(light: 0x281B0E, dark: 0xF7F3EC)
            )
        }
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(FGColor.controlAccent)
            Text("Shaping routine...")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(FGColor.inkMuted)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(light: 0xF3EEE7, dark: 0x262320))
        .clipShape(Capsule())
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
                        .background(Color(light: 0xFFFFFF, dark: 0x1C1712))
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
                .background(Color(light: 0xF1ECE5, dark: 0x25221F))
                .clipShape(Capsule())

            Button {
                submitText()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(light: 0x37241D, dark: 0xFCEFEA))
                    .frame(width: 46, height: 46)
                    .background(
                        LinearGradient(
                            colors: [Color(light: 0xFCCAB5, dark: 0x6E4032), Color(light: 0xF5B2A3, dark: 0x5C2E24)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
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

        let userMsg = ConversationMessage(role: .user, text: trimmed)
        withAnimation(FGMotion.settle) { messages.append(userMsg) }
        savePersistedHistory()
        inputText = ""
        isFieldFocused = false
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
        let userContext = ChatUserContext(
            likedActivities: Array(Set(liked)),
            lastFeel: lastFeel,
            recentCompletions: completedEntries.count,
            recoveryOwed: recoveryOwed,
            hiddenSessionIDs: Array(model.profile.hiddenSessionIDs),
            preferredIntensityTier: banditPrefs.preferredIntensityTier,
            topExploredActivities: banditPrefs.topExploredActivities,
            fatigueSensitivity: banditPrefs.fatigueSensitivity
        )
        let wireHistory = messages.suffix(4).map {
            ChatTurnPayload(role: $0.role == .user ? "user" : "model", text: $0.text)
        }

        let currentActiveID = messages.reversed().compactMap(\.recommendation?.sessionID).first ?? model.menu.main?.session.id
        let todaysMenu = model.menu.items.map {
            LocalStatefulChatEngine.structuredRecommendation(for: $0.session, reason: $0.reasonText)
        }

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
                guard let response else {
                    withAnimation(FGMotion.settle) {
                        messages.append(ConversationMessage(
                            role: .assistant,
                            text: "Couldn't reach the companion just now — try again in a moment."
                        ))
                    }
                    return
                }

                if response.overrides.hasAnyOverrides {
                    model.applyConversationalCheckIn(response)
                    updateActiveTimeLabel()
                }

                let assistantMsg = ConversationMessage(
                    role: .assistant,
                    text: response.message,
                    recommendation: response.recommendation
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
                selectedSession = main.session
            }

        case .commitToToday:
            if let lastRec = messages.reversed().compactMap(\.recommendation).first {
                commitRecommendationToToday(recommendation: lastRec, messageID: nil)
            }

        case .customPrompt:
            inputText = chip.payload ?? chip.label
            submitText()
        }
    }

    private func commitRecommendationToToday(recommendation: StructuredRecommendation, messageID: UUID?) {
        if let session = resolveSession(from: recommendation) {
            model.commitSessionToToday(session)
            updateActiveTimeLabel()
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

    private func toggleReason(for messageID: UUID) {
        if let index = messages.firstIndex(where: { $0.id == messageID }) {
            messages[index].isReasonVisible.toggle()
        }
    }

    private func launchSession(recommendation: StructuredRecommendation) {
        let session = resolveSession(from: recommendation)
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

    private func updateActiveTimeLabel() {
        if !model.menu.items.isEmpty {
            activeTimeLabel = "\(todaysMenuMinutes) min"
        } else if let time = model.checkIn?.time {
            activeTimeLabel = time.checkInLabel
        } else {
            activeTimeLabel = "15 min"
        }
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
