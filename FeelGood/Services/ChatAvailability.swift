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
        self.init(equipment: equipment, places: places, activities: activities)
    }

    /// Same hard filters as `PlanEngine.isEligible`, minus the ones that
    /// depend on a check-in.
    func allows(_ session: Session) -> Bool {
        guard Set(session.equipment).subtracting([.none]).isSubset(of: equipment) else { return false }
        guard session.activity.isAlwaysAvailable || activities.contains(session.activity) else { return false }
        guard session.places.isEmpty || !Set(session.places).isDisjoint(with: places) else { return false }
        return true
    }

    // MARK: - Reading the conversation

    private static let negations = #"n't|\bno\b|\bnot\b|\bnever\b|\bwithout\b"#
    private static let gymPhrases =
        #"\b(at|in|going to|headed to|heading to|hitting)\s+(the|my)\s+gym\b|\b(have|got|with|using)\s+(a\s+|the\s+|my\s+)?(access to\s+)?(a\s+|the\s+)?gym\b|\bgym\s+(today|tonight|access)\b"#
    private static let weightsPhrases =
        #"\b(have|got|with|using)\s+(a set of\s+|some\s+|my\s+)?(dumbbells?|weights|kettlebells?|barbells?)\b"#

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
