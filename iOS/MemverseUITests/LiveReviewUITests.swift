import XCTest

/// Left nil in the tree. A local run can fill these, then put them back.
enum LiveCredentials {
    static let email: String? = nil
    static let password: String? = nil
}

/// Opt-in check against a local Rails server. The default suite skips it.
/// It signs in through `POST /oauth/token` as a synthetic user and saves one grade.
final class LiveReviewUITests: XCTestCase {
    func testLiveSignInPracticesOneVerseAndSaves() throws {
        let credentials = try liveCredentials()
        let email = credentials.email
        let password = credentials.password

        let app = XCUIApplication()
        app.launchArguments = ["-uiTestingResetKeychain"]
        app.launch()

        let emailField = app.textFields["emailField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 10))
        emailField.tap()
        emailField.typeText(email)

        let passwordField = app.secureTextFields["passwordField"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))
        passwordField.tap()
        passwordField.typeText(password)

        app.buttons["signInButton"].tap()

        let due = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "due-")).element
        if due.waitForExistence(timeout: 30) == false {
            if app.staticTexts["signInError"].exists {
                XCTFail("Sign-in failed: \(app.staticTexts["signInError"].label)")
            }
            XCTFail("Due verses did not load")
        }
        due.tap()

        XCTAssertTrue(app.descendants(matching: .any)["reviewReference"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["revealedVerse"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["mnemonicHint"].waitForExistence(timeout: 5))

        var grade = app.buttons["grade-5"]
        if grade.waitForExistence(timeout: 2) == false {
            app.swipeUp()
            grade = app.buttons["grade-5"]
        }
        XCTAssertTrue(grade.waitForExistence(timeout: 5))
        grade.tap()

        let saved = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Saved. Next review")).firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 30))
        attach(app)
    }

    private func liveCredentials() throws -> (email: String, password: String) {
        guard let email = LiveCredentials.email, email.isEmpty == false,
              let password = LiveCredentials.password, password.isEmpty == false else {
            throw XCTSkip("Opt-in. Fill LiveCredentials to sign in against the local Rails server.")
        }
        return (email, password)
    }

    private func attach(_ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
