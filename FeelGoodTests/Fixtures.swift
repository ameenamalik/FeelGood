//
//  Fixtures.swift
//  FeelGoodTests
//
//  A small, deterministic catalog and a fixed clock. Nothing here reads the
//  system date or timezone, so every test asserts on one exact menu.
//

import Foundation
@testable import FeelGood

enum Fixture {

    // MARK: - Clock

    static var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    /// 2026-08-20 09:00 UTC — a Thursday morning.
    static let now = Date(timeIntervalSince1970: 1_787_216_400)

    /// `daysAgo(1)` is yesterday, same time of day.
    static func daysAgo(_ days: Int) -> Date {
        utc.date(byAdding: .day, value: -days, to: now)!
    }

    static func context(
        isOffline: Bool = false,
        dataSaver: Bool = false,
        specials: [ScheduledSpecial] = [],
        calendar: Calendar? = nil
    ) -> PlanContext {
        PlanContext(
            now: now,
            isOffline: isOffline,
            dataSaver: dataSaver,
            scheduledSpecials: specials,
            calendar: calendar ?? utc
        )
    }

    // MARK: - Profile

    /// Someone with a mat, some weights, and the outdoors. Breathwork and
    /// carries are deliberately absent: onboarding never asks about them, so a
    /// realistic profile never names them.
    static func profile(
        activities: Set<Activity> = [.pilates, .walking, .strength, .stretching, .dance],
        equipment: Set<Equipment> = [.none, .mat, .weights, .outdoor],
        places: Set<Place> = [.home, .outdoors, .gym],
        cadence: Cadence = .mostDays,
        moments: MovementMoments = .aCouple,
        realisticMinutes: Int = 30,
        bestTimeOfDay: TimeOfDay = .varies,
        intent: Intent = .strengthen,
        workArounds: Set<WorkAround> = []
    ) -> PlanProfile {
        PlanProfile(
            availableActivities: activities,
            equipment: equipment,
            places: places,
            cadence: cadence,
            moments: moments,
            realisticMinutes: realisticMinutes,
            bestTimeOfDay: bestTimeOfDay,
            intent: intent,
            workArounds: workArounds
        )
    }

    // MARK: - History

    static func completed(
        _ sessionID: String,
        activity: Activity,
        qualities: [Quality] = [.strength],
        intensity: Int = 3,
        course: Course = .main,
        daysAgo days: Int,
        feel: Feel? = nil
    ) -> HistoryEntry {
        HistoryEntry(
            sessionID: sessionID,
            activity: activity,
            qualities: qualities,
            intensity: intensity,
            course: course,
            date: daysAgo(days),
            outcome: .completed(feel: feel)
        )
    }

    // MARK: - Catalog

    static func session(
        id: String,
        activity: Activity,
        qualities: [Quality],
        durationMin: Int,
        intensity: Int,
        course: Course,
        equipment: [Equipment] = [.none],
        places: [Place] = [.home],
        energyFit: [Energy] = Energy.allCases,
        intents: [Intent] = [.strengthen],
        contraindications: [WorkAround] = [],
        video: Bool = false
    ) -> Session {
        Session(
            id: id,
            title: id,
            subtitle: "",
            activity: activity,
            qualities: qualities,
            durationMin: durationMin,
            intensity: intensity,
            energyFit: energyFit,
            equipment: equipment,
            places: places,
            bodyFocus: [.full],
            contraindications: contraindications,
            intents: intents,
            course: course,
            source: video
                ? .youtube(videoID: "vid-\(id)", channel: "Test Channel")
                : .authored(steps: [Step(name: "Move", seconds: durationMin * 60, cue: "Go")])
        )
    }

    /// Ids are prefixed by course so the alphabetical tie-break stays readable.
    static let catalog: [Session] = [
        // Appetizers. `a-breath` needs nothing and is safe for everyone — it is
        // the guaranteed fallback the engine leans on.
        session(id: "a-breath", activity: .breathwork, qualities: [.downRegulation],
                durationMin: 2, intensity: 1, course: .appetizer, intents: [.calm]),
        session(id: "a-jump", activity: .jumpRope, qualities: [.impact],
                durationMin: 2, intensity: 3, course: .appetizer, equipment: [.rope],
                energyFit: [.steady, .strong], intents: [.energize],
                contraindications: [.pregnancy, .postpartum, .pelvicFloor, .knees]),
        session(id: "a-stretch", activity: .stretching, qualities: [.mobility],
                durationMin: 4, intensity: 1, course: .appetizer, intents: [.mobilize]),

        // Mains.
        session(id: "m-pilates-10", activity: .pilates, qualities: [.strength, .mobility],
                durationMin: 10, intensity: 2, course: .main, equipment: [.mat]),
        session(id: "m-pilates-30", activity: .pilates, qualities: [.strength],
                durationMin: 30, intensity: 3, course: .main, equipment: [.mat],
                energyFit: [.steady, .strong]),
        session(id: "m-strength-30", activity: .strength, qualities: [.strength, .grip],
                durationMin: 30, intensity: 4, course: .main, equipment: [.weights],
                places: [.home, .gym], energyFit: [.strong]),
        session(id: "m-video-20", activity: .pilates, qualities: [.strength],
                durationMin: 20, intensity: 3, course: .main, equipment: [.mat],
                energyFit: [.steady, .strong], video: true),
        session(id: "m-walk-20", activity: .walking, qualities: [.endurance],
                durationMin: 20, intensity: 2, course: .main, equipment: [.outdoor],
                places: [.outdoors], intents: [.energize, .calm]),

        // Sides.
        session(id: "s-carry", activity: .carries, qualities: [.grip],
                durationMin: 5, intensity: 2, course: .side),
        session(id: "s-stretch", activity: .stretching, qualities: [.mobility],
                durationMin: 5, intensity: 1, course: .side, intents: [.mobilize]),

        // Dessert.
        session(id: "d-dance", activity: .dance, qualities: [.coordination],
                durationMin: 10, intensity: 2, course: .dessert, intents: [.joy]),

        // Special — needs a pool, and is planned ahead rather than picked today.
        session(id: "sp-swim", activity: .swimming, qualities: [.endurance],
                durationMin: 45, intensity: 3, course: .special, equipment: [.pool],
                places: [.pool], energyFit: [.steady, .strong], intents: [.energize]),
    ]

    static var engine: PlanEngine { PlanEngine(catalog: catalog) }
}
