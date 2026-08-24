//
//  CatalogTests.swift
//  FeelGoodTests
//
//  The shipped catalog is content, which means it changes far more often than
//  the code that reads it. These run the real bundled JSON through the real
//  engine so a bad content drop fails the build, not somebody's morning.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Bundled catalog")
struct CatalogTests {

    private func store() throws -> ContentStore {
        try ContentStore.bundled()
    }

    @Test("The bundled catalog decodes")
    func catalogDecodes() throws {
        let store = try store()
        #expect(store.version >= 1)
        #expect(store.sessions.count >= 20)
        #expect(!store.glossary.isEmpty)
    }

    @Test("The catalog holds its invariants")
    func catalogIsValid() throws {
        let issues = try store().validate()
        #expect(issues.isEmpty, "\(issues.map(\.description))")
    }

    @Test("Every course is represented")
    func everyCourseIsStocked() throws {
        let sessions = try store().sessions
        for course in Course.allCases {
            #expect(sessions.contains { $0.course == course }, "no \(course) sessions")
        }
    }

    @Test("Every step that offers an explanation resolves to one")
    func glossaryReferencesResolve() throws {
        let store = try store()
        for session in store.sessions {
            for step in session.source.steps where step.glossaryID != nil {
                #expect(store.term(id: step.glossaryID) != nil,
                        "\(session.id) references \(step.glossaryID!)")
            }
        }
    }

    @Test("Gym taxonomy never reaches the glossary text")
    func glossaryAvoidsShameVocabulary() throws {
        // "Expert" next to a move someone is about to try is a shame vector, and
        // gym register is the voice we are deliberately not writing in.
        let banned = ["beginner", "intermediate", "expert", "advanced", "calorie", "burn fat", "toned"]
        for term in try store().glossary {
            let text = ([term.name] + term.instructions + term.muscles).joined(separator: " ").lowercased()
            for word in banned {
                #expect(!text.contains(word), "\(term.id) contains \"\(word)\"")
            }
        }
    }

    @Test("Nothing in the catalog claims a creator endorsed it")
    func nothingIsAttributedYet() throws {
        // Stays true until sign-off is in writing. See PRD §6.
        for session in try store().sessions {
            #expect(session.attribution == nil, "\(session.id) carries attribution")
        }
    }

    @Test("Anything bouncy is gated for pregnancy, postpartum and pelvic floor")
    func impactWorkIsSafetyGated() throws {
        for session in try store().sessions where session.qualities.contains(.impact) {
            let gates = Set(session.contraindications)
            #expect(gates.isSuperset(of: [.pregnancy, .postpartum, .pelvicFloor]),
                    "\(session.id) is impact work without full safety gating")
        }
    }

    @Test("Authored sessions carry the offline path")
    func authoredSessionsHaveSteps() throws {
        for session in try store().sessions where !session.source.isVideo {
            #expect(!session.source.steps.isEmpty, "\(session.id) has no steps")
            for step in session.source.steps {
                #expect(step.seconds > 0)
                #expect(!step.cue.isEmpty)
            }
        }
    }

    @Test("The real catalog produces a real menu for a real profile")
    func realCatalogPlansAWholeMenu() throws {
        let engine = PlanEngine(catalog: try store().sessions)
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .steady, time: .some),
            context: Fixture.context()
        )
        let menu = engine.makeMenu(input)

        #expect(menu.main != nil)
        #expect(menu.appetizer != nil)
        #expect((3...PlanEngine.maxMenuItems).contains(menu.items.count))
    }

    @Test("The real catalog never repeats a reason across a menu")
    func realCatalogGivesDistinctReasons() throws {
        let engine = PlanEngine(catalog: try store().sessions)
        for energy in Energy.allCases {
            for time in TimeBudget.allCases {
                let input = PlanInput(
                    profile: Fixture.profile(),
                    checkIn: PlanCheckIn(energy: energy, time: time),
                    context: Fixture.context()
                )
                let texts = engine.makeMenu(input).items.map(\.reasonText)
                #expect(Set(texts).count == texts.count, "\(energy)/\(time): \(texts)")
            }
        }
    }

    @Test("Every appetizer can be done without leaving the house")
    func appetizersAlwaysWorkAtHome() throws {
        for session in try store().sessions where session.course == .appetizer {
            #expect(session.worksAtHome, "\(session.id) needs somewhere other than home")
        }
    }

    @Test("Every session says where it can happen")
    func everySessionIsPlaced() throws {
        for session in try store().sessions {
            #expect(!session.places.isEmpty, "\(session.id) has no place")
        }
    }

    @Test("Twenty minutes, nothing left, not leaving the house")
    func theHardDayStillGetsAMenu() throws {
        let engine = PlanEngine(catalog: try store().sessions)
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .low, time: .some, place: .stayingIn),
            context: Fixture.context()
        )
        let menu = engine.makeMenu(input)

        #expect(menu.appetizer != nil)
        #expect(menu.main != nil)
        for item in menu.items {
            #expect(item.session.places.contains(.home))
            #expect(item.session.durationMin <= TimeBudget.some.maxMinutes)
        }
    }

    @Test("The real catalog holds up for someone with nothing but a floor")
    func realCatalogServesTheHardestCase() throws {
        let engine = PlanEngine(catalog: try store().sessions)
        let input = PlanInput(
            profile: Fixture.profile(
                activities: [.breathwork, .stretching],
                equipment: [.none],
                places: [.home],
                realisticMinutes: 10,
                workArounds: [.pregnancy, .postpartum, .pelvicFloor, .lowBack, .knees, .wrists]
            ),
            checkIn: PlanCheckIn(energy: .low, time: .aLittle),
            context: Fixture.context(isOffline: true)
        )
        let menu = engine.makeMenu(input)

        #expect(menu.appetizer != nil)
        for item in menu.items {
            #expect(!item.session.source.isVideo)
            #expect(Set(item.session.contraindications).isDisjoint(with: input.profile.workArounds))
        }
    }
}
