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
        let service = ChatService(transport: transport, isProUnlocked: { true })

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
        let service = ChatService(transport: transport, isProUnlocked: { true })
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
        timeout: TimeInterval
    ) async throws -> ChatResponse {
        lastPromptReceived = prompt
        lastHistoryReceived = history
        return response
    }
}
