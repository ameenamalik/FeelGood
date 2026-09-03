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
