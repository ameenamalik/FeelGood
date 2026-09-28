//
//  BreathingNarrationService.swift
//  FeelGood
//
//  Plays the bundled narration clip for a breathing step, in step with the
//  paced orb PlayerView already drives. Narration is pre-generated offline
//  (see scripts/generate_narration.py) and resolved via ExerciseNarration —
//  this service only ever plays a local file. No network call, no API key,
//  on-device, same as every other external dependency in this app.
//

import AVFoundation
import Foundation

@MainActor
protocol BreathingNarrationPlaying: AnyObject {
    /// Starts a narration clip from the beginning. Replaces whatever was
    /// already playing, matching a fresh breathing cycle always starting
    /// its cue from the top.
    func play(narrationID: String)
    func pause()
    func resume()
    func stop()
}

/// No-op stand-in for previews, tests, and anyone without bundled narration —
/// playback is optional, never load-bearing for a session to run.
@MainActor
final class SilentNarrationService: BreathingNarrationPlaying {
    func play(narrationID: String) {}
    func pause() {}
    func resume() {}
    func stop() {}
}

@MainActor
final class AVAudioPlayerNarrationService: BreathingNarrationPlaying {
    static let shared = AVAudioPlayerNarrationService()

    private var player: AVAudioPlayer?

    func play(narrationID: String) {
        guard let url = ExerciseNarration.audioURL(for: narrationID) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
            self.player = player
        } catch {
            self.player = nil
        }
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        player?.play()
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
