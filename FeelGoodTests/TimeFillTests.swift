//
//  TimeFillTests.swift
//  FeelGoodTests
//
//  "I have an hour" used to come back as a 28-minute day: the menu was one main,
//  one side, an appetizer and a dessert whatever the budget, so time worked as
//  a ceiling and never as a target. These run the real catalog to keep a long
//  check-in coming back as a long day, without ever going over.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Time fill")
struct TimeFillTests {

    private func total(_ menu: Menu) -> Int {
        menu.items.filter { $0.course != .special }.reduce(0) { $0 + $1.session.durationMin }
    }

    private func menu(for time: TimeBudget, energy: Energy, profile: PlanProfile) throws -> Menu {
        let engine = PlanEngine(catalog: try ContentStore.bundled().sessions)
        return engine.makeMenu(PlanInput(
            profile: profile,
            checkIn: PlanCheckIn(energy: energy, time: time),
            context: Fixture.context()
        ))
    }

    @Test("A long check-in gets most of its time, and never more than it")
    func longCheckInsFillTheirTime() throws {
        let profile = Fixture.profile(realisticMinutes: 60)
        for time in TimeBudget.allCases where time.maxMinutes >= PlanEngine.fillsTimeFrom {
            for energy in Energy.allCases {
                let minutes = total(try menu(for: time, energy: energy, profile: profile))
                #expect(minutes <= time.maxMinutes, "\(minutes) min on a \(time.maxMinutes)-minute budget")
                #expect(
                    Double(minutes) >= Double(time.maxMinutes) * 0.85,
                    "\(minutes) min is under 85% of a \(time.maxMinutes)-minute budget (\(energy))"
                )
            }
        }
    }

    @Test("An hour is not a half-hour day")
    func anHourIsAnHour() throws {
        let hour = try menu(for: .plenty, energy: .steady, profile: Fixture.profile(realisticMinutes: 60))
        let half = try menu(for: .some, energy: .steady, profile: Fixture.profile(realisticMinutes: 60))
        #expect(total(hour) >= 50)
        #expect(total(hour) > total(half))
    }

    @Test("A longer main still respects how someone feels")
    func longerMainRespectsEnergy() throws {
        let profile = Fixture.profile(realisticMinutes: 60)
        for energy in Energy.allCases {
            let menu = try menu(for: .plenty, energy: energy, profile: profile)
            let main = try #require(menu.main)
            let anySuits = try ContentStore.bundled().sessions.contains {
                $0.course == .main && $0.energyFit.contains(energy)
            }
            if anySuits { #expect(main.session.energyFit.contains(energy), "\(main.session.title) is not for \(energy) days") }
        }
    }

    @Test("Someone who chose no sides keeps the menu they asked for")
    func noSidesStaysNoSides() throws {
        let menu = try menu(for: .plenty, energy: .steady, profile: Fixture.profile(guidancePreference: .gettingStarted))
        #expect(menu.sides.isEmpty)
    }

    @Test("The menu stays within one screen")
    func staysWithinOneScreen() throws {
        let profile = Fixture.profile(moments: .sprinkled, realisticMinutes: 60)
        for time in TimeBudget.allCases where !time.isZero {
            let count = try menu(for: time, energy: .steady, profile: profile).items.count
            #expect(count <= PlanEngine.maxMenuItems)
        }
    }
}
