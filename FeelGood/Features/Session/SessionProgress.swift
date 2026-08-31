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
