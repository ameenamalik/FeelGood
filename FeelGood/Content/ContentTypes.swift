//
//  ContentTypes.swift
//  FeelGood
//
//  The content schema. Sessions are data, not code — everything here is
//  Codable so the bundled catalog can later be delivered remotely without
//  a rebuild. See PRD §6.
//

import Foundation

// MARK: - Vocabulary

/// What you do. Answers "what is this session".
nonisolated enum Activity: String, Codable, CaseIterable, Sendable {
    case pilates, yoga, qigong, strength, stretching, walking, biking, swimming
    case skating, dance, jumpRope, agility, carries, racquet, climbing, martialArts
    case breathwork

    /// Some movement is a genuine question of access — a pool, a bike, a pair
    /// of skates, somewhere to be outside. The rest needs nothing but a body
    /// and a floor, so asking about it up front turns a menu into a quiz and
    /// makes someone recognise a word like "carries" before they have seen a
    /// single session. These never appear in onboarding. The engine reaches
    /// for them on merit instead — qi gong on a stressed evening, carries when
    /// the intent is strength — and the equipment filter still decides whether
    /// any individual session is on the table.
    var isAlwaysAvailable: Bool {
        switch self {
        case .qigong, .breathwork, .carries, .agility: true
        default: false
        }
    }
}

/// What it develops. The cross-cutting dimension the engine balances across.
/// Never surfaced to the user as a taxonomy — only ever as one small line.
nonisolated enum Quality: String, Codable, CaseIterable, Sendable {
    case strength, mobility, endurance, impact, agility, coordination, grip
    case balance, downRegulation
}

/// Used both for a session's fit and for today's check-in answer.
nonisolated enum Energy: String, Codable, CaseIterable, Sendable {
    case low, steady, strong
}

nonisolated enum Equipment: String, Codable, CaseIterable, Sendable {
    case none, mat, weights, band, rope, bike, pool, skates, outdoor, gym, reformer

    /// A membership is one tick that stands in for a room full of kit. Ticking
    /// it should not also require ticking weights, a band and a mat to describe
    /// the same building. A pool is deliberately not included — plenty of gyms
    /// don't have one, and a session that can't happen is worse than one that
    /// was never offered.
    var impliedEquipment: Set<Equipment> {
        switch self {
        case .gym: [.mat, .weights, .band, .bike]
        default: []
        }
    }

    /// What the room is for. Someone who has a gym has somewhere to lift,
    /// whether or not they thought to also tick "Strength".
    var impliedActivities: Set<Activity> {
        switch self {
        case .gym: [.strength]
        case .weights: [.strength]
        default: []
        }
    }
}

nonisolated enum BodyFocus: String, Codable, CaseIterable, Sendable {
    case full, core, lowerBody, upperBody, back, hips, neckShoulders
}

/// Things to work around. Tagged on a session as "do not surface if flagged",
/// and on a profile as "I flagged this". Filters, never diagnoses.
nonisolated enum WorkAround: String, Codable, CaseIterable, Sendable {
    case pregnancy, postpartum, pelvicFloor, knees, wrists, lowBack, fatigue
}

nonisolated enum Intent: String, Codable, CaseIterable, Sendable {
    case energize, strengthen, calm, mobilize, joy
}

/// The menu metaphor. See PRD §3.
nonisolated enum Course: String, Codable, CaseIterable, Sendable {
    case appetizer, main, side, dessert, special
}

// MARK: - Session

/// Attribution for a session. Stays `nil` for all v1 content — nothing in the
/// app may state or imply that a real person wrote, taught, or endorsed a
/// session until that is confirmed in writing. See PRD §6.
nonisolated struct Creator: Codable, Hashable, Sendable {
    let name: String
    let channelURL: URL
}

/// One step inside an authored micro-session.
nonisolated struct Step: Codable, Hashable, Sendable {
    let name: String
    let seconds: Int
    let cue: String
    /// Resolves to an `ExerciseTerm`. `nil` means no "what's this?" affordance.
    let glossaryID: String?

    init(name: String, seconds: Int, cue: String, glossaryID: String? = nil) {
        self.name = name
        self.seconds = seconds
        self.cue = cue
        self.glossaryID = glossaryID
    }
}

/// Where the movement comes from. Authored sessions carry the offline path;
/// video sessions require a connection and can never sit behind the paywall.
nonisolated enum SessionSource: Codable, Hashable, Sendable {
    case authored(steps: [Step])
    case youtube(videoID: String, channel: String)

    var isVideo: Bool {
        if case .youtube = self { return true }
        return false
    }

    var steps: [Step] {
        if case .authored(let steps) = self { return steps }
        return []
    }

    // Hand-authored JSON stays readable with an explicit discriminator rather
    // than Swift's synthesised single-key-per-case shape.
    private enum CodingKeys: String, CodingKey { case type, steps, videoID, channel }
    private enum Kind: String, Codable { case authored, youtube }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(Kind.self, forKey: .type) {
        case .authored:
            self = .authored(steps: try c.decode([Step].self, forKey: .steps))
        case .youtube:
            self = .youtube(
                videoID: try c.decode(String.self, forKey: .videoID),
                channel: try c.decode(String.self, forKey: .channel)
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .authored(let steps):
            try c.encode(Kind.authored, forKey: .type)
            try c.encode(steps, forKey: .steps)
        case .youtube(let videoID, let channel):
            try c.encode(Kind.youtube, forKey: .type)
            try c.encode(videoID, forKey: .videoID)
            try c.encode(channel, forKey: .channel)
        }
    }
}

/// Every recommendation is a Session — one unit, two possible sources.
nonisolated struct Session: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let activity: Activity
    let qualities: [Quality]
    let durationMin: Int
    /// 1...5
    let intensity: Int
    let energyFit: [Energy]
    let equipment: [Equipment]
    let bodyFocus: [BodyFocus]
    let contraindications: [WorkAround]
    let intents: [Intent]
    let course: Course
    let source: SessionSource
    let attribution: Creator?

    private enum CodingKeys: String, CodingKey {
        case id, title, subtitle, activity, qualities, durationMin, intensity
        case energyFit, equipment, bodyFocus, contraindications, intents, course
        case source, attribution
    }

    /// Hand-written and later remote-delivered, so optional collections decode
    /// as empty rather than failing the whole catalog.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        subtitle = try c.decode(String.self, forKey: .subtitle)
        activity = try c.decode(Activity.self, forKey: .activity)
        qualities = try c.decodeIfPresent([Quality].self, forKey: .qualities) ?? []
        durationMin = try c.decode(Int.self, forKey: .durationMin)
        intensity = try c.decode(Int.self, forKey: .intensity)
        energyFit = try c.decodeIfPresent([Energy].self, forKey: .energyFit) ?? Energy.allCases
        equipment = try c.decodeIfPresent([Equipment].self, forKey: .equipment) ?? [.none]
        bodyFocus = try c.decodeIfPresent([BodyFocus].self, forKey: .bodyFocus) ?? [.full]
        contraindications = try c.decodeIfPresent([WorkAround].self, forKey: .contraindications) ?? []
        intents = try c.decodeIfPresent([Intent].self, forKey: .intents) ?? []
        course = try c.decode(Course.self, forKey: .course)
        source = try c.decode(SessionSource.self, forKey: .source)
        attribution = try c.decodeIfPresent(Creator.self, forKey: .attribution)
    }

    /// Needs nothing but a body and a floor — the sessions that can always be
    /// offered no matter what the profile says.
    var needsNoEquipment: Bool {
        equipment.isEmpty || equipment == [.none]
    }

    init(
        id: String,
        title: String,
        subtitle: String,
        activity: Activity,
        qualities: [Quality],
        durationMin: Int,
        intensity: Int,
        energyFit: [Energy],
        equipment: [Equipment],
        bodyFocus: [BodyFocus],
        contraindications: [WorkAround] = [],
        intents: [Intent],
        course: Course,
        source: SessionSource,
        attribution: Creator? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.activity = activity
        self.qualities = qualities
        self.durationMin = durationMin
        self.intensity = intensity
        self.energyFit = energyFit
        self.equipment = equipment
        self.bodyFocus = bodyFocus
        self.contraindications = contraindications
        self.intents = intents
        self.course = course
        self.source = source
        self.attribution = attribution
    }
}

// MARK: - Glossary

/// Public-domain movement glossary, text only. Reachable only from a step
/// inside a session already in progress — never browsable. See PRD §6.
nonisolated struct ExerciseTerm: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let name: String
    let aka: [String]
    /// Plain steps. Gym taxonomy (`beginner`/`compound`/`pull`) never reaches
    /// the screen and is not modelled here on purpose.
    let instructions: [String]
    /// Plain language, not muscle-chart names.
    let muscles: [String]
}

// MARK: - Catalog

/// The bundled catalog, versioned so a later remote drop can supersede it.
nonisolated struct ContentCatalog: Codable, Sendable {
    let version: Int
    let sessions: [Session]
    let glossary: [ExerciseTerm]
}
