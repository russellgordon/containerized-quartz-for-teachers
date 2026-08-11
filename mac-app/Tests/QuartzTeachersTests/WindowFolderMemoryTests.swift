import XCTest
@testable import QuartzTeachers

/// Windows coming back in the folders they were left in.
final class WindowFolderMemoryTests: XCTestCase {

    // MARK: - Functions

    /// Folders that really exist, so the memory does not skip them.
    @MainActor
    func makeFolders(_ count: Int) throws -> [String] {
        var paths: [String] = []
        for _ in 0..<count {
            let url: URL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("wfm-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            paths.append(url.path)
        }
        return paths
    }

    func removeAll(_ folders: [String]) {
        for path in folders {
            try? FileManager.default.removeItem(atPath: path)
        }
    }

    @MainActor
    func testTheLaunchWindowTakesTheFirstEntryFolderAndFrame() throws {
        let folders: [String] = try makeFolders(2)
        defer { removeAll(folders) }
        WindowFolderMemory.reset(with: [
            WindowFolderMemory.Entry(path: folders[0], frame: "{{100, 100}, {900, 700}}"),
            WindowFolderMemory.Entry(path: folders[1], frame: "{{300, 200}, {1100, 720}}"),
        ])
        let first = WindowFolderMemory.claimNextEntry()
        XCTAssertEqual(first?.path, folders[0])
        XCTAssertEqual(first?.frame, "{{100, 100}, {900, 700}}")
    }

    @MainActor
    func testAReopenedWindowFindsItsFolderByItsFrame() throws {
        let folders: [String] = try makeFolders(2)
        defer { removeAll(folders) }
        WindowFolderMemory.reset(with: [
            WindowFolderMemory.Entry(path: folders[0], frame: "{{100, 100}, {900, 700}}"),
            WindowFolderMemory.Entry(path: folders[1], frame: "{{300, 200}, {1100, 720}}"),
        ])
        // The SECOND window is reopened first — macOS chooses its own
        // order, which is exactly what swapped the folders.
        XCTAssertEqual(WindowFolderMemory.claimEntry(matchingFrame: "{{300, 200}, {1100, 720}}")?.path, folders[1])
        XCTAssertEqual(WindowFolderMemory.claimEntry(matchingFrame: "{{100, 100}, {900, 700}}")?.path, folders[0])
        XCTAssertFalse(WindowFolderMemory.hasEntriesToClaim())
    }

    @MainActor
    func testAnEmptyFrameNeverMatches() throws {
        let folders: [String] = try makeFolders(1)
        defer { removeAll(folders) }
        WindowFolderMemory.reset(with: [WindowFolderMemory.Entry(path: folders[0], frame: "")])
        XCTAssertNil(WindowFolderMemory.claimEntry(matchingFrame: ""),
                     "Two windows with no recorded frame must not both match the first entry")
        XCTAssertEqual(WindowFolderMemory.claimNextEntry()?.path, folders[0], "Order still hands it out")
    }

    @MainActor
    func testAFolderThatHasGoneIsSkipped() throws {
        let folders: [String] = try makeFolders(2)
        defer { removeAll([folders[1]]) }
        try FileManager.default.removeItem(atPath: folders[0])
        WindowFolderMemory.reset(with: [
            WindowFolderMemory.Entry(path: folders[0], frame: ""),
            WindowFolderMemory.Entry(path: folders[1], frame: ""),
        ])
        XCTAssertEqual(WindowFolderMemory.claimNextEntry()?.path, folders[1],
                       "A window should not be opened in a folder that no longer exists")
    }

    @MainActor
    func testNothingRememberedMeansNothingClaimed() {
        WindowFolderMemory.reset(with: [])
        XCTAssertNil(WindowFolderMemory.claimNextEntry())
    }

    @MainActor
    func testTheListSurvivesARelaunch() throws {
        let defaults: UserDefaults = TestDefaults.make()
        let folders: [String] = try makeFolders(1)
        defer { removeAll(folders) }
        WindowFolderMemory.record([WindowFolderMemory.Entry(path: folders[0], frame: "{{1, 2}, {3, 4}}")], defaults: defaults)
        let stored = defaults.array(forKey: WindowFolderMemory.storageKey) as? [[String: String]]
        XCTAssertEqual(stored?.first?["path"], folders[0])
        XCTAssertEqual(stored?.first?["frame"], "{{1, 2}, {3, 4}}")
    }

    @MainActor
    func testATestNeverWritesIntoTheRealPreferences() throws {
        let before = UserDefaults.standard.array(forKey: WindowFolderMemory.storageKey) as? [[String: String]]
        WindowFolderMemory.record([WindowFolderMemory.Entry(path: "/somewhere/made/up", frame: "")])
        let after = UserDefaults.standard.array(forKey: WindowFolderMemory.storageKey) as? [[String: String]]
        XCTAssertEqual(before, after, "A test must not disturb the teacher's own open windows")
    }

    // MARK: - Holding for a pending claim

    @MainActor
    func testAClaimMayStillArriveWhileEntriesRemainAndClaimsAreOpen() {
        WindowFolderMemory.reset(with: [
            WindowFolderMemory.Entry(path: "/tmp", frame: "{{0, 0}, {800, 600}}"),
        ])
        let now: Date = Date()
        WindowFolderMemory.claimsOpenUntil = now.addingTimeInterval(10)
        XCTAssertTrue(WindowFolderMemory.aClaimMayStillArrive(asOf: now))
    }

    @MainActor
    func testNoClaimCanArriveOnceClaimsHaveClosed() {
        WindowFolderMemory.reset(with: [
            WindowFolderMemory.Entry(path: "/tmp", frame: "{{0, 0}, {800, 600}}"),
        ])
        let now: Date = Date()
        WindowFolderMemory.claimsOpenUntil = now.addingTimeInterval(-1)
        XCTAssertFalse(WindowFolderMemory.aClaimMayStillArrive(asOf: now),
                       "A mid-session window must never hold for a claim")
    }

    @MainActor
    func testNoClaimCanArriveWithNothingLeftToClaim() {
        WindowFolderMemory.reset(with: [])
        let now: Date = Date()
        WindowFolderMemory.claimsOpenUntil = now.addingTimeInterval(10)
        XCTAssertFalse(WindowFolderMemory.aClaimMayStillArrive(asOf: now),
                       "A fresh first launch shows the picker immediately")
    }
}
