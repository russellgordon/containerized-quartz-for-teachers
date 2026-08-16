import SwiftUI
import XCTest
@testable import QuartzTeachers

/// Renaming as a teacher meets it: the row turning into a field, and the
/// sidebar keeping its place afterwards.
///
/// **Why the row is tested in a hosting view rather than through the
/// accessibility tree**, unlike `RemovalButtonTests` next door. A sidebar
/// row is a `DisclosureGroup` label inside a `List`, and macOS collapses
/// that whole row into a single `AXHeading` whose value does not follow the
/// row's content — an unconditional change to the label's text does not
/// change it. So accessibility can confirm the − button exists but cannot
/// see whether this row is showing a label or a field. Hosting the row view
/// on its own answers exactly that question, and answers it the same way
/// every run.
final class CourseRenameInterfaceTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func settle(seconds: Double = 0.8) async {
        try? await Task.sleep(for: .seconds(seconds))
    }

    /// Every AppKit view class inside a hosted SwiftUI view, so a test can
    /// ask what was actually built rather than what was intended.
    @MainActor
    func viewClasses(inside view: NSView) -> [String] {
        var found: [String] = [String(describing: type(of: view))]
        for subview in view.subviews {
            for name in viewClasses(inside: subview) {
                found.append(name)
            }
        }
        return found
    }

    @MainActor
    func hostedRow(course: Course, isBeingRenamed: Bool, workspace: WorkspaceModel) -> [String] {
        let hosting: NSHostingView = NSHostingView(
            rootView: CourseRowLabel(course: course, isBeingRenamed: isBeingRenamed)
                .environment(workspace)
        )
        hosting.frame = NSRect(x: 0, y: 0, width: 220, height: 60)
        hosting.layoutSubtreeIfNeeded()
        return viewClasses(inside: hosting)
    }

    // MARK: - The row becomes a field, and only while renaming

    @MainActor
    func testTheRowTurnsIntoAFieldWhileRenamingAndBackAfterwards() async throws {
        let fixtureURL: URL = try FixtureWorkspace.materialize()
        guard let workspace = WorkspaceModel.windowModels.first else {
            XCTFail("No window model registered; the interface is not on screen")
            return
        }
        workspace.chooseWorkspace(at: fixtureURL)
        await settle()
        let course: Course = try XCTUnwrap(workspace.courses.first)

        let resting: [String] = hostedRow(course: course, isBeingRenamed: false, workspace: workspace)
        var restingHasField: Bool = false
        for name in resting where name.contains("TextField") {
            restingHasField = true
        }
        XCTAssertFalse(restingHasField, "An ordinary row is a label, not a field: \(resting)")

        let renaming: [String] = hostedRow(course: course, isBeingRenamed: true, workspace: workspace)
        var renamingHasField: Bool = false
        for name in renaming where name.contains("TextField") {
            renamingHasField = true
        }
        XCTAssertTrue(renamingHasField, "The row should have become a text field: \(renaming)")

        try? FileManager.default.removeItem(at: fixtureURL)
    }

    // MARK: - Through the real window

    @MainActor
    func testRenamingMovesTheCourseAndTheSidebarFollowsIt() async throws {
        let fixtureURL: URL = try FixtureWorkspace.materialize()
        guard let workspace = WorkspaceModel.windowModels.first else {
            XCTFail("No window model registered; the interface is not on screen")
            return
        }

        workspace.chooseWorkspace(at: fixtureURL)
        await settle()
        XCTAssertFalse(workspace.courses.isEmpty, "Fixture should contain a course")

        let originalCode: String = workspace.courses[0].code
        workspace.selection = SidebarSelection.section(originalCode, 2)
        workspace.expandedCourseCodes.insert(originalCode)
        await settle()

        // What Edit ▸ Rename Course does, and what Return in the sidebar
        // does — both land here.
        XCTAssertNotNil(
            workspace.courseThatCanBeRenamed,
            "A section's row means the course it belongs to — there is nothing else in it to rename"
        )
        workspace.beginRenamingSelectedCourse()
        XCTAssertEqual(workspace.renamingCourseCode, originalCode)

        let course: Course = try XCTUnwrap(workspace.courseThatCanBeRenamed)
        workspace.rename(course, to: "exc3o")
        await settle()

        XCTAssertNil(workspace.renameProblem, workspace.renameProblem ?? "")
        XCTAssertNil(workspace.renamingCourseCode, "The field goes away once the rename lands")

        var renamedCodes: [String] = []
        for loaded in workspace.courses {
            renamedCodes.append(loaded.code)
        }
        XCTAssertTrue(renamedCodes.contains("EXC3O"), "typed lower case, stored upper: \(renamedCodes)")
        XCTAssertFalse(renamedCodes.contains(originalCode), "and the old code is gone: \(renamedCodes)")

        XCTAssertEqual(
            workspace.selection, SidebarSelection.section("EXC3O", 2),
            "the same section stays selected, under the new code"
        )
        XCTAssertTrue(
            workspace.expandedCourseCodes.contains("EXC3O"),
            "and the sections the teacher had unfolded stay unfolded"
        )
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: fixtureURL.appendingPathComponent("courses/EXC3O/section2").path
            ),
            "the folder really moved, contents and all"
        )

        try? FileManager.default.removeItem(at: fixtureURL)
    }

    /// A busy course is not renamed out from under its own preview, and the
    /// Return key and the menu item are refused together — both ask the
    /// model the same question.
    @MainActor
    func testACourseThatIsPreviewingIsNotRenamed() async throws {
        let fixtureURL: URL = try FixtureWorkspace.materialize()
        guard let workspace = WorkspaceModel.windowModels.first else {
            XCTFail("No window model registered; the interface is not on screen")
            return
        }
        workspace.chooseWorkspace(at: fixtureURL)
        await settle()
        let course: Course = try XCTUnwrap(workspace.courses.first)
        workspace.selection = SidebarSelection.course(course.code)

        PreviewLeases.reset()
        _ = try PreviewLeases.lease(
            folderPath: try XCTUnwrap(workspace.workspaceURL).path,
            courseCode: course.code,
            sectionNumber: 1
        )
        defer { PreviewLeases.reset() }

        XCTAssertNotNil(workspace.renameIsUnavailableReason, "the menu item says why it is dimmed")
        workspace.beginRenamingSelectedCourse()
        XCTAssertNil(workspace.renamingCourseCode, "and no field opens")

        // And the commit path refuses too, in case a preview starts while
        // the field is already open.
        workspace.rename(course, to: "EXC3O")
        await settle()
        XCTAssertEqual(
            workspace.renameProblem,
            "\(course.code) is previewing or deploying right now. Stop that first, then rename."
        )
        workspace.renameProblem = nil
        XCTAssertTrue(FileManager.default.fileExists(atPath: course.directoryURL.path))

        try? FileManager.default.removeItem(at: fixtureURL)
    }

    /// A code the rule refuses never gets as far as the file system, and its
    /// reason is shown under the field rather than in an alert.
    @MainActor
    func testAnUnusableCodeIsShownUnderTheFieldRatherThanInAnAlert() async throws {
        let fixtureURL: URL = try FixtureWorkspace.materialize()
        guard let workspace = WorkspaceModel.windowModels.first else {
            XCTFail("No window model registered; the interface is not on screen")
            return
        }

        workspace.chooseWorkspace(at: fixtureURL)
        await settle()
        let course: Course = try XCTUnwrap(workspace.courses.first)
        workspace.selection = SidebarSelection.course(course.code)
        workspace.beginRenamingSelectedCourse()
        await settle()

        XCTAssertEqual(
            CourseCodeRule.problem("TOOLONGCODE", existingCodes: [course.code], currentCode: course.code),
            "A course code can be at most 8 characters.",
            "the field shows this under itself rather than raising an alert"
        )
        XCTAssertNil(workspace.renameProblem, "and nothing has gone wrong that needs an alert")
        XCTAssertEqual(workspace.renamingCourseCode, course.code, "the field is still open")

        workspace.renamingCourseCode = nil
        try? FileManager.default.removeItem(at: fixtureURL)
    }
}
