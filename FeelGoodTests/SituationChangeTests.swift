//
//  SituationChangeTests.swift
//  FeelGoodTests
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Situation change")
struct SituationChangeTests {
    private func answers() -> ProfileAnswers {
        var a = ProfileAnswers()
        a.realisticMinutes = 30
        a.intents = [.strengthen]
        a.workArounds = [.knees]
        return a
    }

    @Test("Pain adds the chosen areas and keeps what was there")
    func painAddsAreas() {
        let result = SituationChange.pain([.lowBack]).applied(to: answers())
        #expect(result.workArounds == [.knees, .lowBack])
        #expect(result.realisticMinutes == 30)
    }

    @Test("Pain ignores anything that is not a body area")
    func painIgnoresOtherFlags() {
        let result = SituationChange.pain([.pregnancy]).applied(to: answers())
        #expect(result.workArounds == [.knees])
    }

    @Test("Less capacity shortens sessions and flags fatigue, never lengthening them")
    func lessCapacity() {
        let result = SituationChange.lessCapacity.applied(to: answers())
        #expect(result.realisticMinutes == SituationChange.reducedMinutes)
        #expect(result.workArounds.contains(.fatigue))

        var short = answers()
        short.realisticMinutes = 5
        #expect(SituationChange.lessCapacity.applied(to: short).realisticMinutes == 5)
    }

    @Test("A new goal replaces what the person is moving toward")
    func newGoal() {
        let result = SituationChange.newGoal([.calm, .joy]).applied(to: answers())
        #expect(result.intents == [.calm, .joy])
    }

    @Test("A change with nothing chosen is not valid")
    func validity() {
        #expect(!SituationChange.pain([]).isValid)
        #expect(!SituationChange.newGoal([]).isValid)
        #expect(SituationChange.lessCapacity.isValid)
        #expect(SituationChange.pain([.hips]).isValid)
    }

    @Test("Reverting restores only the fields the change touched")
    func revertIsScoped() {
        let before = answers()
        let change = SituationChange.pain([.lowBack])
        let revert = AdjustmentRevert(before: before, change: change)

        var edited = change.applied(to: before)
        edited.realisticMinutes = 45 // changed elsewhere meanwhile
        let restored = revert.restoring(into: edited)

        #expect(restored.workArounds == [.knees])
        #expect(restored.realisticMinutes == 45)
    }

    @Test("A second temporary change keeps the original values")
    func mergingKeepsOriginals() {
        let first = AdjustmentRevert(workArounds: ["knees"])
        let second = AdjustmentRevert(workArounds: ["knees", "lowBack"], realisticMinutes: 30)
        let merged = first.merging(second)
        #expect(merged.workArounds == ["knees"])
        #expect(merged.realisticMinutes == 30)
    }

    @Test("A permanent change takes over its fields from a pending revert")
    func droppingFields() {
        let pending = AdjustmentRevert(workArounds: ["knees"], realisticMinutes: 30)
        let rest = pending.dropping(fieldsTouchedBy: .pain([.hips]))
        #expect(rest == AdjustmentRevert(realisticMinutes: 30))
        #expect(AdjustmentRevert(workArounds: ["knees"]).dropping(fieldsTouchedBy: .pain([.hips])) == nil)
    }

    @Test("The revert survives encoding")
    func roundTrip() {
        let revert = AdjustmentRevert(workArounds: ["knees"], realisticMinutes: 20, intents: ["calm"])
        #expect(AdjustmentRevert.decode(revert.encoded()) == revert)
        #expect(AdjustmentRevert.decode(nil) == nil)
    }
}

@Suite("Profile adjustment lifecycle")
struct ProfileAdjustmentTests {
    private let calendar = Fixture.utc

    private func profile() -> UserProfile {
        var a = ProfileAnswers()
        a.realisticMinutes = 30
        a.intents = [.strengthen]
        return UserProfile(answers: a, now: Fixture.now)
    }

    @Test("A temporary change is due after two weeks, and not before")
    func dueAfterTwoWeeks() {
        let p = profile()
        p.adjust(.lessCapacity, temporary: true, now: Fixture.now, calendar: calendar)

        #expect(p.answers.realisticMinutes == SituationChange.reducedMinutes)
        #expect(!p.isAdjustmentDue(now: Fixture.now))
        #expect(!p.isAdjustmentDue(now: calendar.date(byAdding: .day, value: 13, to: Fixture.now)!))
        #expect(p.isAdjustmentDue(now: calendar.date(byAdding: .day, value: 14, to: Fixture.now)!))
    }

    @Test("Going back restores the profile and clears the question")
    func revert() {
        let p = profile()
        p.adjust(.newGoal([.calm]), temporary: true, now: Fixture.now, calendar: calendar)
        #expect(p.answers.intents == [.calm])

        p.revertAdjustment(now: Fixture.now)
        #expect(p.answers.intents == [.strengthen])
        #expect(p.adjustmentRevertData == nil)
        #expect(p.adjustmentRevertAt == nil)
    }

    @Test("Keeping it leaves the change and clears the question")
    func keep() {
        let p = profile()
        p.adjust(.newGoal([.calm]), temporary: true, now: Fixture.now, calendar: calendar)
        p.keepAdjustment()
        #expect(p.answers.intents == [.calm])
        #expect(!p.isAdjustmentDue(now: .distantFuture))
    }

    @Test("A permanent change never asks to go back")
    func permanent() {
        let p = profile()
        p.adjust(.pain([.knees]), temporary: false, now: Fixture.now, calendar: calendar)
        #expect(p.answers.workArounds.contains(.knees))
        #expect(p.adjustmentRevertData == nil)
        #expect(!p.isAdjustmentDue(now: .distantFuture))
    }
}
