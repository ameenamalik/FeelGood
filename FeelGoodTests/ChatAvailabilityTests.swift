//
//  ChatAvailabilityTests.swift
//  FeelGoodTests
//
//  Chat must not offer what Today would have filtered out: a gym session for
//  someone who never said they have a gym. Uses the real bundled catalog.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Chat availability")
struct ChatAvailabilityTests {

    private let catalog: [Session] = (try? ContentStore.bundled().sessions) ?? []

    private func session(_ id: String) throws -> Session {
        try #require(catalog.first { $0.id == id })
    }

    private let homeProfile = PlanProfile(availableActivities: [.stretching, .walking], equipment: [.none, .mat], places: [.home])

    private func reply(showing session: Session) -> ChatResponse {
        ChatResponse(
            message: "Try \(session.title).",
            mode: .recommendation,
            recommendation: LocalStatefulChatEngine.structuredRecommendation(for: session),
            quickReplies: ChatSafety.recommendationChips
        )
    }

    private func apply(_ response: ChatResponse, availability: ChatAvailability) -> ChatResponse {
        ChatSafety.apply(
            to: response,
            workArounds: [],
            availability: availability,
            lookup: { id in catalog.first { $0.id == id } },
            replacement: { rejected in
                LocalStatefulChatEngine.matchBestSession(
                    targetDuration: rejected.durationMin,
                    excludeID: rejected.sessionID,
                    availability: availability
                )
            }
        )
    }

    @Test("A gym card is swapped out for someone with no gym or weights")
    func gymCardIsReplaced() throws {
        let gym = try session("main-gym-machines-20")
        let availability = ChatAvailability(profile: homeProfile)
        #expect(!availability.allows(gym))

        let shown = try #require(apply(reply(showing: gym), availability: availability).recommendation)
        #expect(shown.sessionID != gym.id)
        #expect(availability.allows(try session(shown.sessionID)))
    }

    @Test("The local matcher never returns a session the person cannot do")
    func matcherRespectsAvailability() {
        let availability = ChatAvailability(profile: homeProfile)
        for _ in 0..<50 {
            let pick = LocalStatefulChatEngine.matchBestSession(targetDuration: 30, intensity: "dynamic", availability: availability)
            #expect(pick.map(availability.allows) ?? true)
        }
    }

    @Test("Saying you are at the gym today opens gym sessions without touching the profile")
    func gymOverride() throws {
        let gym = try session("main-gym-machines-20")
        let lifting = try session("main-strength-full-30")
        for phrase in ["I'm at the gym today", "i have a gym", "heading to the gym", "I have dumbbells"] {
            let widened = ChatAvailability(profile: homeProfile, conversation: [phrase])
            #expect(widened.allows(lifting), "\(phrase)")
            if phrase.contains("gym") { #expect(widened.allows(gym), "\(phrase)") }
        }
        #expect(!ChatAvailability(profile: homeProfile).allows(gym))
    }

    @Test("Questions and negations are not claims of access")
    func noFalseOverride() throws {
        let gym = try session("main-gym-machines-20")
        for phrase in ["should I go to the gym?", "I don't have a gym", "no gym today", "I'm not at the gym", "without a gym"] {
            #expect(!ChatAvailability(profile: homeProfile, conversation: [phrase]).allows(gym), "\(phrase)")
        }
    }

    @Test("Saying you want pilates widens availability to allow mat pilates even if not picked in onboarding")
    func pilatesOverride() throws {
        let pilates = try session("main-pilates-core-20")
        let nonPilatesProfile = PlanProfile(availableActivities: [.walking, .stretching], equipment: [.none, .mat], places: [.home])
        let widened = ChatAvailability(profile: nonPilatesProfile, conversation: ["Can I do a 15-minute pilates session?"])
        #expect(widened.allows(pilates))
    }

    @Test("A profile that already has a gym still gets gym sessions")
    func profileWithGym() throws {
        let profile = PlanProfile(
            availableActivities: [.strength], equipment: [.gym, .mat, .weights, .band, .bike], places: [.home, .gym]
        )
        #expect(ChatAvailability(profile: profile).allows(try session("main-gym-machines-20")))
    }

    @Test("Availability survives the wire round trip")
    func wireRoundTrip() throws {
        let availability = ChatAvailability(profile: homeProfile)
        let context = ChatUserContext(availability: availability)
        let decoded = try JSONDecoder().decode(ChatUserContext.self, from: JSONEncoder().encode(context))
        #expect(decoded.availability == availability)
        let json = try #require(String(data: JSONEncoder().encode(context), encoding: .utf8))
        #expect(json.contains("available_equipment"))
    }
}
