//
//  EngagementAnalytics.swift
//  FeelGood
//
//  How people move through the app, and nothing about their body. Same
//  allow-list discipline as `CheckInAnalytics` and `RoutineAnalytics`: every
//  property is built here from ids and coarse state, so a call site cannot add
//  a check-in answer, a work-around, or message text by typing another key.
//

import Foundation

nonisolated enum EngagementAnalytics {
    static let swapUsedEvent = "swap_used"
    static let swapLimitReachedEvent = "swap_limit_reached"
    static let menuViewedEvent = "menu_viewed"
    static let tabViewedEvent = "tab_viewed"
    static let calendarAccessResultEvent = "calendar_access_result"
    static let aiConsentChangedEvent = "ai_consent_changed"

    static let swapUsedKeys: Set<String> = ["course", "is_pro"]
    static let swapLimitReachedKeys: Set<String> = ["course"]
    static let menuViewedKeys: Set<String> = ["item_count"]
    static let tabViewedKeys: Set<String> = ["tab"]
    static let calendarAccessResultKeys: Set<String> = ["result"]
    static let aiConsentChangedKeys: Set<String> = ["choice", "source"]

    /// The tabs by name. Kept here rather than reading the app's private
    /// `Destination` so the wire values do not change if that is renamed.
    enum Tab: String, Sendable, CaseIterable {
        case today, chat, you
    }

    enum CalendarResult: String, Sendable, CaseIterable {
        case connected, denied
    }

    enum ConsentSource: String, Sendable, CaseIterable {
        case sheet, settings
    }

    static func swapUsed(course: Course, isPro: Bool) -> [String: Any] {
        ["course": course.rawValue, "is_pro": isPro]
    }

    static func swapLimitReached(course: Course) -> [String: Any] {
        ["course": course.rawValue]
    }

    static func menuViewed(itemCount: Int) -> [String: Any] {
        ["item_count": itemCount]
    }

    static func tabViewed(_ tab: Tab) -> [String: Any] {
        ["tab": tab.rawValue]
    }

    static func calendarAccessResult(_ result: CalendarResult) -> [String: Any] {
        ["result": result.rawValue]
    }

    static func aiConsentChanged(granted: Bool, source: ConsentSource) -> [String: Any] {
        ["choice": granted ? "granted" : "declined", "source": source.rawValue]
    }
}
