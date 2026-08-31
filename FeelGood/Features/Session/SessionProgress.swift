//
//  SessionProgress.swift
//  FeelGood
//
//  The small piece of state needed to continue an interrupted authored
//  session. Progress is not history: it never counts as movement completed.
//

import Foundation

nonisolated struct SessionProgress: Codable, Equatable, Sendable {
    let stepIndex: Int
    let remainingSeconds: Int
    let startedAt: Date
    let repsDone: Int
    let setsDone: Int

    init(
        stepIndex: Int,
        remainingSeconds: Int,
        startedAt: Date,
        repsDone: Int = 0,
        setsDone: Int = 0
    ) {
        self.stepIndex = stepIndex
        self.remainingSeconds = remainingSeconds
        self.startedAt = startedAt
        self.repsDone = repsDone
        self.setsDone = setsDone
    }

    private enum CodingKeys: String, CodingKey {
        case stepIndex, remainingSeconds, startedAt, repsDone, setsDone
    }

    /// `decodeIfPresent` keeps progress written before rep counting compatible.
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        stepIndex = try values.decode(Int.self, forKey: .stepIndex)
        remainingSeconds = try values.decode(Int.self, forKey: .remainingSeconds)
        startedAt = try values.decode(Date.self, forKey: .startedAt)
        repsDone = try values.decodeIfPresent(Int.self, forKey: .repsDone) ?? 0
        setsDone = try values.decodeIfPresent(Int.self, forKey: .setsDone) ?? 0
    }
}

@MainActor
protocol SessionProgressStoring: AnyObject {
    func progress(for sessionID: String) -> SessionProgress?
    func save(_ progress: SessionProgress, for sessionID: String)
    func clearProgress(for sessionID: String)
}

/// Kept outside SwiftData because it is transient player state, not part of
/// the workout history. UserDefaults lets a paused session survive relaunches
/// without pretending an unfinished workout happened.
@MainActor
final class UserDefaultsSessionProgressStore: SessionProgressStoring {
    private let defaults: UserDefaults
    private let key = "sessionProgress.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func progress(for sessionID: String) -> SessionProgress? {
        allProgress()[sessionID]
    }

    func save(_ progress: SessionProgress, for sessionID: String) {
        var progressBySession = allProgress()
        progressBySession[sessionID] = progress
        guard let data = try? JSONEncoder().encode(progressBySession) else { return }
        defaults.set(data, forKey: key)
    }

    func clearProgress(for sessionID: String) {
        var progressBySession = allProgress()
        progressBySession.removeValue(forKey: sessionID)
        guard let data = try? JSONEncoder().encode(progressBySession) else { return }
        defaults.set(data, forKey: key)
    }

    private func allProgress() -> [String: SessionProgress] {
        guard let data = defaults.data(forKey: key),
              let saved = try? JSONDecoder().decode([String: SessionProgress].self, from: data)
        else { return [:] }
        return saved
    }
}

/// Predictable storage for previews and tests.
@MainActor
final class InMemorySessionProgressStore: SessionProgressStoring {
    private(set) var progressBySession: [String: SessionProgress] = [:]

    func progress(for sessionID: String) -> SessionProgress? {
        progressBySession[sessionID]
    }

    func save(_ progress: SessionProgress, for sessionID: String) {
        progressBySession[sessionID] = progress
    }

    func clearProgress(for sessionID: String) {
        progressBySession.removeValue(forKey: sessionID)
    }
}
