//
//  BreathingCoverageTests.swift
//  FeelGoodTests
//

import Foundation
import Testing
@testable import FeelGood

@Suite("Breathing animation coverage")
struct BreathingCoverageTests {
    /// A rest between two bursts, or a step about something else, is a plain
    /// card (see `recoveryGapsAreNotPaced`). Anything else named for
    /// breathing is breathing, and gets the orb.
    private static let restWords = ["rest", "recover", "break", "reset", "catch your", "set down", "splash"]

    private static func isRest(_ name: String) -> Bool {
        restWords.contains { name.localizedCaseInsensitiveContains($0) }
    }

    @Test("Every short step that is breathing shows the breathing orb")
    func breathingStepsHaveTheOrb() throws {
        let store = try ContentStore.bundled()
        var checked = 0
        for session in store.sessions {
            for step in session.source.steps {
                guard step.name.localizedCaseInsensitiveContains("breath"),
                      !Self.isRest(step.name),
                      step.seconds <= 180 else { continue }
                checked += 1
                #expect(step.visual?.breathingCadence != nil, "\(session.id) step '\(step.name)' has no breathing orb")
            }
        }
        #expect(checked > 10)
    }
}
