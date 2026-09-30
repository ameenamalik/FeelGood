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
    /// Returns the clip duration only when playback starts successfully;
    /// `nil` means there is no audio to wait for (including when muted).
    @discardableResult
    func play(narrationID: String) -> TimeInterval?
    func pause()
    func resume()
    func stop()
    func playbackPosition(at date: Date) -> NarrationPlaybackPosition?
}

/// No-op stand-in for previews, tests, and anyone without bundled narration —
/// playback is optional, never load-bearing for a session to run.
@MainActor
final class SilentNarrationService: BreathingNarrationPlaying {
    var isMuted = false
    @discardableResult
    func play(narrationID: String) -> TimeInterval? { nil }
    func pause() {}
    func resume() {}
    func stop() {}
    func playbackPosition(at date: Date) -> NarrationPlaybackPosition? { nil }
}

@MainActor
final class AVAudioPlayerNarrationService: BreathingNarrationPlaying {
    static let shared = AVAudioPlayerNarrationService()

    private static let mutedDefaultsKey = "FeelGood.NarrationMuted"

    private var player: AVAudioPlayer?
    private var narrationID: String?
    private var completedAt: Date?
    private var pausedAt: Date?

    func playbackPosition(at date: Date) -> NarrationPlaybackPosition? {
        guard let player, let narrationID else { return nil }
        // AVAudioPlayer resets currentTime when playback finishes. Keep the
        // breathing clock advancing from the end instead of jumping to zero.
        if !player.isPlaying, pausedAt == nil, completedAt == nil {
            completedAt = date
        }
        let seconds: TimeInterval
        if let completedAt {
            seconds = player.duration + max((pausedAt ?? date).timeIntervalSince(completedAt), 0)
        } else {
            seconds = player.currentTime
        }
        return NarrationPlaybackPosition(narrationID: narrationID, seconds: seconds)
    }

    var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: Self.mutedDefaultsKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.mutedDefaultsKey)
            if newValue { stop() }
        }
    }

    @discardableResult
    func play(narrationID: String) -> TimeInterval? {
        stop()
        guard !isMuted, let url = ExerciseNarration.audioURL(for: narrationID) else { return nil }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            guard player.play() else { return nil }
            self.player = player
            self.narrationID = narrationID
            return player.duration
        } catch {
            self.player = nil
            return nil
        }
    }

    func pause() {
        guard pausedAt == nil else { return }
        let now = Date()
        _ = playbackPosition(at: now)
        pausedAt = now
        player?.pause()
    }

    func resume() {
        guard !isMuted, let pausedAt else { return }
        if let completedAt {
            self.completedAt = completedAt.addingTimeInterval(Date().timeIntervalSince(pausedAt))
        } else if player?.play() != true {
            stop()
        }
        self.pausedAt = nil
    }

    func stop() {
        player?.stop()
        player = nil
        narrationID = nil
        completedAt = nil
        pausedAt = nil
    }
}
