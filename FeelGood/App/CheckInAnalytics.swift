//
//  CheckInAnalytics.swift
//  FeelGood
//
//  Everything a check-in is ever allowed to report, and nothing else.
//
//  The same allow-list-as-a-type that `CopyPayload` is for the copy proxy,
//  applied to the analytics channel. `check_in_completed` used to be built as
//  a dictionary literal at the call site, which meant the rule "`body` never
//  ships" lived in a comment: adding `"body": body_?.rawValue` would have
//  compiled, shipped, and quietly made the PRD §11 claim false.
//
//  So there is nowhere to put it. `body` is an initialiser parameter with no
//  stored home — `cramping` is reproductive health data, it is load-bearing
//  for the engine and worth nothing to a funnel, and adding a field for it
//  here would have to be a deliberate act that `AnalyticsPayloadTests` then
//  fails on.
//
//  What does travel is coarse state — energy, time, place — which is exactly
//  what `Analytics.log`'s allow-list already permits and what makes the event
//  answerable at all.
//

import Foundation

nonisolated struct CheckInAnalytics: Sendable {
    let energy: Energy?
    let time: TimeBudget?
    let place: PlaceIntent?
    /// Whether the body question was answered — never which answer. Sending
    /// the value "except when it's cramping" would make the absence itself the
    /// disclosure, so it is all or nothing, and this is nothing.
    let hasBody: Bool
    /// Whether any question was answered at all. Distinguishes a real check-in
    /// from someone tapping straight through "Skip".
    let hasCheckIn: Bool

    /// `body` is taken and dropped, the same shape `CopyPayload.init` uses for
    /// the `checkIn` it never stores.
    init(energy: Energy?, time: TimeBudget?, place: PlaceIntent?, body: BodyState?) {
        self.energy = energy
        self.time = time
        self.place = place
        hasBody = body != nil
        hasCheckIn = energy != nil || time != nil || place != nil || body != nil
    }

    /// Multi-select variant. The set is intentionally reduced to a boolean;
    /// no individual body concern is sent to analytics.
    init(energy: Energy?, time: TimeBudget?, place: PlaceIntent?, bodies: Set<BodyState>) {
        self.energy = energy
        self.time = time
        self.place = place
        hasBody = !bodies.isEmpty
        hasCheckIn = energy != nil || time != nil || place != nil || !bodies.isEmpty
    }

    /// The event name this payload belongs to, next to the payload rather than
    /// spelled out at the call site.
    static let eventName = "check_in_completed"

    /// The wire shape, declared in one place so the test can assert on it.
    ///
    /// Skipped questions are omitted rather than sent as null, so a property
    /// value in PostHog is always an answer somebody actually gave.
    var properties: [String: Any] {
        var properties: [String: Any] = [
            "has_check_in": hasCheckIn,
            "has_body": hasBody
        ]
        if let energy { properties["energy"] = energy.rawValue }
        if let time { properties["time"] = time.rawValue }
        if let place { properties["place"] = place.rawValue }
        return properties
    }
}
