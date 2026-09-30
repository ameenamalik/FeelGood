//
//  AnalyticsPayloadTests.swift
//  FeelGoodTests
//
//  The sibling of `CopyPayloadTests`. That file guards what reaches the copy
//  proxy; this one guards what reaches PostHog. `check_in_completed` carries
//  check-in state now, which makes it the second channel off the device and
//  the second place a refactor can make a sentence in the PRD false.
//

import Testing
import Foundation
import PostHog
@testable import FeelGood

@Suite("Analytics payload")
struct AnalyticsPayloadTests {

    /// A check-in whose every answer is given, and whose body answer is the one
    /// that must never travel.
    private func sensitivePayload(body: BodyState? = .cramping) -> CheckInAnalytics {
        CheckInAnalytics(energy: .strong, time: .plenty, place: .atTheGym, body: body)
    }

    /// The properties as they would actually be serialised on the way out —
    /// not the struct's stored fields, which is where a leak would hide.
    private func encoded(_ payload: CheckInAnalytics) throws -> String {
        let data = try JSONSerialization.data(
            withJSONObject: payload.properties,
            options: [.sortedKeys]
        )
        return try #require(String(data: data, encoding: .utf8))
    }

    @Test("The wire shape is exactly the five permitted keys")
    func wireShapeIsClosed() throws {
        // Written out rather than derived from the type: a test that reads the
        // same source as the thing it checks agrees with any mistake.
        #expect(
            Set(sensitivePayload().properties.keys)
                == ["has_check_in", "has_body", "energy", "time", "place"],
            "The check-in event grew or lost a property. If this is deliberate, the PRD §11 table changes too."
        )
    }

    /// The one that matters. Every case, not just `cramping` — a ban-list on
    /// the single value somebody thought of rots the moment the enum grows.
    @Test("No body state ever appears in the encoded properties")
    func bodyStateNeverTravels() throws {
        for body in BodyState.allCases {
            let json = try encoded(sensitivePayload(body: body)).lowercased()
            // `.good` is excluded the way `CopyPayloadTests` excludes it: the
            // word is too ordinary for its presence to mean anything.
            guard body != .good else { continue }
            #expect(
                !json.contains(body.rawValue.lowercased()),
                "\(body.rawValue) reached PostHog. Body state stays on the device."
            )
        }
    }

    /// Work-arounds have no route to this event at all, which is the claim
    /// worth pinning: `CheckInAnalytics` cannot see a profile.
    @Test("No work-around appears in the encoded properties")
    func workAroundsNeverTravel() throws {
        let json = try encoded(sensitivePayload()).lowercased()
        for workAround in WorkAround.allCases {
            #expect(
                !json.contains(workAround.rawValue.lowercased()),
                "\(workAround.rawValue) reached PostHog. Work-arounds are a filter, never a payload."
            )
        }
    }

    @Test("Coarse state is carried verbatim")
    func coarseStateIsCarried() {
        let properties = sensitivePayload().properties
        #expect(properties["energy"] as? String == Energy.strong.rawValue)
        #expect(properties["time"] as? String == TimeBudget.plenty.rawValue)
        #expect(properties["place"] as? String == PlaceIntent.atTheGym.rawValue)
    }

    /// `has_body` is the only trace the body question leaves. If it stopped
    /// tracking the answer it would be a silently useless property.
    @Test("has_body reports whether the question was answered, not which answer")
    func hasBodyCarriesItsSignal() {
        #expect(sensitivePayload(body: .cramping).properties["has_body"] as? Bool == true)
        #expect(sensitivePayload(body: .good).properties["has_body"] as? Bool == true)
        #expect(sensitivePayload(body: nil).properties["has_body"] as? Bool == false)
    }

    @Test("Skipped questions are absent rather than null")
    func skippedQuestionsAreOmitted() {
        let empty = CheckInAnalytics(energy: nil, time: nil, place: nil, body: nil)
        #expect(Set(empty.properties.keys) == ["has_check_in", "has_body"])
        #expect(empty.properties["has_check_in"] as? Bool == false)
    }

    @Test("Answering only the body question still counts as a check-in")
    func bodyOnlyStillCountsAsACheckIn() {
        let bodyOnly = CheckInAnalytics(energy: nil, time: nil, place: nil, body: .cramping)
        #expect(bodyOnly.properties["has_check_in"] as? Bool == true)
        #expect(bodyOnly.properties["energy"] == nil)
    }

    @MainActor
    @Test("The check-in event reaches the sink under its own name")
    func captureReachesTheSink() {
        let sink = FakeAnalyticsSink()
        let original = Analytics.sink
        Analytics.sink = sink
        defer { Analytics.sink = original }

        Analytics.capture(sensitivePayload())

        #expect(sink.captured.count == 1)
        let call = sink.captured.first
        #expect(call?.event == "check_in_completed")
        #expect(call?.properties["energy"] as? String == Energy.strong.rawValue)
        #expect(call?.properties["body"] == nil)
    }

    @MainActor
    @Test("identify and reset reach the sink")
    func identifyAndResetReachTheSink() {
        let sink = FakeAnalyticsSink()
        let original = Analytics.sink
        Analytics.sink = sink
        defer { Analytics.sink = original }

        Analytics.identify("uid-123", properties: ["email": "a@b.com"])
        Analytics.reset()

        #expect(sink.identified.count == 1)
        #expect(sink.identified.first?.userID == "uid-123")
        #expect(sink.identified.first?.properties["email"] as? String == "a@b.com")
        #expect(sink.resetCount == 1)
    }
}

// MARK: - Engagement events

@Suite("Engagement analytics")
struct EngagementAnalyticsTests {
    @Test("Each event carries exactly its permitted keys")
    func wireShapesAreClosed() {
        #expect(Set(EngagementAnalytics.swapUsed(course: .main, isPro: true).keys) == EngagementAnalytics.swapUsedKeys)
        #expect(Set(EngagementAnalytics.swapLimitReached(course: .main).keys) == EngagementAnalytics.swapLimitReachedKeys)
        #expect(Set(EngagementAnalytics.menuViewed(itemCount: 4).keys) == EngagementAnalytics.menuViewedKeys)
        #expect(Set(EngagementAnalytics.tabViewed(.chat).keys) == EngagementAnalytics.tabViewedKeys)
        #expect(Set(EngagementAnalytics.calendarAccessResult(.denied).keys) == EngagementAnalytics.calendarAccessResultKeys)
        #expect(Set(EngagementAnalytics.aiConsentChanged(granted: false, source: .sheet).keys) == EngagementAnalytics.aiConsentChangedKeys)
    }

    @Test("Values are coarse and carry no body state or free text")
    func valuesAreCoarse() throws {
        let all: [[String: Any]] = [
            EngagementAnalytics.swapUsed(course: .main, isPro: false),
            EngagementAnalytics.swapLimitReached(course: .main),
            EngagementAnalytics.menuViewed(itemCount: 4),
            EngagementAnalytics.tabViewed(.you),
            EngagementAnalytics.calendarAccessResult(.connected),
            EngagementAnalytics.aiConsentChanged(granted: true, source: .settings),
        ]
        for properties in all {
            let data = try JSONSerialization.data(withJSONObject: properties, options: [.sortedKeys])
            let json = try #require(String(data: data, encoding: .utf8)).lowercased()
            for body in BodyState.allCases where body != .good {
                #expect(!json.contains(body.rawValue.lowercased()), "\(body.rawValue) reached an engagement event")
            }
        }
    }

    @Test("Consent choice reports granted or declined, with its source")
    func consentChoice() {
        let granted = EngagementAnalytics.aiConsentChanged(granted: true, source: .sheet)
        #expect(granted["choice"] as? String == "granted")
        #expect(granted["source"] as? String == "sheet")
        #expect(EngagementAnalytics.aiConsentChanged(granted: false, source: .settings)["choice"] as? String == "declined")
    }
}

// MARK: - Fake

/// Records what it was handed. Lives here rather than in `Fixtures`, the way
/// `FakeCopyTransport` lives in `CopyServiceTests`.
private final class FakeAnalyticsSink: AnalyticsSink {
    struct Call {
        let event: String
        let properties: [String: Any]
    }

    private(set) var captured: [Call] = []

    func capture(_ event: String, properties: [String: Any]) {
        captured.append(Call(event: event, properties: properties))
    }

    func log(_: String, level _: PostHogLogSeverity, attributes _: [String: Any]) {}

    private(set) var identified: [(userID: String, properties: [String: Any])] = []
    private(set) var resetCount = 0

    func identify(_ userID: String, properties: [String: Any]) {
        identified.append((userID, properties))
    }

    func reset() {
        resetCount += 1
    }
}

@Suite("Routine analytics")
struct RoutineAnalyticsTests {

    private let typed = "Mom's sore back stretch"

    @Test("Custom routine events carry no title, only the permitted keys")
    func customRoutineHasNoTitle() throws {
        let properties = RoutineAnalytics.customRoutineProperties(
            activity: "stretching",
            durationMin: 10,
            course: "main",
            addedToToday: true
        )

        #expect(Set(properties.keys) == RoutineAnalytics.customRoutineKeys)
        #expect(properties["title"] == nil)
    }

    @Test("Session-hidden events carry the id and nothing typed")
    func sessionHiddenHasOnlyID() {
        let properties = RoutineAnalytics.sessionHiddenProperties(sessionID: "own-1234")

        #expect(Set(properties.keys) == RoutineAnalytics.sessionHiddenKeys)
        #expect(!String(describing: properties).contains(typed))
    }
}

@Suite("Chat analytics")
struct ChatAnalyticsTests {

    @Test("Reply events carry the permitted keys and values are enums, numbers, or booleans")
    func replyShape() {
        let properties = ChatAnalytics.replyReceived(
            mode: .recommendation,
            intent: .refinement,
            phase: .recommendationActive,
            hasCard: true,
            quickReplyCount: 4,
            latencyMs: 812,
            hadCheckInOverrides: true
        )

        #expect(Set(properties.keys) == ChatAnalytics.replyReceivedKeys)
        for value in properties.values {
            let isPermitted = value is Bool || value is Int
                || ["clarifying", "banter", "recommendation", "refinement", "recommendation_active"]
                    .contains(value as? String ?? "")
            #expect(isPermitted, "\(value) is not a closed value")
        }
    }

    @Test("Failure, chip, and card events carry only their own key")
    func otherShapes() {
        #expect(Set(ChatAnalytics.replyFailed(latencyMs: 1).keys) == ChatAnalytics.replyFailedKeys)
        #expect(Set(ChatAnalytics.quickReplyTapped(.customPrompt).keys) == ChatAnalytics.quickReplyTappedKeys)
        #expect(ChatAnalytics.quickReplyTapped(.customPrompt)["action_type"] as? String == "custom_prompt")
        #expect(Set(ChatAnalytics.cardCommitted(source: .card).keys) == ChatAnalytics.cardCommittedKeys)
    }
}
