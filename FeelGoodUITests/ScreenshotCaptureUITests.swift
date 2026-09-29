//
//  ScreenshotCaptureUITests.swift
//  FeelGoodUITests
//
//  TEMPORARY — recaptures 01/04/05 after "Five minutes of qi gong" showed up
//  as the Appetizer in the previous capture and the user asked for a
//  different one. Not part of the shipping app; safe to delete once the
//  screenshots are captured.
//
//  The simulator this runs against is expected to already be onboarded, with
//  one completed Appetizer ("Five minutes of qi gong") in history and today's
//  check-in already set to Energized / 35 min / Outdoors / Feeling good. This
//  test edits that check-in to get a fresh, history-aware menu, then drives
//  whatever Appetizer comes back through to completion.
//
//  Root-cause note: resubmitting the check-in with *identical* answers is a
//  guaranteed no-op — TodayView.handleCheckInDismissal() only calls
//  regenerateMenu() when `model.checkIn != update.checkIn`, and PlanCheckIn
//  is a plain Hashable struct over energy/time/place/bodies with no
//  timestamp. So this goes straight to changing the time budget (the
//  fallback the task described), instead of wasting a round trip on an
//  identical resubmit that the source proves can't change anything.
//

import XCTest

final class ScreenshotCaptureUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private let outputDir = "/Users/ameena/Projects/yoga/FeelGood/app-store-screenshots-editor/public/screenshots/apple/iphone/en"

    private func save(_ app: XCUIApplication, _ name: String) {
        let shot = app.screenshot()
        if let data = shot.image.pngData() {
            let url = URL(fileURLWithPath: "\(outputDir)/\(name).png")
            try? data.write(to: url)
        }
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Walks the goal-led check-in: Energised, Clear-headed, then a length.
    /// Every step moves on by itself, so the last tap closes the sheet.
    private func checkIn(forLength length: String, in app: XCUIApplication) {
        let goal = app.buttons["Energised"]
        XCTAssertTrue(goal.waitForExistence(timeout: 5))
        goal.tap()
        let answer = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Clear-headed'")).firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5))
        answer.tap()
        let chip = app.buttons[length]
        XCTAssertTrue(chip.waitForExistence(timeout: 5))
        chip.tap()
    }

    private func currentAppetizerLabel(in app: XCUIApplication, timeout: TimeInterval = 10) -> String? {
        let card = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Appetizer.'")).firstMatch
        guard card.waitForExistence(timeout: timeout) else { return nil }
        return card.label
    }

    func testRecaptureAppetizer() throws {
        let app = XCUIApplication()
        app.launch()

        // Lands on Today, already checked in (Energized / 35 min / Outdoors /
        // Feeling good), with "Five minutes of qi gong" already Done.
        let editButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Edit'")).firstMatch
        XCTAssertTrue(editButton.waitForExistence(timeout: 10))

        var appetizerLabel = currentAppetizerLabel(in: app) ?? ""
        XCTAssertTrue(
            appetizerLabel.localizedCaseInsensitiveContains("qi gong")
                || appetizerLabel.localizedCaseInsensitiveContains("qigong"),
            "Expected the pre-existing qigong Appetizer before editing the check-in; found: \(appetizerLabel)"
        )

        // Check in again with a shorter length (35 -> 20 min) so `didChange`
        // is true and the menu actually regenerates against history that now
        // includes the completed qigong session.
        editButton.tap()
        checkIn(forLength: "Twenty minutes", in: app)
        sleep(3)

        appetizerLabel = currentAppetizerLabel(in: app) ?? ""

        if appetizerLabel.localizedCaseInsensitiveContains("qi gong")
            || appetizerLabel.localizedCaseInsensitiveContains("qigong") {
            // Second fallback: drop further, to 15 min (index 3).
            editButton.tap()
            checkIn(forLength: "Fifteen minutes", in: app)
            sleep(3)
            appetizerLabel = currentAppetizerLabel(in: app) ?? ""
        }

        XCTAssertFalse(
            appetizerLabel.localizedCaseInsensitiveContains("qi gong")
                || appetizerLabel.localizedCaseInsensitiveContains("qigong"),
            "Still landed on the qigong Appetizer after two time-budget changes: \(appetizerLabel)"
        )

        // 01 — Today, fresh menu, nothing done yet, new Appetizer showing.
        save(app, "01")

        // 04 — the new Appetizer's detail screen, before completing it.
        let appetizerCard = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Appetizer.'")).firstMatch
        XCTAssertTrue(appetizerCard.waitForExistence(timeout: 5))
        appetizerCard.tap()
        sleep(2)
        save(app, "04")

        // Start the session.
        let startButton = app.buttons
            .matching(NSPredicate(format: "label BEGINSWITH 'Start' OR label BEGINSWITH 'Resume'"))
            .firstMatch
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()
        sleep(2)

        // Drive through every step via the player's "Next" control — it
        // unconditionally calls advance() regardless of timers/counts
        // (PlayerView.swift), so this works for any Appetizer, timed or not.
        let nextButton = app.buttons["Next"]
        for _ in 0..<24 {
            guard nextButton.waitForExistence(timeout: 2), nextButton.isHittable else { break }
            nextButton.tap()
            usleep(300_000)
        }

        // Completion screen ("How did that feel?") — skip feedback to finish fast.
        let skipFeedback = app.buttons["Skip feedback"]
        if skipFeedback.waitForExistence(timeout: 10) {
            skipFeedback.tap()
        }

        // Optional "Little Win" celebration sheet.
        let nice = app.buttons["Nice"]
        if nice.waitForExistence(timeout: 5) {
            nice.tap()
        }

        // Back on Today with the new Appetizer now marked Done.
        sleep(2)
        save(app, "05")
    }
}
