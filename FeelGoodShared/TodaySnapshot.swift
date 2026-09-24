//
//  TodaySnapshot.swift
//  FeelGood — shared by the app and the widget
//
//  The widget does not plan anything and does not open the store. The app has
//  already decided today's menu; this is a flat copy of the lines worth
//  putting on a home screen, written to the shared container.
//
//  Deliberately free of `Session`, `Course`, and the design system, so the
//  widget target compiles against sixty lines instead of the whole app. The
//  accent arrives as a number for the same reason: the app knows which colour
//  a course is, so the widget never has to.
//

import Foundation

/// One session worth mentioning on a home screen.
nonisolated struct TodayItem: Codable, Hashable, Sendable {
    /// Which session this is, so tapping the widget opens *this* one rather
    /// than dropping the reader on the menu to find it again.
    var sessionID: String
    var courseLabel: String
    var accentHex: UInt32
    var title: String
    var reason: String
    var durationLabel: String
    var isDone: Bool
}

/// The whole of today's menu, in menu order. The widget rotates through it
/// through the day, one item an hour, so it reads as a nudge rather than a list.
nonisolated struct TodaySnapshot: Codable, Hashable, Sendable {
    /// Start of the local day this describes, so a stale snapshot is obvious.
    var day: Date
    var items: [TodayItem]

    /// Whether this still describes the day being asked about.
    func isCurrent(on date: Date, calendar: Calendar) -> Bool {
        calendar.isDate(day, inSameDayAs: date)
    }

    /// What to show at `hour` (0–23). Things not yet done come first, and the
    /// pick is a pure function of the hour, so a re-render never reshuffles it.
    /// Once everything is done the rotation carries on through all of it: a
    /// finished day still gets a warm line, not a blank.
    func item(atHour hour: Int) -> TodayItem? {
        let open = items.filter { !$0.isDone }
        let pool = open.isEmpty ? items : open
        guard !pool.isEmpty else { return nil }
        return pool[hour % pool.count]
    }
}

/// How the widget should look, taken from the person's profile.
///
/// Kept apart from `TodaySnapshot` on purpose: the snapshot is a day's
/// suggestion and is thrown away when the day turns over, whereas a fruit is a
/// standing choice that should still be on the home screen when there is
/// nothing to suggest. Raw strings rather than the app's enums so the widget
/// never links the design system; an unknown value falls back rather than fails.
nonisolated struct WidgetAppearance: Codable, Hashable, Sendable {
    /// `ProfileAvatar.rawValue`.
    var avatarRaw: String
    /// The aura already resolved (`automatic` applied), e.g. `"apricot"`, so the
    /// widget does not have to know each fruit's default colour.
    var auraRaw: String

    static let fallback = WidgetAppearance(avatarRaw: "apple", auraRaw: "apricot")
}

/// The app group both targets share. Changing this is an entitlements change
/// in two places, not just here.
nonisolated enum SharedContainer {
    static let appGroup = "group.com.ameenamalik.FeelGood"

    private static func fileURL(_ name: String) -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appending(path: name)
    }

    private static func write<Value: Encodable>(_ value: Value, to name: String) {
        guard let url = fileURL(name), let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private static func read<Value: Decodable>(_ type: Value.Type, from name: String) -> Value? {
        guard let url = fileURL(name), let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    /// Best effort in both directions. A widget with nothing to show falls back
    /// to an invitation, and a failed write costs the home screen a refresh —
    /// neither is worth taking the app down for.
    static func writeSnapshot(_ snapshot: TodaySnapshot) { write(snapshot, to: "today.json") }
    static func readSnapshot() -> TodaySnapshot? { read(TodaySnapshot.self, from: "today.json") }

    static func writeAppearance(_ appearance: WidgetAppearance) { write(appearance, to: "appearance.json") }
    static func readAppearance() -> WidgetAppearance? { read(WidgetAppearance.self, from: "appearance.json") }

    /// The look the app is wearing right now, already resolved (an unearned
    /// choice has been replaced by Kiln). Its own file, apart from the avatar,
    /// because it changes for different reasons and is written from elsewhere.
    static func writeTheme(_ theme: FGThemeID) { write(theme, to: "theme.json") }
    static func readTheme() -> FGThemeID? { read(FGThemeID.self, from: "theme.json") }
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
