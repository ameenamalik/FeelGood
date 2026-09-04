//
//  Display.swift
//  FeelGood
//
//  How the vocabulary is spoken out loud. The taxonomy stays behind the glass —
//  you see a menu, never a data model.
//

import Foundation

nonisolated extension Course {
    /// The menu metaphor is user-facing; the rest of the schema is not.
    var label: String {
        switch self {
        case .appetizer: "Appetizer"
        case .main: "Main"
        case .side: "Side"
        case .dessert: "Dessert"
        case .special: "Special"
        }
    }
}

nonisolated extension Activity {
    var label: String {
        switch self {
        case .pilates: "Pilates"
        case .yoga: "Yoga"
        case .qigong: "Qi gong"
        case .strength: "Strength"
        case .stretching: "Stretching"
        case .walking: "Walking"
        case .biking: "Biking"
        case .swimming: "Swimming"
        case .skating: "Skating"
        case .dance: "Dance"
        case .jumpRope: "Jump rope"
        case .agility: "Footwork"
        case .carries: "Carries"
        case .racquet: "Racquet"
        case .climbing: "Climbing"
        case .martialArts: "Martial arts"
        case .breathwork: "Breathwork"
        }
    }
}

nonisolated extension Equipment {
    /// `nil` for things that aren't worth saying out loud.
    var label: String? {
        switch self {
        case .none: nil
        case .mat: "Mat"
        case .weights: "Weights"
        case .band: "Band"
        case .rope: "Rope"
        case .bike: "Bike"
        case .pool: "Pool"
        case .skates: "Skates"
        case .outdoor: "Outside"
        case .gym: "Gym"
        case .reformer: "Reformer"
        }
    }
}

nonisolated extension BodyFocus {
    var label: String {
        switch self {
        case .full: "Full Body"
        case .core: "Core"
        case .lowerBody: "Lower Body"
        case .upperBody: "Upper Body"
        case .back: "Spine & Back"
        case .hips: "Hips"
        case .neckShoulders: "Neck & Shoulders"
        }
    }
}

nonisolated extension Session {
    var durationLabel: String { "\(durationMin) min" }

    /// What the session targets — e.g. "Spine & Hips", "Neck & Shoulders", "Full Body".
    var targetLabel: String {
        let titleAndSubtitle = "\(title) \(subtitle)".lowercased()
        let focusSet = Set(bodyFocus)

        // 1. Spine & Hips explicitly combined
        if (titleAndSubtitle.contains("spine") && titleAndSubtitle.contains("hip")) ||
           (focusSet.contains(.back) && focusSet.contains(.hips)) {
            return "Spine & Hips"
        }

        // 2. Desk worker or posture resets targeting spine / back / hips
        if titleAndSubtitle.contains("posture") || titleAndSubtitle.contains("desk") || titleAndSubtitle.contains("hunch") {
            if focusSet.contains(.back) && focusSet.contains(.hips) {
                return "Spine & Hips"
            }
            if focusSet.contains(.back) {
                return "Spine & Posture"
            }
            if focusSet.contains(.neckShoulders) {
                return "Neck & Shoulders"
            }
            return "Spine & Hips"
        }

        // 3. Keyword cues in title or subtitle
        if titleAndSubtitle.contains("spine") {
            return focusSet.contains(.hips) ? "Spine & Hips" : "Spine & Back"
        }
        if titleAndSubtitle.contains("neck") || titleAndSubtitle.contains("shoulder") || focusSet.contains(.neckShoulders) {
            return "Neck & Shoulders"
        }
        if titleAndSubtitle.contains("glute") || titleAndSubtitle.contains("hip") || focusSet == [.hips] {
            return focusSet.contains(.lowerBody) ? "Hips & Legs" : "Hips"
        }
        if focusSet.contains(.back) {
            return "Spine & Back"
        }
        if focusSet.contains(.core) || titleAndSubtitle.contains("core") || titleAndSubtitle.contains("ab") {
            return "Core"
        }
        if focusSet.contains(.lowerBody) || titleAndSubtitle.contains("leg") {
            return "Lower Body"
        }
        if focusSet.contains(.upperBody) || titleAndSubtitle.contains("arm") || titleAndSubtitle.contains("chest") {
            return "Upper Body"
        }

        // 4. Default to first non-full body focus if present
        if let primary = bodyFocus.first(where: { $0 != .full }) {
            return primary.label
        }

        return "Full Body"
    }

    /// Impact classification — e.g. "Low Impact", "High Impact".
    var impactLabel: String {
        if qualities.contains(.impact) || activity == .jumpRope || (intensity >= 4 && (activity == .agility || activity == .skating)) {
            return "High Impact"
        }
        return "Low Impact"
    }

    /// Quick visual pills: equipment, duration, target area, impact level.
    /// e.g. ["Mat", "30 min", "Spine & Hips", "Low Impact"]
    var chips: [String] {
        var pills: [String] = []
        pills.append(contentsOf: equipment.compactMap(\.label))
        pills.append(durationLabel)
        pills.append(targetLabel)
        pills.append(impactLabel)
        return pills
    }
}

// MARK: The check-in

// SF Symbols keep the check-in visually consistent with onboarding. Nothing
// medical: no bandages or pills next to a question about someone's body.

nonisolated extension Energy {
    var checkInLabel: String {
        switch self {
        case .low: "Empty"
        case .steady: "Steady"
        case .strong: "Energized"
        }
    }

    /// Weather, not a battery meter — a cloudy morning is a kind of day, not a
    /// depleted version of a sunny one.
    var checkInSymbol: String {
        switch self {
        case .low: "cloud"
        case .steady: "cloud.sun"
        case .strong: "sun.max"
        }
    }
}

nonisolated extension TimeBudget {
    var checkInLabel: String {
        switch self {
        case .fiveMinutes: "Five minutes"
        case .aLittle: "Ten minutes"
        case .fifteenMinutes: "Fifteen minutes"
        case .twentyMinutes: "Twenty minutes"
        case .twentyFiveMinutes: "Twenty-five minutes"
        case .some: "Thirty minutes"
        case .thirtyFiveMinutes: "Thirty-five minutes"
        case .fortyMinutes: "Forty minutes"
        case .plenty: "45+ minutes"
        }
    }

    var checkInDetail: String {
        switch self {
        case .fiveMinutes: "5 min"
        case .aLittle: "10 min"
        case .fifteenMinutes: "15 min"
        case .twentyMinutes: "20 min"
        case .twentyFiveMinutes: "25 min"
        case .some: "30 min"
        case .thirtyFiveMinutes: "35 min"
        case .fortyMinutes: "40 min"
        case .plenty: "45+ min"
        }
    }

    /// The ceiling as a bare numeral, for the tile that prints it large with
    /// "min" underneath. Reads off `maxMinutes` rather than restating it, so
    /// the number on screen is the number the engine actually caps at.
    var checkInMinutes: String { "\(maxMinutes)" }

    var checkInSymbol: String {
        switch self {
        case .fiveMinutes: "5.circle"
        case .aLittle: "10.circle"
        case .fifteenMinutes: "15.circle"
        case .twentyMinutes: "20.circle"
        case .twentyFiveMinutes: "25.circle"
        case .some: "30.circle"
        case .thirtyFiveMinutes: "35.circle"
        case .fortyMinutes: "40.circle"
        case .plenty: "45.circle"
        }
    }

    var summaryPhrase: String { checkInDetail }
}

extension PlaceIntent {
    var checkInLabel: String {
        switch self {
        case .stayingIn: "Staying in"
        case .happyToGoOut: "Going out"
        case .atTheGym: "The gym"
        }
    }

    var checkInSymbol: String {
        switch self {
        case .stayingIn: "house"
        case .happyToGoOut: "tree"
        case .atTheGym: "dumbbell"
        }
    }
}

nonisolated extension BodyState {
    var checkInLabel: String {
        switch self {
        case .sore: "Sore"
        case .stiff: "Stiff"
        case .stressed: "Stressed"
        case .cramping: "Cramping"
        case .good: "Good"
        }
    }

    var checkInSymbol: String {
        switch self {
        case .sore: "figure.walk.motion"
        case .stiff: "figure.flexibility"
        case .stressed: "brain.head.profile"
        case .cramping: "water.waves"
        case .good: "sparkles"
        }
    }
}

// MARK: The Look Back

extension Activity {
    /// The name as it reads *mid-sentence*: "Mostly Pilates and walking."
    /// `label` is title-case for tags and headings, which would give
    /// "Mostly Pilates and Walking" — so the proper noun keeps its capital
    /// here and everything else goes lower.
    var lookBackName: String {
        switch self {
        case .pilates: "Pilates"
        case .yoga: "yoga"
        case .qigong: "qi gong"
        case .strength: "strength work"
        case .stretching: "stretching"
        case .walking: "walking"
        case .biking: "biking"
        case .swimming: "swimming"
        case .skating: "skating"
        case .dance: "dance"
        case .jumpRope: "jump rope"
        case .agility: "footwork"
        case .carries: "carries"
        case .racquet: "racquet"
        case .climbing: "climbing"
        case .martialArts: "martial arts"
        case .breathwork: "breathwork"
        }
    }
}

extension TimeOfDay {
    /// Plural: it describes a habit, not an appointment.
    var lookBackLabel: String {
        switch self {
        case .morning: "mornings"
        case .midday: "early afternoons"
        case .evening: "evenings"
        case .varies: "whenever you can"
        }
    }
}

extension Reflection.Note {
    /// One note, said out loud.
    ///
    /// Identity rather than measurement: the register is "this is who you are
    /// lately", not "here is your total". Nothing praises, compares, or asks —
    /// and there is no target anywhere for any of it to fall short of.
    var line: String {
        switch self {
        case .moved(let times):
            times == 1
                ? "Once in the last two weeks. That counts."
                : "\(Self.spelled(times)) times in the last two weeks."
        case .mostly(let when):
            when == .varies
                ? "You move whenever you can."
                : "You move in the \(when.lookBackLabel), mostly."
        case .activities(let activities):
            activities.count == 1
                ? "\(activities[0].lookBackName.capitalisedFirst) more than anything."
                : "\(activities[0].lookBackName.capitalisedFirst) and \(activities[1].lookBackName), mostly."
        case .keepsReturningTo(let activity):
            "You keep coming back to the \(activity.lookBackName) sessions."
        case .madeRoomForRest:
            "And you make room for the gentle ones."
        }
    }

    /// Editorial style: words up to ten, figures above. The app is meant to
    /// read like a cookbook, and cookbooks don't say "8 times".
    private static func spelled(_ n: Int) -> String {
        let words = ["zero", "once", "Two", "Three", "Four", "Five",
                     "Six", "Seven", "Eight", "Nine", "Ten"]
        return (2...10).contains(n) ? words[n] : "\(n)"
    }
}

private extension String {
    /// Uppercases only the first character, so "qi gong" becomes "Qi gong"
    /// rather than "Qi Gong".
    var capitalisedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}


nonisolated extension PlanCheckIn {
    /// The morning's answers as one line, for the card that shows what today's
    /// menu was built from.
    ///
    /// Energy and time only. `body` is deliberately absent — it is the field
    /// that can say `cramping`, and a summary line is read over someone's
    /// shoulder more often than anything else on the screen.
    var summaryLine: String {
        "\(energy.checkInLabel), \(time.summaryPhrase)"
    }
}
