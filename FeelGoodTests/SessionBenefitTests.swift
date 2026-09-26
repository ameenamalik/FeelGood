//
//  SessionBenefitTests.swift
//  FeelGoodTests
//
//  "Why this feels good" used to be keyed on activity alone, so every
//  stretch in the catalog said the same thing. These hold it to varying with
//  the session, and to staying out of medical territory.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Why this feels good")
struct SessionBenefitTests {

    @Test("Two sessions of the same activity don't have to read the same")
    func sameActivityDiffers() {
        let quick = Session.own(id: "a", title: "Quick", activity: .stretching, durationMin: 3, intensity: 2)
        let long = Session.own(id: "b", title: "Long", activity: .stretching, durationMin: 25, intensity: 4)
        #expect(SessionBenefit(session: quick) != SessionBenefit(session: long))
    }

    @Test("The bundled catalog gets more than one line per activity")
    func catalogVaries() throws {
        let sessions = try ContentStore.bundled().sessions
        let texts = Set(sessions.map { SessionBenefit(session: $0) }.map { "\($0.headline)|\($0.description)" })
        let activities = Set(sessions.map(\.activity))
        #expect(texts.count > activities.count * 2)
    }

    @Test("No physiology or outcome claims in any session's copy")
    func noMedicalClaims() throws {
        let banned = ["heart rate", "nervous system", "vagus", "cortisol", "bone density",
                      "dopamine", "endorphin", "neurotransmitter", "circulation", "treat", "cure", "heal"]
        for session in try ContentStore.bundled().sessions {
            let benefit = SessionBenefit(session: session)
            let text = "\(benefit.headline) \(benefit.description)".lowercased()
            for word in banned {
                #expect(!text.contains(word), "\(session.id) says \(word)")
            }
        }
    }
}
