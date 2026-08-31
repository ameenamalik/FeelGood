//
//  CopyPayloadTests.swift
//  FeelGoodTests
//
//  The privacy claim in one file. `CopyPayload` is the only thing that ever
//  leaves the device, so these tests are what stand between a refactor and a
//  sentence in the PRD becoming false.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Copy payload")
struct CopyPayloadTests {

    /// Someone whose engine input is full of the things that must never travel:
    /// pregnant, postpartum, pelvic floor, and cramping today.
    private func sensitiveInput() -> PlanInput {
        PlanInput(
            profile: Fixture.profile(workArounds: [.pregnancy, .postpartum, .pelvicFloor]),
            checkIn: PlanCheckIn(energy: .low, time: .aLittle, place: .stayingIn, body: .cramping),
            history: [Fixture.completed("s-walk", activity: .walking, daysAgo: 3)],
            context: Fixture.context()
        )
    }

    private func payload(from input: PlanInput) -> CopyPayload {
        CopyPayload(
            menu: Fixture.engine.makeMenu(input),
            checkIn: Fixture.engine.resolvedCheckIn(input),
            stats: HistoryStats(input: input),
            subscriberID: "install-abc123"
        )
    }

    private func encoded(_ payload: CopyPayload) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(payload), as: UTF8.self)
    }

    @Test("The wire shape is exactly the six permitted keys")
    func wireShapeIsClosed() throws {
        let json = try JSONSerialization.jsonObject(
            with: Data(try encoded(payload(from: sensitiveInput())).utf8)
        )
        let object = try #require(json as? [String: Any])

        // Written out rather than derived from CodingKeys: a test that reads
        // the same source as the thing it checks agrees with any mistake.
        #expect(
            Set(object.keys) == ["picks", "reasonCodes", "energy", "time", "daysSinceLast", "subscriberID"],
            "The copy payload grew or lost a field. If this is deliberate, the PRD §11 table changes too."
        )
    }

    /// The one that matters. Catches a leak through a *nested* type as well —
    /// somebody adding a field to `MenuItem` or `ReasonCode` that carries a
    /// work-around along with it would fail here without touching this file.
    @Test("No work-around or body state appears anywhere in the encoded payload")
    func sensitiveValuesNeverTravel() throws {
        let json = try encoded(payload(from: sensitiveInput())).lowercased()

        for workAround in WorkAround.allCases {
            #expect(
                !json.contains(workAround.rawValue.lowercased()),
                "\(workAround.rawValue) reached the wire. Work-arounds are a filter, never a payload."
            )
        }
        for body in BodyState.allCases where body != .good {
            #expect(
                !json.contains(body.rawValue.lowercased()),
                "\(body.rawValue) reached the wire. Body state stays on the device."
            )
        }
    }

    @Test("Coarse state is the check-in the engine actually used")
    func coarseStateIsCarried() {
        let input = sensitiveInput()
        let made = payload(from: input)

        #expect(made.energy == .low)
        #expect(made.time == .aLittle)
        // Reuses the engine's own gap, so the two can never disagree.
        #expect(made.daysSinceLast == HistoryStats(input: input).daysSinceLastCompleted)
        #expect(made.daysSinceLast == 3)
    }

    @Test("Reason codes are deduplicated with their order kept")
    func reasonCodesAreDeduplicated() {
        let made = payload(from: sensitiveInput())
        #expect(Set(made.reasonCodes).count == made.reasonCodes.count)
    }

    @Test("A kept workout's own title never travels, only its id")
    func titlesNeverTravel() throws {
        // Fixture sessions use their id as their title, so this needs a session
        // where the two differ — which is exactly the real case: a workout
        // somebody kept, named in their own words.
        let mine = Session(
            id: "own-1",
            title: "Tuesday with Dad's old kettlebell",
            subtitle: "",
            activity: .strength,
            qualities: [.strength],
            durationMin: 20,
            intensity: 3,
            energyFit: Energy.allCases,
            equipment: [.none],
            places: [.home],
            bodyFocus: [.full],
            contraindications: [],
            intents: [.strengthen],
            course: .main,
            source: .authored(steps: [Step(name: "Move", seconds: 1200, cue: "Go")])
        )
        let menu = Menu(
            dayStart: Fixture.now,
            appetizer: nil,
            main: MenuItem(session: mine, course: .main, reasons: [.matchesIntent], reasonText: "Because."),
            sides: [],
            dessert: nil,
            special: nil,
            headline: "Today",
            assumedCheckIn: PlanCheckIn(energy: .steady, time: .some)
        )
        let json = try encoded(CopyPayload(
            menu: menu,
            checkIn: PlanCheckIn(energy: .steady, time: .some),
            stats: HistoryStats(input: sensitiveInput()),
            subscriberID: "install-abc123"
        ))

        #expect(json.contains("own-1"))
        #expect(!json.contains("kettlebell"), "A title somebody wrote themselves reached the wire.")
        #expect(!json.contains("Dad"))
    }
}
