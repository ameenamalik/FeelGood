//
//  CheckInNudgeTests.swift
//  FeelGoodTests
//
//  The check-in's second answer can ask for a body area and lean toward some
//  activities. Both must move the menu, and neither may empty it: they are
//  nudges, never filters.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Check-in nudges")
struct CheckInNudgeTests {

    /// Two mains identical in every way but the body area they work.
    private func main(_ id: String, focus: BodyFocus, activity: Activity = .strength) -> Session {
        Session(
            id: id,
            title: id,
            subtitle: "",
            activity: activity,
            qualities: [.strength],
            durationMin: 20,
            intensity: 2,
            energyFit: Energy.allCases,
            equipment: [.none],
            places: [.home],
            bodyFocus: [focus],
            contraindications: [],
            intents: [.strengthen],
            course: .main,
            source: .authored(steps: [Step(name: "Move", seconds: 1200, cue: "Go")])
        )
    }

    private func menu(_ checkIn: PlanCheckIn, catalog: [Session], weights: PlanWeights = PlanWeights()) -> Menu {
        PlanEngine(catalog: catalog, weights: weights).makeMenu(
            PlanInput(profile: Fixture.profile(), checkIn: checkIn, context: Fixture.context())
        )
    }

    @Test("Asking for a body area brings a session for it to the main", arguments: [BodyFocus.lowerBody, .upperBody])
    func focusLeadsTheMain(focus: BodyFocus) {
        let catalog = Fixture.catalog.filter { $0.course != .main } + [
            main("m-legs", focus: .lowerBody),
            main("m-arms", focus: .upperBody),
        ]
        var checkIn = PlanCheckIn(energy: .steady, time: .some, todayIntent: .strengthen)
        checkIn.focus = focus

        #expect(menu(checkIn, catalog: catalog).main?.session.bodyFocus == [focus])
    }

    @Test("A favoured activity leads when it can")
    func favouredActivityLeadsTheMain() {
        let catalog = Fixture.catalog.filter { $0.course != .main } + [
            main("m-strength", focus: .full, activity: .strength),
            main("m-pilates", focus: .full, activity: .pilates),
        ]
        for activity in [Activity.strength, .pilates] {
            var checkIn = PlanCheckIn(energy: .steady, time: .some, todayIntent: .strengthen)
            checkIn.favoured = [activity]
            #expect(menu(checkIn, catalog: catalog).main?.session.activity == activity)
        }
    }

    @Test("Asking for something the catalog doesn't have still gets a full menu")
    func unmetNudgesNeverEmptyTheMenu() {
        var checkIn = PlanCheckIn(energy: .steady, time: .some, todayIntent: .play)
        checkIn.focus = .neckShoulders
        checkIn.favoured = [.racquet, .climbing]

        let nudged = menu(checkIn, catalog: Fixture.catalog)
        let plain = menu(PlanCheckIn(energy: .steady, time: .some, todayIntent: .play), catalog: Fixture.catalog)

        #expect(!nudged.items.isEmpty)
        #expect(nudged.items.map(\.session.id) == plain.items.map(\.session.id))
    }

    @Test("With both weights at zero the nudges change nothing")
    func nudgesAreOnlyWeights() {
        var weights = PlanWeights()
        weights.focusMatch = 0
        weights.favouredActivityMatch = 0

        var checkIn = PlanCheckIn(energy: .steady, time: .some, todayIntent: .strengthen)
        let plain = menu(checkIn, catalog: Fixture.catalog, weights: weights)
        checkIn.focus = .core
        checkIn.favoured = [.pilates]
        let nudged = menu(checkIn, catalog: Fixture.catalog, weights: weights)

        #expect(nudged.items.map(\.session.id) == plain.items.map(\.session.id))
    }
}
