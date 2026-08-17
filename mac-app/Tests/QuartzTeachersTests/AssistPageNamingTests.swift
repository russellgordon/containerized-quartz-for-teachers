import XCTest
@testable import QuartzTeachers

/// What the assistant CALLS a page when it talks to a teacher.
///
/// Reported from a real course: unpublishing a class explained that four pages
/// were staying published because "index" still linked to them. Every folder in
/// a course has an `index.md`, so "index" is both meaningless and ambiguous —
/// the page the teacher would go and look at is the one the sidebar calls
/// **Portfolios**.
///
/// The rule is deliberately copied from Quartz's own `fileTrie.ts` rather than
/// invented, so what the assistant says and what the site shows cannot drift.
final class AssistPageNamingTests: XCTestCase {

    // MARK: - Helpers

    private func url(_ path: String) -> URL {
        return URL(fileURLWithPath: "/courses/ADA1O/" + path)
    }

    private func frontmatter(title: String?) -> String {
        guard let title else {
            return "---\npublish: true\n---\n\nSome words.\n"
        }
        return "---\ntitle: \(title)\npublish: true\n---\n\nSome words.\n"
    }

    // MARK: - The ordinary case

    /// A normal page is called what its file is called, which is also what its
    /// frontmatter says. Nothing about this change may alter that.
    @MainActor
    func testAnOrdinaryPageKeepsItsOwnName() {
        XCTAssertEqual(
            AssistSectionGraph.displayName(
                forPageAt: url("Portfolios/Journal Checklist.md"),
                in: frontmatter(title: "Journal Checklist")
            ),
            "Journal Checklist"
        )
    }

    /// A page a teacher wrote by hand in Obsidian has no frontmatter at all.
    @MainActor
    func testAPageWithNoFrontmatterTitleIsCalledAfterItsFile() {
        XCTAssertEqual(
            AssistSectionGraph.displayName(
                forPageAt: url("Concepts/Stage Directions.md"), in: frontmatter(title: nil)
            ),
            "Stage Directions"
        )
    }

    // MARK: - The reported bug

    /// The one that was reported. A folder's landing page is named after the
    /// FOLDER — what the sidebar shows — never after the file.
    @MainActor
    func testAFolderLandingPageIsCalledAfterItsFolder() {
        XCTAssertEqual(
            AssistSectionGraph.displayName(
                forPageAt: url("Portfolios/index.md"), in: frontmatter(title: "Portfolios")
            ),
            "Portfolios"
        )
    }

    /// And when nobody has given it a title — which is every folder a teacher
    /// makes themselves — the folder name still answers, rather than "index".
    @MainActor
    func testAFolderLandingPageWithNoTitleIsStillCalledAfterItsFolder() {
        XCTAssertEqual(
            AssistSectionGraph.displayName(
                forPageAt: url("Warm-Ups/index.md"), in: frontmatter(title: nil)
            ),
            "Warm-Ups"
        )
    }

    /// Quartz's own guard, kept for Quartz's own reason: a frontmatter title of
    /// literally "index" is thrown away rather than shown. It is the one answer
    /// that is never worth giving anybody.
    @MainActor
    func testATitleOfIndexIsIgnoredJustAsQuartzIgnoresIt() {
        XCTAssertEqual(
            AssistSectionGraph.displayName(
                forPageAt: url("Style/index.md"), in: frontmatter(title: "index")
            ),
            "Style"
        )
    }

    /// A quoted title is unwrapped, the way the date reader already unwraps
    /// one — YAML allows it and Obsidian writes it for titles with colons.
    @MainActor
    func testAQuotedTitleIsUnwrapped() {
        XCTAssertEqual(
            AssistSectionGraph.displayName(
                forPageAt: url("Tasks/index.md"), in: "---\ntitle: \"Tasks & Deadlines\"\n---\n"
            ),
            "Tasks & Deadlines"
        )
    }

    /// Nothing a teacher is shown may be the word "index", whatever shape the
    /// page is in. This is the assertion the report actually asked for.
    @MainActor
    func testNoFolderLandingPageIsEverCalledIndex() {
        let shapes: [String] = [
            frontmatter(title: nil),
            frontmatter(title: "index"),
            frontmatter(title: ""),
            "no frontmatter at all\n"
        ]
        for folder in ["Portfolios", "Style", "Warm-Ups", "All Classes"] {
            for shape in shapes {
                let shown: String = AssistSectionGraph.displayName(
                    forPageAt: url("\(folder)/index.md"), in: shape
                )
                XCTAssertEqual(shown, folder, "A teacher was shown “\(shown)”")
            }
        }
    }
}
