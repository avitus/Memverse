import XCTest

final class ReviewFlowUITests: XCTestCase {
    func testLoadFailureStaysSignedInUntilSignOut() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestingLoadFailed"]
        app.launch()

        XCTAssertTrue(app.staticTexts["loadError"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["retryLoad"].exists)
        XCTAssertFalse(app.buttons["signInButton"].exists)
        app.buttons["retryLoad"].tap()
        XCTAssertTrue(app.staticTexts["loadError"].exists)
        app.buttons["signOutButton"].tap()
        XCTAssertTrue(app.buttons["signInButton"].waitForExistence(timeout: 5))
        attach(app)
    }

    func testSignedOutScreenHasASignInButton() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestingSignedOut"]
        app.launch()

        XCTAssertTrue(app.buttons["signInButton"].waitForExistence(timeout: 5))
        attach(app)
    }

    func testReviewStaysUsableAtTheLargestContentSize() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTestingQueue",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["due-1"].waitForExistence(timeout: 5))
        app.descendants(matching: .any)["due-1"].tap()
        XCTAssertTrue(app.buttons["grade-5"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Alpha bravo charlie."].exists)
        attach(app)
    }

    func testReviewHidesTheVerseUntilAskedAndSavesAGrade() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestingQueue"]
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["due-1"].waitForExistence(timeout: 5))
        app.descendants(matching: .any)["due-1"].tap()

        XCTAssertTrue(app.staticTexts["reviewReference"].waitForExistence(timeout: 5) || app.staticTexts["Fixture 1:1"].exists)
        XCTAssertFalse(app.staticTexts["Alpha bravo charlie."].exists)

        app.buttons["showVerse"].tap()
        XCTAssertTrue(app.staticTexts["Alpha bravo charlie."].exists)

        app.buttons["grade-5"].tap()
        XCTAssertTrue(app.staticTexts["saveStatus"].waitForExistence(timeout: 5))
        attach(app)
    }

    private func attach(_ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
