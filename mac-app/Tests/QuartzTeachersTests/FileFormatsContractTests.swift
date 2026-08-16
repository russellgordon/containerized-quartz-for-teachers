import XCTest
@testable import QuartzTeachers

/// Runs `contracts/file-formats.json` — the two files both apps WRITE and the
/// Python then reads.
///
/// Everything else in these contracts describes behaviour. This describes a
/// FORMAT, and the failure mode is different in kind: a behaviour that differs
/// is a bug someone reports, while a format that drifts is a setting the site
/// build silently ignores, or a page published that a teacher held back.
///
/// Both halves have already caused a real one. `SectionAdder` was found
/// writing the OLD frontmatter key on both platforms — a section added through
/// the app was born in a schema everything else had moved off — and it was
/// missed because the TEST agreed with the code. A contract read by both sides
/// is the answer to a test that agrees with the code.
@MainActor
final class FileFormatsContractTests: XCTestCase {

    // MARK: - course_config.json

    /// Every key the contract documents is one this app really reads.
    ///
    /// Not the reverse — the app may read a key the contract has not caught up
    /// with, and that failure is caught by the count check below rather than
    /// by pretending this list is exhaustive.
    func testEveryDocumentedConfigKeyIsOneTheAppReads() throws {
        let section: [String: Any] = try FileFormatsContractTests.section("courseConfigKeys")
        let source: String = try FileFormatsContractTests.readSource(
            "QuartzTeachers/Models/CourseConfiguration.swift"
        )
        for entry in try XCTUnwrap(section["keys"] as? [[String: Any]]) {
            let key: String = try XCTUnwrap(entry["key"] as? String)
            XCTAssertTrue(
                source.contains("\"\(key)\""),
                "contracts/file-formats.json documents \"\(key)\", which CourseConfiguration no longer "
                + "mentions. A key that has been renamed here and not there is a setting the Python "
                + "silently ignores."
            )
        }
    }

    /// And the reverse, as a count: if the app grows a key, this fails and
    /// somebody has to decide whether Windows needs to know about it.
    func testNoConfigKeyHasBeenAddedWithoutTellingWindows() throws {
        let section: [String: Any] = try FileFormatsContractTests.section("courseConfigKeys")
        let documented: Int = try XCTUnwrap(section["keys"] as? [[String: Any]]).count
        let source: String = try FileFormatsContractTests.readSource(
            "QuartzTeachers/Models/CourseConfiguration.swift"
        )

        var found: Set<String> = []
        var search: Substring = source[...]
        while let range = search.range(of: "forKey: \"") {
            let rest: Substring = search[range.upperBound...]
            if let end = rest.firstIndex(of: "\"") {
                found.insert(String(rest[rest.startIndex..<end]))
            }
            search = rest
        }
        // `section_numbers` is read through its own accessor rather than
        // `forKey:`, so it is counted here deliberately.
        found.insert("section_numbers")

        let difference: [String] = found.symmetricDifference(Set(try documentedKeys())).sorted()
        XCTAssertEqual(
            found.count, documented,
            "CourseConfiguration reads \(found.count) keys and the contract documents \(documented). "
            + "The difference: \(difference). "
            + "Add it to contracts/file-formats.json — Windows writes this file too."
        )
    }

    // MARK: - Frontmatter: who sees a page

    func testVisibilityIsReadAsTheContractSays() throws {
        let section: [String: Any] = try FileFormatsContractTests.section("pageVisibility")
        for testCase in try XCTUnwrap(section["readingCases"] as? [[String: Any]]) {
            let frontmatter: String = try XCTUnwrap(testCase["page"] as? String)
            let page: String = """
            ---
            \(frontmatter)
            ---

            The lesson.
            """
            let visible: Bool = AssistPageVisibility.publishes(
                in: page,
                forSection: testCase["section"] as? Int ?? 1,
                isSectionLocal: try XCTUnwrap(testCase["sectionLocal"] as? Bool)
            )
            XCTAssertEqual(visible, testCase["expectVisible"] as? Bool, frontmatter)
        }
    }

    /// The writing rules, which are where the legacy spelling actually bites:
    /// a page written as `draft:` keeps that key, INVERTED.
    func testTheLegacySpellingIsKeptAndInverted() throws {
        let old: String = """
        ---
        title: Unit 1, Day 1
        draft: true
        ---

        The lesson.
        """
        let published = AssistPageVisibility.setting(
            published: true, in: old, forSection: 1, isSectionLocal: true
        )
        XCTAssertTrue(published.changed)
        XCTAssertTrue(published.text.contains("draft: false"), published.text)
        XCTAssertFalse(published.text.contains("publish:"),
                       "The teacher's own spelling is kept — rewriting the key changes a page they did "
                       + "not ask to have changed.")

        // Writing the value it already has changes nothing, so the file's
        // modification time is left alone and the next build is not fooled.
        let again = AssistPageVisibility.setting(
            published: true, in: published.text, forSection: 1, isSectionLocal: true
        )
        XCTAssertFalse(again.changed)
        XCTAssertEqual(again.text, published.text)

        // A page with no frontmatter at all gets a block of its own.
        let bare = AssistPageVisibility.setting(
            published: false, in: "Just a page.", forSection: 1, isSectionLocal: true
        )
        XCTAssertTrue(bare.changed)
        XCTAssertTrue(bare.text.hasPrefix("---\npublish: false\n---\n"), bare.text)
    }

    // MARK: - Private

    private func documentedKeys() throws -> [String] {
        let section: [String: Any] = try FileFormatsContractTests.section("courseConfigKeys")
        var keys: [String] = []
        for entry in try XCTUnwrap(section["keys"] as? [[String: Any]]) {
            keys.append(try XCTUnwrap(entry["key"] as? String))
        }
        return keys
    }

    private static func repositoryRoot() -> URL {
        return URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
    }

    private static func readSource(_ relativePath: String) throws -> String {
        return try String(
            contentsOf: repositoryRoot().appendingPathComponent("mac-app").appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }

    private static func section(_ name: String) throws -> [String: Any] {
        let url: URL = repositoryRoot().appendingPathComponent("contracts/file-formats.json")
        let all: [String: Any] = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: try Data(contentsOf: url)) as? [String: Any]
        )
        return try XCTUnwrap(all[name] as? [String: Any], "No \(name) in file-formats.json")
    }
}
