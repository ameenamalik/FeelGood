//
//  AccountSyncPrivacyTests.swift
//  FeelGoodTests
//
//  The third channel off the device, beside `CopyPayloadTests` and
//  `AnalyticsPayloadTests`. Account sync writes the profile to Firestore, and
//  the privacy policy promises work-arounds never go with it.
//

import Testing
import Foundation
@testable import FeelGood

@MainActor
@Suite("Account sync privacy")
struct AccountSyncPrivacyTests {

    private func profile(workArounds: Set<WorkAround>) -> UserProfile {
        var answers = ProfileAnswers()
        answers.workArounds = workArounds
        return UserProfile(answers: answers, now: Fixture.now)
    }

    @Test("No work-around leaves the device in the uploaded profile")
    func uploadCarriesNoWorkArounds() throws {
        let data = AccountDataSyncService.preferenceData(
            from: profile(workArounds: Set(WorkAround.allCases))
        )

        #expect(data["workArounds"] == nil)

        // Checked against the serialised form too, so a value renamed or
        // tucked under another key is still caught.
        let flattened = String(describing: data)
        for workAround in WorkAround.allCases {
            #expect(!flattened.contains(workAround.rawValue), "\(workAround) reached the sync payload")
        }
    }

    @Test("Work-arounds in the cloud are ignored on download")
    func downloadIgnoresCloudWorkArounds() {
        let local = profile(workArounds: [.knees])

        AccountDataSyncService.apply(
            ["workArounds": ["lowBack", "pregnancy"]],
            to: local
        )

        #expect(local.answers.workArounds == [.knees])
    }
}
