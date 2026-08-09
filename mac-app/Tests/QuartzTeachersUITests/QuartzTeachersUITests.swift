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

    func testAddingFoldersAndFilesInWizardStructureSection() throws {
        let application: XCUIApplication = try launchApp()

        let newCourseButton: XCUIElement = application.buttons["newCourseButton"]
        XCTAssertTrue(newCourseButton.waitForExistence(timeout: 10))
        newCourseButton.click()

        // Expand the Structure section's disclosure.
        let disclosure: XCUIElement = application.staticTexts["Folders and files"]
        XCTAssertTrue(disclosure.waitForExistence(timeout: 10), "The Structure disclosure should exist")
        disclosure.click()

        // Add a folder by typing and clicking the + button.
        let folderField: XCUIElement = application.textFields["addField-Shared folders"]
        XCTAssertTrue(folderField.waitForExistence(timeout: 5), "The shared-folders add field should appear")
        folderField.click()
        folderField.typeText("Projects")
        let folderAddButton: XCUIElement = application.buttons["addTo-Shared folders"]
        XCTAssertTrue(folderAddButton.isEnabled, "The add button should be clickable")
        folderAddButton.click()
        XCTAssertTrue(application.staticTexts["Projects"].waitForExistence(timeout: 5), "The added folder should appear in the list")

        // Add a file WITHOUT typing .md; it should display without the
        // extension too.
        let fileField: XCUIElement = application.textFields["addField-Shared files"]
        XCTAssertTrue(fileField.waitForExistence(timeout: 5))
        fileField.click()
        fileField.typeText("Field Trips")
        application.buttons["addTo-Shared files"].click()
        XCTAssertTrue(application.staticTexts["Field Trips"].waitForExistence(timeout: 5), "The added file should appear, shown without .md")

        saveScreenshot(named: "06-structure-add", of: application)

        let closeButton: XCUIElement = application.buttons["wizardCloseButton"]
        closeButton.click()
    }

    func testSidebarContextMenuOffersFolderActions() throws {
        let application: XCUIApplication = try launchApp()

        let courseRow: XCUIElement = application.outlines.staticTexts["EXC2O"]
        XCTAssertTrue(courseRow.waitForExistence(timeout: 10))
        courseRow.rightClick()

        let showInFinder: XCUIElement = application.menuItems["Show in Finder"]
        XCTAssertTrue(showInFinder.waitForExistence(timeout: 5), "The context menu should offer Show in Finder")
        let newTerminal: XCUIElement = application.menuItems["New Terminal at Folder"]
        XCTAssertTrue(newTerminal.exists, "The context menu should offer New Terminal at Folder")

        saveScreenshot(named: "07-context-menu", of: application)

        // Close the menu without opening Finder or Terminal windows.
        application.typeKey(.escape, modifierFlags: [])
    }

    /// Regression guard for toolbar-transition layout glitches: while a
    /// preview starts (toolbar state changes underfoot), the progress
    /// header must stay strictly below the toolbar at every sampled
    /// frame. Uses a stub preview so the test needs no Docker and
    /// exercises the exact transition window.
    func testProgressHeaderStaysBelowToolbarWhilePreviewStarts() throws {
        let fixtureURL: URL = try FixtureWorkspace.materialize()

        // Replace the real launcher with a slow, harmless stub so the
        // "starting" state lasts long enough to sample. (It never emits
        // the launch announcement, so the app keeps showing progress.)
        let stubScript: String = """
        #!/bin/bash
        echo "Stub preview starting"
        for step in 1 2 3 4 5 6 7 8 9 10; do
          echo "working step $step"
          sleep 0.3
        done
        exit 0
        """
        let stubURL: URL = fixtureURL.appendingPathComponent("preview.sh")
        try stubScript.write(to: stubURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: stubURL.path)

        let application: XCUIApplication = XCUIApplication()
        application.launchEnvironment["UITEST_WORKSPACE"] = fixtureURL.path
        application.launch()

        let courseRow: XCUIElement = application.outlines.staticTexts["EXC2O"]
        XCTAssertTrue(courseRow.waitForExistence(timeout: 10))
        courseRow.click()
        let sectionRow: XCUIElement = application.outlines.staticTexts["Section 1"]
        XCTAssertTrue(sectionRow.waitForExistence(timeout: 10))
        sectionRow.click()

        let previewButton: XCUIElement = application.buttons["previewButton"]
        XCTAssertTrue(previewButton.waitForExistence(timeout: 10))
        previewButton.click()

        let toolbar: XCUIElement = application.toolbars.firstMatch
        let phaseLabel: XCUIElement = application.staticTexts["taskPhaseLabel"]
        XCTAssertTrue(phaseLabel.waitForExistence(timeout: 5), "The progress header should appear once the preview starts")

        // Sample the layout repeatedly through the transition window.
        var samplesTaken: Int = 0
        for sampleNumber in 0..<12 {
            if !phaseLabel.exists {
                break
            }
            let labelFrame: CGRect = phaseLabel.frame
            let toolbarFrame: CGRect = toolbar.frame
            samplesTaken += 1
            XCTAssertGreaterThanOrEqual(
                labelFrame.minY,
                toolbarFrame.maxY - 2,
                "Sample \(sampleNumber): the progress header (y=\(labelFrame.minY)) must sit below the toolbar (bottom=\(toolbarFrame.maxY))"
            )
            Thread.sleep(forTimeInterval: 0.2)
        }
        XCTAssertGreaterThan(samplesTaken, 3, "The transition window should have been sampled several times")

        saveScreenshot(named: "08-preview-progress-layout", of: application)
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
