//
//  CheckInTextParserTests.swift
//  FeelGoodTests
//
//  `KeywordCheckInParser` is the deterministic, CI-runnable path — the model
//  path needs real Apple Intelligence hardware and is smoke-tested manually
//  only. The privacy suite below is the structural half of the same
//  guarantee `CopyPayloadTests` makes for the copy layer: raw check-in text
//  can legitimately mention reproductive health (a cramping or pregnancy
//  disclosure should still parse into `BodyState`), the constraint is only
//  that this file has no way to send any of it off the device.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Check-in text parser")
struct CheckInTextParserTests {
    private let parser = KeywordCheckInParser()

    struct Case {
        let text: String
        let energy: Energy?
        let time: TimeBudget?
        let place: PlaceIntent?
        let body: BodyState?
    }

    static let cases: [Case] = [
        // The PRD's own example sentence (§7.2): "a complete brief".
        Case(text: "twenty minutes, running on empty, staying in", energy: .low, time: .some, place: .stayingIn, body: nil),
        Case(text: "I've got a strong hour, happy to go to the gym", energy: .strong, time: .plenty, place: .atTheGym, body: nil),
        // A reproductive-health disclosure must still parse — the rule is
        // "never leaves the device", not "never recognized".
        Case(text: "I'm cramping today, not much time", energy: nil, time: .aLittle, place: nil, body: .cramping),
        Case(text: "feeling stiff and stressed, ten minutes", energy: nil, time: .aLittle, place: nil, body: .stiff),
        Case(text: "asdkjf qwoeiru nonsense", energy: nil, time: nil, place: nil, body: nil),
        Case(text: "", energy: nil, time: nil, place: nil, body: nil),
    ]

    @Test("Representative check-in sentences", arguments: cases)
    func parsesRepresentativeSentences(testCase: Case) async {
        let result = await parser.parse(testCase.text)

        #expect(result.energy == testCase.energy)
        #expect(result.time == testCase.time)
        #expect(result.place == testCase.place)
        #expect(result.body == testCase.body)
    }

    @Test("Gibberish and empty input never crash and resolve to all-nil")
    func gibberishIsSilentNoOp() async {
        let result = await parser.parse("asdkjf qwoeiru nonsense 🎲")
        #expect(result == ParsedCheckIn())
    }
}

/// Structural, `EngineBoundaryTests`-style: the check-in text parser has no
/// way to reach the network, checked directly against its own source rather
/// than trusted as a design intent. Mainly here to catch someone later
/// merging this parser with the copy layer by mistake.
@Suite("Check-in text parser privacy")
struct CheckInTextParserPrivacyTests {
    private static let forbiddenIdentifiers = ["URLSession", "URLRequest", "CopyPayload", "CopyProviding", "CopyTransport"]
    private static let files = ["CheckInTextParsing.swift", "CheckInTextParser.swift"]

    @Test("Neither file references networking or the copy layer", arguments: files)
    func noNetworkingReference(file: String) throws {
        let path = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // FeelGoodTests
            .deletingLastPathComponent()  // repository root
            .appending(path: "FeelGood/Services")
            .appending(path: file)

        let contents = try String(contentsOf: path, encoding: .utf8)

        for identifier in Self.forbiddenIdentifiers {
            #expect(
                !contents.contains(identifier),
                "\(file) references \(identifier). Free-text check-in parsing must stay entirely on-device — see CLAUDE.md."
            )
        }
    }
}
