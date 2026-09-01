//
//  ChatServiceTests.swift
//  FeelGoodTests
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Chat Service")
struct ChatServiceTests {

    @Test("Local heuristic parser extracts time, energy, and body state")
    func localHeuristicParserExtraction() {
        let text = "I am exhausted and my lower back is sore. Only have 15 min at home."
        let response = LocalHeuristicParser.parse(text)

        #expect(response.overrides.energy == .low)
        #expect(response.overrides.time == .fifteenMinutes)
        #expect(response.overrides.body == .sore)
        #expect(response.overrides.place == .stayingIn)

        let checkIn = response.overrides.toPlanCheckIn()
        #expect(checkIn.energy == .low)
        #expect(checkIn.time == .fifteenMinutes)
        #expect(checkIn.place == .stayingIn)
        #expect(checkIn.body == .sore)
    }

    @Test("Local heuristic parser handles energized gym prompts")
    func localHeuristicParserGym() {
        let text = "Feeling energized and strong, 30 min at the gym"
        let response = LocalHeuristicParser.parse(text)

        #expect(response.overrides.energy == .strong)
        #expect(response.overrides.time == .some)
        #expect(response.overrides.place == .atTheGym)
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
                overrides: ConversationalOverrides(energy: .low, time: .fifteenMinutes)
            )
        )
        let service = ChatService(transport: transport, isProUnlocked: { true })

        let response = await service.describeDay(prompt: "User at test@example.com with 15 min")

        #expect(response?.message == "Here's a gentle mat plan.")
        #expect(await transport.lastPromptReceived?.contains("[email]") == true)
        #expect(await transport.lastPromptReceived?.contains("test@example.com") == false)
    }
}

private actor FakeChatTransport: ChatTransport {
    let response: ChatResponse
    private(set) var lastPromptReceived: String?

    init(response: ChatResponse) {
        self.response = response
    }

    func sendChat(prompt: String, subscriberID: String, timeout: TimeInterval) async throws -> ChatResponse {
        lastPromptReceived = prompt
        return response
    }
}
