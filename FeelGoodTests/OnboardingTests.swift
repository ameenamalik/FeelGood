//
//  OnboardingTests.swift
//  FeelGoodTests
//
//  The first card decides the whole candidate pool, so what it implies matters
//  as much as what it asks. See PRD §7.1.
//

import Testing
import Foundation
import UIKit
@testable import FeelGood

@Suite("Onboarding")
@MainActor
struct OnboardingTests {

    @Test("Home is available to the engine but is not preselected")
    func homeIsNotPreselected() {
        let model = OnboardingModel()

        #expect(model.places.isEmpty)
        #expect(model.makeProfile().places.contains(.home))
    }

    @Test("Every choice icon is an available SF Symbol")
    func choiceSymbolsExist() {
        var symbols = Activity.allCases.map(\.onboardingSymbol)
        symbols += SportPreference.allCases.map(\.onboardingSymbol)
        symbols += Equipment.allCases.map(\.onboardingSymbol)
        symbols += Place.allCases.map(\.onboardingSymbol)
        symbols += Cadence.allCases.map(\.onboardingSymbol)
        symbols += MovementMoments.allCases.map(\.onboardingSymbol)
        symbols += Intent.allCases.map(\.onboardingSymbol)
        symbols += WorkAround.allCases.map(\.onboardingSymbol)
        symbols += Energy.allCases.map(\.checkInSymbol)
        symbols += TimeBudget.allCases.map(\.checkInSymbol)
        symbols += PlaceIntent.allCases.map(\.checkInSymbol)
        symbols += BodyState.allCases.map(\.checkInSymbol)
        symbols.append("checkmark")

        for symbol in symbols {
            #expect(UIImage(systemName: symbol) != nil, "Missing SF Symbol: \(symbol)")
        }
    }

    @Test("A gym membership stands in for the room full of kit")
    func gymImpliesWhatIsInside() {
        let model = OnboardingModel()
        model.places = [.home, .gym]
        let profile = model.makeProfile()

        #expect(profile.equipment.isSuperset(of: [.gym, .mat, .weights, .band, .bike]))
        #expect(profile.places.contains(.gym))
        // Plenty of gyms have no pool, and a session that can't happen is worse
        // than one that was never offered.
        #expect(!profile.equipment.contains(.pool))
    }

    @Test("A gym membership means somewhere to lift, whether or not it was ticked")
    func gymImpliesStrength() {
        let model = OnboardingModel()
        model.places = [.home, .gym]

        #expect(model.makeProfile().availableActivities.contains(.strength))
        // It still does not answer the separate Movement and Equipment
        // sections on the first slide.
        #expect(!model.canAdvance)
    }

    @Test("Every section on the first slide needs an explicit answer")
    func everyAccessSectionIsRequired() {
        let model = OnboardingModel()
        #expect(!model.canAdvance)

        model.activities = [.walking]
        #expect(!model.canAdvance)

        model.equipment = [.none]
        #expect(!model.canAdvance)

        model.places = [.home]
        #expect(model.canAdvance)
    }

    @Test("Onboarding skips cadence and uses gentle defaults")
    func cadenceUsesDefaults() {
        let model = OnboardingModel()
        model.activities = [.walking]
        model.equipment = [.none]
        model.places = [.home]
        model.advance()

        #expect(model.card == .intent)
        #expect(!model.canAdvance)
        model.intents = [.calm]
        #expect(model.canAdvance)
        #expect(model.makeProfile().cadence == .mostDays)
        #expect(model.makeProfile().moments == .aCouple)
    }

    @Test("Energy is not preselected on onboarding")
    func intentsStartEmpty() {
        let model = OnboardingModel()
        #expect(model.intents.isEmpty)
        #expect(!model.intents.contains(.energize))
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
        model.places = [.home, .gym]
        model.intents = [.strengthen]

        let engine = PlanEngine(catalog: try ContentStore.bundled().sessions)
        let menu = engine.makeMenu(
            PlanInput(
                profile: model.makeProfile(),
                // Willing to go: a gym session is not reachable from a day
                // somebody has already decided to stay in.
                checkIn: PlanCheckIn(energy: .strong, time: .plenty, place: .atTheGym),
                context: Fixture.context()
            )
        )

        #expect(menu.main != nil)
        #expect(menu.items.contains { $0.session.equipment.contains(.gym) })
    }

    @Test("Moving toward can hold more than one direction")
    func multipleIntentsAreKept() {
        let model = OnboardingModel()
        model.activities = [.pilates]
        model.intents = [.strengthen, .calm]

        #expect(model.makeProfile().intents == [.strengthen, .calm])
    }

    @Test("Picking an activity still implies the obvious equipment")
    func activitiesStillImplyTheirKit() {
        let model = OnboardingModel()
        model.activities = [.swimming]

        #expect(model.makeProfile().equipment.contains(.pool))
    }
}
