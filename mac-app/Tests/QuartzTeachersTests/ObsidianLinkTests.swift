import XCTest
@testable import QuartzTeachers

/// The obsidian:// link that opens a course or section folder as a vault.
final class ObsidianLinkTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testTheLinkCarriesTheFullPathEncoded() throws {
        let folder: URL = URL(fileURLWithPath: "/Users/teacher/Desktop/Class Websites/courses/ICS3U/section2")
        let link: URL = try XCTUnwrap(FolderActions.obsidianURL(forFolder: folder))

        XCTAssertEqual(link.scheme, "obsidian")
        XCTAssertEqual(link.host, "open")
        XCTAssertEqual(link.absoluteString,
                       "obsidian://open?path=/Users/teacher/Desktop/Class%20Websites/courses/ICS3U/section2",
                       "Spaces in the path must be percent-encoded or Obsidian gets a broken path")

        // And the path survives the round trip exactly.
        let components: URLComponents = try XCTUnwrap(URLComponents(url: link, resolvingAgainstBaseURL: false))
        var pathValue: String?
        for item in components.queryItems ?? [] {
            if item.name == "path" {
                pathValue = item.value
            }
        }
        XCTAssertEqual(pathValue, folder.path)
    }

    /// The registry Obsidian keeps: a folder counts as "in a vault" when a
    /// registered vault IS the folder or contains it.
    @MainActor
    func testRecognizingAFolderInsideARegisteredVault() throws {
        let registry: [String: Any] = [
            "vaults": [
                "abc123": ["path": "/Users/teacher/Desktop/Class Websites/courses/ICS3U", "ts": 1],
            ],
        ]
        let data: Data = try JSONSerialization.data(withJSONObject: registry)

        XCTAssertTrue(FolderActions.folderIsInRegisteredVault(
            "/Users/teacher/Desktop/Class Websites/courses/ICS3U", registryData: data))
        XCTAssertTrue(FolderActions.folderIsInRegisteredVault(
            "/Users/teacher/Desktop/Class Websites/courses/ICS3U/section2", registryData: data))
        XCTAssertFalse(FolderActions.folderIsInRegisteredVault(
            "/Users/teacher/Desktop/Class Websites/courses/ICS3UOTHER", registryData: data),
            "A sibling folder whose name merely starts the same is NOT inside the vault")
        XCTAssertFalse(FolderActions.folderIsInRegisteredVault(
            "/Users/teacher/Desktop/temp/courses/EXC2O", registryData: data))
        XCTAssertFalse(FolderActions.folderIsInRegisteredVault(
            "/Users/teacher/anything", registryData: nil),
            "No registry at all means nothing is registered")
    }

    /// Registering adds one vault and loses none of the teacher's own.
    @MainActor
    func testRegisteringAVaultPreservesTheExistingOnes() throws {
        let registry: [String: Any] = [
            "vaults": [
                "abc123": ["path": "/Users/teacher/Existing Vault", "ts": 1, "open": true],
            ],
        ]
        let before: Data = try JSONSerialization.data(withJSONObject: registry)
        let after: Data = try XCTUnwrap(FolderActions.registryData(
            afterRegisteringVaultAt: "/Users/teacher/Desktop/temp/courses/EXC2O",
            in: before,
            identifier: "def456",
            timestamp: 99
        ))

        let decoded: [String: Any] = try XCTUnwrap(JSONSerialization.jsonObject(with: after) as? [String: Any])
        let vaults: [String: Any] = try XCTUnwrap(decoded["vaults"] as? [String: Any])
        XCTAssertEqual(vaults.count, 2, "The existing vault survives")
        let added: [String: Any] = try XCTUnwrap(vaults["def456"] as? [String: Any])
        XCTAssertEqual(added["path"] as? String, "/Users/teacher/Desktop/temp/courses/EXC2O")
        XCTAssertEqual(added["ts"] as? Int, 99)
        let kept: [String: Any] = try XCTUnwrap(vaults["abc123"] as? [String: Any])
        XCTAssertEqual(kept["open"] as? Bool, true, "Even keys we do not use are preserved")
    }

    /// A Mac where Obsidian has never written a registry still works: the
    /// registry is built from nothing.
    @MainActor
    func testRegisteringIntoAnEmptyRegistry() throws {
        let after: Data = try XCTUnwrap(FolderActions.registryData(
            afterRegisteringVaultAt: "/Users/teacher/courses/SNC1W",
            in: nil,
            identifier: "aaa111",
            timestamp: 5
        ))
        let decoded: [String: Any] = try XCTUnwrap(JSONSerialization.jsonObject(with: after) as? [String: Any])
        let vaults: [String: Any] = try XCTUnwrap(decoded["vaults"] as? [String: Any])
        XCTAssertEqual(vaults.count, 1)
    }
}
