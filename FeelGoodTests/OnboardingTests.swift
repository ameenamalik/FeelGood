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

    @Test("Home and outdoors are defaults since Where is removed from onboarding")
    func homeAndOutdoorsAreDefault() {
        let model = OnboardingModel()

        #expect(model.places == [.home, .outdoors])
        #expect(model.makeProfile().places.contains(.home))
        #expect(model.makeProfile().places.contains(.outdoors))
    }

    @Test("The text typed for Other is kept with the answers")
    func otherMovementNoteIsKept() {
        let model = OnboardingModel()
        model.otherMovementNote = "Roller derby"

        let record = model.makeRecord(now: Date(timeIntervalSince1970: 0))

        #expect(record.otherMovementNote == "Roller derby")
        #expect(record.answers.otherMovementNote == "Roller derby")
    }

    @Test("Pickleball is still stored as a sport under the racquet activity")
    func pickleballStorage() {
        var answers = ProfileAnswers()
        answers.activities = [.racquet]
        answers.sports = [.pickleball]

        let record = UserProfile(answers: answers, now: Date(timeIntervalSince1970: 0))

        #expect(record.answers.sports == [.pickleball])
        #expect(record.answers.activities.contains(.racquet))
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

    @Test("Movement and equipment have separate questions and validation")
    func everyAccessSectionIsRequired() {
        let model = OnboardingModel()
        #expect(!model.canAdvance)

        model.selectedGuidancePreference = .knowsWhatTheyEnjoy
        #expect(model.canAdvance)
        model.advance()
        #expect(model.card == .movement)
        #expect(!model.canAdvance)

        model.advance()
        #expect(model.card == .movement)
        model.activities = [.walking]
        #expect(model.canAdvance)
        model.advance()
        #expect(model.card == .equipment)
        #expect(!model.canAdvance)
        model.advance()
        #expect(model.card == .equipment)

        model.equipment = [.none]
        #expect(model.canAdvance)
    }

    @Test("Onboarding skips cadence and uses gentle defaults")
    func cadenceUsesDefaults() {
        let model = OnboardingModel()
        model.selectedGuidancePreference = .knowsWhatTheyEnjoy
        model.advance()
        model.activities = [.walking]
        model.equipment = [.none]
        model.places = [.home]
        model.advance()
        model.advance()

        #expect(model.card == .intent)
        #expect(!model.canAdvance)
        model.intents = [.calm]
        #expect(model.canAdvance)
        #expect(model.makeProfile().cadence == .mostDays)
        #expect(model.makeProfile().moments == .aCouple)
    }

    @Test("The first answer is required and reaches the planning profile")
    func guidancePreferenceIsExplicit() {
        let model = OnboardingModel()

        #expect(model.card == .guidance)
        #expect(!model.canAdvance)

        model.selectedGuidancePreference = .hasOwnRoutine

        #expect(model.canAdvance)
        #expect(model.makeProfile().guidancePreference == .hasOwnRoutine)
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

    private func draftURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("OnboardingTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("draft.json")
    }

    @Test("Every question and all partial answers survive recreating the model",
          arguments: OnboardingModel.Card.allCases)
    func resumeAtEachQuestion(_ question: OnboardingModel.Card) {
        let url = draftURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let original = OnboardingModel(draftURL: url)
        original.selectedGuidancePreference = .hasOwnRoutine
        original.activities = [.racquet, .yoga]
        original.sports = [.pickleball, .tennis]
        original.equipment = [.mat, .weights]
        original.places = [.home, .gym]
        original.intents = [.calm, .strengthen]
        original.workArounds = [.other, .knees]
        original.otherWorkAroundNote = "Avoid floor work"
        original.otherMovementNote = "Roller derby"
        for _ in 0..<question.rawValue { original.advance() }

        let resumed = OnboardingModel(draftURL: url)
        #expect(resumed.card == question)
        #expect(resumed.selectedGuidancePreference == .hasOwnRoutine)
        #expect(resumed.answers == original.answers)
    }

    @Test("Back navigation and removing an answer are saved before continuing")
    func resumeEditedQuestion() {
        let url = draftURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let model = OnboardingModel(draftURL: url)
        model.selectedGuidancePreference = .gettingStarted
        model.advance()
        model.activities = [.walking]
        model.advance()
        model.equipment = [.none]
        model.goBack()
        model.activities = []

        let resumed = OnboardingModel(draftURL: url)
        #expect(resumed.card == .movement)
        #expect(resumed.activities.isEmpty)
        #expect(resumed.equipment == [.none])
        #expect(!resumed.canAdvance)
    }

    @Test("An unanswered guidance choice stays unanswered after reopening")
    func guidanceIsNotInventedOnResume() {
        let url = draftURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let model = OnboardingModel(draftURL: url)
        model.otherWorkAroundNote = "A partial answer"

        let resumed = OnboardingModel(draftURL: url)
        #expect(resumed.selectedGuidancePreference == nil)
        #expect(!resumed.canAdvance)
        #expect(resumed.card == .guidance)
    }

    @Test("Completing or resetting onboarding removes its draft")
    func clearedDraftStartsFresh() {
        let url = draftURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let model = OnboardingModel(draftURL: url)
        model.selectedGuidancePreference = .gettingStarted
        model.advance()
        #expect(FileManager.default.fileExists(atPath: url.path))

        model.clearDraft()

        #expect(!FileManager.default.fileExists(atPath: url.path))
        let fresh = OnboardingModel(draftURL: url)
        #expect(fresh.card == .guidance)
        #expect(fresh.selectedGuidancePreference == nil)
        #expect(fresh.activities.isEmpty)
    }

    @Test("A damaged draft safely starts fresh and can be replaced")
    func corruptDraftDoesNotBlockOnboarding() throws {
        let url = draftURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("incomplete file".utf8).write(to: url)

        let model = OnboardingModel(draftURL: url)
        #expect(model.card == .guidance)
        #expect(model.selectedGuidancePreference == nil)
        model.selectedGuidancePreference = .knowsWhatTheyEnjoy
        model.advance()

        let resumed = OnboardingModel(draftURL: url)
        #expect(resumed.card == .movement)
        #expect(resumed.selectedGuidancePreference == .knowsWhatTheyEnjoy)
    }


    @Test("The guide responds to an explicit answer and follows changes")
    func guideRespondsToChoices() {
        let model = OnboardingModel()
        #expect(model.acknowledgement == nil)
        model.selectedGuidancePreference = .gettingStarted
        let startingReply = model.acknowledgement
        #expect(startingReply != nil)
        model.selectedGuidancePreference = .hasOwnRoutine
        #expect(model.acknowledgement != nil)
        #expect(model.acknowledgement != startingReply)
        model.advance()
        #expect(model.acknowledgement == nil)
        model.activities = [.walking]
        #expect(model.acknowledgement != nil)
        model.activities = []
        #expect(model.acknowledgement == nil)
    }

    @Test("The guide distinguishes no equipment from equipment access")
    func equipmentReplyMatchesAccess() {
        let model = OnboardingModel()
        model.selectedGuidancePreference = .gettingStarted
        model.advance()
        model.activities = [.yoga]
        model.advance()
        #expect(model.acknowledgement == nil)
        model.equipment = [.none]
        let noEquipmentReply = model.acknowledgement
        model.equipment = [.mat]
        #expect(model.acknowledgement != noEquipmentReply)
        #expect(model.acknowledgement != nil)
    }

    @Test("The summary reflects actual movement and sport choices without inferred kit")
    func summaryReflectsExplicitAnswers() throws {
        let answers = ProfileAnswers(
            activities: [.swimming, .racquet, .yoga],
            sports: [.pickleball, .tennis],
            equipment: [.none],
            intents: [.calm, .mobilize]
        )
        let rows = OnboardingSummary(answers: answers).rows
        #expect(rows.map(\.id) == ["movement", "equipment", "intent"])
        let movement = try #require(rows.first { $0.id == "movement" })
        #expect(movement.value == "Yoga, Swimming, Pickleball, Tennis")
        let equipment = try #require(rows.first { $0.id == "equipment" })
        #expect(equipment.value == "No equipment")
        #expect(!equipment.value.contains("Pool"))
        #expect(rows.first { $0.id == "intent" }?.value == "Calm, Mobility")
    }

    @Test("A reviewed summary updates when the person edits their answers")
    func summaryUpdatesAfterEditing() {
        var answers = ProfileAnswers(activities: [.yoga], equipment: [.mat], intents: [.calm])
        let original = OnboardingSummary(answers: answers)
        answers.activities = [.walking]
        answers.intents = [.energize]
        answers.workArounds = [.wrists]
        let revised = OnboardingSummary(answers: answers)
        #expect(revised.rows.first { $0.id == "movement" }?.value == "Walking")
        #expect(revised.rows.first { $0.id == "intent" }?.value == "Energy")
        #expect(revised.rows.first { $0.id == "needs" }?.value == "Wrists")
        #expect(original.rows.first { $0.id == "needs" } == nil)
    }


    @Test("Draft answers saved before the Other movement field still decode")
    func olderDraftAnswersRemainReadable() throws {
        let legacy = Data(#"{"activities":["walking"],"equipment":["none"],"intents":["calm"],"otherWorkAroundNote":"Avoid floor work"}"#.utf8)
        let answers = try JSONDecoder().decode(ProfileAnswers.self, from: legacy)
        #expect(answers.activities == [.walking])
        #expect(answers.equipment == [.none])
        #expect(answers.intents == [.calm])
        #expect(answers.otherWorkAroundNote == "Avoid floor work")
        #expect(answers.otherMovementNote.isEmpty)
        #expect(answers.places == [.home, .outdoors])
        #expect(try JSONDecoder().decode(ProfileAnswers.self, from: JSONEncoder().encode(answers)) == answers)
    }

}
