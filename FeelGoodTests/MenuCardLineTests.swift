//
//  MenuCardLineTests.swift
//  FeelGoodTests
//
//  The one sentence on the main card: at most two inputs, plain words, and
//  nothing drawn from work-arounds.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Main card line")
struct MenuCardLineTests {

    private let session: Session = {
        let sessions = (try? ContentStore.bundled().sessions) ?? []
        return sessions.first { $0.course == .main && $0.durationMin >= 10 }!
    }()

    private func item(_ reasons: [ReasonCode] = []) -> MenuItem {
        MenuItem(session: session, course: .main, reasons: reasons, reasonText: "Engine reason.")
    }

    private func line(_ reasons: [ReasonCode] = [], energy: Energy, time: TimeBudget, intent: Intent? = nil) -> String {
        MenuCopy.cardLine(for: item(reasons), checkIn: PlanCheckIn(energy: energy, time: time, todayIntent: intent))
    }

    @Test("Low energy and little time name both, and stay gentle")
    func lowEnergyShortTime() {
        let text = line(energy: .low, time: .fiveMinutes)
        #expect(text.contains("Low energy"))
        #expect(text.contains("\(session.durationMin) minutes"))
    }

    @Test("Each single input gets its own sentence")
    func singleInputs() {
        #expect(line(energy: .low, time: .plenty) == "Low energy today, so this one is gentle.")
        #expect(line(energy: .steady, time: .fiveMinutes).hasPrefix("Short on time"))
        #expect(line(energy: .strong, time: .plenty, intent: .energize).contains("energy"))
    }

    @Test("Coming back after time away is warm, and never counts the gap")
    func returningAfterGap() {
        let text = line([.returningAfterGap], energy: .steady, time: .plenty)
        #expect(text == "It's been a little while, so this one starts small.")
        #expect(text.rangeOfCharacter(from: .decimalDigits) == nil)
    }

    @Test("Recovery is spoken as doing less on purpose")
    func recoveryBalance() {
        #expect(line([.recoveryBalance], energy: .steady, time: .plenty).contains("Easier"))
    }

    @Test("A rest day defers to the headline")
    func restDay() {
        #expect(line(energy: .low, time: .zeroMinutes) == "Engine reason.")
    }

    @Test("An ordinary day names its two inputs")
    func ordinaryDay() {
        #expect(line(energy: .steady, time: .twentyMinutes) == "Steady energy and 20 minutes, so this is a good main.")
        #expect(line(energy: .strong, time: .twentyMinutes).hasPrefix("Good energy and 20 minutes"))
    }

    @Test("A specific engine reason wins over the ordinary-day line")
    func specificReasonWins() {
        #expect(line([.varietyBreak], energy: .steady, time: .twentyMinutes) == "Engine reason.")
    }

    @Test("The engine's generic repeat-avoidance line is not shown as a reason")
    func genericLineIsSkipped() {
        let generic = MenuCopy.fallbackLine(for: session)
        let repeated = MenuItem(session: session, course: .main, reasons: [.matchesIntent], reasonText: generic)
        let text = MenuCopy.cardLine(for: repeated, checkIn: PlanCheckIn(energy: .steady, time: .twentyMinutes))
        #expect(text == "Steady energy and 20 minutes, so this is a good main.")

        let unspoken = MenuItem(session: session, course: .main, reasons: [.qualityGap], reasonText: MenuCopy.defaultLine(for: session))
        #expect(MenuCopy.cardLine(for: unspoken, checkIn: PlanCheckIn(energy: .steady, time: .twentyMinutes)) == text)
    }

    @Test("No line ever mentions the body or work-arounds")
    func nothingPrivate() {
        let words = ["back", "pregnan", "postpartum", "pelvic", "knee", "wrist", "cramp"]
        for energy in Energy.allCases {
            for time in TimeBudget.allCases {
                let text = line([.lowEnergy, .timeConstrained, .recoveryBalance], energy: energy, time: time).lowercased()
                for word in words { #expect(!text.contains(word), "\(text)") }
            }
        }
    }
}
