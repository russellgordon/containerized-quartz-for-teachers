import XCTest

/// Temporary: prints the assistant window's element tree so the marketing
/// capture can address the prompt shelf by what it actually is.
final class AssistantTreeDump: MarketingScreenshotCase {

    func testDumpAssistantTree() throws {
        let application: XCUIApplication = launchApp(workspacePath: try demoWorkspacePath())
        openSection(1, ofCourse: "ENG2D", in: application)

        let sectionRow: XCUIElement = application.descendants(matching: .any)
            .matching(identifier: "sidebar-ENG2D-section1")
            .firstMatch
        sectionRow.rightClick()
        let assistantItem: XCUIElement = application.menuItems["Revise with Local AI Assistant…"]
        XCTAssertTrue(assistantItem.waitForExistence(timeout: 15))
        assistantItem.click()

        XCTAssertTrue(application.textFields["assistInputField"].waitForExistence(timeout: 240))
        Thread.sleep(forTimeInterval: 3.0)

        print("=== ASSISTANT TREE BEGIN ===")
        print(application.debugDescription)
        print("=== ASSISTANT TREE END ===")
    }
}
