//
//  RoutineDraftTests.swift
//  FeelGoodTests
//
//  When Chat has nothing for a request it offers to build it, and when the
//  person already built one it offers theirs. Also covers running, which was
//  the request Chat had nothing for.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Routine drafts from Chat")
struct RoutineDraftTests {

    @Test("A request naming a kind of movement becomes a draft of it")
    func draftFromRequest() throws {
        let draft = try #require(RoutineDraft.from(prompt: "I want to play tennis for 30 min"))
        #expect(draft.activity == .racquet)
        #expect(draft.durationMin == 30)
        #expect(draft.parts.count == 3)
        #expect(draft.course == .main)
    }

    @Test("The draft is named with the word they used")
    func draftUsesTheirWord() throws {
        let boxing = try #require(RoutineDraft.from(prompt: "i want to do boxing for 10 min"))
        #expect(boxing.title == "My boxing")
        #expect(boxing.activity == .martialArts)
        let tennis = try #require(RoutineDraft.from(prompt: "tennis later"))
        #expect(tennis.title == "My tennis")
    }

    @Test("A run with no time given defaults to twenty minutes")
    func runDefaults() throws {
        let draft = try #require(RoutineDraft.from(prompt: "I want to go for a run"))
        #expect(draft.activity == .running)
        #expect(draft.title == "My run")
        #expect(draft.durationMin == 20)
    }

    @Test("A short request is one part and a side")
    func shortRequest() throws {
        let draft = try #require(RoutineDraft.from(prompt: "quick 10 minute swim"))
        #expect(draft.activity == .swimming)
        #expect(draft.parts.count == 1)
        #expect(draft.durationMin == 10)
        #expect(draft.course == .side)
    }

    @Test("Nothing to build from a request with no movement in it")
    func noDraftForVagueRequest() {
        #expect(RoutineDraft.from(prompt: "meh, not sure") == nil)
        #expect(RoutineDraft.from(prompt: "brunch then errands") == nil)
    }

    @Test("A saved routine of the same kind is found, and hidden ones are not")
    func savedMatch() {
        let run = Fixture.session(id: "own-run", title: "Canal loop", activity: .running)
        let hiddenSwim = Fixture.session(id: "own-swim", title: "Laps", activity: .swimming)

        #expect(RoutineDraft.savedMatch(for: "I want to go for a run", in: [run, hiddenSwim], isHidden: { _ in false })?.id == "own-run")
        #expect(RoutineDraft.savedMatch(for: "canal loop today?", in: [run], isHidden: { _ in false })?.id == "own-run")
        #expect(RoutineDraft.savedMatch(for: "a swim", in: [hiddenSwim], isHidden: { $0 == "own-swim" }) == nil)
        #expect(RoutineDraft.savedMatch(for: "some yoga", in: [run], isHidden: { _ in false }) == nil)
    }

    @Test("Saying you want to run opens running outdoors for today")
    func runningWidensAvailability() throws {
        let catalog = try ContentStore.bundled().sessions
        let run = try #require(catalog.first { $0.id == "main-easy-run-twenty" })
        let profile = PlanProfile(availableActivities: [.stretching], equipment: [.none], places: [.home])

        #expect(!ChatAvailability(profile: profile).allows(run))
        #expect(ChatAvailability(profile: profile, conversation: ["I want to go for a run"]).allows(run))
        #expect(!ChatAvailability(profile: profile, conversation: ["I don't want to run"]).allows(run))
        #expect(!ChatAvailability(profile: profile, conversation: ["running late, something quick"]).allows(run))
    }

    @Test("The on-device engine answers a run request with a run")
    func localEngineFindsRun() {
        let response = LocalStatefulChatEngine.orchestrate(prompt: "I want a 10 min run")
        let sessionID = response.recommendation?.sessionID ?? ""
        let catalog = (try? ContentStore.bundled().sessions) ?? []
        #expect(catalog.first { $0.id == sessionID }?.activity == .running)
    }
}
