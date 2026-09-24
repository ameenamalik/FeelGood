//
//  CalendarAvailabilityTests.swift
//  FeelGoodTests
//

import Foundation
import Testing
@testable import FeelGood

@Suite("Calendar availability")
struct CalendarAvailabilityTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    @Test("A preferred lunch opening wins over larger openings elsewhere")
    func prefersLunchOpening() throws {
        let now = date(hour: 8)
        let busy = [
            CalendarBusyInterval(start: date(hour: 9), end: date(hour: 12)),
            CalendarBusyInterval(start: date(hour: 13), end: date(hour: 16)),
        ]

        let opening = try #require(CalendarOpeningFinder.bestOpening(
            on: now,
            busy: busy,
            preferredTime: .midday,
            realisticMinutes: 20,
            calendar: calendar
        ))

        #expect(opening.start == date(hour: 12, minute: 10))
        #expect(opening.end == date(hour: 12, minute: 50))
        #expect(opening.budget == .twentyMinutes)
        #expect(opening.context == .beforeNextEvent)
    }

    @Test("The suggestion never exceeds the person's realistic duration")
    func capsAtRealisticDuration() throws {
        let opening = try #require(CalendarOpeningFinder.bestOpening(
            on: date(hour: 8),
            busy: [],
            preferredTime: .varies,
            realisticMinutes: 15,
            calendar: calendar
        ))

        #expect(opening.budget == .fifteenMinutes)
        #expect(opening.context == .openToday)
    }

    @Test("An opening after the final event is described as the rest of the day")
    func recognizesOpenRestOfDay() throws {
        let opening = try #require(CalendarOpeningFinder.bestOpening(
            on: date(hour: 12),
            busy: [CalendarBusyInterval(start: date(hour: 9), end: date(hour: 10))],
            preferredTime: .varies,
            realisticMinutes: 20,
            calendar: calendar
        ))

        #expect(opening.context == .openForRestOfDay)
    }

    @Test("A day with no remaining active hours has no suggestion")
    func noOpeningAfterActiveDay() {
        let opening = CalendarOpeningFinder.bestOpening(
            on: date(hour: 21, minute: 5),
            busy: [],
            preferredTime: .varies,
            realisticMinutes: 20,
            calendar: calendar
        )

        #expect(opening == nil)
    }

    @Test("Offers a best fit with distinct sooner and later choices")
    func offersRankedChoices() {
        let openings = CalendarOpeningFinder.rankedOpenings(
            on: date(hour: 8),
            busy: [],
            preferredTime: .midday,
            realisticMinutes: 20,
            calendar: calendar
        )

        #expect(openings.count == 3)
        #expect(openings[0].start == date(hour: 12))
        #expect(openings[1].start == date(hour: 8))
        #expect(openings[2].start == date(hour: 18))
        #expect(Set(openings.map(\.start)).count == openings.count)
    }

    @Test("Every choice respects buffers, duration, and the active-day boundary")
    func choicesStayWithinSafeWindows() {
        let busy = [
            CalendarBusyInterval(start: date(hour: 10), end: date(hour: 11)),
            CalendarBusyInterval(start: date(hour: 14), end: date(hour: 15)),
        ]
        let openings = CalendarOpeningFinder.rankedOpenings(
            on: date(hour: 8),
            busy: busy,
            preferredTime: .varies,
            realisticMinutes: 15,
            calendar: calendar
        )

        #expect(openings.count <= 3)
        #expect(openings.allSatisfy { $0.suggestedEnd <= date(hour: 21) })
        #expect(openings.allSatisfy { $0.budget.maxMinutes <= 15 })
        #expect(openings.allSatisfy { opening in
            busy.allSatisfy { interval in
                opening.suggestedEnd <= interval.start.addingTimeInterval(-10 * 60)
                    || opening.start >= interval.end.addingTimeInterval(10 * 60)
            }
        })
    }

    private func date(hour: Int, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(
            year: 2026,
            month: 9,
            day: 1,
            hour: hour,
            minute: minute
        ))!
    }
}

@Suite("Calendar movement title recognition")
struct CalendarMovementTitleClassifierTests {
    @Test("Recognizes clear supported movement names", arguments: [
        ("Reformer Pilates class", Activity.pilates),
        ("Morning yoga", Activity.yoga),
        ("Pool swim", Activity.swimming),
        ("Gym workout", Activity.strength),
        ("Gym", Activity.strength),
        ("Pickleball with Sam", Activity.racquet),
        ("Morning run", Activity.agility),
        ("Football practice", Activity.racquet),
        ("Boxing class", Activity.martialArts),
        ("Evening bike ride", Activity.biking),
        ("Barre class", Activity.pilates),
        ("Saturday hike", Activity.walking),
        ("Zumba", Activity.dance),
    ])
    func recognizesMovement(title: String, expected: Activity) {
        #expect(CalendarMovementTitleClassifier.activity(for: title) == expected)
    }

    @Test("Does not guess from ordinary calendar language", arguments: [
        "Team training",
        "Product walkthrough",
        "Dentist appointment",
        "Dinner",
    ])
    func ignoresUnclearTitles(title: String) {
        #expect(CalendarMovementTitleClassifier.activity(for: title) == nil)
    }
}

@Suite("Calendar movement companion")
struct CalendarMovementCompanionSelectorTests {
    private let profile = PlanProfile(
        availableActivities: Set(Activity.allCases),
        equipment: [.none],
        places: [.home]
    )

    @Test("Warm-up matches the planned movement's body area")
    func warmUpMatchesBodyFocus() throws {
        let plan = CalendarMovementPlan(
            id: "walk",
            start: Date().addingTimeInterval(3_600),
            end: Date().addingTimeInterval(5_400),
            activity: .walking
        )
        let calf = session(
            id: "calf",
            activity: .stretching,
            qualities: [.mobility],
            bodyFocus: [.lowerBody]
        )
        let shoulders = session(
            id: "shoulders",
            activity: .stretching,
            qualities: [.mobility],
            bodyFocus: [.neckShoulders]
        )

        let result = CalendarMovementCompanionSelector.session(
            for: plan,
            phase: .warmUp,
            from: [shoulders, calf],
            profile: profile
        )

        #expect(result?.id == calf.id)
    }

    @Test("Recovery prefers down-regulation")
    func recoveryPrefersDownRegulation() throws {
        let plan = CalendarMovementPlan(
            id: "strength",
            start: Date().addingTimeInterval(-3_600),
            end: Date().addingTimeInterval(-1_800),
            activity: .strength
        )
        let mobility = session(
            id: "mobility",
            activity: .stretching,
            qualities: [.mobility],
            bodyFocus: [.full]
        )
        let settle = session(
            id: "settle",
            activity: .breathwork,
            qualities: [.mobility, .downRegulation],
            bodyFocus: [.full]
        )

        let result = CalendarMovementCompanionSelector.session(
            for: plan,
            phase: .recovery,
            from: [mobility, settle],
            profile: profile
        )

        #expect(result?.id == settle.id)
    }

    @Test("Hidden and contraindicated sessions are never companions")
    func honorsSafetyAndHiddenChoices() {
        let plan = CalendarMovementPlan(
            id: "yoga",
            start: Date(),
            end: Date().addingTimeInterval(3_600),
            activity: .yoga
        )
        let unsafe = session(
            id: "unsafe",
            activity: .stretching,
            qualities: [.mobility],
            bodyFocus: [.back],
            contraindications: [.lowBack]
        )
        let hidden = session(
            id: "hidden",
            activity: .qigong,
            qualities: [.mobility],
            bodyFocus: [.full]
        )
        let constrainedProfile = PlanProfile(
            availableActivities: Set(Activity.allCases),
            workArounds: [.lowBack],
            hiddenSessionIDs: [hidden.id]
        )

        let result = CalendarMovementCompanionSelector.session(
            for: plan,
            phase: .warmUp,
            from: [unsafe, hidden],
            profile: constrainedProfile
        )

        #expect(result == nil)
    }

    private func session(
        id: String,
        activity: Activity,
        qualities: [Quality],
        bodyFocus: [BodyFocus],
        contraindications: [WorkAround] = []
    ) -> Session {
        Session(
            id: id,
            title: id,
            subtitle: "Test session",
            activity: activity,
            qualities: qualities,
            durationMin: 4,
            intensity: 1,
            energyFit: Energy.allCases,
            equipment: [.none],
            places: [.home],
            bodyFocus: bodyFocus,
            contraindications: contraindications,
            intents: [.mobilize],
            course: .side,
            source: .authored(steps: [])
        )
    }
}
