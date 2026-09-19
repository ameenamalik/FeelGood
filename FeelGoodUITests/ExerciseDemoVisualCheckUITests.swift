//
//  ExerciseDemoVisualCheckUITests.swift
//  FeelGoodUITests
//

import XCTest

final class ExerciseDemoVisualCheckUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private let brainDir = "/Users/ameena/.gemini/antigravity-ide/brain/84f6589c-19ef-4db9-b044-76cf7ef84e21"

    private func saveScreenshot(_ app: XCUIApplication, name: String) {
        let shot = app.screenshot()
        if let data = shot.image.pngData() {
            let url = URL(fileURLWithPath: "\(brainDir)/\(name).png")
            try? data.write(to: url)
        }
    }

    func testVisualCheckNewExerciseDemos() throws {
        let app = XCUIApplication()
        app.launch()

        // 1. Qigong & Deep Breath Check
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.launch()
        _ = safari.wait(for: .runningForeground, timeout: 5)

        // Open Morning Qigong session via deep link URL
        let url = URL(string: "feelgood://session/app-morning-qigong")!
        app.open(url)
        _ = app.wait(for: .runningForeground, timeout: 5)

        let startButton = app.buttons["Start"]
        if startButton.waitForExistence(timeout: 5) {
            startButton.tap()
        }

        // Step 1: Stand and settle (deep-breath)
        sleep(2)
        saveScreenshot(app, name: "sim-visual-01-deep-breath")

        // Step 2: Lifting the sky (qigong-lifting-the-sky)
        let nextButton = app.buttons["Next"]
        if nextButton.waitForExistence(timeout: 5) {
            nextButton.tap()
        }
        sleep(2)
        saveScreenshot(app, name: "sim-visual-02-lifting-the-sky")

        // 2. Shakeout Check
        let shakeURL = URL(string: "feelgood://session/app-shake-out-five")!
        app.open(shakeURL)
        _ = app.wait(for: .runningForeground, timeout: 5)

        let startShake = app.buttons["Start"]
        if startShake.waitForExistence(timeout: 5) {
            startShake.tap()
        }
        sleep(1)

        // Step 1 is "Settle & breathe" (deep-breath) -> advance to "Full body shake"
        if nextButton.waitForExistence(timeout: 5) {
            nextButton.tap()
        }
        sleep(2)
        saveScreenshot(app, name: "sim-visual-03-shakeout")

        // 3. Wall Angels Check
        let deskURL = URL(string: "feelgood://session/main-desk-worker-posture-flow")!
        app.open(deskURL)
        _ = app.wait(for: .runningForeground, timeout: 5)

        let startDesk = app.buttons["Start"]
        if startDesk.waitForExistence(timeout: 5) {
            startDesk.tap()
        }
        sleep(1)

        // Advance to step 3 (Wall angels)
        if nextButton.waitForExistence(timeout: 5) {
            nextButton.tap()
        }
        sleep(1)
        if nextButton.waitForExistence(timeout: 5) {
            nextButton.tap()
        }
        sleep(2)
        saveScreenshot(app, name: "sim-visual-04-wall-angels")
    }
}
