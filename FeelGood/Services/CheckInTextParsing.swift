//
//  CheckInTextParsing.swift
//  FeelGood
//
//  Lets someone type how they're feeling instead of only tapping — but the
//  result only ever pre-fills `CheckInSheet`'s existing buttons, it never
//  writes anything itself. This file (and CheckInTextParser.swift) have no
//  dependency on the copy layer or on networking of any kind — enforced by
//  `CheckInTextParserPrivacyTests` in FeelGoodTests, which checks their
//  source directly — because raw check-in text can easily contain
//  reproductive-health disclosures ("I'm cramping", "I might be pregnant")
//  that CLAUDE.md says must never leave the device. Parsing it is fine and
//  expected; sending it anywhere is not, so this type structurally has no
//  way to.
//

import Foundation

/// What the parser is confident about. `nil` means "not mentioned/not
/// confident" — consumed exactly like an untapped `CheckInSheet` question
/// already is.
nonisolated struct ParsedCheckIn: Hashable, Sendable {
    var energy: Energy?
    var time: TimeBudget?
    var place: PlaceIntent?
    var body: BodyState?

    init(energy: Energy? = nil, time: TimeBudget? = nil, place: PlaceIntent? = nil, body: BodyState? = nil) {
        self.energy = energy
        self.time = time
        self.place = place
        self.body = body
    }
}

protocol CheckInTextParsing: Sendable {
    func parse(_ text: String) async -> ParsedCheckIn
}
