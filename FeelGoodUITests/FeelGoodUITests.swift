//
//  FeelGoodUITests.swift
//  FeelGoodUITests
//
//  Created by Ameena Malik on 2026-08-17.
//

import XCTest

final class FeelGoodUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation
    }

    @MainActor
    private func completeOnboarding(_ app: XCUIApplication) {
        let introNext = app.buttons["Next"]
        // Product intro has both Next and Skip. The onboarding quiz also has a
        // Next button, so checking only that label can accidentally advance the
        // quiz when a previous UI-test launch already finished the intro.
        if introNext.waitForExistence(timeout: 2), app.buttons["Skip"].exists {
            introNext.tap()
            let startButton = app.buttons["Start"]
            XCTAssertTrue(startButton.waitForExistence(timeout: 5))
            startButton.tap()
        }

        let continueAsGuest = app.buttons["Not now — just show me today"]
        if continueAsGuest.waitForExistence(timeout: 3) {
            continueAsGuest.tap()
        }

        let guidance = app.buttons["I’m getting started, I’d like clear guidance."]
        if guidance.waitForExistence(timeout: 5) {
            guidance.tap()
            app.buttons["Next"].tap()
        }

        let pilates = app.buttons["Pilates"]
        guard pilates.waitForExistence(timeout: 5) else { return }
        pilates.tap()
        app.buttons["No equipment"].tap()
        app.buttons["At home"].tap()
        app.buttons["Next"].tap()

        app.buttons["Energy"].tap()
        app.buttons["Next"].tap()
        app.buttons["Show me today"].tap()

        // RevenueCat owns the onboarding paywall UI. Prefer its native close
        // action, while retaining the old label as a fallback for cached test
        // paywalls during a dashboard rollout.
        let paywallClose = app.buttons["Close"]
        if paywallClose.waitForExistence(timeout: 5) {
            paywallClose.tap()
        } else {
            let legacyExploreFree = app.buttons["Explore Free Menu First"]
            if legacyExploreFree.waitForExistence(timeout: 2) {
                legacyExploreFree.tap()
            }
        }
    }

    @MainActor
    func testYouTabOpens() throws {
        let app = XCUIApplication()
        app.launch()
        completeOnboarding(app)

        let youTab = app.buttons["You"]
        XCTAssertTrue(youTab.waitForExistence(timeout: 5))
        youTab.tap()

        // Preferences and account sit behind the gear at the top right.
        let settings = app.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()
        XCTAssertTrue(app.buttons["My preferences"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["My account"].exists)
    }

    @MainActor
    private func openViaLibrary(_ app: XCUIApplication, titleContains: String) {
        app.buttons["You"].tap()
        let library = app.buttons["Library"]
        XCTAssertTrue(library.waitForExistence(timeout: 5))
        library.tap()
        let cell = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", titleContains)
        ).firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        cell.tap()
        let start = app.buttons["Start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
    }

    @MainActor
    private func screenshot(_ app: XCUIApplication, name: String, afterSteps: [String]) {
        let next = app.buttons["Next"]
        for stepName in afterSteps {
            XCTAssertTrue(next.waitForExistence(timeout: 5))
            next.tap()
            XCTAssertTrue(app.staticTexts[stepName].waitForExistence(timeout: 5))
        }
        sleep(2)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testGluteBridgeDemoScreenshot() throws {
        let app = XCUIApplication()
        app.launch()
        completeOnboarding(app)
        openViaLibrary(app, titleContains: "Ten gentle minutes on the mat")
        // Breathing -> Pelvic tilts -> Dead bug -> Bridge
        screenshot(app, name: "GluteBridgeDemo", afterSteps: ["Pelvic tilts", "Dead bug", "Bridge"])
    }

    @MainActor
    func testGobletSquatDemoScreenshot() throws {
        let app = XCUIApplication()
        app.launch()
        completeOnboarding(app)
        openViaLibrary(app, titleContains: "Fifteen minutes with weights")
        // Warm up -> Goblet squats
        screenshot(app, name: "GobletSquatDemo", afterSteps: ["Goblet squats"])
    }

    @MainActor
    func testPlankAndSidePlankDemoScreenshot() throws {
        let app = XCUIApplication()
        app.launch()
        completeOnboarding(app)
        openViaLibrary(app, titleContains: "Thirty minutes, full body")
        // Warm up -> The hundred -> Roll ups -> Leg series -> Bridge series -> Side series
        screenshot(app, name: "SidePlankDemo", afterSteps: ["The hundred", "Roll ups and roll overs", "Leg series", "Bridge series", "Side series"])
        // Side series -> Front support
        screenshot(app, name: "PlankDemo", afterSteps: ["Front support"])
    }

    @MainActor
    func testYouTabScreenshot() throws {
        let app = XCUIApplication()
        app.launch()
        completeOnboarding(app)
        app.buttons["You"].tap()
        sleep(1)
        screenshot(app, name: "YouTabLookBack", afterSteps: [])
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
