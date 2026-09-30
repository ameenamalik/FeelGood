//
//  BreathingCycleTests.swift
//  FeelGoodTests
//
//  The orb and its label share one clock; these pin down where that clock
//  says the breath is, so "Hold" can never show while the orb is moving.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Breathing cycle")
struct BreathingCycleTests {
    private let box = BreathingCadence(inhale: 4, holdIn: 4, exhale: 4, holdOut: 4)

    @Test("Box breathing walks through all four phases in order")
    func boxBreathingPhases() {
        #expect(BreathingCycleState.state(atSecond: 0, in: box).phase == .inhale)
        #expect(BreathingCycleState.state(atSecond: 3.9, in: box).phase == .inhale)
        #expect(BreathingCycleState.state(atSecond: 4, in: box).phase == .holdIn)
        #expect(BreathingCycleState.state(atSecond: 8, in: box).phase == .exhale)
        #expect(BreathingCycleState.state(atSecond: 12, in: box).phase == .holdOut)
        #expect(BreathingCycleState.state(atSecond: 15.9, in: box).phase == .holdOut)
    }

    @Test("The orb is still through a hold and moves through a breath")
    func holdsAreStill() {
        let fullAtStart = BreathingCycleState.state(atSecond: 4, in: box).scale
        let fullAtEnd = BreathingCycleState.state(atSecond: 7.9, in: box).scale
        #expect(fullAtStart == fullAtEnd)
        #expect(fullAtStart == 1)

        let emptyAtStart = BreathingCycleState.state(atSecond: 12, in: box).scale
        let emptyAtEnd = BreathingCycleState.state(atSecond: 15.9, in: box).scale
        #expect(emptyAtStart == emptyAtEnd)

        let midInhale = BreathingCycleState.state(atSecond: 2, in: box).scale
        #expect(midInhale > emptyAtStart && midInhale < fullAtStart)
    }

    @Test("A cadence with no holds skips straight from in to out")
    func defaultCadenceHasNoHold() {
        let cadence = BreathingCadence.default
        #expect(BreathingCycleState.state(atSecond: 3.99, in: cadence).phase == .inhale)
        #expect(BreathingCycleState.state(atSecond: 4, in: cadence).phase == .exhale)
        #expect(BreathingCycleState.state(atSecond: 9.99, in: cadence).phase == .exhale)
    }

    @Test("The clock wraps at the cycle length and freezes while paused")
    func clockWrapsAndFreezes() {
        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        let oneCycleLater = BreathingCycleState(
            at: start.addingTimeInterval(16), cadence: box, isActive: true,
            reduceMotion: false, startedAt: start, pausedAt: nil
        )
        #expect(oneCycleLater.phase == .inhale)

        let pausedAt = start.addingTimeInterval(5)
        let whilePaused = BreathingCycleState(
            at: start.addingTimeInterval(30), cadence: box, isActive: false,
            reduceMotion: false, startedAt: start, pausedAt: pausedAt
        )
        #expect(whilePaused.phase == .holdIn)
    }

    @Test("A step that hasn't started, or Reduce Motion, rests")
    func restsWhenNotBreathing() {
        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        let notStarted = BreathingCycleState(
            at: start.addingTimeInterval(6), cadence: box, isActive: false,
            reduceMotion: false, startedAt: start, pausedAt: nil
        )
        #expect(notStarted == .resting)

        let reduced = BreathingCycleState(
            at: start.addingTimeInterval(6), cadence: box, isActive: true,
            reduceMotion: true, startedAt: start, pausedAt: nil
        )
        #expect(reduced == .resting)
    }
    @Test("The recorded hold and exhale override the independent wall clock")
    func followsRecordedPhases() {
        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        for (second, expected): (Double, BreathingCycleState.Phase) in [
            (6.92, .holdIn), (10.36, .holdIn), (12.58, .exhale), (18.18, .holdOut)
        ] {
            let state = BreathingCycleState(
                at: start.addingTimeInterval(second), cadence: box, isActive: true,
                reduceMotion: false, startedAt: start, pausedAt: nil,
                narrationPosition: NarrationPlaybackPosition(narrationID: "box-breathing-round-one", seconds: second)
            )
            #expect(state.phase == expected)
        }
    }

    @Test("Every spoken count and phase shares the narration timeline")
    func recordedCounts() {
        for (id, timing) in BreathingNarrationTiming.all {
            for (index, time) in timing.countTimes.dropLast().enumerated() {
                let position = NarrationPlaybackPosition(narrationID: id, seconds: time)
                #expect(abs((position.breathingElapsed(for: timing.cadence) ?? -1) - Double(index)) < 0.001)
            }
        }
    }

    @Test("The final spoken cycle continues smoothly into silent breathing")
    func narrationHandoff() throws {
        let timing = try #require(BreathingNarrationTiming.all["slow-breaths-four-six"])
        let end = try #require(timing.countTimes.last)
        let before = BreathingCycleState.state(atSecond: timing.elapsed(at: end - 0.001), in: .default)
        let after = BreathingCycleState.state(atSecond: timing.elapsed(at: end + 0.001).truncatingRemainder(dividingBy: 10), in: .default)
        #expect(abs(before.scale - after.scale) < 0.001)
        #expect(before.phase == .exhale)
        #expect(after.phase == .inhale)
        #expect(abs(timing.elapsed(at: end + 2) - 12) < 0.001)
    }

    @Test("Paused narration freezes the visual even as wall time advances")
    func narrationPause() {
        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        let position = NarrationPlaybackPosition(narrationID: "box-breathing-round-one", seconds: 14)
        let first = BreathingCycleState(at: start.addingTimeInterval(14), cadence: box, isActive: true,
            reduceMotion: false, startedAt: start, pausedAt: nil, narrationPosition: position)
        let paused = BreathingCycleState(at: start.addingTimeInterval(40), cadence: box, isActive: false,
            reduceMotion: false, startedAt: start, pausedAt: start.addingTimeInterval(14), narrationPosition: position)
        #expect(first == paused)
    }

    @Test("Unknown narration keeps the normal breathing cadence")
    func unknownNarration() {
        let position = NarrationPlaybackPosition(narrationID: "missing", seconds: 100)
        #expect(position.breathingElapsed(for: box) == nil)
    }

}
