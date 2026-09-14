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

/// One user-authored timed item inside a custom routine.
nonisolated struct CustomRoutinePart: Codable, Hashable, Sendable, Identifiable {
    let id: String
    var title: String
    var durationMin: Int

    init(id: String = UUID().uuidString, title: String, durationMin: Int) {
        self.id = id
        self.title = title
        self.durationMin = max(1, durationMin)
    }

    var step: Step {
        Step(name: title, seconds: durationMin * 60, cue: "Move at a pace that feels good.")
    }
}

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
        case .biking, .walking, .climbing, .skating: [.outdoors]
        case .racquet: []
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
        case .walking, .climbing: [.outdoor]
        case .racquet: []
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
        description: String? = nil,
        parts: [CustomRoutinePart] = [],
        activity: Activity = .stretching,
        durationMin: Int,
        intensity: Int,
        course: Course? = nil,
        equipment: [Equipment]? = nil
    ) -> Session {
        let qualities = activity.typicalQualities
        let intensity = min(max(intensity, 1), 5)
        let finalDuration = parts.isEmpty
            ? max(1, durationMin)
            : parts.reduce(0) { $0 + $1.durationMin }
        let finalCourse = course ?? Self.course(for: finalDuration)
        let subtitle = description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return Session(
            id: id,
            title: title,
            subtitle: subtitle,
            activity: activity,
            qualities: qualities,
            durationMin: finalDuration,
            intensity: intensity,
            energyFit: energyFit(for: intensity),
            equipment: equipment ?? Array(activity.impliedEquipment.sorted { $0.rawValue < $1.rawValue }),
            places: Array(activity.impliedPlaces.sorted { $0.rawValue < $1.rawValue }),
            bodyFocus: [.full],
            // The same safety rule the authored catalog holds to: anything
            // bouncy stays off the menu for someone who flagged pregnancy,
            // postpartum or their pelvic floor. It filters; it never explains.
            contraindications: qualities.contains(.impact) ? [.pregnancy, .postpartum, .pelvicFloor] : [],
            intents: intents(for: qualities),
            course: finalCourse,
            source: .custom(steps: parts.map(\.step))
        )
    }

    /// Ownership and playability are separate: a custom routine can contain
    /// timed steps and still remain editable by the person who made it.
    var isOwn: Bool {
        if case .custom = source { return true }
        return false
    }

    var customRoutineParts: [CustomRoutinePart] {
        guard case .custom(let steps) = source else { return [] }
        return steps.map { step in
            CustomRoutinePart(title: step.name, durationMin: max(1, Int(ceil(Double(step.seconds) / 60))))
        }
    }

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
