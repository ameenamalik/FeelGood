//
//  ExerciseNarration.swift
//  FeelGood
//
//  Bundled breathing-cue narration, keyed by `Step.narrationID`. Audio is
//  generated offline (see scripts/generate_narration.py) from the same cue
//  copy authored in catalog.json, then dropped into ExerciseNarration/ as a
//  plain `{id}.mp3` — never fetched at runtime. Adding narration is a file
//  drop, never a code change. See BreathingNarrationService for playback.
//

import Foundation

nonisolated enum ExerciseNarration {
    /// A bundled narration clip for a narration id, if one has been generated.
    static func audioURL(for narrationID: String?) -> URL? {
        guard let narrationID else { return nil }
        return Bundle.main.url(forResource: narrationID, withExtension: "mp3")
    }
}
