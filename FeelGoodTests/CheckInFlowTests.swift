//
//  CheckInFlowTests.swift
//  FeelGoodTests
//
//  The check-in advances itself, so the rule that decides *when* is the only
//  thing standing between someone and being carried past a question they were
//  trying to un-answer.
//

import Testing
@testable import FeelGood

@Suite("Check-in flow")
struct CheckInFlowTests {

    @Test("Answering a question moves on to the next one")
    func answeringAdvances() {
        #expect(CheckInFlow.next(after: 0, didAnswer: true) == 1)
        #expect(CheckInFlow.next(after: 1, didAnswer: true) == 2)
        #expect(CheckInFlow.next(after: 2, didAnswer: true) == 3)
    }

    @Test("The last question does not advance — there is nowhere to go")
    func lastStepStaysPut() {
        #expect(CheckInFlow.next(after: CheckInFlow.lastStep, didAnswer: true) == nil)
    }

    @Test("Taking an answer back leaves you on the question")
    func clearingDoesNotAdvance() {
        // The optional questions toggle: tapping the selected option clears it.
        // Being moved on from that would read as the app deciding you meant
        // something you had just said you didn't.
        for step in 0..<CheckInFlow.stepCount {
            #expect(CheckInFlow.next(after: step, didAnswer: false) == nil)
        }
    }

    @Test("A step outside the flow never produces a destination")
    func outOfRangeIsRefused() {
        #expect(CheckInFlow.next(after: -1, didAnswer: true) == nil)
        #expect(CheckInFlow.next(after: CheckInFlow.stepCount, didAnswer: true) == nil)
        #expect(CheckInFlow.next(after: 99, didAnswer: true) == nil)
    }

    @Test("Advancing from the first question reaches the last in one pass")
    func theWholeFlowIsWalkable() {
        var step = 0
        var visited = [step]

        while let next = CheckInFlow.next(after: step, didAnswer: true) {
            step = next
            visited.append(step)
        }

        #expect(visited == [0, 1, 2, 3])
        #expect(step == CheckInFlow.lastStep)
    }
}
