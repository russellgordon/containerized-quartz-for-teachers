import XCTest
@testable import QuartzTeachers

/// Windows coming back in the folders they were left in.
final class WindowFolderMemoryTests: XCTestCase {

    // MARK: - Functions

    /// Two folders that really exist, so the memory does not skip them.
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

    @MainActor
    func testWindowsTakeTheFoldersInOrder() throws {
        let folders: [String] = try makeFolders(2)
        defer {
            for path in folders {
                try? FileManager.default.removeItem(atPath: path)
            }
        }
        WindowFolderMemory.reset(with: folders)

        XCTAssertEqual(WindowFolderMemory.claimNextFolder(), folders[0], "The first window takes the first folder")
        XCTAssertEqual(WindowFolderMemory.claimNextFolder(), folders[1], "The second takes the second")
        XCTAssertNil(WindowFolderMemory.claimNextFolder(), "A third window has nothing remembered for it")
    }

    @MainActor
    func testAFolderThatHasGoneIsSkipped() throws {
        let folders: [String] = try makeFolders(2)
        defer { try? FileManager.default.removeItem(atPath: folders[1]) }
        try FileManager.default.removeItem(atPath: folders[0])

        WindowFolderMemory.reset(with: folders)
        XCTAssertEqual(WindowFolderMemory.claimNextFolder(), folders[1],
                       "A window should not be opened in a folder that no longer exists")
    }

    @MainActor
    func testNothingRememberedMeansNothingClaimed() {
        WindowFolderMemory.reset(with: [])
        XCTAssertNil(WindowFolderMemory.claimNextFolder())
    }

    @MainActor
    func testTheListSurvivesARelaunch() throws {
        let defaults: UserDefaults = TestDefaults.make()
        let folders: [String] = try makeFolders(2)
        defer {
            for path in folders {
                try? FileManager.default.removeItem(atPath: path)
            }
        }
        WindowFolderMemory.record(folders, defaults: defaults)
        XCTAssertEqual(defaults.stringArray(forKey: WindowFolderMemory.storageKey), folders)
    }

    @MainActor
    func testATestNeverWritesIntoTheRealPreferences() throws {
        let before: [String]? = UserDefaults.standard.stringArray(forKey: WindowFolderMemory.storageKey)
        WindowFolderMemory.record(["/somewhere/made/up"])
        let after: [String]? = UserDefaults.standard.stringArray(forKey: WindowFolderMemory.storageKey)
        XCTAssertEqual(before, after, "A test must not disturb the teacher's own open windows")
    }
}
