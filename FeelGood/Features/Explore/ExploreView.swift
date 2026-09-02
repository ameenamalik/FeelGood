//
//  ExploreView.swift
//  FeelGood
//
//  The Chat / Explore tab. A stateful, schema-driven conversational companion
//  that handles multi-turn context, intent classification, dynamic routine
//  recommendation cards, and interactive quick-reply action chips.
//

import SwiftUI

private struct ConversationMessage: Identifiable, Codable, Sendable {
    enum Role: String, Codable, Sendable {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    let text: String
    let timestamp: Date
    var recommendation: StructuredRecommendation?
    var isReasonVisible: Bool = false
    var isCommittedToToday: Bool = false

    init(
        id: UUID = UUID(),
        role: Role,
        text: String,
        timestamp: Date = Date(),
        recommendation: StructuredRecommendation? = nil,
        isReasonVisible: Bool = false,
        isCommittedToToday: Bool = false
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
        self.recommendation = recommendation
        self.isReasonVisible = isReasonVisible
        self.isCommittedToToday = isCommittedToToday
    }
}

struct ExploreView: View {
    let model: TodayModel

    @State private var messages: [ConversationMessage] = []
    @State private var quickReplies: [QuickReplyAction] = []
    @State private var inputText: String = ""
    @State private var isProcessing: Bool = false
    @State private var service: any ChatProviding = ChatService()
    @State private var selectedSession: Session?
    @State private var activeTimeLabel: String = "15 min"
    @FocusState private var isFieldFocused: Bool

    private let persistenceKey = "FeelGood.ChatHistory.v2"

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
                                    }
                                }

                                if isProcessing {
                                    typingIndicator
                                        .id("typingIndicator")
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
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
        .onAppear {
            loadPersistedHistory()
            updateActiveTimeLabel()
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
            // Menu / Clear button
            SwiftUI.Menu {
                Button(role: .destructive) {
                    clearChatThread()
                } label: {
                    Label("Clear Chat Thread", systemImage: "trash")
                }

                Button {
                    loadStarterExample()
                } label: {
                    Label("Reset to Starter", systemImage: "arrow.counterclockwise")
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(FGColor.ink)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }

            Spacer()

            // Title
            Text("Today's menu")
                .font(.custom("SFProRounded-Semibold", size: 18))
                .foregroundStyle(FGColor.ink)

            Spacer()

            // Right Time Pill Badge
            Text(activeTimeLabel)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(FGColor.inkMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(light: 0xEDE9DF, dark: 0x2A2724))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(FGColor.bg)
        .overlay(
            Divider()
                .opacity(0.4),
            alignment: .bottom
        )
    }

    // MARK: - Initial Curated Conversation State

    private var initialCuratedThread: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Dynamic Welcome from Assistant
            if let main = model.menu.main {
                assistantTextBubble(text: "Here is your plan for today (\(activeTimeLabel)). How is your body feeling?")

                recommendationCard(
                    recommendation: StructuredRecommendation(
                        sessionID: main.session.id,
                        title: main.session.title,
                        subtitle: main.session.subtitle,
                        durationMin: main.session.durationMin,
                        intensity: main.session.intensity <= 2 ? "gentle" : "moderate",
                        course: main.session.course.rawValue,
                        reason: "Curated for your daily routine.",
                        tags: [main.session.course.rawValue.capitalized, "\(main.session.durationMin) min", main.session.activity.rawValue.capitalized]
                    ),
                    messageID: nil
                )
            } else {
                assistantTextBubble(text: "How is your body feeling today? Tell me what you need, or tap an option below.")
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
                .background(Color(light: 0xF2EFE9, dark: 0x242220))
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
                .background(Color(light: 0x221E1C, dark: 0x36302C))
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
            HStack(spacing: 6) {
                ForEach(recommendation.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(palette.tagText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.65))
                        .clipShape(Capsule())
                }
                Spacer()
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
                    .background(Color.white.opacity(0.5))
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
                .background(Color(light: 0x231F1C, dark: 0x1A1715))
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
                    .background(Color.white.opacity(0.55))
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
                            .background(Color.white.opacity(0.55))
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
                    colors: [Color(red: 0.99, green: 0.89, blue: 0.84), Color(red: 0.98, green: 0.77, blue: 0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                titleText: Color(red: 0.22, green: 0.12, blue: 0.08),
                subtitleText: Color(red: 0.38, green: 0.24, blue: 0.20),
                tagText: Color(red: 0.22, green: 0.12, blue: 0.08)
            )

        case "side", "sides":
            return CardPalette(
                gradient: LinearGradient(
                    colors: [Color(red: 0.90, green: 0.94, blue: 0.88), Color(red: 0.78, green: 0.86, blue: 0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                titleText: Color(red: 0.12, green: 0.22, blue: 0.12),
                subtitleText: Color(red: 0.24, green: 0.36, blue: 0.24),
                tagText: Color(red: 0.12, green: 0.22, blue: 0.12)
            )

        case "dessert":
            return CardPalette(
                gradient: LinearGradient(
                    colors: [Color(red: 0.94, green: 0.88, blue: 0.94), Color(red: 0.86, green: 0.76, blue: 0.88)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                titleText: Color(red: 0.24, green: 0.12, blue: 0.24),
                subtitleText: Color(red: 0.38, green: 0.22, blue: 0.38),
                tagText: Color(red: 0.24, green: 0.12, blue: 0.24)
            )

        default: // Main
            return CardPalette(
                gradient: LinearGradient(
                    colors: [Color(red: 0.98, green: 0.93, blue: 0.86), Color(red: 0.94, green: 0.85, blue: 0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                titleText: Color(red: 0.24, green: 0.18, blue: 0.10),
                subtitleText: Color(red: 0.40, green: 0.30, blue: 0.18),
                tagText: Color(red: 0.24, green: 0.18, blue: 0.10)
            )
        }
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(FGColor.clay)
            Text("Shaping routine...")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(FGColor.inkMuted)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(light: 0xF2EFE9, dark: 0x242220))
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
                        .background(FGColor.surface)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(FGColor.line, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
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
                .submitLabel(.send)
                .onSubmit(submitText)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color(light: 0xEEEBE4, dark: 0x262320))
                .clipShape(Capsule())

            Button(action: submitText) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(red: 0.22, green: 0.12, blue: 0.08))
                    .frame(width: 46, height: 46)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.99, green: 0.85, blue: 0.78), Color(red: 0.96, green: 0.72, blue: 0.68)],
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

    private func submitText() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isProcessing else { return }

        let userMsg = ConversationMessage(role: .user, text: trimmed)
        messages.append(userMsg)
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
        let userContext = ChatUserContext(
            likedActivities: Array(Set(liked)),
            lastFeel: lastFeel,
            recentCompletions: completedEntries.count,
            recoveryOwed: recoveryOwed
        )
        let wireHistory = messages.map { WireChatMessage(role: $0.role == .user ? "user" : "assistant", content: $0.text) }

        Task {
            let response = await service.describeDay(
                prompt: trimmed,
                history: wireHistory,
                activeSessionID: model.menu.main?.session.id,
                userContext: userContext
            )

            await MainActor.run {
                isProcessing = false
                guard let response else {
                    messages.append(ConversationMessage(
                        role: .assistant,
                        text: "Couldn't reach the companion just now — try again in a moment."
                    ))
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
                messages.append(assistantMsg)
                quickReplies = response.quickReplies
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

    private func updateActiveTimeLabel() {
        if let time = model.checkIn?.time {
            activeTimeLabel = time.checkInLabel
        } else if let main = model.menu.main {
            activeTimeLabel = main.session.durationLabel
        } else {
            activeTimeLabel = "15 min"
        }
    }

    // MARK: - Persistence

    private func loadPersistedHistory() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let decoded = try? JSONDecoder().decode([ConversationMessage].self, from: data) else {
            return
        }
        messages = decoded
    }

    private func savePersistedHistory() {
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func clearChatThread() {
        withAnimation(FGMotion.gentle) {
            messages.removeAll()
            quickReplies.removeAll()
            UserDefaults.standard.removeObject(forKey: persistenceKey)
        }
    }

    private func loadStarterExample() {
        withAnimation(FGMotion.gentle) {
            clearChatThread()
        }
    }
}
