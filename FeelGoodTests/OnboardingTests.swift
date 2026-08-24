//
//  OnboardingTests.swift
//  FeelGoodTests
//
//  The first card decides the whole candidate pool, so what it implies matters
//  as much as what it asks. See PRD §7.1.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Onboarding")
@MainActor
struct OnboardingTests {

    @Test("A gym membership stands in for the room full of kit")
    func gymImpliesWhatIsInside() {
        let model = OnboardingModel()
        model.equipment = [.none, .gym]
        let profile = model.makeProfile()

        #expect(profile.equipment.isSuperset(of: [.gym, .mat, .weights, .band, .bike]))
        // Plenty of gyms have no pool, and a session that can't happen is worse
        // than one that was never offered.
        #expect(!profile.equipment.contains(.pool))
    }

    @Test("A gym membership means somewhere to lift, whether or not it was ticked")
    func gymImpliesStrength() {
        let model = OnboardingModel()
        model.equipment = [.none, .gym]

        #expect(model.makeProfile().availableActivities.contains(.strength))
        // ...and it is enough on its own to leave the first card.
        #expect(model.canAdvance)
    }

    @Test("The first card still has to be answered with something")
    func nothingPickedCannotAdvance() {
        #expect(!OnboardingModel().canAdvance)
    }

    @Test("Movement the card never asks about is never recorded as a preference")
    func alwaysAvailableActivitiesAreNotProfileAnswers() {
        let model = OnboardingModel()
        model.activities = [.pilates]
        model.equipment = [.none, .mat]

        // Qi gong, breathwork, carries and footwork reach the menu through the
        // engine, not through a chip nobody would recognise.
        #expect(model.makeProfile().availableActivities.allSatisfy { !$0.isAlwaysAvailable })
    }

    @Test("Ticking only the gym produces a menu of things you can do at a gym")
    func gymMembershipEndToEnd() throws {
        let model = OnboardingModel()
        model.equipment = [.none, .gym]
        model.intent = .strengthen

        let engine = PlanEngine(catalog: try ContentStore.bundled().sessions)
        let menu = engine.makeMenu(
            PlanInput(
                profile: model.makeProfile(),
                checkIn: PlanCheckIn(energy: .strong, time: .plenty),
                context: Fixture.context()
            )
        )

        #expect(menu.main != nil)
        #expect(menu.items.contains { $0.session.equipment.contains(.gym) })
    }

    @Test("Picking an activity still implies the obvious equipment")
    func activitiesStillImplyTheirKit() {
        let model = OnboardingModel()
        model.activities = [.swimming]

        #expect(model.makeProfile().equipment.contains(.pool))
    }
}
