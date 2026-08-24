//
//  TodaySnapshot.swift
//  FeelGood — shared by the app and the widget
//
//  The widget does not plan anything and does not open the store. The app has
//  already decided today's menu; this is a flat copy of the one line worth
//  putting on a home screen, written to the shared container.
//
//  Deliberately free of `Session`, `Course`, and the design system, so the
//  widget target compiles against sixty lines instead of the whole app. The
//  accent arrives as a number for the same reason: the app knows which colour
//  a course is, so the widget never has to.
//

import Foundation

nonisolated struct TodaySnapshot: Codable, Hashable, Sendable {
    /// Start of the local day this describes, so a stale snapshot is obvious.
    var day: Date
    /// Which session this is, so tapping the widget opens *this* one rather
    /// than dropping the reader on the menu to find it again.
    var sessionID: String
    var courseLabel: String
    var accentHex: UInt32
    var title: String
    var reason: String
    var durationLabel: String
    var isDone: Bool

    /// Whether this still describes the day being asked about.
    func isCurrent(on date: Date, calendar: Calendar) -> Bool {
        calendar.isDate(day, inSameDayAs: date)
    }
}

/// The app group both targets share. Changing this is an entitlements change
/// in two places, not just here.
nonisolated enum SharedContainer {
    static let appGroup = "group.com.ameenamalik.FeelGood"

    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appending(path: "today.json")
    }

    /// Best effort in both directions. A widget with nothing to show falls back
    /// to an invitation, and a failed write costs the home screen a refresh —
    /// neither is worth taking the app down for.
    static func writeSnapshot(_ snapshot: TodaySnapshot) {
        guard let fileURL, let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    static func readSnapshot() -> TodaySnapshot? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(TodaySnapshot.self, from: data)
    }
}

/// The one URL shape the widget and the app both have to agree on.
///
/// Lives here rather than in either target, because a scheme that only one
/// side knows about is a link that silently does nothing.
nonisolated enum DeepLink {
    static let scheme = "feelgood"

    /// `feelgood://session/main-pilates-core-20`
    static func session(_ id: String) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "session"
        components.path = "/" + id
        return components.url
    }

    /// The session id in a link, or `nil` if this isn't one of ours.
    static func sessionID(from url: URL) -> String? {
        guard url.scheme == scheme, url.host == "session" else { return nil }
        let id = url.path.trimmingPrefix("/")
        return id.isEmpty ? nil : String(id)
    }
}
