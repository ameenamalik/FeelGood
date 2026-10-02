//
//  ExerciseNarrationTests.swift
//  FeelGoodTests
//

import Testing
import Foundation
import CryptoKit
@testable import FeelGood

@Suite("Exercise narration")
struct ExerciseNarrationTests {

    @Test("No narration id resolves to no URL")
    func nilIDResolvesToNil() {
        #expect(ExerciseNarration.audioURL(for: nil) == nil)
    }

    @Test("An id with nothing bundled resolves to no URL")
    func missingClipResolvesToNil() {
        #expect(ExerciseNarration.audioURL(for: "not-a-real-narration-id") == nil)
    }

    @Test("A bundled box-breathing clip resolves to a real file")
    func bundledClipResolves() {
        guard let url = ExerciseNarration.audioURL(for: "box-breathing-round-one") else {
            Issue.record("box-breathing-round-one.mp3 is not bundled — run scripts/generate_narration.py")
            return
        }
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test("Every narrationID referenced in the bundled catalog has a matching audio clip")
    func everyCatalogNarrationIDResolves() throws {
        let store = try ContentStore.bundled()
        var checked = Set<String>()
        for session in store.sessions {
            for step in session.source.steps {
                guard let narrationID = step.narrationID, !checked.contains(narrationID) else { continue }
                checked.insert(narrationID)
                let url = ExerciseNarration.audioURL(for: narrationID)
                #expect(url != nil, "\(session.id) references narrationID '\(narrationID)' with no bundled clip — run scripts/generate_narration.py")
            }
        }
        #expect(!checked.isEmpty, "No session in the bundled catalog references a narrationID — has the field been renamed?")
    }

    @Test("Every breathing step in the catalog has narration")
    func everyBreathingStepIsNarrated() throws {
        let store = try ContentStore.bundled()
        for session in store.sessions {
            for step in session.source.steps {
                let isBreathing = step.visual?.breathingCadence != nil || step.name.localizedCaseInsensitiveContains("breath")
                guard isBreathing else { continue }
                #expect(step.narrationID != nil, "\(session.id) step '\(step.name)' has no narrationID — add it to catalog.json and scripts/narration_scripts.json")
            }
        }
    }

    @Test("A step without narrationID decodes as silent")
    func stepWithoutNarrationIDDecodes() throws {
        let json = Data("""
        {"name": "Settle", "seconds": 20, "cue": "Let your shoulders drop."}
        """.utf8)
        let step = try JSONDecoder().decode(Step.self, from: json)
        #expect(step.narrationID == nil)
    }

    @Test("A step with narrationID decodes it")
    func stepWithNarrationIDDecodes() throws {
        let json = Data("""
        {"name": "Round one", "seconds": 32, "cue": "In for four.", "narrationID": "box-breathing-round-one"}
        """.utf8)
        let step = try JSONDecoder().decode(Step.self, from: json)
        #expect(step.narrationID == "box-breathing-round-one")
    }
    @Test("Recorded timing matches the exact bundled audio and its count pattern")
    func narrationTimingMatchesAudio() throws {
        for (id, timing) in BreathingNarrationTiming.all {
            let url = try #require(ExerciseNarration.audioURL(for: id))
            let data = try Data(contentsOf: url)
            let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            #expect(hash == timing.audioSHA256, "Realign timing after regenerating \(id)")
            #expect(timing.countTimes.count == timing.cadence.cycleSeconds + 1)
            #expect(zip(timing.countTimes, timing.countTimes.dropFirst()).allSatisfy { $1 > $0 })
        }
    }

}
