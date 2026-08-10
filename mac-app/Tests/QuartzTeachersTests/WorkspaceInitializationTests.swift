import XCTest
@testable import QuartzTeachers

/// Choosing an empty folder must offer initialization, and initializing
/// must produce a valid working folder with executable launcher scripts.
final class WorkspaceInitializationTests: XCTestCase {

    // MARK: - Functions

    func makeTemporaryFolder() throws -> URL {
        let url: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cq4t-init-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @MainActor
    func testEmptyFolderOffersInitialization() throws {
        let folderURL: URL = try makeTemporaryFolder()
        let workspace: WorkspaceModel = WorkspaceModel(defaults: TestDefaults.make())
        workspace.chooseWorkspace(at: folderURL)

        XCTAssertTrue(workspace.workspaceCanBeInitialized, "An empty folder should offer setup")
        XCTAssertNil(workspace.workspaceProblem, "An empty folder should not read as an error")
    }

    @MainActor
    func testNonEmptyFolderWithoutScriptsKeepsPickerUpWithoutAnError() throws {
        let folderURL: URL = try makeTemporaryFolder()
        try Data("hello".utf8).write(to: folderURL.appendingPathComponent("unrelated.txt"))
        let workspace: WorkspaceModel = WorkspaceModel(defaults: TestDefaults.make())
        workspace.chooseWorkspace(at: folderURL)

        XCTAssertFalse(workspace.workspaceCanBeInitialized, "A folder with existing content should not be silently taken over")
        XCTAssertTrue(workspace.workspaceIsUnrecognized, "The picker should stay up so a different folder can be chosen")
        XCTAssertNil(workspace.workspaceProblem, "An unfinished choice is not an error and should show no red text")
    }

    @MainActor
    func testInitializationProducesAValidWorkspace() throws {
        let folderURL: URL = try makeTemporaryFolder()
        let workspace: WorkspaceModel = WorkspaceModel(defaults: TestDefaults.make())
        workspace.chooseWorkspace(at: folderURL)
        workspace.initializeWorkspace()

        XCTAssertNil(workspace.workspaceProblem)
        XCTAssertFalse(workspace.workspaceCanBeInitialized, "The folder should now validate as a working folder")
        XCTAssertTrue(workspace.isShowingNewCourseWizard, "A fresh folder should lead straight into creating a course")

        let fileManager: FileManager = FileManager.default
        let scriptNames: [String] = ["setup.sh", "preview.sh", "deploy.sh"]
        for scriptName in scriptNames {
            let scriptPath: String = folderURL.appendingPathComponent(scriptName).path
            XCTAssertTrue(fileManager.fileExists(atPath: scriptPath), "\(scriptName) should be copied in")
            XCTAssertTrue(fileManager.isExecutableFile(atPath: scriptPath), "\(scriptName) should be executable")
        }
        XCTAssertTrue(fileManager.fileExists(atPath: folderURL.appendingPathComponent("courses").path))

        // The copied script must be the real launcher, not a stub.
        let previewContents: String = try String(contentsOf: folderURL.appendingPathComponent("preview.sh"), encoding: .utf8)
        XCTAssertTrue(previewContents.contains("ensure_container_runtime"), "The bundled script should be the current toolchain launcher")

        // Tidy the wizard flag so this test leaves no UI behind.
        workspace.isShowingNewCourseWizard = false
    }
}

/// Remembering the working folder across launches.
final class WorkspacePersistenceTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testChoosingAFolderIsRemembered() throws {
        let defaults: UserDefaults = TestDefaults.make()
        let folderURL: URL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ws-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folderURL) }

        let workspace: WorkspaceModel = WorkspaceModel(defaults: defaults)
        workspace.chooseWorkspace(at: folderURL)

        let reopened: WorkspaceModel = WorkspaceModel(defaults: defaults)
        XCTAssertEqual(reopened.workspaceURL?.path, folderURL.path, "The folder must survive a relaunch")
    }

    @MainActor
    func testAFolderThatNoLongerExistsIsForgotten() throws {
        let defaults: UserDefaults = TestDefaults.make()
        let folderURL: URL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ws-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

        let workspace: WorkspaceModel = WorkspaceModel(defaults: defaults)
        workspace.chooseWorkspace(at: folderURL)
        try FileManager.default.removeItem(at: folderURL)

        let reopened: WorkspaceModel = WorkspaceModel(defaults: defaults)
        XCTAssertNil(reopened.workspaceURL, "A deleted folder must not be presented as the working folder")
        XCTAssertNil(defaults.string(forKey: WorkspaceModel.storedPathKey), "The stale path should be cleared")
    }

    @MainActor
    func testAWindowAdoptsTheFolderItWasRestoredWith() throws {
        let defaults: UserDefaults = TestDefaults.make()
        let folderURL: URL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ws-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folderURL) }

        let workspace: WorkspaceModel = WorkspaceModel(defaults: defaults)
        workspace.adoptRestoredPath(folderURL.path)
        XCTAssertEqual(workspace.workspaceURL?.path, folderURL.path)
    }

    @MainActor
    func testARestoredFolderThatIsGoneIsIgnored() {
        let defaults: UserDefaults = TestDefaults.make()
        let workspace: WorkspaceModel = WorkspaceModel(defaults: defaults)
        workspace.adoptRestoredPath("/nowhere/this/does/not/exist")
        XCTAssertNil(workspace.workspaceURL)
    }

    @MainActor
    func testATestNeverWritesIntoTheRealPreferences() throws {
        let before: String? = UserDefaults.standard.string(forKey: WorkspaceModel.storedPathKey)
        let defaults: UserDefaults = TestDefaults.make()
        let folderURL: URL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ws-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folderURL) }

        let workspace: WorkspaceModel = WorkspaceModel(defaults: defaults)
        workspace.chooseWorkspace(at: folderURL)

        let after: String? = UserDefaults.standard.string(forKey: WorkspaceModel.storedPathKey)
        XCTAssertEqual(before, after, "A test must leave the teacher's own working folder alone")
    }
}
