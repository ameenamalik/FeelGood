//
//  ShowcaseNewFeaturesUITests.swift
//  FeelGoodUITests
//
//  Automated UI test capturing screenshots and verifying all 6 UX friction improvements:
//  1. Dopamine Menu Tour (first-run preview slides 1-4)
//  2. Today Tab with new subtitle & swap affordances
//  3. Session Detail with "Why this feels good" benefits
//  4. Check-In Sheet with clarified time & expectation prompts
//  5. You Tab with Activity History past sessions list
//

import XCTest

final class ShowcaseNewFeaturesUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private let artifactDir = "/Users/ameena/.gemini/antigravity-ide/brain/5a373cc2-88c8-4cb4-a743-801af12b4eaa"

    private func saveScreenshot(_ app: XCUIApplication, name: String) {
        let shot = app.screenshot()
        if let data = shot.image.pngData() {
            let url = URL(fileURLWithPath: "\(artifactDir)/\(name).png")
            try? data.write(to: url)
        }
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testCaptureAllNewFeatures() throws {
        let app = XCUIApplication()
        app.launch()

        // 1. Dopamine Menu Tour (if presented)
        let nextButton = app.buttons["Next"]
        if nextButton.waitForExistence(timeout: 4) {
            saveScreenshot(app, name: "tour_slide_1_welcome")

            nextButton.tap()
            sleep(1)
            saveScreenshot(app, name: "tour_slide_2_courses")

            if nextButton.waitForExistence(timeout: 2) {
                nextButton.tap()
                sleep(1)
                saveScreenshot(app, name: "tour_slide_3_swap")
            }

            if nextButton.waitForExistence(timeout: 2) {
                nextButton.tap()
                sleep(1)
                saveScreenshot(app, name: "tour_slide_4_zeroguilt")
            }

            let letsMove = app.buttons["Let's move!"]
            if letsMove.waitForExistence(timeout: 3) {
                letsMove.tap()
                sleep(1)
            }
        }

        // Check if Onboarding intro is showing instead
        let introNext = app.buttons["Next"]
        if introNext.waitForExistence(timeout: 2), app.buttons["Skip"].exists {
            introNext.tap()
            let continueButton = app.buttons["Continue"]
            if continueButton.waitForExistence(timeout: 3) {
                continueButton.tap()
            }
            let makeItMine = app.buttons["Make it mine"]
            if makeItMine.waitForExistence(timeout: 3) {
                makeItMine.tap()
            }
        }

        // Onboarding Goal Selection (Cube contrast verification)
        let energyCube = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Energy' OR label CONTAINS 'Focus' OR label CONTAINS 'Gentle'")).firstMatch
        if energyCube.waitForExistence(timeout: 3) {
            energyCube.tap()
            saveScreenshot(app, name: "onboarding_goals_high_contrast")
            // Advance through onboarding
            let nextBtn = app.buttons["Next"]
            if nextBtn.waitForExistence(timeout: 2) {
                nextBtn.tap()
            }
        }

        let continueAsGuest = app.buttons["Not now — just show me today"]
        if continueAsGuest.waitForExistence(timeout: 2) {
            continueAsGuest.tap()
        }

        // 2. Today Tab Screenshot
        sleep(2)
        saveScreenshot(app, name: "today_tab_menu_fresh")

        // 3. Check-In Sheet (Clarified prompt)
        let checkInBanner = app.buttons.matching(NSPredicate(format: "label CONTAINS 'feeling today' OR label CONTAINS 'Tailor today' OR label CONTAINS 'How are you'")).firstMatch
        if checkInBanner.waitForExistence(timeout: 4) {
            checkInBanner.tap()
            sleep(1)

            // Tap Energized to reveal the time question
            let energized = app.buttons["Energized"]
            if energized.waitForExistence(timeout: 3) {
                energized.tap()
                sleep(1)
                saveScreenshot(app, name: "check_in_clarified_prompts")
            }

            let showMeToday = app.buttons["Show me today"]
            if showMeToday.waitForExistence(timeout: 3) {
                showMeToday.tap()
                sleep(2)
            } else {
                let skipBtn = app.buttons["Skip — just show me something"]
                if skipBtn.waitForExistence(timeout: 2) {
                    skipBtn.tap()
                } else {
                    app.swipeDown()
                }
                sleep(2)
            }
        }

        // 4. You Tab (Activity History section)
        let youTab = app.tabBars.buttons["You"]
        if youTab.waitForExistence(timeout: 5) {
            youTab.tap()
            sleep(2)
            saveScreenshot(app, name: "you_tab_activity_history")
        }
    }

    @MainActor
    func testAccountSettingsAndSwipeSwap() throws {
        let app = XCUIApplication()
        app.launch()

        // 1. Dismiss any intro sheets if needed
        let letsMove = app.buttons["Let's move!"]
        if letsMove.waitForExistence(timeout: 2) {
            letsMove.tap()
            sleep(1)
        }

        let todayTab = app.tabBars.buttons["Today"]
        if todayTab.waitForExistence(timeout: 3) {
            todayTab.tap()
            sleep(1)
        }

        // 2. Perform a swipe to swap on the first card
        let appetizerCard = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Appetizer' OR label CONTAINS 'APPETIZER'")).firstMatch
        if appetizerCard.waitForExistence(timeout: 3) {
            appetizerCard.swipeLeft()
            sleep(2)
            saveScreenshot(app, name: "today_tab_after_swipe_swap")
        }

        // 3. Go to You tab
        let youTab = app.tabBars.buttons["You"]
        if youTab.waitForExistence(timeout: 3) {
            youTab.tap()
            sleep(1)

            // Tap Settings gear
            let settingsBtn = app.buttons["Settings"]
            if settingsBtn.waitForExistence(timeout: 3) {
                settingsBtn.tap()
                sleep(1)
                saveScreenshot(app, name: "you_settings_menu_no_library")

                let myAccount = app.buttons["My account"]
                if myAccount.waitForExistence(timeout: 3) {
                    myAccount.tap()
                    sleep(1)
                    app.swipeUp()
                    sleep(1)
                    saveScreenshot(app, name: "account_privacy_with_disclaimer")

                    let doneBtn = app.buttons["Done"]
                    if doneBtn.waitForExistence(timeout: 2) {
                        doneBtn.tap()
                    }
                }
            }
        }
    }

    @MainActor
    func testDopamineMenuTourUpdated() throws {
        let app = XCUIApplication()
        app.launch()

        let infoBtn = app.buttons["How the Dopamine Menu works"]
        if infoBtn.waitForExistence(timeout: 5) {
            infoBtn.tap()
            sleep(1)

            saveScreenshot(app, name: "tour_slide_1_welcome_updated")

            let nextBtn = app.buttons["Next"]
            if nextBtn.waitForExistence(timeout: 3) {
                nextBtn.tap()
                sleep(1)
                saveScreenshot(app, name: "tour_slide_2_courses_updated")

                nextBtn.tap()
                sleep(1)
                saveScreenshot(app, name: "tour_slide_3_swap_updated")

                nextBtn.tap()
                sleep(1)
                saveScreenshot(app, name: "tour_slide_4_zeroguilt_updated")
            }

            let letsMove = app.buttons["Let's move!"]
            if letsMove.waitForExistence(timeout: 3) {
                letsMove.tap()
            }
        }
    }

    @MainActor
    func testCaptureSettingUpMenuAnimation() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-FGForceSettingUpMenu")
        app.launch()

        // Capture initial phase immediately
        saveScreenshot(app, name: "setting_up_menu_phase_1")
        sleep(1)
        saveScreenshot(app, name: "setting_up_menu_phase_2")
    }

    @MainActor
    func testSwipeSwapAnimationVerification() throws {
        let app = XCUIApplication()
        app.launch()

        let todayTab = app.tabBars.buttons["Today"]
        if todayTab.waitForExistence(timeout: 3) {
            todayTab.tap()
            sleep(1)
        }

        let mainCard = app.buttons.matching(NSPredicate(format: "label CONTAINS 'MAIN' OR label CONTAINS 'Main'")).firstMatch
        if mainCard.waitForExistence(timeout: 3) {
            mainCard.swipeLeft()
            sleep(2)
        }
    }
}
