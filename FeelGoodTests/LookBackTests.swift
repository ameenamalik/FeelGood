//
//  LookBackTests.swift
//  FeelGoodTests
//
//  The Look Back's job is to be true and kind at the same time. Most of these
//  tests are really about the second half: what it must never say.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Look Back")
struct LookBackTests {

    private func reflect(_ history: [HistoryEntry]) -> Reflection {
        LookBack.reflect(history: history, context: Fixture.context())
    }

    /// Morning fixture times are 09:00 UTC; these shift a completion's hour.
    private func at(hour: Int, daysAgo days: Int) -> Date {
        let base = Fixture.daysAgo(days)
        return Fixture.utc.date(bySettingHour: hour, minute: 0, second: 0, of: base)!
    }

    private func completed(
        _ id: String,
        _ activity: Activity,
        daysAgo days: Int,
        hour: Int = 9,
        intensity: Int = 3,
        feel: Feel? = nil
    ) -> HistoryEntry {
        HistoryEntry(
            sessionID: id,
            activity: activity,
            qualities: [.strength],
            intensity: intensity,
            course: .main,
            date: at(hour: hour, daysAgo: days),
            outcome: .completed(feel: feel)
        )
    }

    // MARK: Nothing yet

    @Test("With no history at all there is nothing to say, and it says nothing")
    func emptyHistoryIsEarlyNotZero() {
        let reflection = reflect([])
        #expect(reflection.isEarly)
        #expect(reflection.notes.isEmpty)
    }

    @Test("A swapped-away session is not a completion and never becomes one")
    func swapsAreNotMovement() {
        let swapped = HistoryEntry(
            sessionID: "a", activity: .pilates, qualities: [], intensity: 3,
            course: .main, date: Fixture.daysAgo(1), outcome: .swappedAway
        )
        #expect(reflect([swapped]).isEarly)
    }

    @Test("Anything older than the window is simply not in view")
    func historyOutsideTheWindowIsIgnored() {
        let old = completed("a", .pilates, daysAgo: PlanEngine.historyWindowDays + 1)
        #expect(reflect([old]).isEarly)
    }

    // MARK: Counting

    @Test("One session reads as 'once', not as '1 times'")
    func singleCompletionReadsAsOnce() throws {
        let reflection = reflect([completed("a", .pilates, daysAgo: 1)])
        let first = try #require(reflection.notes.first)
        #expect(first == .moved(times: 1))
        #expect(first.line == "You've moved once in the last two weeks.")
    }

    @Test("The count is always the opening note")
    func countLeads() throws {
        let history = (1...4).map { completed("s\($0)", .pilates, daysAgo: $0) }
        let first = try #require(reflect(history).notes.first)
        #expect(first == .moved(times: 4))
    }

    // MARK: Patterns need evidence

    @Test("Two sessions are not a pattern, so no pattern is claimed")
    func twoSessionsClaimNoPattern() {
        let history = [
            completed("a", .pilates, daysAgo: 1, hour: 8),
            completed("b", .pilates, daysAgo: 2, hour: 8),
        ]
        let notes = reflect(history).notes
        #expect(notes == [.moved(times: 2)])
    }

    @Test("A dominant time of day is named once there is enough of it")
    func namesTheDominantTimeOfDay() {
        let history = [
            completed("a", .pilates, daysAgo: 1, hour: 7),
            completed("b", .walking, daysAgo: 2, hour: 8),
            completed("c", .yoga, daysAgo: 3, hour: 9),
        ]
        #expect(reflect(history).notes.contains(.mostly(.morning)))
    }

    @Test("An even three-way split has no 'mostly', so none is invented")
    func noDominantTimeOfDayMeansNoClaim() {
        let history = [
            completed("a", .pilates, daysAgo: 1, hour: 8),
            completed("b", .walking, daysAgo: 2, hour: 14),
            completed("c", .yoga, daysAgo: 3, hour: 20),
        ]
        let mentionsTime = reflect(history).notes.contains { if case .mostly = $0 { true } else { false } }
        #expect(!mentionsTime)
    }

    @Test("One activity that carries the majority is named alone")
    func namesASingleDominantActivity() {
        let history = [
            completed("a", .pilates, daysAgo: 1),
            completed("b", .pilates, daysAgo: 2),
            completed("c", .walking, daysAgo: 3),
        ]
        #expect(reflect(history).notes.contains(.activities([.pilates])))
    }

    @Test("When no single activity carries it, two are named — never three")
    func namesAtMostTwoActivities() throws {
        let history = [
            completed("a", .pilates, daysAgo: 1),
            completed("b", .walking, daysAgo: 2),
            completed("c", .yoga, daysAgo: 3),
            completed("d", .dance, daysAgo: 4),
        ]
        let note = try #require(reflect(history).notes.first { if case .activities = $0 { true } else { false } })
        guard case .activities(let named) = note else { return }
        #expect(named.count == 2)
    }

    // MARK: What gets loved

    @Test("The loved activity is named when it is not already the busiest one")
    func namesWhatSheKeepsReturningTo() {
        let history = [
            completed("a", .pilates, daysAgo: 1),
            completed("b", .pilates, daysAgo: 2),
            completed("c", .pilates, daysAgo: 3),
            completed("d", .stretching, daysAgo: 4, feel: .lovedIt),
            completed("e", .stretching, daysAgo: 5, feel: .lovedIt),
        ]
        #expect(reflect(history).notes.contains(.keepsReturningTo(.stretching)))
    }

    @Test("The same activity is never named twice in one reflection")
    func neverSaysTheSameThingTwice() {
        let history = (1...4).map { completed("s\($0)", .pilates, daysAgo: $0, feel: .lovedIt) }
        let notes = reflect(history).notes
        #expect(notes.contains(.activities([.pilates])))
        #expect(!notes.contains(.keepsReturningTo(.pilates)))
    }

    @Test("One loved session is affection, not a habit worth naming")
    func oneLovedSessionIsNotAPattern() {
        let history = [
            completed("a", .pilates, daysAgo: 1),
            completed("b", .pilates, daysAgo: 2),
            completed("c", .pilates, daysAgo: 3),
            completed("d", .stretching, daysAgo: 4, feel: .lovedIt),
        ]
        let returning = reflect(history).notes.contains { if case .keepsReturningTo = $0 { true } else { false } }
        #expect(!returning)
    }

    @Test("Rest is counted as showing up")
    func restfulSessionsAreMovementToo() {
        let history = [
            completed("a", .breathwork, daysAgo: 1, intensity: 1),
            completed("b", .stretching, daysAgo: 2, intensity: 2),
        ]
        #expect(reflect(history).notes.contains(.madeRoomForRest))
    }

    // MARK: What it must never do

    @Test("No note ever mentions a gap, a miss, a streak, or a score")
    func neverShamesAcrossEveryShape() {
        // A deliberately patchy fortnight: one session, then a long silence.
        let sparse = [completed("a", .pilates, daysAgo: 13)]
        let dense = (1...10).map { completed("s\($0)", .pilates, daysAgo: $0) }
        let mixed = [
            completed("a", .pilates, daysAgo: 1, feel: .tooMuch),
            completed("b", .walking, daysAgo: 9),
            HistoryEntry(sessionID: "c", activity: .yoga, qualities: [], intensity: 3,
                         course: .main, date: Fixture.daysAgo(2), outcome: .swappedAway),
        ]

        let forbidden = ["miss", "gap", "streak", "score", "behind", "fail",
                         "should", "only", "but ", "goal", "target"]
        for history in [sparse, dense, mixed] {
            for note in reflect(history).notes {
                let line = note.line.lowercased()
                for word in forbidden {
                    #expect(!line.contains(word), "\"\(note.line)\" contains \"\(word)\"")
                }
                // A zero is checked structurally rather than by substring: "10
                // times" contains a zero and is a perfectly kind sentence.
                #expect(note != .moved(times: 0))
            }
        }
    }

    @Test("Every note produces a non-empty sentence that ends in a full stop")
    func everyNoteIsASentence() {
        let all: [Reflection.Note] = [
            .moved(times: 1), .moved(times: 7),
            .mostly(.morning), .mostly(.midday), .mostly(.evening), .mostly(.varies),
            .activities([.pilates]), .activities([.pilates, .walking]),
            .keepsReturningTo(.stretching), .madeRoomForRest,
        ]
        for note in all {
            #expect(!note.line.isEmpty)
            #expect(note.line.hasSuffix("."), "\(note.line)")
        }
    }

    @Test("Every activity has a mid-sentence name and none of them shout")
    func everyActivityReadsInASentence() {
        for activity in Activity.allCases {
            let name = activity.lookBackName
            #expect(!name.isEmpty)
            #expect(name != name.uppercased(), "\(name) is shouting")
        }
    }

    @Test("Reflecting never crashes and never claims more than it knows")
    func neverFailsAcrossTheHistoryMatrix() {
        for count in 0...12 {
            for hour in [6, 13, 21] {
                let history = (0..<count).map {
                    completed("s\($0)", Activity.allCases[$0 % Activity.allCases.count],
                              daysAgo: $0, hour: hour)
                }
                let reflection = reflect(history)
                #expect(reflection.isEarly == (count == 0))
                if count > 0 {
                    #expect(reflection.notes.first == .moved(times: count))
                }
                if count < LookBack.minimumForPattern {
                    let claimsPattern = reflection.notes.contains {
                        switch $0 {
                        case .mostly, .activities: true
                        default: false
                        }
                    }
                    #expect(!claimsPattern, "claimed a pattern from \(count) session(s)")
                }
            }
        }
    }
}
