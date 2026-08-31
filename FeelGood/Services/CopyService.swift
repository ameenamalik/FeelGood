//
//  CopyService.swift
//  FeelGood
//
//  Talks to the copy Worker (PRD §11) to upgrade `Menu.headline` in place.
//  `CopyPayload` is already the allow-list; this is the layer that sends it
//  and comes back with nothing when anything at all goes wrong. Offline,
//  timeout, not-entitled, rate-limited, a malformed body — every one of
//  those collapses to `nil` here, because the caller has exactly one
//  fallback for all of them: the deterministic template copy that already
//  rendered.
//

import Foundation

/// The copy layer, seen from `TodayModel`. Builds the payload (and threads
/// `subscriberID`) internally, so nothing above `Services/` ever constructs
/// a `CopyPayload` or touches the install id itself.
nonisolated protocol CopyProviding: Sendable {
    func upgradedHeadline(menu: Menu, checkIn: PlanCheckIn, stats: HistoryStats) async -> String?
}

/// The network boundary underneath `CopyService`, pulled out so caching and
/// timeout/fallback behaviour is testable without a real request.
nonisolated protocol CopyTransport: Sendable {
    func fetchLine(payload: CopyPayload, timeout: TimeInterval) async throws -> String
}

/// `POST`s to the Worker and decodes `{ "line": "..." }`.
nonisolated struct URLSessionCopyTransport: CopyTransport {
    func fetchLine(payload: CopyPayload, timeout: TimeInterval) async throws -> String {
        guard let copyURL = WorkerConstants.copyURL else {
            throw CopyTransportError.notConfigured
        }
        var request = URLRequest(url: copyURL)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw CopyTransportError.badResponse
        }

        let decoded = try JSONDecoder().decode(CopyResponse.self, from: data)
        let line = decoded.line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { throw CopyTransportError.emptyLine }
        return line
    }

    private struct CopyResponse: Decodable {
        let line: String
    }

    private enum CopyTransportError: Error {
        case notConfigured
        case badResponse
        case emptyLine
    }
}

/// The real, injectable `CopyProviding`. An `actor` rather than `@MainActor`:
/// this is a non-UI service (CLAUDE.md's isolation rule), and the actor gives
/// the in-memory cache thread-safe access without opting into the main queue.
///
/// Cache is per-`CopyPayload` (already `Hashable`), in-memory, and reset on
/// relaunch — the menu changes only a handful of times a day, so identical
/// state not re-billing *within a session* is the only guarantee worth the
/// complexity here.
///
/// PRD §10: this line is a Pro feature ("Warm, written-for-you coaching
/// voice"). The Worker already checks entitlement server-side before
/// generating anything; this check is fresh on every call rather than once
/// at construction, so a purchase mid-session starts producing upgraded
/// copy without needing a relaunch.
actor CopyService: CopyProviding {
    private let transport: any CopyTransport
    private let timeout: TimeInterval
    private let isProUnlocked: @Sendable () async -> Bool
    private let subscriberID: @Sendable () async -> String
    private var cache: [CopyPayload: String] = [:]

    init(
        transport: any CopyTransport = URLSessionCopyTransport(),
        timeout: TimeInterval = WorkerConstants.requestTimeout,
        isProUnlocked: @escaping @Sendable () async -> Bool = { await PurchasesManager.shared.isProUnlocked },
        subscriberID: @escaping @Sendable () async -> String = { await PurchasesManager.shared.appUserID }
    ) {
        self.transport = transport
        self.timeout = timeout
        self.isProUnlocked = isProUnlocked
        self.subscriberID = subscriberID
    }

    func upgradedHeadline(menu: Menu, checkIn: PlanCheckIn, stats: HistoryStats) async -> String? {
        guard await isProUnlocked() else { return nil }

        let payload = CopyPayload(menu: menu, checkIn: checkIn, stats: stats, subscriberID: await subscriberID())

        if let cached = cache[payload] {
            return cached
        }

        guard let line = try? await transport.fetchLine(payload: payload, timeout: timeout) else {
            return nil
        }

        cache[payload] = line
        return line
    }
}

/// Fake for previews and for anything (like `TodayModel`'s default init
/// parameter) that needs a `CopyProviding` without a network dependency.
nonisolated struct InMemoryCopyService: CopyProviding {
    var line: String?

    init(line: String? = nil) {
        self.line = line
    }

    func upgradedHeadline(menu: Menu, checkIn: PlanCheckIn, stats: HistoryStats) async -> String? {
        line
    }
}
