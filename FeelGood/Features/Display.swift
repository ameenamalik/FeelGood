//
//  Display.swift
//  FeelGood
//
//  How the vocabulary is spoken out loud. The taxonomy stays behind the glass —
//  you see a menu, never a data model.
//

import Foundation

extension Course {
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

extension Activity {
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

extension Equipment {
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
        case .reformer: "Reformer"
        }
    }
}

extension Session {
    var durationLabel: String { "\(durationMin) min" }

    /// "Mat · 20 min" — what you need and how long, nothing else.
    var chips: [String] {
        equipment.compactMap(\.label) + [durationLabel]
    }
}

// MARK: The check-in

// Every emoji below is checked against one rule: no red anywhere. That rules
// out the obvious picks — 🪫 for low energy (Apple renders it red, and it is
// precisely the "you're behind" signal this app refuses to send), ⏰, and any
// house glyph, whose roofs are red-brown. Nothing medical, either: no bandages
// and no pills next to a question about someone's body.

extension Energy {
    var checkInLabel: String {
        switch self {
        case .low: "Empty"
        case .steady: "Steady"
        case .strong: "Strong"
        }
    }

    /// Weather, not a battery meter — a cloudy morning is a kind of day, not a
    /// depleted version of a sunny one.
    var checkInEmoji: String {
        switch self {
        case .low: "☁️"
        case .steady: "🌤️"
        case .strong: "☀️"
        }
    }
}

extension TimeBudget {
    var checkInLabel: String {
        switch self {
        case .aLittle: "A little"
        case .some: "Some"
        case .plenty: "Plenty"
        }
    }

    var checkInDetail: String {
        switch self {
        case .aLittle: "10 min"
        case .some: "20–30"
        case .plenty: "45+"
        }
    }

    var checkInEmoji: String {
        switch self {
        case .aLittle: "⏳"
        case .some: "🕰️"
        case .plenty: "🪁"
        }
    }
}

extension PlaceIntent {
    var checkInLabel: String {
        switch self {
        case .stayingIn: "Staying in"
        case .happyToGoOut: "Going out"
        case .atTheGym: "The gym"
        }
    }

    /// An arm rather than a weightlifter: the base glyph renders as a man, and
    /// this app does not assume who is reading it.
    var checkInEmoji: String {
        switch self {
        case .stayingIn: "🛋️"
        case .happyToGoOut: "🌳"
        case .atTheGym: "💪"
        }
    }
}

extension BodyState {
    var checkInLabel: String {
        switch self {
        case .sore: "Sore"
        case .stiff: "Stiff"
        case .stressed: "Stressed"
        case .cramping: "Cramping"
        case .good: "Good"
        }
    }

    var checkInEmoji: String {
        switch self {
        case .sore: "😔"
        case .stiff: "🪵"
        case .stressed: "🌀"
        case .cramping: "🌊"
        case .good: "🌼"
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
    /// One note, said out loud. Statements of fact in a warm register —
    /// nothing here praises, compares, or asks for anything.
    var line: String {
        switch self {
        case .moved(let times):
            times == 1
                ? "You've moved once in the last two weeks."
                : "You've moved \(times) times in the last two weeks."
        case .mostly(let when):
            "Mostly \(when.lookBackLabel)."
        case .activities(let activities):
            activities.count == 1
                ? "Mostly \(activities[0].lookBackName)."
                : "Mostly \(activities[0].lookBackName) and \(activities[1].lookBackName)."
        case .keepsReturningTo(let activity):
            "The \(activity.lookBackName) sessions are the ones you keep coming back to."
        case .madeRoomForRest:
            "You've made room for the gentle ones, too."
        }
    }
}
