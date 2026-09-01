//
//  OwnSession.swift
//  FeelGood
//
//  Somebody's own workout, described in three taps and turned into a Session
//  the engine can score like any other. Everything the engine needs beyond
//  those three answers is inferred here rather than asked for — a form is not
//  a menu. See PRD §7.1.
//

import Foundation

nonisolated extension Activity {

    /// What this kind of movement develops. Used to place someone's own
    /// workout in the same quality balance as the authored catalog, so a week
    /// of their own lifting still reads as a week of strength.
    var typicalQualities: [Quality] {
        switch self {
        case .pilates: [.strength, .mobility]
        case .yoga: [.mobility, .balance]
        case .qigong: [.mobility, .balance]
        case .strength: [.strength]
        case .stretching: [.mobility]
        case .walking: [.endurance]
        case .biking: [.endurance]
        case .swimming: [.endurance]
        case .skating: [.coordination, .balance]
        case .dance: [.coordination]
        case .jumpRope: [.impact]
        case .agility: [.agility]
        case .carries: [.grip, .strength]
        case .racquet: [.agility, .coordination]
        case .climbing: [.strength, .grip]
        case .martialArts: [.coordination, .agility]
        case .breathwork: [.downRegulation]
        }
    }

    /// Where this kind of movement happens. Somebody who saves a swim should
    /// not be offered it on a day they have already decided to stay in.
    var impliedPlaces: Set<Place> {
        switch self {
        case .swimming: [.pool]
        case .biking, .walking, .racquet, .climbing, .skating: [.outdoors]
        case .strength, .carries: [.home, .gym]
        default: [.home]
        }
    }

    /// What this kind of movement can't happen without. Someone who saves a
    /// swim shouldn't be offered it on a day they have no pool.
    var impliedEquipment: Set<Equipment> {
        switch self {
        case .swimming: [.pool]
        case .biking: [.bike]
        case .skating: [.skates]
        case .jumpRope: [.rope]
        case .walking, .racquet, .climbing: [.outdoor]
        case .pilates, .yoga, .stretching: [.mat]
        default: []
        }
    }
}

nonisolated extension Session {

    /// A session built from what somebody says they did. Three answers —
    /// what, how long, how hard — and the rest follows from them.
    static func own(
        id: String,
        title: String,
        activity: Activity,
        durationMin: Int,
        intensity: Int
    ) -> Session {
        let qualities = activity.typicalQualities
        let intensity = min(max(intensity, 1), 5)
        return Session(
            id: id,
            title: title,
            subtitle: "Yours",
            activity: activity,
            qualities: qualities,
            durationMin: max(1, durationMin),
            intensity: intensity,
            energyFit: energyFit(for: intensity),
            equipment: Array(activity.impliedEquipment.sorted { $0.rawValue < $1.rawValue }),
            places: Array(activity.impliedPlaces.sorted { $0.rawValue < $1.rawValue }),
            bodyFocus: [.full],
            // The same safety rule the authored catalog holds to: anything
            // bouncy stays off the menu for someone who flagged pregnancy,
            // postpartum or their pelvic floor. It filters; it never explains.
            contraindications: qualities.contains(.impact) ? [.pregnancy, .postpartum, .pelvicFloor] : [],
            intents: intents(for: qualities),
            course: course(for: durationMin),
            source: .authored(steps: [])
        )
    }

    /// True for a session somebody logged themselves: there are no steps to
    /// play, because nobody wrote any.
    var isOwn: Bool { source.steps.isEmpty && !source.isVideo }

    private static func energyFit(for intensity: Int) -> [Energy] {
        switch intensity {
        case ...2: Energy.allCases
        case 3: [.steady, .strong]
        default: [.strong]
        }
    }

    private static func intents(for qualities: [Quality]) -> [Intent] {
        var intents: Set<Intent> = []
        for quality in qualities {
            switch quality {
            case .strength, .grip: intents.insert(.strengthen)
            case .mobility, .balance: intents.insert(.mobilize)
            case .endurance, .impact, .agility: intents.insert(.energize)
            case .coordination: intents.insert(.play)
            case .downRegulation: intents.insert(.calm)
            }
        }
        return intents.sorted { $0.rawValue < $1.rawValue }
    }

    /// Length decides the course. A twenty-minute thing is the day's main
    /// event; five minutes is something you put next to it.
    private static func course(for durationMin: Int) -> Course {
        switch durationMin {
        case ...5: .appetizer
        case ...10: .side
        default: .main
        }
    }
}
