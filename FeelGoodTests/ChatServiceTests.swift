//
//  ChatServiceTests.swift
//  FeelGoodTests
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Chat Service")
struct ChatServiceTests {

    @Test("Local stateful engine classifies intents and extracts check-in state")
    func localStatefulEngineExtraction() {
        let text = "I am exhausted and my lower back is sore. Only have 15 min at home."
        let response = LocalStatefulChatEngine.orchestrate(prompt: text)

        #expect(response.intent == .newRoutineRequest)
        #expect(response.overrides.energy == .low)
        #expect(response.overrides.time == .fifteenMinutes)
        #expect(response.overrides.body == .sore)
        #expect(response.overrides.place == .stayingIn)

        let checkIn = response.overrides.toPlanCheckIn()
        #expect(checkIn.energy == .low)
        #expect(checkIn.time == .fifteenMinutes)
        #expect(checkIn.place == .stayingIn)
        #expect(checkIn.body == .sore)

        // Recommendation card is populated
        #expect(response.recommendation != nil)
        #expect(!response.quickReplies.isEmpty)
    }

    @Test("Local stateful engine handles inquiries and adjustments")
    func localStatefulEngineInquiry() {
        let text = "what if I can't sit still"
        let response = LocalStatefulChatEngine.orchestrate(prompt: text)

        #expect(response.intent == .inquiry)
        #expect(response.phase == .inquiryActive)
        #expect(response.recommendation?.sessionID == "app-jump-rope-ninety")
        #expect(response.recommendation?.course == "appetizer")
        #expect(response.message.contains("Then move first"))
    }

    @Test("Local stateful engine handles acknowledgments")
    func localStatefulEngineAcknowledgment() {
        let text = "sounds good"
        let response = LocalStatefulChatEngine.orchestrate(prompt: text)

        #expect(response.intent == .acknowledgment)
        #expect(response.phase == .routineCommitted)
        #expect(response.message.contains("all set"))
    }

    @Test("Local stateful engine asks clarifying questions on vague inputs without returning exercise card")
    func localStatefulEngineVagueInputDiscovery() {
        let text = "it feels okay"
        let response = LocalStatefulChatEngine.orchestrate(prompt: text)

        #expect(response.phase == .needsDiscovery)
        #expect(response.recommendation == nil)
        #expect(response.message.contains("prefer a short breath reset") || response.message.contains("Got it"))
        #expect(!response.quickReplies.isEmpty)
    }

    @Test("ConversationalOverrides converts with fallback defaults")
    func overridesFallbackDefaults() {
        let overrides = ConversationalOverrides(energy: .strong)
        let checkIn = overrides.toPlanCheckIn(
            fallback: PlanCheckIn(energy: .low, time: .aLittle, place: .stayingIn, body: .stiff)
        )

        #expect(checkIn.energy == .strong)
        #expect(checkIn.time == .aLittle)
        #expect(checkIn.place == .stayingIn)
        #expect(checkIn.body == .stiff)
    }

    @Test("ChatService sanitizes before calling transport")
    func chatServiceSanitizesInput() async {
        let transport = FakeChatTransport(
            response: ChatResponse(
                message: "Here's a gentle mat plan.",
                intent: .newRoutineRequest,
                phase: .recommendationActive,
                recommendation: StructuredRecommendation(
                    sessionID: "test-1",
                    title: "Test Routine",
                    subtitle: "Test Subtitle",
                    durationMin: 15,
                    course: "main",
                    reason: "Test Reason",
                    tags: ["Main", "15 min"]
                ),
                quickReplies: [QuickReplyAction(id: "why", label: "Why this?", actionType: .askWhy)],
                overrides: ConversationalOverrides(energy: .low, time: .fifteenMinutes)
            )
        )
        let service = ChatService(transport: transport, isProUnlocked: { true }, hasChatConsent: { true })

        let response = await service.describeDay(prompt: "User at test@example.com with 15 min")

        #expect(response?.message == "Here's a gentle mat plan.")
        #expect(response?.recommendation?.title == "Test Routine")
        #expect(response?.quickReplies.first?.actionType == .askWhy)
        #expect(await transport.lastPromptReceived?.contains("[email]") == true)
        #expect(await transport.lastPromptReceived?.contains("test@example.com") == false)
    }

    @Test("TodayModel commits recommended session directly to Today menu")
    @MainActor
    func commitSessionToTodayMenu() {
        let store = ContentStore(catalog: ContentCatalog(version: 1, sessions: Fixture.catalog, glossary: []))
        let profile = PlanProfile(availableActivities: [.pilates, .stretching, .yoga])
        let model = TodayModel(store: store, profile: profile, now: Date())

        let chosenSession = Session(
            id: "test-chosen-session",
            title: "Chosen Flow",
            subtitle: "Custom from chat",
            activity: .yoga,
            qualities: [.mobility],
            durationMin: 15,
            intensity: 2,
            energyFit: [.low, .steady],
            equipment: [.none],
            places: [.home],
            bodyFocus: [.back],
            intents: [.calm],
            course: .main,
            source: .authored(steps: [])
        )

        model.commitSessionToToday(chosenSession)

        #expect(model.menu.main?.session.id == "test-chosen-session")
        #expect(model.menu.main?.session.title == "Chosen Flow")
        #expect(model.menu.main?.reasonText == "Chosen in conversation with you")
    }

    @Test("Local stateful engine adheres to lean ChatMode enum")
    func localStatefulEngineModes() {
        // Clarifying mode on vague input
        let clarifyingResp = LocalStatefulChatEngine.orchestrate(prompt: "nah")
        #expect(clarifyingResp.mode == .clarifying)
        #expect(clarifyingResp.recommendation == nil)

        // Banter mode on acknowledgment
        let banterResp = LocalStatefulChatEngine.orchestrate(prompt: "sounds good")
        #expect(banterResp.mode == .banter)
        #expect(banterResp.recommendation == nil)

        // Recommendation mode on specific routine query
        let recResp = LocalStatefulChatEngine.orchestrate(prompt: "15 min gentle floor stretch")
        #expect(recResp.mode == .recommendation)
        #expect(recResp.recommendation != nil)
    }

    @Test("ChatTurnPayload encodes and decodes role and text")
    func chatTurnPayloadCoding() throws {
        let turn = ChatTurnPayload(role: "model", text: "Got it, how does 15 min sound?")
        let data = try JSONEncoder().encode(turn)
        let decoded = try JSONDecoder().decode(ChatTurnPayload.self, from: data)

        #expect(decoded.role == "model")
        #expect(decoded.text == "Got it, how does 15 min sound?")

        // Backwards compatibility decoding from content field
        let jsonString = "{\"role\":\"user\",\"content\":\"5 mins\"}"
        let legacyDecoded = try JSONDecoder().decode(ChatTurnPayload.self, from: jsonString.data(using: .utf8)!)
        #expect(legacyDecoded.role == "user")
        #expect(legacyDecoded.text == "5 mins")
    }

    @Test("ChatService forwards multi-turn ChatTurnPayload history to transport")
    func chatServiceForwardsHistory() async {
        let transport = FakeChatTransport(
            response: ChatResponse(
                message: "Got it.",
                mode: .banter,
                intent: .acknowledgment,
                phase: .routineCommitted
            )
        )
        let service = ChatService(transport: transport, isProUnlocked: { true }, hasChatConsent: { true })
        let history = [
            ChatTurnPayload(role: "user", text: "I'm feeling stiff"),
            ChatTurnPayload(role: "model", text: "Would you like a gentle stretch or a breath reset?")
        ]

        _ = await service.describeDay(prompt: "gentle stretch", history: history)

        let received = await transport.lastHistoryReceived
        #expect(received?.count == 2)
        #expect(received?.first?.role == "user")
        #expect(received?.first?.text == "I'm feeling stiff")
        #expect(received?.last?.role == "model")
        #expect(received?.last?.text == "Would you like a gentle stretch or a breath reset?")
    }

    @Test("Local stateful engine recommends Dopamine Menu routines from keywords")
    func localStatefulEngineDopamineRoutines() {
        let shake = LocalStatefulChatEngine.orchestrate(prompt: "I'm overwhelmed and restless, need a shake out")
        #expect(shake.recommendation?.sessionID == "app-shake-out-five")

        let powerPose = LocalStatefulChatEngine.orchestrate(prompt: "Need a quick power pose for confidence")
        #expect(powerPose.recommendation?.sessionID == "app-power-pose-two")

        let walk = LocalStatefulChatEngine.orchestrate(prompt: "I have brain fog, want a brisk walk")
        #expect(walk.recommendation?.sessionID == "main-brisk-walk-ten")

        let dance = LocalStatefulChatEngine.orchestrate(prompt: "I want to dance it out to music")
        #expect(dance.recommendation?.sessionID == "side-dance-it-out-five")

        let pmr = LocalStatefulChatEngine.orchestrate(prompt: "Too tense to sleep, need progressive muscle relaxation")
        #expect(pmr.recommendation?.sessionID == "dessert-pmr-ten")

        let cold = LocalStatefulChatEngine.orchestrate(prompt: "Panicked, need a cold water splash reset")
        #expect(cold.recommendation?.sessionID == "app-cold-water-splash")

        let gratitude = LocalStatefulChatEngine.orchestrate(prompt: "Feeling down on myself, want a gratitude body scan")
        #expect(gratitude.recommendation?.sessionID == "dessert-gratitude-scan-five")

        let jacks = LocalStatefulChatEngine.orchestrate(prompt: "Procrastinating, need a 2 min jumping jacks burst")
        #expect(jacks.recommendation?.sessionID == "app-jumping-jacks-two")
    }

    @Test("Local stateful engine dynamically matches catalog across durations")
    func localStatefulEngineCatalogMatching() {
        let response45 = LocalStatefulChatEngine.orchestrate(prompt: "I have 45 min and feeling strong")
        #expect(response45.recommendation != nil)
        #expect(response45.recommendation?.durationMin ?? 0 >= 30)

        let response5 = LocalStatefulChatEngine.orchestrate(prompt: "Just 5 min for a quick reset")
        #expect(response5.recommendation != nil)
        #expect(response5.recommendation?.durationMin ?? 0 <= 5)
    }

    @Test("Local stateful engine handles back inquiry and hip negation")
    func localStatefulEngineBackAndHipNegation() {
        let inquiry = LocalStatefulChatEngine.orchestrate(prompt: "will this help with my back problem")
        #expect(inquiry.intent == .inquiry)
        #expect(inquiry.message.contains("Yes") || inquiry.message.contains("spine"))

        let negation = LocalStatefulChatEngine.orchestrate(prompt: "i don't need hips", activeSessionID: "app-hip-openers")
        #expect(negation.intent == .refinement)
        #expect(negation.recommendation?.sessionID != "app-hip-openers")
        #expect(negation.message.contains("skipping hips") || negation.message.contains("no hips"))
    }

    @Test("Card tags show body-focus labels, never the raw enum name")
    func displayTagsUseBodyFocusLabels() {
        let recommendation = StructuredRecommendation(
            sessionID: "app-neck-and-shoulder-release",
            title: "Neck and shoulder release",
            subtitle: "",
            durationMin: 3,
            reason: "A gentle three minutes you can do sitting down.",
            tags: ["Appetizer", "3 min", "Gentle", "neckShoulders"]
        )

        #expect(recommendation.displayTags == ["Appetizer", "3 min", "Gentle", "Neck & Shoulders"])
    }

    @Test("Local engine replies describe the session, never what it does to the body (no medical claims)")
    func localEngineRepliesMakeNoBodilyOutcomeClaims() {
        let prompts = [
            "will this help with my back problem", "why this", "shake it out", "i'm restless",
            "cold water splash", "progressive muscle relaxation", "brisk walk", "box breathing",
            "something for the evening to unwind", "my wrists hurt from typing", "desk shoulder neck",
        ]
        let banned = [
            "tension", "nervous system", "racing heart", "calming", "relaxation",
            "blood flow", "brain fog", "dissipate", "ease down",
        ]

        for prompt in prompts {
            let message = LocalStatefulChatEngine.orchestrate(prompt: prompt).message.lowercased()
            for phrase in banned {
                #expect(!message.contains(phrase), "\"\(prompt)\" reply says \"\(phrase)\": \(message)")
            }
        }
    }

    @Test("Local stateful engine answers questions about a specific menu item from its own data")
    func localStatefulEngineAnswersFromTodaysMenu() {
        let todaysMenu = [
            StructuredRecommendation(
                sessionID: "dessert-gratitude-scan-five",
                title: "Gratitude Body Scan",
                subtitle: "Five minutes of appreciation",
                durationMin: 5,
                course: "dessert",
                reason: "Purely because you want to, in 5 minutes.",
                tags: ["Dessert", "5 min"]
            ),
            StructuredRecommendation(
                sessionID: "main-brisk-walk-ten",
                title: "Brisk Walk",
                subtitle: "Clear the fog",
                durationMin: 10,
                course: "main",
                reason: "Today's main thing.",
                tags: ["Main", "10 min"]
            )
        ]

        let byCourse = LocalStatefulChatEngine.orchestrate(prompt: "what's my dessert today?", todaysMenu: todaysMenu)
        #expect(byCourse.recommendation?.sessionID == "dessert-gratitude-scan-five")
        #expect(byCourse.message == "Purely because you want to, in 5 minutes.")

        let byTitle = LocalStatefulChatEngine.orchestrate(prompt: "tell me about the brisk walk", todaysMenu: todaysMenu)
        #expect(byTitle.recommendation?.sessionID == "main-brisk-walk-ten")

        // With no matching menu item, falls through to the normal catalog search.
        let noMatch = LocalStatefulChatEngine.orchestrate(prompt: "15 min gentle floor stretch", todaysMenu: todaysMenu)
        #expect(noMatch.recommendation?.sessionID != "dessert-gratitude-scan-five")
        #expect(noMatch.recommendation?.sessionID != "main-brisk-walk-ten")
    }

    @Test("Local stateful engine strictly excludes hidden sessions")
    func localStatefulEngineExcludesHiddenSessions() {
        // Find what matches normally for a 5 min low intensity session
        let normalMatch = LocalStatefulChatEngine.matchBestSession(targetDuration: 5, intensity: "gentle")
        #expect(normalMatch != nil)

        if let normalMatch {
            let context = ChatUserContext(hiddenSessionIDs: [normalMatch.id])
            let hiddenMatch = LocalStatefulChatEngine.matchBestSession(
                targetDuration: 5,
                intensity: "gentle",
                userContext: context
            )
            #expect(hiddenMatch?.id != normalMatch.id)
        }
    }

    @Test("An elongated 'nah' is still a 'nah' and gets no card")
    func elongatedRejectionIsVague() {
        for text in ["nahhh", "Noooo", "nope"] {
            let response = LocalStatefulChatEngine.orchestrate(prompt: text)
            #expect(response.mode == .clarifying, "\(text)")
            #expect(response.recommendation == nil, "\(text)")
        }
    }

    @Test("Repeated letters collapse only in runs of three or more")
    func collapsingRepeatsRuns() {
        #expect(LocalStatefulChatEngine.collapsingRepeats("nahhh") == "nah")
        #expect(LocalStatefulChatEngine.collapsingRepeats("good") == "good")
        #expect(LocalStatefulChatEngine.collapsingRepeats("") == "")
        #expect(LocalStatefulChatEngine.collapsingRepeats("yesss please") == "yes please")
    }

    @Test("A refinement never comes back with a session already shown in the chat")
    func refinementSkipsShownSessions() throws {
        let first = try #require(
            LocalStatefulChatEngine.orchestrate(prompt: "15 min gentle floor stretch").recommendation
        )
        var shown = [first.sessionID]

        // Keep turning things down; every answer must be new, run enough times
        // that the random pick within the top tier would have repeated by now.
        for _ in 0..<25 {
            let context = ChatUserContext(shownSessionIDs: shown)
            let next = try #require(
                LocalStatefulChatEngine.orchestrate(
                    prompt: "Gentler option",
                    activeSessionID: shown.last,
                    userContext: context
                ).recommendation
            )
            #expect(!shown.contains(next.sessionID))
            shown.append(next.sessionID)
        }
    }

    @Test("Shown session ids reach the worker as shown_session_ids")
    func shownSessionIDsEncodeKey() throws {
        let context = ChatUserContext(hiddenSessionIDs: ["a"], shownSessionIDs: ["b", "c"])
        let data = try JSONEncoder().encode(context)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["shown_session_ids"] as? [String] == ["b", "c"])
        #expect(json["hidden_session_ids"] as? [String] == ["a"])
    }
}

extension ChatServiceTests {
    @Test("Without consent a Pro message never reaches the transport")
    func noConsentStaysOnDevice() async {
        let transport = FakeChatTransport(
            response: ChatResponse(message: "x", mode: .banter, intent: .acknowledgment, phase: .greeting)
        )
        let service = ChatService(transport: transport, isProUnlocked: { true }, hasChatConsent: { false })

        let response = await service.describeDay(prompt: "gentle stretch please")

        #expect(response != nil)
        #expect(await transport.lastPromptReceived == nil)
    }

    @Test("History turns are redacted before they leave the device")
    func historyIsRedacted() async {
        let transport = FakeChatTransport(
            response: ChatResponse(message: "x", mode: .banter, intent: .acknowledgment, phase: .greeting)
        )
        let service = ChatService(transport: transport, isProUnlocked: { true }, hasChatConsent: { true })
        let history = [ChatTurnPayload(role: "user", text: "I'm pregnant, email me at a@b.com")]

        _ = await service.describeDay(prompt: "something gentle", history: history)

        let sent = await transport.lastHistoryReceived?.first?.text ?? ""
        #expect(!sent.lowercased().contains("pregnant"))
        #expect(!sent.contains("a@b.com"))
    }

    @Test("A failing edge call falls back to the on-device engine instead of returning nothing")
    func failingTransportFallsBackLocally() async {
        let service = ChatService(transport: ThrowingChatTransport(), isProUnlocked: { true }, hasChatConsent: { true })

        let response = await service.describeDay(prompt: "gentle stretch please")

        #expect(response != nil)
    }
}

private struct ThrowingChatTransport: ChatTransport {
    func sendChat(
        prompt: String,
        subscriberID: String,
        history: [WireChatMessage],
        activeSessionID: String?,
        userContext: ChatUserContext?,
        todaysMenu: [StructuredRecommendation],
        timeout: TimeInterval
    ) async throws -> ChatResponse {
        throw URLError(.timedOut)
    }
}

private actor FakeChatTransport: ChatTransport {
    let response: ChatResponse
    private(set) var lastPromptReceived: String?
    private(set) var lastHistoryReceived: [WireChatMessage]?

    init(response: ChatResponse) {
        self.response = response
    }

    func sendChat(
        prompt: String,
        subscriberID: String,
        history: [WireChatMessage],
        activeSessionID: String?,
        userContext: ChatUserContext?,
        todaysMenu: [StructuredRecommendation],
        timeout: TimeInterval
    ) async throws -> ChatResponse {
        lastPromptReceived = prompt
        lastHistoryReceived = history
        return response
    }
}
