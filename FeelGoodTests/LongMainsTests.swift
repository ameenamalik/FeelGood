//
//  LongMainsTests.swift
//  FeelGoodTests
//
//  Mains used to stop at 20 minutes for mobility, stretching and yoga, so a
//  long check-in could only be filled with extras around a short main. These
//  keep a 40-50 minute main on offer for each of the main activities, and keep
//  their step times honest.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Long mains")
struct LongMainsTests {

    private let newIDs = [
        "main-mobility-30", "main-mobility-40", "main-mobility-50",
        "main-yoga-flow-40", "main-yoga-flow-50",
        "main-pilates-full-40", "main-pilates-full-50",
        "main-bodyweight-strength-45", "main-upper-core-strength-50",
    ]

    @Test("The longest main is fifty minutes")
    func longestMainIsFifty() throws {
        let mains = try ContentStore.bundled().sessions.filter { $0.course == .main }
        #expect(mains.map(\.durationMin).max() == 50)
    }

    @Test("Mobility and stretching, yoga, pilates and strength each have a main of 40 minutes or more")
    func eachActivityHasALongMain() throws {
        let mains = try ContentStore.bundled().sessions.filter { $0.course == .main }
        for activity in [Activity.stretching, .yoga, .pilates, .strength] {
            #expect(
                mains.contains { $0.activity == activity && $0.durationMin >= 40 },
                "no 40+ minute \(activity) main"
            )
        }
    }

    @Test("The new mains' step times add up to the length they promise")
    func newMainsAddUp() throws {
        let store = try ContentStore.bundled()
        for id in newIDs {
            let session = try #require(store.sessions.first { $0.id == id }, "\(id) is missing")
            let seconds = session.source.steps.reduce(0) { $0 + $1.seconds }
            #expect(seconds == session.durationMin * 60, "\(id): steps total \(seconds)s for \(session.durationMin) min")
        }
    }

    @Test("The new mains reuse the catalog's own exercises, so every step keeps its explanation or is a plain cue")
    func newMainsUseCatalogExercises() throws {
        let store = try ContentStore.bundled()
        for id in newIDs {
            let session = try #require(store.sessions.first { $0.id == id })
            for step in session.source.steps {
                #expect(!step.cue.isEmpty, "\(id) '\(step.name)' has no cue")
                if let glossaryID = step.glossaryID {
                    #expect(store.term(id: glossaryID) != nil, "\(id) '\(step.name)' points at missing \(glossaryID)")
                }
            }
        }
    }

    @Test("A long main carries every safety gate of the sessions it was built from")
    func newMainsKeepSafetyGates() throws {
        let store = try ContentStore.bundled()
        func gates(_ id: String) -> Set<WorkAround> {
            Set(store.sessions.first { $0.id == id }?.contraindications ?? [])
        }
        #expect(gates("main-yoga-flow-40").isSuperset(of: gates("main-yoga-flow-20")))
        #expect(gates("main-pilates-full-50").isSuperset(of: gates("main-pilates-full-30")))
        #expect(gates("main-upper-core-strength-50").isSuperset(of: gates("main-shoulders-core-thirty")))
        #expect(gates("main-bodyweight-strength-45").isSuperset(of: gates("main-beginner-calisthenics-fifteen")))
    }

    @Test("A mobility check-in for an hour is offered a main well past twenty minutes")
    func mobilityHourGetsALongMain() throws {
        let engine = PlanEngine(catalog: try ContentStore.bundled().sessions)
        var checkIn = PlanCheckIn(energy: .steady, time: .plenty, todayIntent: .mobilize)
        checkIn.focus = .full
        let menu = engine.makeMenu(PlanInput(
            profile: Fixture.profile(
                activities: [.stretching, .yoga],
                preferredActivities: [.stretching, .yoga],
                equipment: [.none, .mat],
                realisticMinutes: 30
            ),
            checkIn: checkIn,
            context: Fixture.context()
        ))
        let main = try #require(menu.main)
        #expect(main.session.durationMin >= 30, "got a \(main.session.durationMin)-minute main: \(main.session.title)")
        let total = menu.items.filter { $0.course != .special }.reduce(0) { $0 + $1.session.durationMin }
        #expect(total <= 60)
        #expect(Double(total) >= 60 * 0.85, "\(total) min for an hour")
    }
}
