import XCTest
@testable import QuartzTeachers

/// The mirror that keeps a working folder's `.toolchain` in step with the
/// app's own copy.
///
/// Worth its own tests because it is both load-bearing and invisible: the
/// launchers hash that folder to name the image, so a mirror that copies too
/// much rebuilds the image for nothing, and one that copies too little runs
/// the teacher's site build with last week's scripts.
@MainActor
final class ToolchainMirrorTests: XCTestCase {

    // MARK: - Stored properties

    var root: URL = URL(fileURLWithPath: "/")

    // MARK: - Functions

    override func setUp() {
        super.setUp()
        // NOT the temporary directory: /var is a symlink to /private/var, and
        // this suite is partly about paths that are reached through symlinks.
        // The home folder is the closest thing to a teacher's real one.
        root = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("plantoir-mirror-test-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let created: URL = root
        addTeardownBlock {
            try? FileManager.default.removeItem(at: created)
        }
    }

    func write(_ contents: String, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Copying, and not copying

    func testItCopiesOnceAndThenLeavesEverythingAlone() throws {
        let source: URL = root.appendingPathComponent("source")
        let destination: URL = root.appendingPathComponent("destination")
        try write("one", to: source.appendingPathComponent("a.txt"))
        try write("two", to: source.appendingPathComponent("nested/b.txt"))

        XCTAssertEqual(WorkspaceModel.syncDirectory(from: source, to: destination), 2)
        XCTAssertEqual(
            try String(contentsOf: destination.appendingPathComponent("nested/b.txt"), encoding: .utf8),
            "two"
        )

        XCTAssertEqual(
            WorkspaceModel.syncDirectory(from: source, to: destination), 0,
            "Nothing changed, so nothing should be written — this is the pass a teacher waits through"
        )
    }

    /// The cheap check is what makes the mirror usable, so it is pinned:
    /// after a sync the copy carries the original's modification date, which
    /// is what lets the next pass answer without reading 61 MB.
    func testTheCopyKeepsTheOriginalsModificationDate() throws {
        let source: URL = root.appendingPathComponent("source")
        let destination: URL = root.appendingPathComponent("destination")
        let file: URL = source.appendingPathComponent("a.txt")
        try write("one", to: file)

        _ = WorkspaceModel.syncDirectory(from: source, to: destination)

        XCTAssertTrue(
            WorkspaceModel.filesLookIdentical(file, destination.appendingPathComponent("a.txt")),
            "The copy should be recognisable without reading it"
        )
    }

    /// Same bytes, different stamp — every file in the bundle, the first pass
    /// after the app is rebuilt. Nothing is written, and the stamp is brought
    /// across so the next pass is cheap.
    func testAFileWithTheSameBytesIsNotRewrittenButIsRestamped() throws {
        let source: URL = root.appendingPathComponent("source")
        let destination: URL = root.appendingPathComponent("destination")
        try write("same", to: source.appendingPathComponent("a.txt"))
        try write("same", to: destination.appendingPathComponent("a.txt"))
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSince1970: 1_000_000)],
            ofItemAtPath: destination.appendingPathComponent("a.txt").path
        )

        XCTAssertEqual(WorkspaceModel.syncDirectory(from: source, to: destination), 0)
        XCTAssertTrue(
            WorkspaceModel.filesLookIdentical(
                source.appendingPathComponent("a.txt"),
                destination.appendingPathComponent("a.txt")
            ),
            "and the next pass can tell without reading them"
        )
    }

    func testAChangedFileIsCopiedAndAnExtraOneIsRemoved() throws {
        let source: URL = root.appendingPathComponent("source")
        let destination: URL = root.appendingPathComponent("destination")
        try write("one", to: source.appendingPathComponent("a.txt"))
        _ = WorkspaceModel.syncDirectory(from: source, to: destination)

        try write("changed", to: source.appendingPathComponent("a.txt"))
        try write("stray", to: destination.appendingPathComponent("gone.txt"))

        XCTAssertEqual(WorkspaceModel.syncDirectory(from: source, to: destination), 2)
        XCTAssertEqual(
            try String(contentsOf: destination.appendingPathComponent("a.txt"), encoding: .utf8),
            "changed"
        )
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: destination.appendingPathComponent("gone.txt").path),
            "An extraneous file changes the recipe's hash and rebuilds the image for nothing"
        )
    }

    // MARK: - Paths reached through a symlink

    /// The bug this replaced: the enumerator hands back RESOLVED paths, so a
    /// folder reached through a symlink did not match the prefix the old
    /// arithmetic assumed. Every destination file then looked extraneous, and
    /// the mirror deleted the whole toolchain and copied it back — every
    /// single pass.
    func testAFolderReachedThroughASymlinkIsMirroredNotEmptied() throws {
        let real: URL = root.appendingPathComponent("real")
        let source: URL = root.appendingPathComponent("source")
        try write("one", to: source.appendingPathComponent("a.txt"))
        try FileManager.default.createDirectory(at: real, withIntermediateDirectories: true)

        let link: URL = root.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: real)

        XCTAssertEqual(WorkspaceModel.syncDirectory(from: source, to: link), 1)
        XCTAssertEqual(
            WorkspaceModel.syncDirectory(from: source, to: link), 0,
            "and the second pass must find nothing to do, rather than deleting what it just wrote"
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: real.appendingPathComponent("a.txt").path))
    }

    func testRelativePathsAreFoundThroughASymlinkOrNotAtAll() throws {
        let folder: URL = root.appendingPathComponent("folder")
        XCTAssertEqual(
            WorkspaceModel.relativePath(of: folder.appendingPathComponent("a/b.txt"), under: folder),
            "a/b.txt"
        )
        XCTAssertNil(
            WorkspaceModel.relativePath(
                of: URL(fileURLWithPath: "/somewhere/else.txt"), under: folder
            ),
            "A file outside the folder is not ours to delete"
        )
    }
}
