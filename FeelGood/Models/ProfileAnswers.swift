//
//  ProfileAnswers.swift
//  FeelGood
//
//  The six answers from onboarding, in one value. Stored as given — what was
//  actually ticked — with everything the answers imply derived on the way out,
//  so unticking the gym later takes the weights with it. See PRD §7.1.
//

import Foundation

nonisolated struct ProfileAnswers: Hashable, Sendable {
    var activities: Set<Activity> = []
    /// Empty until the person explicitly picks equipment or "No equipment".
    /// `availableEquipment` still adds `.none` as the engine's safe baseline.
    var equipment: Set<Equipment> = []
    /// Starts empty so onboarding reflects an actual choice. `availablePlaces`
    /// still adds home as the engine's safe floor-only fallback.
    var places: Set<Place> = []
    var cadence: Cadence = .mostDays
    var moments: MovementMoments = .aCouple
    var realisticMinutes: Int = 20
    var bestTimeOfDay: TimeOfDay = .varies
    var intents: Set<Intent> = [.energize]
    var workArounds: Set<WorkAround> = []
    var hiddenSessionIDs: Set<String> = []

    /// A room implies what happens in it: a gym means somewhere to lift, even
    /// if "Strength" was never ticked.
    var availableActivities: Set<Activity> {
        availableEquipment.reduce(into: activities) { $0.formUnion($1.impliedActivities) }
    }

    /// Home is always available. Somebody can untick everywhere else; they
    /// cannot untick being somewhere.
    var availablePlaces: Set<Place> { places.union([.home]) }

    /// Kit is implied in both directions — picking swimming without ticking
    /// "pool" shouldn't produce an empty menu, and ticking the gym shouldn't
    /// mean also ticking everything inside it.
    var availableEquipment: Set<Equipment> {
        var derived: Set<Equipment> = equipment.union([.none])
        for activity in activities {
            derived.formUnion(activity.impliedEquipment)
        }
        // Somewhere to be implies what's in it — a gym is asked about as a
        // place, and the kit inside it follows from that rather than from a
        // second chip asking the same question.
        for place in places {
            derived.formUnion(place.impliedEquipment)
        }
        for item in equipment {
            derived.formUnion(item.impliedEquipment)
        }
        return derived
    }

    /// Enough has been said to plan a day.
    var isAnswered: Bool { !availableActivities.isEmpty && !intents.isEmpty }

    var planProfile: PlanProfile {
        PlanProfile(
            availableActivities: availableActivities,
            equipment: availableEquipment,
            places: availablePlaces,
            cadence: cadence,
            moments: moments,
            realisticMinutes: realisticMinutes,
            bestTimeOfDay: bestTimeOfDay,
            workArounds: workArounds,
            intents: intents,
            hiddenSessionIDs: hiddenSessionIDs
        )
    }
}
