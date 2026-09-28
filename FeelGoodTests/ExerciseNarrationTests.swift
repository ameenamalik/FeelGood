//
//  ExerciseNarrationTests.swift
//  FeelGoodTests
//

import Testing
import Foundation
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
}
