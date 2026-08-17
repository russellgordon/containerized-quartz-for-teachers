import AppKit
import XCTest

/// Screenshots for plantoir.app.
///
/// These are not tests of behaviour — they exist so the marketing site can be
/// rebuilt from the real app rather than from images somebody remembered to
/// retake. `website/shots/capture.py` runs them twice, once with the Mac in
/// light appearance and once in dark, and exports the attachments into
/// `site/img/`. Each attachment's name is the shot id in
/// `website/shots.json`; renaming one here without renaming it there leaves a
/// placeholder on a published page.
///
/// They need a demo working folder with the ENG2D, MCV4U and SCH3U courses in
/// it, supplied as `MARKETING_WORKSPACE`. `DemoWorkspaceProvisioning` below
/// builds one.
class MarketingScreenshotCase: XCTestCase {

    // MARK: - Stored properties

    /// A window big enough to read in a screenshot and small enough to sit on
    /// a page. Points; the capture is taken at the display's own resolution.
    static let windowWidth: CGFloat = 1280
    static let windowHeight: CGFloat = 800

    /// The autosave name AppKit gives the app's main window. Passing a frame
    /// under this key as a launch argument puts it in the argument domain,
    /// which outranks the saved value — so every capture is the same size
    /// regardless of where the window was left last time.
    static let mainWindowFrameKey: String =
        "NSWindow Frame SwiftUI.ModifiedContent<QuartzTeachers.WindowRootView, SwiftUI._FlexFrameLayout>-1-AppWindow-1"

    /// The assistant keeps its own window, remembered per course and section.
    static let assistantWindowFrameKey: String = "NSWindow Frame AssistantWindow-ENG2D-1"
    static let assistantWidth: CGFloat = 480
    static let assistantHeight: CGFloat = 760

    // MARK: - Functions

    /// The demo working folder, or a skipped test explaining what is missing.
    func demoWorkspacePath() throws -> String {
        let environment: [String: String] = ProcessInfo.processInfo.environment
        guard let path = environment["MARKETING_WORKSPACE"] else {
            throw XCTSkip("Set MARKETING_WORKSPACE to a working folder holding the demo courses. `python3 website/shots/capture.py` does this for you.")
        }
        return path
    }

    /// The frame string AppKit stores for a window: the window's own frame
    /// followed by the frame of the screen it was on.
    static func frameArgument(width: CGFloat, height: CGFloat) -> String {
        let screen: CGRect = NSScreen.screens.first?.frame ?? CGRect(x: 0, y: 0, width: 1512, height: 982)
        let x: CGFloat = (screen.width - width) / 2
        let y: CGFloat = (screen.height - height) / 2
        return "\(Int(x)) \(Int(y)) \(Int(width)) \(Int(height)) "
            + "\(Int(screen.minX)) \(Int(screen.minY)) \(Int(screen.width)) \(Int(screen.height)) "
    }

    func launchApp(workspacePath: String) -> XCUIApplication {
        let application: XCUIApplication = XCUIApplication()
        application.launchEnvironment["UITEST_WORKSPACE"] = workspacePath
        application.launchArguments = [
            "-" + MarketingScreenshotCase.mainWindowFrameKey,
            MarketingScreenshotCase.frameArgument(
                width: MarketingScreenshotCase.windowWidth,
                height: MarketingScreenshotCase.windowHeight
            ),
            "-" + MarketingScreenshotCase.assistantWindowFrameKey,
            MarketingScreenshotCase.frameArgument(
                width: MarketingScreenshotCase.assistantWidth,
                height: MarketingScreenshotCase.assistantHeight
            ),
        ]
        application.launch()
        return application
    }

    /// Saves one window as an attachment named for its entry in shots.json.
    func save(_ window: XCUIElement, as name: String) {
        let attachment: XCTAttachment = XCTAttachment(screenshot: window.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Opens a course's section in the sidebar and returns the main window.
    @discardableResult
    func openSection(_ sectionNumber: Int, ofCourse code: String, in application: XCUIApplication) -> XCUIElement {
        let courseRow: XCUIElement = application.outlines.staticTexts[code]
        XCTAssertTrue(courseRow.waitForExistence(timeout: 30), "\(code) should be in the sidebar")
        courseRow.click()
        application.typeKey(.rightArrow, modifierFlags: [])

        let sectionRow: XCUIElement = application.descendants(matching: .any)
            .matching(identifier: "sidebar-\(code)-section\(sectionNumber)")
            .firstMatch
        XCTAssertTrue(sectionRow.waitForExistence(timeout: 20), "Section \(sectionNumber) of \(code) should be in the sidebar")
        sectionRow.click()
        return application.windows.firstMatch
    }

    /// A pause long enough for a view to settle before it is photographed.
    /// Screenshots are the one place where "it exists" is not the same as
    /// "it has finished drawing".
    func settle(_ seconds: TimeInterval = 1.5) {
        Thread.sleep(forTimeInterval: seconds)
    }
}

/// The captures themselves. Named in order because XCTest runs a class's
/// tests alphabetically, and the slow ones (which need a container) belong
/// last so a failure there still leaves the quick ones captured.
final class MarketingScreenshots: MarketingScreenshotCase {

    // MARK: - Functions

    /// The whole product in one picture: courses in the sidebar, one section
    /// open beside them.
    func test1Courses() throws {
        let application: XCUIApplication = launchApp(workspacePath: try demoWorkspacePath())
        let window: XCUIElement = openSection(1, ofCourse: "ENG2D", in: application)
        XCTAssertTrue(application.buttons["previewButton"].waitForExistence(timeout: 20))
        settle()
        save(window, as: "courses")
    }

    /// Adding a course: the panel filled in for a code that has ready-made
    /// material, before anything is created.
    func test2NewCourse() throws {
        let application: XCUIApplication = launchApp(workspacePath: try demoWorkspacePath())
        let window: XCUIElement = application.windows.firstMatch
        XCTAssertTrue(application.outlines.staticTexts["ENG2D"].waitForExistence(timeout: 30))

        application.buttons["addCourseButton"].click()
        let codeField: XCUIElement = application.textFields["wizardCourseCodeField"]
        XCTAssertTrue(codeField.waitForExistence(timeout: 15), "The new course panel should open")
        codeField.click()
        codeField.typeText("SBI3U")

        // The name fills itself in from the code; give it a moment to land.
        settle(2.0)

        let sectionNumbers: XCUIElement = application.textFields["wizardSectionNumbersField"]
        if sectionNumbers.exists {
            sectionNumbers.click()
            sectionNumbers.typeKey("a", modifierFlags: .command)
            sectionNumbers.typeText("1, 2")
        }
        settle(1.5)
        save(window, as: "new-course")

        application.buttons["wizardCloseButton"].click()
    }

    /// What a section's own settings look like.
    func test3Section() throws {
        let application: XCUIApplication = launchApp(workspacePath: try demoWorkspacePath())
        let window: XCUIElement = openSection(1, ofCourse: "MCV4U", in: application)
        XCTAssertTrue(application.buttons["previewButton"].waitForExistence(timeout: 20))
        settle(2.0)
        save(window, as: "section")
    }

    /// Building a preview: the progress wording on the way, and the finished
    /// site in the window at the end. One test, because the two are two
    /// moments of the same run.
    func test4PreviewAndProgress() throws {
        let application: XCUIApplication = launchApp(workspacePath: try demoWorkspacePath())
        let window: XCUIElement = openSection(1, ofCourse: "ENG2D", in: application)

        let previewButton: XCUIElement = application.buttons["previewButton"]
        XCTAssertTrue(previewButton.waitForExistence(timeout: 20))
        previewButton.click()

        let milestone: XCUIElement = application.staticTexts["taskMilestoneLabel"]
        XCTAssertTrue(milestone.waitForExistence(timeout: 60), "Progress should be described while the site builds")
        // Far enough in that the wording is about the site rather than about
        // starting up, but not so far that the build has finished.
        settle(8.0)
        save(window, as: "progress")

        let webView: XCUIElement = application.webViews.firstMatch
        XCTAssertTrue(webView.waitForExistence(timeout: 900), "The built site should appear in the window")
        settle(6.0)
        save(window, as: "preview")

        if application.buttons["stopPreviewButton"].exists {
            application.buttons["stopPreviewButton"].click()
        }
    }

    /// The assistant, holding a plan and waiting to be told to go ahead.
    func test5Assistant() throws {
        let application: XCUIApplication = launchApp(workspacePath: try demoWorkspacePath())
        openSection(1, ofCourse: "ENG2D", in: application)

        let sectionRow: XCUIElement = application.descendants(matching: .any)
            .matching(identifier: "sidebar-ENG2D-section1")
            .firstMatch
        sectionRow.rightClick()

        let assistantItem: XCUIElement = application.menuItems["Revise with Local AI Assistant…"]
        XCTAssertTrue(assistantItem.waitForExistence(timeout: 15), "The section menu should offer the assistant")
        assistantItem.click()

        let input: XCUIElement = application.textFields["assistInputField"]
        XCTAssertTrue(input.waitForExistence(timeout: 240), "The assistant should be ready")
        input.click()
        input.typeText("Hide Unit 4, Day 12 — we didn't get to it")
        application.buttons["assistSendButton"].click()

        // The reply is a plan with a button to approve it; that is the moment
        // worth photographing, because it is the promise the product makes.
        let approve: XCUIElement = application.buttons["assistApproveButton"]
        XCTAssertTrue(approve.waitForExistence(timeout: 300), "The assistant should answer with something to approve")
        settle(2.0)

        let assistantWindow: XCUIElement = assistantWindowIn(application)
        save(assistantWindow, as: "assistant")

        if application.buttons["assistDeclineButton"].exists {
            application.buttons["assistDeclineButton"].click()
        }
    }

    /// The assistant lives in its own window; find it by the field only it has.
    func assistantWindowIn(_ application: XCUIApplication) -> XCUIElement {
        let windows: XCUIElementQuery = application.windows
        for index in 0..<windows.count {
            let candidate: XCUIElement = windows.element(boundBy: index)
            if candidate.textFields["assistInputField"].exists {
                return candidate
            }
        }
        return windows.firstMatch
    }
}

/// Builds the demo working folder by driving the app's own new-course panel.
///
/// Not part of the capture run: it takes minutes, needs a container, and the
/// folder it produces is reused by every capture afterwards. Kept separate so
/// a re-shoot costs nothing.
final class DemoWorkspaceProvisioning: MarketingScreenshotCase {

    // MARK: - Functions

    func testCreateDemoCourses() throws {
        let workspacePath: String = try demoWorkspacePath()
        let application: XCUIApplication = launchApp(workspacePath: workspacePath)

        // A brand-new folder needs the launchers put into it first.
        let initialize: XCUIElement = application.buttons["initializeFolderButton"]
        if initialize.waitForExistence(timeout: 10) {
            initialize.click()
        }

        let wanted: [(code: String, sections: String)] = [
            ("ENG2D", "1, 2"),
            ("MCV4U", "1"),
            ("SCH3U", "1"),
        ]

        for course in wanted {
            if application.outlines.staticTexts[course.code].waitForExistence(timeout: 5) {
                continue
            }
            try createCourse(code: course.code, sections: course.sections, in: application)
        }

        for course in wanted {
            XCTAssertTrue(
                application.outlines.staticTexts[course.code].waitForExistence(timeout: 60),
                "\(course.code) should have been created"
            )
        }
    }

    func createCourse(code: String, sections: String, in application: XCUIApplication) throws {
        let addButton: XCUIElement = application.buttons["addCourseButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 60), "The sidebar should offer to add a course")
        addButton.click()

        let codeField: XCUIElement = application.textFields["wizardCourseCodeField"]
        XCTAssertTrue(codeField.waitForExistence(timeout: 20))
        codeField.click()
        codeField.typeText(code)
        Thread.sleep(forTimeInterval: 2.0)

        let sectionNumbers: XCUIElement = application.textFields["wizardSectionNumbersField"]
        if sectionNumbers.exists {
            sectionNumbers.click()
            sectionNumbers.typeKey("a", modifierFlags: .command)
            sectionNumbers.typeText(sections)
        }

        application.buttons["createCourseButton"].click()

        // Creating a course runs the real setup script, which builds the site
        // builder on a cold machine. Minutes, not seconds — so this waits a
        // long time, but watches for the failure panel as well as for success.
        // Waiting only for success turned a folder misconfigured in one second
        // into a test that sat there for half an hour saying nothing.
        let created: XCUIElement = application.outlines.staticTexts[code]
        let failure: XCUIElement = application.staticTexts["failureExplanation"]
        let deadline: Date = Date().addingTimeInterval(1800)
        while Date() < deadline {
            if created.exists {
                break
            }
            if failure.exists {
                XCTFail("Creating \(code) failed: \(failure.label)")
                return
            }
            Thread.sleep(forTimeInterval: 3.0)
        }
        XCTAssertTrue(created.exists, "\(code) should appear once setup finishes")

        let closeButton: XCUIElement = application.buttons["wizardCloseActionButton"]
        if closeButton.exists {
            closeButton.click()
        }
        Thread.sleep(forTimeInterval: 2.0)
    }
}
