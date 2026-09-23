//
//  ChatSafetyTests.swift
//  FeelGoodTests
//
//  The chat server cannot filter for work-arounds (they never leave the
//  device), so this is the only thing standing between someone who is pregnant
//  and a jump-rope card. Every case here uses the real bundled catalog.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Chat safety")
struct ChatSafetyTests {

    private let catalog: [Session] = (try? ContentStore.bundled().sessions) ?? []

    private func session(_ id: String) throws -> Session {
        try #require(catalog.first { $0.id == id })
    }

    private func lookup(_ id: String) -> Session? { catalog.first { $0.id == id } }

    private func reply(showing session: Session) -> ChatResponse {
        ChatResponse(
            message: "Try \(session.title).",
            mode: .recommendation,
            recommendation: LocalStatefulChatEngine.structuredRecommendation(for: session),
            quickReplies: ChatSafety.recommendationChips
        )
    }

    private func apply(_ response: ChatResponse, workArounds: Set<WorkAround>) -> ChatResponse {
        ChatSafety.apply(
            to: response,
            workArounds: workArounds,
            lookup: lookup,
            replacement: { rejected in
                LocalStatefulChatEngine.matchBestSession(
                    targetDuration: rejected.durationMin,
                    intensity: rejected.intensity,
                    excludeID: rejected.sessionID,
                    workArounds: workArounds
                )
            }
        )
    }

    @Test("Someone who is pregnant is never shown jump rope from chat")
    func pregnancyDropsJumpRope() throws {
        let jumpRope = try session("app-jump-rope-ninety")
        let result = apply(reply(showing: jumpRope), workArounds: [.pregnancy])

        let shown = try #require(result.recommendation)
        #expect(shown.sessionID != jumpRope.id)
        #expect(!ChatSafety.conflicts(try session(shown.sessionID), workArounds: [.pregnancy]))
        #expect(!result.message.contains(jumpRope.title), "the reply about the unsafe session must not be shown")
    }

    @Test("Someone with knee trouble is never shown squats from chat")
    func kneesDropsSquats() throws {
        let squats = try session("app-desk-chair-squats")
        let result = apply(reply(showing: squats), workArounds: [.knees])

        let shown = try #require(result.recommendation)
        #expect(!ChatSafety.conflicts(try session(shown.sessionID), workArounds: [.knees]))
    }

    @Test("A safe card, or no work-arounds, passes through untouched")
    func safeCardUnchanged() throws {
        let breathing = try session("app-box-breathing")
        let safe = reply(showing: breathing)
        #expect(apply(safe, workArounds: [.pregnancy, .knees]).message == safe.message)
        #expect(apply(safe, workArounds: [.pregnancy, .knees]).recommendation?.sessionID == breathing.id)

        let jumpRope = try session("app-jump-rope-ninety")
        let unsafe = reply(showing: jumpRope)
        #expect(apply(unsafe, workArounds: []).recommendation?.sessionID == jumpRope.id)
    }

    @Test("A card for a session the app does not know is dropped, not guessed at")
    func unknownSessionIsUnsafe() throws {
        let unknown = ChatResponse(
            message: "Try this.",
            mode: .recommendation,
            recommendation: StructuredRecommendation(
                sessionID: "not-in-this-build", title: "Mystery", subtitle: "", durationMin: 5,
                intensity: "gentle", course: "main", reason: "", tags: [], targetArea: nil
            )
        )
        let result = apply(unknown, workArounds: [.lowBack])
        #expect(result.recommendation?.sessionID != "not-in-this-build")
    }

    @Test("With no safe alternative the card is dropped and the person is asked instead")
    func noReplacementAsksInstead() throws {
        let jumpRope = try session("app-jump-rope-ninety")
        let result = ChatSafety.apply(
            to: reply(showing: jumpRope),
            workArounds: [.pregnancy],
            lookup: lookup,
            replacement: { _ in nil }
        )

        #expect(result.recommendation == nil)
        #expect(result.mode == .clarifying)
        #expect(result.message == ChatSafety.noCardMessage)
        #expect(!result.quickReplies.contains { $0.actionType == .commitToToday })
    }

    @Test("Every conflicting session, for every work-around it conflicts with, ends up safe")
    func exhaustive() throws {
        let conflicting = catalog.filter { !$0.contraindications.isEmpty }
        #expect(!conflicting.isEmpty)

        for session in conflicting {
            for workAround in session.contraindications {
                let result = apply(reply(showing: session), workArounds: [workAround])
                if let shown = result.recommendation {
                    let resolved = try self.session(shown.sessionID)
                    #expect(!ChatSafety.conflicts(resolved, workArounds: [workAround]),
                            "\(session.id) for \(workAround) still surfaced \(resolved.id)")
                }
            }
        }
    }

    @Test("The on-device fallback engine never picks a conflicting session")
    func fallbackEngineRespectsWorkArounds() {
        let all = Set(WorkAround.allCases)
        for _ in 0..<40 {
            let pick = LocalStatefulChatEngine.matchBestSession(workArounds: all)
            if let pick { #expect(!ChatSafety.conflicts(pick, workArounds: all)) }
        }
    }
}
