import Foundation

/// Measured word onsets in the bundled recordings, not an assumed TTS speed.
/// Each entry is a spoken count (including the phase cue as count one),
/// followed by the end of the final count. Regenerated audio must be realigned;
/// the audio hashes are checked by ExerciseNarrationTests. Source word timings
/// are retained in artifacts/breathing-narration/word-timestamps.json.
nonisolated struct BreathingNarrationTiming: Sendable {
    let cadence: BreathingCadence
    let countTimes: [TimeInterval]
    let audioSHA256: String

    /// Converts the recording's playback position to the shared breathing clock.
    /// After its counted pattern, continue the authored cadence without a jump.
    func elapsed(at audioTime: TimeInterval) -> TimeInterval {
        guard let start = countTimes.first, let end = countTimes.last else { return 0 }
        if audioTime < start { return 0 }
        if audioTime >= end { return Double(cadence.cycleSeconds) + audioTime - end }
        for index in 0..<(countTimes.count - 1) {
            let next = countTimes[index + 1]
            if audioTime < next {
                return Double(index) + (audioTime - countTimes[index]) / (next - countTimes[index])
            }
        }
        return 0
    }

    private static let box = BreathingCadence(inhale: 4, holdIn: 4, exhale: 4, holdOut: 4)
    static let all: [String: Self] = [
        "box-breathing-round-one": Self(cadence: box, countTimes: [0.96, 2.32, 4.7, 5.5, 6.92, 9.12, 10.36, 11.6, 12.58, 13.98, 15.58, 16.86, 18.18, 19.84, 20.92, 22.74, 23.59], audioSHA256: "ce2c18fb31def83d15640ef3b5345098b31d2d39f1e5b94a35079736d8d3f8e2"),
        "box-breathing-round-two": Self(cadence: box, countTimes: [0.0, 1.04, 3.0, 3.72, 5.38, 6.46, 8.24, 9.6, 11.18, 13.16, 14.64, 16.22, 18.04, 19.12, 20.76, 22.54, 23.33], audioSHA256: "019dd0412993ede95cc8cccbb22c46dfb5e4ba46e8a8a4509895cf5ccad68898"),
        "box-breathing-round-three": Self(cadence: box, countTimes: [0.0, 0.9, 2.48, 3.52, 4.4, 6.02, 6.98, 8.08, 9.3, 10.86, 12.36, 13.2, 14.62, 16.36, 17.18, 18.2, 19.31], audioSHA256: "0ff71c1427368a23a84ae13ad5c4ef612772d51811d79c81847246813c271ba6"),
        "box-breathing-round-four": Self(cadence: box, countTimes: [0.0, 0.9, 2.88, 4.02, 5.06, 6.92, 8.46, 8.9, 10.48, 12.28, 13.82, 14.98, 16.02, 17.8, 19.1, 20.3, 21.45], audioSHA256: "895e9138432a8ad1cc4176078037192d21a099849829726a3b2bbaba2e2288e9"),
        "barefoot-breathing-box": Self(cadence: box, countTimes: [1.2, 2.76, 3.82, 5.04, 7.26, 8.64, 9.26, 10.64, 12.72, 14.58, 15.24, 16.64, 18.56, 20.22, 20.9, 22.56, 23.41], audioSHA256: "74794ab083c4ea567083e9c5e73d67609d7fc03f958181b50838362611bb5e90"),
        "legs-up-the-wall-breathe": Self(cadence: .default, countTimes: [2.6, 3.66, 5.9, 7.56, 9.46, 10.36, 12.36, 14.42, 16.22, 17.84, 19.49], audioSHA256: "92e3a8b39a5222f3a903572f5d72f624d559e52e9e36807f415fb073f0e89f2c"),
        "slow-breaths-four-six": Self(cadence: .default, countTimes: [0.0, 1.52, 3.48, 5.04, 6.36, 8.14, 11.58, 12.72, 15.46, 17.92, 18.51], audioSHA256: "459709b5bd4b5cd6827e7036130a8c5fb2376ff2be9afadbe8220abe806c5e11"),
        "rest-box-breathing-settle": Self(cadence: box, countTimes: [0.0, 0.76, 3.08, 4.14, 4.78, 7.28, 8.42, 9.6, 10.68, 12.84, 14.52, 15.46, 17.34, 19.12, 20.36, 21.84, 23.39], audioSHA256: "d782467c2b48956fd389cac208ef574e5dc219df4cc553ba63d6b27415d57c61"),
    ]
}

nonisolated struct NarrationPlaybackPosition: Sendable {
    let narrationID: String
    let seconds: TimeInterval

    func breathingElapsed(for cadence: BreathingCadence) -> TimeInterval? {
        guard let timing = BreathingNarrationTiming.all[narrationID], timing.cadence == cadence else { return nil }
        return timing.elapsed(at: seconds)
    }
}
