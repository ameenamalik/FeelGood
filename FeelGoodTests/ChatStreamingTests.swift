//
//  ChatStreamingTests.swift
//  FeelGoodTests
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Chat streaming")
struct ChatStreamingTests {
    @Test("A frame completes at its data line, whatever else arrives")
    func parserEmitsDeltasThenDone() {
        var parser = ChatEventParser()

        #expect(parser.feed(line: "event: delta") == nil)
        #expect(parser.feed(line: #"data: {"text":"Got it."}"#) == .delta("Got it."))
        #expect(parser.feed(line: "event: delta") == nil)
        #expect(parser.feed(line: #"data: {"text":" Rest."}"#) == .delta(" Rest."))
        #expect(parser.feed(line: "event: done") == nil)
        #expect(parser.feed(line: #"data: {"message":"Got it. Rest."}"#) == .done(Data(#"{"message":"Got it. Rest."}"#.utf8)))
    }

    @Test("An error frame is reported, and unknown frames are ignored")
    func parserErrorsAndUnknowns() {
        var parser = ChatEventParser()

        #expect(parser.feed(line: "event: error") == nil)
        #expect(parser.feed(line: #"data: {"reason":"stream_failed"}"#) == .error)
        #expect(parser.feed(line: "event: ping") == nil)
        #expect(parser.feed(line: "data: {}") == nil)
        #expect(parser.feed(line: ": comment") == nil)
    }

    @Test("The final response replaces the partial text the person watched")
    func serviceDeliversPartialsThenFinal() async {
        let transport = StreamingFakeTransport(partials: ["Got", "Got it."], final: "Got it. Rest.")
        let service = ChatService(transport: transport, isProUnlocked: { true }, hasChatConsent: { true })
        let seen = PartialLog()

        let response = await service.describeDayStreaming(
            prompt: "tired",
            history: [],
            activeSessionID: nil,
            userContext: nil,
            todaysMenu: [],
            onPartial: { seen.append($0) }
        )

        #expect(seen.values == ["Got", "Got it."])
        #expect(response?.message == "Got it. Rest.")
        #expect(response?.isFromAI == true)
    }

    @Test("A transport that can't stream still answers")
    func fallsBackToOnePiece() async {
        let transport = PlainTransport()
        let service = ChatService(transport: transport, isProUnlocked: { true }, hasChatConsent: { true })
        let seen = PartialLog()

        let response = await service.describeDayStreaming(
            prompt: "tired",
            history: [],
            activeSessionID: nil,
            userContext: nil,
            todaysMenu: [],
            onPartial: { seen.append($0) }
        )

        #expect(seen.values.isEmpty)
        #expect(response?.message == "One piece.")
    }
}

private final class PartialLog: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [String] = []

    func append(_ text: String) {
        lock.lock()
        stored.append(text)
        lock.unlock()
    }

    var values: [String] {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }
}

private struct StreamingFakeTransport: ChatTransport {
    let partials: [String]
    let final: String

    private var response: ChatResponse {
        ChatResponse(message: final, mode: .banter, intent: .generalCheckIn, phase: .greeting, isFromAI: true)
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
        response
    }

    func streamChat(
        prompt: String,
        subscriberID: String,
        history: [WireChatMessage],
        activeSessionID: String?,
        userContext: ChatUserContext?,
        todaysMenu: [StructuredRecommendation],
        timeout: TimeInterval,
        onPartial: @escaping @Sendable (String) -> Void
    ) async throws -> ChatResponse {
        partials.forEach(onPartial)
        return response
    }
}

/// Implements only `sendChat`, as every transport did before streaming.
private struct PlainTransport: ChatTransport {
    func sendChat(
        prompt: String,
        subscriberID: String,
        history: [WireChatMessage],
        activeSessionID: String?,
        userContext: ChatUserContext?,
        todaysMenu: [StructuredRecommendation],
        timeout: TimeInterval
    ) async throws -> ChatResponse {
        ChatResponse(message: "One piece.", mode: .banter, intent: .generalCheckIn, phase: .greeting, isFromAI: true)
    }
}
