//
//  CopyPayload.swift
//  FeelGood
//
//  Everything that is ever allowed to leave the device, and nothing else.
//
//  This is an allow-list expressed as a type. The point is not that the call
//  site remembers to strip `body` and `workArounds` — call sites forget. The
//  point is that there is nowhere to put them: `cramping`, `pregnancy`,
//  `postpartum` and `pelvicFloor` are reproductive health data, they are
//  load-bearing for the engine and worthless to a layer writing one warm
//  sentence, and adding a field for them here would have to be a deliberate
//  act that `CopyPayloadTests` then fails on. See PRD §11.
//

import Foundation

/// The request body for the copy proxy. Coarse by construction.
nonisolated struct CopyPayload: Codable, Hashable, Sendable {
    /// Session ids the engine already chose. The model is told what was
    /// picked; it never picks.
    let picks: [String]
    /// Why the engine chose them, machine-readable. None of the seven cases
    /// encodes a work-around — they are applied as a filter upstream and never
    /// surface as a reason, which is what keeps this channel clean by
    /// construction rather than by redaction.
    let reasonCodes: [ReasonCode]
    let energy: Energy
    let time: TimeBudget
    /// `nil` on a first run or after the history window. Coarse on purpose: a
    /// count of days, never a date, never the sessions themselves.
    let daysSinceLast: Int?
    /// RevenueCat's own app user id, which is the only id the Worker can
    /// actually look a subscriber up by. Before Apple Sign In this is
    /// RevenueCat's anonymous id; after it, the Apple user id — an opaque
    /// Apple-issued string, never an email or a name. It already goes to
    /// RevenueCat; this sends it to our own Worker as well, which is the
    /// deliberate cost of a server-side entitlement check.
    ///
    /// Read from RevenueCat rather than generated here. A locally generated id
    /// is what the previous version sent, and RevenueCat had never heard of it
    /// — every lookup 404'd and every user was silently refused.
    let subscriberID: String

    /// The wire shape, declared in one place so the test can assert on it.
    enum CodingKeys: String, CodingKey {
        case picks, reasonCodes, energy, time, daysSinceLast, subscriberID
    }

    /// `checkIn` carries `body` and the profile carries `workArounds`; neither
    /// is a parameter here, and neither has a home on this type. Reads
    /// `HistoryStats` for the gap rather than recomputing it, so there is only
    /// ever one definition of "days since last".
    init(menu: Menu, checkIn: PlanCheckIn, stats: HistoryStats, subscriberID: String) {
        picks = menu.items.map(\.session.id)
        // `Menu` already defines "unique reasons in menu order". Reusing it
        // rather than repeating it here keeps one definition.
        reasonCodes = menu.reasonCodes
        energy = checkIn.energy
        time = checkIn.time
        daysSinceLast = stats.daysSinceLastCompleted
        self.subscriberID = subscriberID
    }
}
