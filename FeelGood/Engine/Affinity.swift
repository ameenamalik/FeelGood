//
//  Affinity.swift
//  FeelGood
//
//  Quiet, long-memory preference. The engine reads two affinity signals and
//  adds them: one derived from the last fourteen days of history, and this one,
//  a rolled-up score that outlives the window so "loved it" keeps counting long
//  after the log has scrolled past. See PRD §7.3.
//

import Foundation

nonisolated enum Affinity {

    /// The engine clamps the sum of both signals to this before scoring.
    static let range: ClosedRange<Double> = -1...1

    /// Deliberately smaller than the in-window deltas in `HistoryStats`: for
    /// the first fortnight both signals count the same event, and a single
    /// "loved it" should not pin a session to the top of every menu.
    static func delta(for outcome: HistoryOutcome) -> Double {
        switch outcome {
        case .completed(let feel):
            switch feel {
            case .lovedIt: 0.25
            case .fine: 0.05
            case .tooMuch: -0.25
            case .none: 0.02
            }
        // Turning something down is information, not a verdict. It moves the
        // needle a little so the same card stops arriving, and no further.
        case .swappedAway: -0.1
        // Skipping is not a judgement. It's a Tuesday.
        case .skipped: 0
        }
    }

    static func updated(_ score: Double, after outcome: HistoryOutcome) -> Double {
        min(max(score + delta(for: outcome), range.lowerBound), range.upperBound)
    }
}
