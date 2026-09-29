//
//  ChatAvailability.swift
//  FeelGood
//
//  What someone can actually do today, so Chat only suggests sessions Today
//  would also have allowed. It mirrors the plan engine's equipment, activity
//  and place filters, starting from the profile and widened by anything the
//  person says in the conversation ("I'm at the gym").
//
//  Equipment, places and activities carry no health data, so unlike
//  work-arounds they may go to the chat server.
//

import Foundation

nonisolated struct ChatAvailability: Hashable, Sendable {
    var equipment: Set<Equipment>
    var places: Set<Place>
    var activities: Set<Activity>

    init(equipment: Set<Equipment>, places: Set<Place>, activities: Set<Activity>) {
        self.equipment = equipment.union([.none])
        self.places = places.union([.home])
        self.activities = activities
    }

    /// - Parameter conversation: what the person has typed in this chat. A
    ///   statement there widens today's access without touching the profile.
    init(profile: PlanProfile, conversation: [String] = []) {
        var equipment = profile.equipment
        var places = profile.places
        var activities = profile.availableActivities

        for item in Self.mentionedEquipment(in: conversation) {
            equipment.insert(item)
            equipment.formUnion(item.impliedEquipment)
            activities.formUnion(item.impliedActivities)
            if item == .gym { places.insert(.gym) }
        }
        // Saying you want to run is saying you're going outside to do it, so
        // it opens running for today without adding it to the profile.
        if Self.mentionsRunning(in: conversation) {
            activities.insert(.running)
            equipment.insert(.outdoor)
            places.insert(.outdoors)
        }

        // Detect other explicitly mentioned activities so requests in chat
        // (e.g. Pilates, Yoga, Dance, Swim) are never falsely refused.
        for message in conversation {
            let text = message.lowercased()
            if Self.matches(text, Self.negations) { continue }

            if Self.matches(text, Self.pilatesPhrases) {
                activities.insert(.pilates)
                equipment.insert(.mat)
            }
            if Self.matches(text, Self.yogaPhrases) {
                activities.insert(.yoga)
                equipment.insert(.mat)
            }
            if Self.matches(text, Self.dancePhrases) {
                activities.insert(.dance)
            }
            if Self.matches(text, Self.stretchingPhrases) {
                activities.insert(.stretching)
            }
            if Self.matches(text, Self.bikePhrases) {
                activities.insert(.biking)
                equipment.insert(.bike)
                places.insert(.outdoors)
            }
            if Self.matches(text, Self.swimPhrases) {
                activities.insert(.swimming)
                equipment.insert(.pool)
                places.insert(.pool)
            }
            if Self.matches(text, Self.skatePhrases) {
                activities.insert(.skating)
                equipment.insert(.skates)
            }
            if Self.matches(text, Self.jumpRopePhrases) {
                activities.insert(.jumpRope)
                equipment.insert(.rope)
            }
        }

        self.init(equipment: equipment, places: places, activities: activities)
    }

    /// Same hard filters as `PlanEngine.isEligible`, minus the ones that
    /// depend on a check-in.
    func allows(_ session: Session) -> Bool {
        guard Set(session.equipment).subtracting([.none]).isSubset(of: equipment) else { return false }
        guard session.activity.isAlwaysAvailable || activities.contains(session.activity) || isHomeFloorSession(session) else { return false }
        guard session.places.isEmpty || !Set(session.places).isDisjoint(with: places) else { return false }
        return true
    }

    /// Mat and floor sessions at home require no special equipment and are always safe to explore in Chat.
    private func isHomeFloorSession(_ session: Session) -> Bool {
        let isFloorKit = Set(session.equipment).isSubset(of: [.none, .mat])
        let isHomeSafe = session.places.isEmpty || session.places.contains(.home)
        return isFloorKit && isHomeSafe && (session.activity == .pilates || session.activity == .yoga || session.activity == .dance)
    }

    // MARK: - Reading the conversation

    private static let negations = #"n't|\bno\b|\bnot\b|\bnever\b|\bwithout\b"#
    private static let gymPhrases =
        #"\b(at|in|going to|headed to|heading to|hitting)\s+(the|my)\s+gym\b|\b(have|got|with|using)\s+(a\s+|the\s+|my\s+)?(access to\s+)?(a\s+|the\s+)?gym\b|\bgym\s+(today|tonight|access)\b"#
    private static let weightsPhrases =
        #"\b(have|got|with|using)\s+(a set of\s+|some\s+|my\s+)?(dumbbells?|weights|kettlebells?|barbells?)\b"#

    private static let runningPhrases =
        #"\b(go|going|went|head|heading)\s+(for\s+)?(a\s+)?(run|jog)\b|\b(go|going|went)\s+(running|jogging)\b|\b(want|wanna|like|love|need|trying|plan|planning|hoping|about)\s+(to\s+)?(go\s+)?(run|jog)\b|\b(i|i'm|im|i am)\s+(a\s+)?(runner|running|jogging)\b|\b(a|my)\s+(run|jog)\b"#

    private static let pilatesPhrases = #"\bpilates\b"#
    private static let yogaPhrases = #"\byoga\b"#
    private static let dancePhrases = #"\b(dance|dancing)\b"#
    private static let stretchingPhrases = #"\b(stretch|stretching|flexibility|mobility)\b"#
    private static let bikePhrases = #"\b(bike|biking|cycle|cycling)\b"#
    private static let swimPhrases = #"\b(swim|swimming|pool)\b"#
    private static let skatePhrases = #"\b(skate|skates|skating|roller|ice skate)\b"#
    private static let jumpRopePhrases = #"\b(jump rope|jumprope|skipping)\b"#

    private static func matches(_ text: String, _ pattern: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }

    /// Only first-person statements count, and a negation anywhere in the
    /// message cancels it. "Should I go to the gym?" is not a claim.
    static func mentionedEquipment(in messages: [String]) -> Set<Equipment> {
        var found: Set<Equipment> = []
        for message in messages {
            let text = message.lowercased()
            if matches(text, negations) { continue }
            if matches(text, gymPhrases) { found.insert(.gym) }
            if matches(text, weightsPhrases) { found.insert(.weights) }
        }
        return found
    }

    /// Same rules as equipment: a first-person statement, cancelled by any
    /// negation in the same message. "I don't want to run" opens nothing.
    static func mentionsRunning(in messages: [String]) -> Bool {
        messages.contains { message in
            let text = message.lowercased()
            return !matches(text, negations) && matches(text, runningPhrases)
        }
    }
}

nonisolated extension ChatUserContext {
    /// The wire fields, rebuilt as a filter. `nil` when the client sent none.
    var availability: ChatAvailability? {
        guard availableEquipment != nil || availablePlaces != nil || availableActivities != nil else { return nil }
        return ChatAvailability(
            equipment: Set((availableEquipment ?? []).compactMap(Equipment.init(rawValue:))),
            places: Set((availablePlaces ?? []).compactMap(Place.init(rawValue:))),
            activities: Set((availableActivities ?? []).compactMap(Activity.init(rawValue:)))
        )
    }
}
