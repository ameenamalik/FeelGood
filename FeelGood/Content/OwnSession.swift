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
    var cue: String?

    init(id: String = UUID().uuidString, title: String, durationMin: Int, cue: String? = nil) {
        self.id = id
        self.title = title
        self.durationMin = max(1, durationMin)
        self.cue = cue
    }

    var step: Step {
        let finalCue: String
        if let cue, !cue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            finalCue = cue
        } else {
            finalCue = Self.defaultCue(for: title)
        }
        return Step(name: title, seconds: durationMin * 60, cue: finalCue)
    }

    /// The stand-in lines a step gets when nobody wrote one. They are not
    /// something the person said, so the editor shows an empty field instead
    /// of pretending they wrote it.
    static let fallbackCues: Set<String> = [
        "Take slow, steady breaths and stay present.",
        "Move with control and breathe steadily."
    ]

    private static func defaultCue(for title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("breath") || lower.contains("breathe") || lower.contains("settle") || lower.contains("pause") || lower.contains("rest") || lower.contains("still") {
            return "Take slow, steady breaths and stay present."
        }
        return "Move with control and breathe steadily."
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
        case .running: [.endurance, .impact]
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
        case .biking, .walking, .running, .climbing, .skating: [.outdoors]
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
        case .walking, .running, .climbing: [.outdoor]
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
            let cue = CustomRoutinePart.fallbackCues.contains(step.cue) ? nil : step.cue
            return CustomRoutinePart(title: step.name, durationMin: max(1, Int(ceil(Double(step.seconds) / 60))), cue: cue)
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

// MARK: - Matching typed steps to what the app can show

nonisolated extension Step {
    /// A step somebody typed themselves, matched to what the app already
    /// knows how to draw. Authored catalog steps are tagged by hand and are
    /// returned untouched; a custom part has no author to tag it, so its
    /// title is the only thing to go on. Applied when the routine is played,
    /// not when it is saved, so routines saved before this existed get the
    /// same treatment and a glossary that grows later is picked up for free.
    func inferringVisual(from glossary: [ExerciseTerm]) -> Step {
        guard glossaryID == nil, visual == nil else { return self }
        return Step(
            name: name,
            seconds: seconds,
            cue: cue,
            glossaryID: CustomStepMatcher.glossaryID(for: name, in: glossary),
            visual: CustomStepMatcher.breathingVisual(for: name),
            reps: reps,
            sets: sets,
            switchSides: switchSides,
            switchAfterSeconds: switchAfterSeconds
        )
    }
}

/// Pure string matching, kept out of the views so it can be tested with a
/// list of titles. Deliberately conservative: a wrong figure on the card is
/// worse than none, so a title has to contain a glossary name or alias as
/// whole words, and the longest such name wins ("knee push-ups" is the knee
/// version, not the plain one).
nonisolated enum CustomStepMatcher {
    static func glossaryID(for title: String, in glossary: [ExerciseTerm]) -> String? {
        let normalizedTitle = normalized(title)
        guard !normalizedTitle.isEmpty else { return nil }
        var best: (id: String, length: Int)?
        for term in glossary {
            for candidate in [term.name] + term.aka {
                let normalizedCandidate = normalized(candidate)
                guard !normalizedCandidate.isEmpty,
                      normalizedCandidate.count > (best?.length ?? 0),
                      contains(normalizedTitle, wholeWords: normalizedCandidate)
                else { continue }
                best = (term.id, normalizedCandidate.count)
            }
        }
        return best?.id
    }

    /// Box and square breathing are four-four-four-four; a named 4-7-8 is
    /// itself; anything else that mentions breath gets the resting default.
    static func breathingVisual(for title: String) -> StepVisual? {
        let normalizedTitle = normalized(title)
        if normalizedTitle.contains("box breath") || normalizedTitle.contains("square breath") {
            return .breathing(BreathingCadence(inhale: 4, holdIn: 4, exhale: 4, holdOut: 4))
        }
        if normalizedTitle.contains("4 7 8") {
            return .breathing(BreathingCadence(inhale: 4, holdIn: 7, exhale: 8, holdOut: 0))
        }
        let breathWords = ["breath", "pranayama", "inhale", "exhale"]
        if breathWords.contains(where: normalizedTitle.contains) {
            return .breathing(.default)
        }
        return nil
    }

    /// Lowercased, letters and digits only, single spaces. "Knee Push-Ups
    /// (Right)" becomes "knee push ups right".
    static func normalized(_ text: String) -> String {
        let lowered = text.lowercased()
        let kept = lowered.map { $0.isLetter || $0.isNumber ? $0 : " " }
        return String(kept)
            .split(separator: " ", omittingEmptySubsequences: true)
            .joined(separator: " ")
    }

    /// Whole-word containment, forgiving a plural on the candidate's last
    /// word so "push ups" still finds "push up".
    private static func contains(_ title: String, wholeWords candidate: String) -> Bool {
        let padded = " \(title) "
        return padded.contains(" \(candidate) ")
            || padded.contains(" \(candidate)s ")
            || padded.contains(" \(candidate)es ")
    }
}
