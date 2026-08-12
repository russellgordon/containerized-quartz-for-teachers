import XCTest
@testable import QuartzTeachers

/// The quiet clean-up that ends a stopped preview's container-side
/// processes instead of orphaning them.
final class PreviewStopperTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testAStopRunsTheLauncherAndCleansUpAfterItself() async throws {
        let fileManager: FileManager = FileManager.default
        let folder: URL = fileManager.temporaryDirectory
            .appendingPathComponent("preview-stopper-\(UUID().uuidString)")
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        defer {
            try? fileManager.removeItem(at: folder)
        }
        // A stand-in launcher that simply succeeds.
        let script: URL = folder.appendingPathComponent("preview.sh")
        try Data("exit 0\n".utf8).write(to: script)

        PreviewStopper.stopSectionProcesses(courseCode: "ICS3U", sectionNumber: 1, workspaceURL: folder)
        XCTAssertEqual(PreviewStopper.running.count, 1, "The stop process is held while it runs")

        // The termination handler prunes the list when the process ends.
        var waitsLeft: Int = 100
        while !PreviewStopper.running.isEmpty && waitsLeft > 0 {
            try await Task.sleep(for: .milliseconds(50))
            waitsLeft -= 1
        }
        XCTAssertTrue(PreviewStopper.running.isEmpty, "A finished stop process is let go")
    }

    @MainActor
    func testAMissingLauncherIsAQuietNoOp() {
        let before: Int = PreviewStopper.running.count
        PreviewStopper.stopSectionProcesses(
            courseCode: "ICS3U",
            sectionNumber: 1,
            workspaceURL: URL(fileURLWithPath: "/no/such/folder/anywhere")
        )
        XCTAssertEqual(PreviewStopper.running.count, before,
                       "Without the launcher there is nothing to run")
    }
}
