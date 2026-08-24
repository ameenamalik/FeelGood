//
//  LookBackTests.swift
//  FeelGoodTests
//
//  The Look Back is the anti-shame thesis in four sentences. These tests are
//  as much about what it must never say as about what it says.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Look Back")
struct LookBackTests {

    private func at(_ daysAgo: Int, hour: Int, _ activity: Activity, id: String? = nil) -> HistoryEntry {
        let day = Fixture.utc.date(byAdding: .day, value: -daysAgo, to: Fixture.now)!
        let date = Fixture.utc.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
        return HistoryEntry(
            sessionID: id ?? "s-\(activity.rawValue)",
            activity: activity,
            qualities: activity.typicalQualities,
            intensity: 3,
            course: .main,
            date: date,
            outcome: .completed(feel: nil)
        )
    }

    private func lookBack(_ history: [HistoryEntry], affinity: [String: Double] = [:]) -> LookBack {
        LookBack(history: history, affinity: affinity, calendar: Fixture.utc, now: Fixture.now)
    }

    @Test("With nothing to look back on, it says nothing about absence")
    func nothingYet() {
        #expect(lookBack([]).isEmpty)
        #expect(lookBack([at(1, hour: 9, .pilates)]).isEmpty)
        // The empty state looks forward. It never names a day nobody was here.
        #expect(!LookBack.openingLine.lowercased().contains("haven't"))
    }

    @Test("It counts what happened, never what didn't")
    func countsWhatHappened() {
        let seen = lookBack([
            at(1, hour: 9, .pilates), at(3, hour: 9, .walking), at(5, hour: 9, .stretching)
        ])
        #expect(seen.observations.first?.text == "You've moved 3 times in the last two weeks.")
    }

    @Test("A clear time of day is named; a mixed one is left alone")
    func timeOfDayIsOnlyClaimedWhenItIsReal() {
        let mornings = lookBack([
            at(1, hour: 7, .pilates), at(2, hour: 8, .walking), at(4, hour: 9, .pilates)
        ])
        #expect(mornings.observations.contains { $0.text == "Mostly mornings." })

        // One of each: no pattern, so nothing is invented.
        let scattered = lookBack([
            at(1, hour: 8, .pilates), at(2, hour: 14, .walking), at(3, hour: 20, .stretching)
        ])
        #expect(!scattered.observations.contains { $0.id == "when" })
    }

    @Test("Activities are spoken, not listed as a taxonomy")
    func activitiesReadAsEnglish() {
        let seen = lookBack([
            at(1, hour: 9, .pilates), at(2, hour: 9, .pilates),
            at(3, hour: 9, .walking), at(4, hour: 9, .walking)
        ])
        #expect(seen.observations.contains { $0.text == "Mostly Pilates and walking." })
    }

    @Test("What got loved is what it names, not what got done most")
    func favouriteComesFromAffinity() {
        let history = [
            at(1, hour: 9, .pilates, id: "p1"), at(2, hour: 9, .pilates, id: "p1"),
            at(3, hour: 9, .pilates, id: "p1"), at(4, hour: 9, .stretching, id: "s1")
        ]
        let seen = lookBack(history, affinity: ["s1": 0.8])

        #expect(seen.observations.contains { $0.text == "The stretching sessions are the ones you keep coming back to." })
    }

    @Test("A fortnight with a long gap in it reads exactly like one without")
    func gapsAreNeverRendered() {
        // Three sessions, then eleven days of life happening.
        let withGap = lookBack([
            at(11, hour: 9, .pilates), at(12, hour: 9, .pilates), at(13, hour: 9, .walking)
        ])
        #expect(withGap.observations.first?.text == "You've moved 3 times in the last two weeks.")
        #expect(withGap.observations.allSatisfy { !$0.text.contains("since") })
    }

    @Test("Nothing it can say carries a shame register")
    func noShameVocabulary() {
        // Every shape of fortnight this thing can be handed.
        var histories: [[HistoryEntry]] = [
            [], [at(1, hour: 9, .pilates)],
            [at(1, hour: 6, .pilates), at(2, hour: 15, .walking), at(13, hour: 22, .stretching)]
        ]
        for activity in Activity.allCases {
            histories.append((1...6).map { at($0, hour: 7 + $0, activity) })
        }

        let banned = [
            "missed", "streak", "behind", "should", "failed", "only",
            "haven't", "didn't", "gap", "skipped", "off track", "goal", "target", "%"
        ]
        for history in histories {
            let seen = lookBack(history, affinity: ["s-pilates": 0.5])
            for line in seen.observations.map(\.text) + [LookBack.openingLine] {
                for word in banned {
                    #expect(!line.lowercased().contains(word), "\"\(line)\" contains \"\(word)\"")
                }
            }
        }
    }

    @Test("The same fortnight always reads the same way")
    func observationsAreDeterministic() {
        let history = [
            at(1, hour: 9, .pilates), at(2, hour: 9, .walking),
            at(3, hour: 9, .pilates), at(4, hour: 9, .walking)
        ]
        #expect(lookBack(history).observations == lookBack(history).observations)
    }
}
