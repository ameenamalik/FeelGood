//
//  BreathingNarrationService.swift
//  FeelGood
//
//  Plays the bundled narration clip for a session step — the breathing cues
//  and, now, the setup/settle/close steps around them — in step with
//  PlayerView's own timing. Narration is pre-generated offline (see
//  scripts/generate_narration.py) and resolved via ExerciseNarration — this
//  service only ever plays a local file. No network call, no API key,
//  on-device, same as every other external dependency in this app.
//

import AVFoundation
import Foundation

@MainActor
protocol BreathingNarrationPlaying: AnyObject {
    /// Persisted across launches: once someone mutes narration, it stays
    /// muted until they turn it back on, not just for the current session.
    /// Setting this to `true` stops whatever is currently playing.
    var isMuted: Bool { get set }

    /// Starts a narration clip from the beginning. Replaces whatever was
    /// already playing, matching a fresh step always starting its cue from
    /// the top. A no-op while `isMuted` is `true`.
    func play(narrationID: String)
    func pause()
    func resume()
    func stop()
}

/// No-op stand-in for previews, tests, and anyone without bundled narration —
/// playback is optional, never load-bearing for a session to run.
@MainActor
final class SilentNarrationService: BreathingNarrationPlaying {
    var isMuted = false
    func play(narrationID: String) {}
    func pause() {}
    func resume() {}
    func stop() {}
}

@MainActor
final class AVAudioPlayerNarrationService: BreathingNarrationPlaying {
    static let shared = AVAudioPlayerNarrationService()

    private static let mutedDefaultsKey = "FeelGood.NarrationMuted"

    private var player: AVAudioPlayer?

    var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: Self.mutedDefaultsKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.mutedDefaultsKey)
            if newValue { stop() }
        }
    }

    func play(narrationID: String) {
        guard !isMuted, let url = ExerciseNarration.audioURL(for: narrationID) else { return }
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
        guard !isMuted else { return }
        player?.play()
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
