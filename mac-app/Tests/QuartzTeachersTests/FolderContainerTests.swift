import XCTest
@testable import QuartzTeachers

/// One container per working folder, resting when unused.
final class FolderContainerTests: XCTestCase {

    // MARK: - Functions

    /// The app and the launchers must derive the SAME name, or the app
    /// would stop a container that does not exist while the real one runs
    /// on. The launchers use `pwd -P | shasum -a 256 | cut -c1-8`.
    @MainActor
    func testTheNameMatchesWhatTheLaunchersDerive() throws {
        let folder: String = NSTemporaryDirectory() + "fc-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: folder) }

        let shell: Process = Process()
        shell.executableURL = URL(fileURLWithPath: "/bin/bash")
        shell.arguments = ["-c", "cd '\(folder)' && pwd -P | shasum -a 256 | cut -c1-8"]
        let output: Pipe = Pipe()
        shell.standardOutput = output
        try shell.run()
        shell.waitUntilExit()
        let launcherHash: String = String(
            data: output.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )!.trimmingCharacters(in: .whitespacesAndNewlines)

        XCTAssertEqual(
            FolderContainers.containerName(forFolder: folder),
            "teaching-quartz-" + launcherHash,
            "The app must name the container exactly as the launchers do"
        )
    }

    @MainActor
    func testDifferentFoldersGetDifferentContainers() {
        XCTAssertNotEqual(
            FolderContainers.containerName(forFolder: "/Users/t/ThisYear"),
            FolderContainers.containerName(forFolder: "/Users/t/LastYear")
        )
    }

    @MainActor
    func testAFolderIsInUseWhileAnyWindowIsOnIt() throws {
        let folder: String = NSTemporaryDirectory() + "fc-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: folder) }

        let first: WorkspaceModel = WorkspaceModel(defaults: TestDefaults.make())
        let second: WorkspaceModel = WorkspaceModel(defaults: TestDefaults.make())
        first.chooseWorkspace(at: URL(fileURLWithPath: folder))
        second.chooseWorkspace(at: URL(fileURLWithPath: folder))
        WorkspaceModel.registerWindowModel(first)
        WorkspaceModel.registerWindowModel(second)
        defer {
            WorkspaceModel.unregisterWindowModel(first)
            WorkspaceModel.unregisterWindowModel(second)
        }

        XCTAssertTrue(WorkspaceModel.folderIsInUse(folder))
        WorkspaceModel.unregisterWindowModel(second)
        XCTAssertTrue(WorkspaceModel.folderIsInUse(folder), "One window still has it open")
        WorkspaceModel.unregisterWindowModel(first)
        XCTAssertFalse(WorkspaceModel.folderIsInUse(folder), "Now nobody does — the container can rest")
    }
}
