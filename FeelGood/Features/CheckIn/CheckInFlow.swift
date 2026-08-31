//
//  CheckInFlow.swift
//  FeelGood
//
//  Where the check-in goes after a tap, as a pure function of where it was.
//
//  Small enough to have lived inside `CheckInSheet`, and it did — but the rule
//  it encodes is the one that decides whether someone can be carried past a
//  question they were trying to un-answer, and that deserves a test rather than
//  a careful reading of a view body.
//

import Foundation

nonisolated enum CheckInFlow {
    /// Energy, time, place, body.
    static let stepCount = 4

    static var lastStep: Int { stepCount - 1 }

    /// The step a tap should land on, or `nil` to stay where it is.
    ///
    /// `didAnswer` is false when the tap *cleared* an answer rather than giving
    /// one — tapping the option you already picked takes it back. Moving on
    /// from that would read as the app deciding you meant something, so it
    /// stays put.
    static func next(after origin: Int, didAnswer: Bool) -> Int? {
        guard didAnswer else { return nil }
        guard (0..<lastStep).contains(origin) else { return nil }
        return origin + 1
    }
}
