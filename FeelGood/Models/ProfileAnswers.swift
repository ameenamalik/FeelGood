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
    var equipment: Set<Equipment> = [.none]
    var cadence: Cadence = .mostDays
    var realisticMinutes: Int = 20
    var bestTimeOfDay: TimeOfDay = .varies
    var intent: Intent = .energize
    var workArounds: Set<WorkAround> = []

    /// A room implies what happens in it: a gym means somewhere to lift, even
    /// if "Strength" was never ticked.
    var availableActivities: Set<Activity> {
        equipment.reduce(into: activities) { $0.formUnion($1.impliedActivities) }
    }

    /// Kit is implied in both directions — picking swimming without ticking
    /// "pool" shouldn't produce an empty menu, and ticking the gym shouldn't
    /// mean also ticking everything inside it.
    var availableEquipment: Set<Equipment> {
        var derived: Set<Equipment> = equipment.union([.none])
        for activity in activities {
            derived.formUnion(activity.impliedEquipment)
        }
        for item in equipment {
            derived.formUnion(item.impliedEquipment)
        }
        return derived
    }

    /// Enough has been said to plan a day.
    var isAnswered: Bool { !availableActivities.isEmpty }

    var planProfile: PlanProfile {
        PlanProfile(
            availableActivities: availableActivities,
            equipment: availableEquipment,
            cadence: cadence,
            realisticMinutes: realisticMinutes,
            bestTimeOfDay: bestTimeOfDay,
            intent: intent,
            workArounds: workArounds
        )
    }
}
