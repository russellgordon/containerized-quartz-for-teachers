import XCTest

/// Drives the real app against a fixture working folder (a copy of the
/// repository checkout with the EXC2O example course) supplied via the
/// UITEST_WORKSPACE environment variable.
final class QuartzTeachersUITests: XCTestCase {

    // MARK: - Functions

    /// Launches the app pointed at a fixture workspace: the one supplied
    /// via UITEST_WORKSPACE, or a fresh disposable one built from the test
    /// bundle's resources — so plain Cmd-U needs no setup.
    func launchApp() throws -> XCUIApplication {
        let application: XCUIApplication = XCUIApplication()
        let environment: [String: String] = ProcessInfo.processInfo.environment
        if let fixturePath = environment["UITEST_WORKSPACE"] {
            application.launchEnvironment["UITEST_WORKSPACE"] = fixturePath
        } else {
            let fixtureURL: URL = try FixtureWorkspace.materialize()
            application.launchEnvironment["UITEST_WORKSPACE"] = fixtureURL.path
        }
        application.launch()
        return application
    }

    func saveScreenshot(named name: String, of application: XCUIApplication) {
        let screenshot: XCUIScreenshot = application.screenshot()
        let attachment: XCTAttachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testSidebarShowsExampleCourse() throws {
        let application: XCUIApplication = try launchApp()

        let courseRow: XCUIElement = application.outlines.staticTexts["EXC2O"]
        XCTAssertTrue(courseRow.waitForExistence(timeout: 10), "The EXC2O course should appear in the sidebar")

        saveScreenshot(named: "01-sidebar", of: application)
    }

    func testEditingAndSavingCourseSettings() throws {
        let application: XCUIApplication = try launchApp()

        let courseRow: XCUIElement = application.outlines.staticTexts["EXC2O"]
        XCTAssertTrue(courseRow.waitForExistence(timeout: 10))
        courseRow.click()

        let nameField: XCUIElement = application.textFields["courseNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10), "The settings form should appear")

        saveScreenshot(named: "02-settings-form", of: application)

        // Toggle the reading-time setting and save.
        let readingTimeToggle: XCUIElement = application.descendants(matching: .any).matching(identifier: "readingTimeToggle").firstMatch
        XCTAssertTrue(readingTimeToggle.waitForExistence(timeout: 5))
        readingTimeToggle.click()

        let saveButton: XCUIElement = application.buttons["saveButton"]
        XCTAssertTrue(saveButton.isEnabled, "Save should enable after an edit")
        saveButton.click()

        let savedLabel: XCUIElement = application.staticTexts["savedConfirmation"]
        XCTAssertTrue(savedLabel.waitForExistence(timeout: 5), "Saving should confirm")

        saveScreenshot(named: "03-after-save", of: application)
    }

    func testWizardSuggestsCourseNameFromCode() throws {
        let application: XCUIApplication = try launchApp()

        let newCourseButton: XCUIElement = application.buttons["newCourseButton"]
        XCTAssertTrue(newCourseButton.waitForExistence(timeout: 10))
        newCourseButton.click()

        let codeField: XCUIElement = application.textFields["wizardCourseCodeField"]
        XCTAssertTrue(codeField.waitForExistence(timeout: 10), "The wizard sheet should appear")
        codeField.click()
        codeField.typeText("ICS3U")

        // Typing a known Ontario code should auto-fill the formal name.
        let nameField: XCUIElement = application.textFields["wizardCourseNameField"]
        let expectedName: String = "Introduction to Computer Science, Grade 11, U"
        let autoFilled: NSPredicate = NSPredicate(format: "value == %@", expectedName)
        let expectation: XCTNSPredicateExpectation = XCTNSPredicateExpectation(predicate: autoFilled, object: nameField)
        let waitResult: XCTWaiter.Result = XCTWaiter().wait(for: [expectation], timeout: 5)
        XCTAssertEqual(waitResult, .completed, "The course name should auto-fill from the code; value was: \(String(describing: nameField.value))")

        // The short-name suggestion button should switch the name.
        let shortNameButton: XCUIElement = application.buttons["suggestedShortNameButton"]
        XCTAssertTrue(shortNameButton.waitForExistence(timeout: 5))
        shortNameButton.click()
        XCTAssertEqual("\(nameField.value ?? "")", "Intro to Comp Sci")

        saveScreenshot(named: "05-wizard-name-suggestions", of: application)

        let closeButton: XCUIElement = application.buttons["wizardCloseButton"]
        closeButton.click()
    }

    func testCancelRevertsEdits() throws {
        let application: XCUIApplication = try launchApp()

        let courseRow: XCUIElement = application.outlines.staticTexts["EXC2O"]
        XCTAssertTrue(courseRow.waitForExistence(timeout: 10))
        courseRow.click()

        let readingTimeToggle: XCUIElement = application.descendants(matching: .any).matching(identifier: "readingTimeToggle").firstMatch
        XCTAssertTrue(readingTimeToggle.waitForExistence(timeout: 10))
        let initialValue: String = "\(readingTimeToggle.value ?? "")"

        readingTimeToggle.click()

        let cancelButton: XCUIElement = application.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.isEnabled, "Cancel should enable after an edit")
        cancelButton.click()

        let restoredValue: String = "\(readingTimeToggle.value ?? "")"
        XCTAssertEqual(initialValue, restoredValue, "Cancel should revert the toggle")
    }
}
