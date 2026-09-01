//
//  ExploreView.swift
//  FeelGood
//
//  The third tab. A deeper, ongoing version of "Describe Day" (PRD §7.5.8) —
//  the same redact-on-device → Worker → structured-extraction pipeline as
//  the check-in sheet's conversational mode, but living in a persistent
//  thread instead of a one-shot drawer.
//
//  Every reply either reads today's menu (the course-lookup chips) or moves
//  it forward through `TodayModel.applyConversationalCheckIn` /
//  `applyQuickFilter` — the same two entry points the check-in sheet and the
//  quick-pivot chips already use. The LLM never picks a session here either;
//  it narrates whatever the engine already chose, exactly as PRD §7.3
//  requires everywhere else.
//

import SwiftUI

private struct ExploreMessage: Identifiable {
    enum Role { case user, assistant }

    let id = UUID()
    let role: Role
    let text: String
    var item: MenuItem?
}

struct ExploreView: View {
    let model: TodayModel

    @State private var messages: [ExploreMessage] = []
    @State private var inputText = ""
    @State private var isProcessing = false
    @State private var service: any ChatProviding = ChatService()
    @State private var revealedReasons: Set<UUID> = []
    @State private var confirmedMessages: Set<UUID> = []
    @State private var selectedItem: MenuItem?
    @FocusState private var isFieldFocused: Bool

    private let freeTextPrompts = [
        "wired, fifteen minutes, staying in",
        "low energy, need a gentle reset",
        "I want to feel strong today",
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                FGColor.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: FGSpace.m) {
                                if messages.isEmpty {
                                    emptyState
                                } else {
                                    ForEach(messages) { message in
                                        bubble(for: message).id(message.id)
                                    }
                                }
                                if isProcessing {
                                    processingRow.id("processing")
                                }
                            }
                            .padding(FGSpace.page)
                        }
                        .scrollBounceBehavior(.basedOnSize)
                        .onChange(of: messages.count) { _, _ in
                            scrollToLatest(proxy)
                        }
                        .onChange(of: isProcessing) { _, _ in
                            scrollToLatest(proxy)
                        }
                    }

                    inputBar
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(FGColor.bg, for: .navigationBar)
        }
        .sheet(item: $selectedItem) { item in
            SessionDetailView(item: item, model: model)
        }
    }

    private func scrollToLatest(_ proxy: ScrollViewProxy) {
        withAnimation(FGMotion.gentle) {
            if isProcessing {
                proxy.scrollTo("processing", anchor: .bottom)
            } else if let last = messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: FGSpace.l) {
            HStack {
                Text("Whatever's on your mind about today's menu — I'm here. Try one below, or just start typing.")
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.ink)
                    .padding(FGSpace.m)
                    .background(FGColor.surface, in: RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
                Spacer(minLength: 40)
            }

            if !model.menu.items.isEmpty {
                promptGroup(title: "Ask about a course") {
                    ForEach(model.menu.items) { item in
                        promptChip("What's the \(item.course.label) for today?") { askAboutCourse(item) }
                    }
                }
            }

            promptGroup(title: "Quick pivot") {
                ForEach(QuickFilter.allCases, id: \.self) { filter in
                    promptChip(filter.label, symbol: filter.symbol) { pivot(filter) }
                }
            }

            promptGroup(title: "Or describe your day") {
                ForEach(freeTextPrompts, id: \.self) { prompt in
                    promptChip(prompt) {
                        inputText = prompt
                        submitFreeText()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func promptGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            Text(title)
                .font(FGFont.label)
                .foregroundStyle(FGColor.inkMuted)
            content()
        }
    }

    private func promptChip(_ text: String, symbol: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: FGSpace.xs) {
                if let symbol {
                    Image(systemName: symbol).font(.system(size: 12, weight: .semibold))
                }
                Text(text)
            }
            .font(FGFont.body.weight(.medium))
            .foregroundStyle(FGColor.ink)
            .padding(.horizontal, FGSpace.m)
            .padding(.vertical, FGSpace.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FGColor.surface, in: RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                    .stroke(FGColor.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Thread

    @ViewBuilder
    private func bubble(for message: ExploreMessage) -> some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 40)
                Text(message.text)
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.bg)
                    .padding(.horizontal, FGSpace.m)
                    .padding(.vertical, FGSpace.s)
                    .background(FGColor.ink, in: RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
            }
        case .assistant:
            VStack(alignment: .leading, spacing: FGSpace.s) {
                HStack {
                    Text(message.text)
                        .font(FGFont.body)
                        .foregroundStyle(FGColor.ink)
                        .padding(.horizontal, FGSpace.m)
                        .padding(.vertical, FGSpace.s)
                        .background(FGColor.surface, in: RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
                    Spacer(minLength: 40)
                }
                if let item = message.item {
                    inlineCard(item)
                        .onTapGesture { selectedItem = item }
                    actionPills(for: message, item: item)
                    if revealedReasons.contains(message.id) {
                        Text(item.reasonText)
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                            .padding(.horizontal, FGSpace.xs)
                    }
                }
            }
        }
    }

    private func inlineCard(_ item: MenuItem) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            HStack(spacing: FGSpace.xs) {
                ForEach(item.session.chips, id: \.self) { chip in
                    Text(chip)
                        .font(FGFont.label)
                        .foregroundStyle(item.course.accentText)
                        .padding(.horizontal, FGSpace.s)
                        .padding(.vertical, 4)
                        .background(item.course.accentText.opacity(0.14), in: Capsule())
                }
            }

            Text(item.session.title)
                .font(FGFont.itemTitle)
                .foregroundStyle(item.course.accentText)

            Text(item.session.subtitle)
                .font(FGFont.reason)
                .foregroundStyle(item.course.accentText.opacity(0.78))
        }
        .padding(FGSpace.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(item.course.accentGradient, in: RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
        .contentShape(Rectangle())
    }

    /// The card is always tappable to open; these three sit underneath as
    /// distinct actions rather than crowding the card itself.
    private func actionPills(for message: ExploreMessage, item: MenuItem) -> some View {
        HStack(spacing: FGSpace.s) {
            pill("Something else") { somethingElse(for: message.id) }
            pill(revealedReasons.contains(message.id) ? "Hide why" : "Why this?") { toggleReason(message.id) }
            pill(confirmedMessages.contains(message.id) ? "Added" : "Add to today", isConfirmed: confirmedMessages.contains(message.id)) {
                confirmedMessages.insert(message.id)
            }
        }
    }

    private func pill(_ text: String, isConfirmed: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(FGFont.body.weight(.medium))
                .foregroundStyle(isConfirmed ? FGColor.sageDeep : FGColor.ink)
                .padding(.horizontal, FGSpace.m)
                .padding(.vertical, FGSpace.s - 2)
                .background(FGColor.surface, in: Capsule())
                .overlay(Capsule().stroke(isConfirmed ? FGColor.sageDeep : FGColor.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(isConfirmed)
    }

    private var processingRow: some View {
        HStack(spacing: FGSpace.s) {
            ProgressView()
                .tint(FGColor.goldDeep)
                .scaleEffect(0.8)
            Text("Shaping today's options...")
                .font(FGFont.caption)
                .foregroundStyle(FGColor.inkMuted)
        }
    }

    // MARK: Input

    private var inputBar: some View {
        HStack(spacing: FGSpace.s) {
            TextField("Tell it what you're looking for...", text: $inputText, axis: .vertical)
                .font(FGFont.body)
                .foregroundStyle(FGColor.ink)
                .lineLimit(1...4)
                .focused($isFieldFocused)
                .submitLabel(.send)
                .onSubmit(submitFreeText)
                .padding(.horizontal, FGSpace.m)
                .padding(.vertical, FGSpace.s + 4)
                .background(FGColor.surface, in: Capsule())
                .overlay(Capsule().stroke(isFieldFocused ? FGColor.goldDeep : FGColor.line, lineWidth: 1))

            Button(action: submitFreeText) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(FGColor.inkOnAccent)
                    .frame(width: FGSize.minTouchTarget, height: FGSize.minTouchTarget)
                    .background(FGColor.clay, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
            .opacity(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing ? 0.5 : 1)
        }
        .padding(.horizontal, FGSpace.page)
        .padding(.vertical, FGSpace.s)
    }

    // MARK: Actions

    /// Same swap the menu's own shuffle icon uses — a real alternative for
    /// that course, committed immediately, exactly like everywhere else in
    /// the app (PRD §7.2a: swapping is a success signal, not a rejection).
    private func somethingElse(for messageID: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == messageID }),
              let item = messages[index].item else { return }
        model.swap(item)
        if let updated = model.menu.items.first(where: { $0.course == item.course }) {
            messages[index].item = updated
        }
        revealedReasons.remove(messageID)
        confirmedMessages.remove(messageID)
    }

    private func toggleReason(_ messageID: UUID) {
        if revealedReasons.contains(messageID) {
            revealedReasons.remove(messageID)
        } else {
            revealedReasons.insert(messageID)
        }
    }

    /// Reads today's menu directly — no network, no re-plan. PRD's "say why"
    /// principle (§4) is already carried on every `MenuItem`; this just
    /// surfaces it in the thread instead of on the card.
    private func askAboutCourse(_ item: MenuItem) {
        messages.append(ExploreMessage(role: .user, text: "What's the \(item.course.label) for today?"))
        messages.append(ExploreMessage(role: .assistant, text: item.reasonText, item: item))
    }

    /// Same entry point the quick-pivot chips under the menu already use —
    /// one constraint applied to a re-plan, not a new check-in.
    private func pivot(_ filter: QuickFilter) {
        messages.append(ExploreMessage(role: .user, text: filter.label))
        model.applyQuickFilter(filter)
        let highlight = model.menu.main ?? model.menu.items.first
        messages.append(ExploreMessage(
            role: .assistant,
            text: model.upgradedHeadline ?? model.menu.headline,
            item: highlight
        ))
    }

    private func submitFreeText() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isProcessing else { return }

        messages.append(ExploreMessage(role: .user, text: trimmed))
        inputText = ""
        isFieldFocused = false
        isProcessing = true

        Task {
            let response = await service.describeDay(prompt: trimmed)
            await MainActor.run {
                isProcessing = false
                guard let response else {
                    messages.append(ExploreMessage(
                        role: .assistant,
                        text: "Couldn't reach the menu just now — try again in a moment."
                    ))
                    return
                }

                let hasOverrides = response.overrides.hasAnyOverrides
                if hasOverrides {
                    model.applyConversationalCheckIn(response)
                }
                let highlight = hasOverrides ? (model.menu.main ?? model.menu.items.first) : nil
                messages.append(ExploreMessage(role: .assistant, text: response.message, item: highlight))
            }
        }
    }
}
