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
        let workspace: WorkspaceModel = WorkspaceModel()
        workspace.chooseWorkspace(at: folderURL)

        XCTAssertTrue(workspace.workspaceCanBeInitialized, "An empty folder should offer setup")
        XCTAssertNil(workspace.workspaceProblem, "An empty folder should not read as an error")
    }

    @MainActor
    func testNonEmptyFolderWithoutScriptsStillReadsAsProblem() throws {
        let folderURL: URL = try makeTemporaryFolder()
        try Data("hello".utf8).write(to: folderURL.appendingPathComponent("unrelated.txt"))
        let workspace: WorkspaceModel = WorkspaceModel()
        workspace.chooseWorkspace(at: folderURL)

        XCTAssertFalse(workspace.workspaceCanBeInitialized, "A folder with existing content should not be silently taken over")
        XCTAssertNotNil(workspace.workspaceProblem)
    }

    @MainActor
    func testInitializationProducesAValidWorkspace() throws {
        let folderURL: URL = try makeTemporaryFolder()
        let workspace: WorkspaceModel = WorkspaceModel()
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
