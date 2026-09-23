//
//  RoutineAnalytics.swift
//  FeelGood
//
//  The wire shape of the events that touch a session's name. A routine's title
//  is text the person typed, and the privacy policy says analytics never
//  receives that, so these events carry ids and enums only. Built here, in one
//  place, so `AnalyticsPayloadTests` can assert on the keys and a title cannot
//  be added back at a call site without failing it.
//

import Foundation

nonisolated enum RoutineAnalytics {
    static let customRoutineKeys: Set<String> = ["activity", "duration", "course", "added_to_today"]
    static let sessionHiddenKeys: Set<String> = ["session_id"]

    static func customRoutineProperties(
        activity: String,
        durationMin: Int,
        course: String,
        addedToToday: Bool
    ) -> [String: Any] {
        [
            "activity": activity,
            "duration": durationMin,
            "course": course,
            "added_to_today": addedToToday
        ]
    }

    static func sessionHiddenProperties(sessionID: String) -> [String: Any] {
        ["session_id": sessionID]
    }
}
