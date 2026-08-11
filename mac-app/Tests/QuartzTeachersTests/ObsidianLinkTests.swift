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

    /// Obsidian opens files, not folders: a section is represented by its
    /// landing page, and a section without one falls back to the vault.
    @MainActor
    func testASectionOpensAtItsLandingPage() throws {
        let vault: URL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("vault-\(UUID().uuidString)")
        let section: URL = vault.appendingPathComponent("section6")
        try FileManager.default.createDirectory(at: section, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: vault) }

        // No landing page yet: fall back to the vault, never the bare
        // folder — handing Obsidian a folder gets "File not found".
        XCTAssertEqual(FolderActions.obsidianTarget(forFolder: section, vaultURL: vault), vault)

        try "---\ntitle: Section 6\n---".write(to: section.appendingPathComponent("index.md"), atomically: true, encoding: .utf8)
        XCTAssertEqual(FolderActions.obsidianTarget(forFolder: section, vaultURL: vault),
                       section.appendingPathComponent("index.md"))

        // The vault's own folder passes through: a path that IS a vault
        // opens that vault.
        XCTAssertEqual(FolderActions.obsidianTarget(forFolder: vault, vaultURL: vault), vault)
    }

    /// Auto-reveal is flipped on in the saved layout without disturbing
    /// anything else in it.
    @MainActor
    func testAutoRevealIsEnabledAndTheRestOfTheLayoutSurvives() throws {
        let layout: [String: Any] = [
            "main": ["id": "m1", "type": "split"],
            "left": [
                "type": "split",
                "children": [
                    [
                        "type": "tabs",
                        "children": [
                            [
                                "type": "leaf",
                                "state": [
                                    "type": "file-explorer",
                                    "state": ["sortOrder": "alphabetical", "autoReveal": false],
                                    "icon": "lucide-folder-closed",
                                ],
                            ],
                            [
                                "type": "leaf",
                                "state": ["type": "search", "state": ["query": "keep me"]],
                            ],
                        ],
                    ],
                ],
            ],
            "active": "m1",
        ]

        let improved: [String: Any] = try XCTUnwrap(FolderActions.layoutEnablingAutoReveal(layout) as? [String: Any])

        let left: [String: Any] = try XCTUnwrap(improved["left"] as? [String: Any])
        let tabs: [String: Any] = try XCTUnwrap((left["children"] as? [Any])?.first as? [String: Any])
        let leaves: [Any] = try XCTUnwrap(tabs["children"] as? [Any])
        let explorer: [String: Any] = try XCTUnwrap(leaves[0] as? [String: Any])
        let explorerState: [String: Any] = try XCTUnwrap(explorer["state"] as? [String: Any])
        let innerState: [String: Any] = try XCTUnwrap(explorerState["state"] as? [String: Any])
        XCTAssertEqual(innerState["autoReveal"] as? Bool, true)
        XCTAssertEqual(innerState["sortOrder"] as? String, "alphabetical", "The teacher's sort order survives")

        let search: [String: Any] = try XCTUnwrap(leaves[1] as? [String: Any])
        let searchState: [String: Any] = try XCTUnwrap(search["state"] as? [String: Any])
        let searchInner: [String: Any] = try XCTUnwrap(searchState["state"] as? [String: Any])
        XCTAssertEqual(searchInner["query"] as? String, "keep me", "Other leaves are untouched")
        XCTAssertEqual(improved["active"] as? String, "m1")
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
