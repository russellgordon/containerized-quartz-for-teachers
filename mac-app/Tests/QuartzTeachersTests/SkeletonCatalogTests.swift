import XCTest
@testable import QuartzTeachers

/// The subject skeletons: what a course starts as when no example content
/// exists for its code.
final class SkeletonCatalogTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testACodeGetsTheSkeletonForItsSubject() throws {
        XCTAssertEqual(SkeletonCatalog.familyName(forCode: "AMU3M"), "music")
        XCTAssertEqual(SkeletonCatalog.familyName(forCode: "ADA2O"), "drama")
        XCTAssertEqual(SkeletonCatalog.familyName(forCode: "SBI3U"), "biology")
        XCTAssertEqual(SkeletonCatalog.familyName(forCode: "MCV4U"), "mathematics")
        XCTAssertEqual(SkeletonCatalog.familyName(forCode: "TXJ3E"), "hairstyling")
        XCTAssertEqual(SkeletonCatalog.familyName(forCode: " amu3m "), "music",
                       "Lookup trims and uppercases, like every other code lookup")
    }

    @MainActor
    func testAClubCodeFallsBackToTheGenericSkeleton() {
        XCTAssertEqual(SkeletonCatalog.familyName(forCode: "CODING"), "general")
        XCTAssertNil(SkeletonCatalog.familyName(forCode: ""))
    }

    @MainActor
    func testTheFamilyCarriesTheFoldersItsPagesWereWrittenFor() throws {
        let music: SkeletonCatalog.Family = try XCTUnwrap(SkeletonCatalog.family(forCode: "AMU3M"))
        XCTAssertEqual(music.label, "Music")
        XCTAssertTrue(music.sharedFolders.contains("Repertoire"),
                      "A music course rehearses repertoire")
        XCTAssertTrue(music.sharedFolders.contains("Ontario Curriculum"))
        XCTAssertTrue(music.perSectionFolders.contains("All Classes"))

        let chemistry: SkeletonCatalog.Family = try XCTUnwrap(SkeletonCatalog.family(forCode: "SCH3U"))
        XCTAssertTrue(chemistry.sharedFolders.contains("Investigations"),
                      "A chemistry course investigates — and does not rehearse")
        XCTAssertFalse(chemistry.sharedFolders.contains("Repertoire"))
    }

    /// Example content beats a skeleton, so a code that has real pages is
    /// never offered the placeholder ones.
    @MainActor
    func testACodeWithExampleContentIsNotOfferedASkeleton() {
        XCTAssertFalse(SkeletonCatalog.hasSkeleton(forCode: "ADA1O"))
        XCTAssertTrue(SkeletonCatalog.hasSkeleton(forCode: "ADA2O"))
    }

    @MainActor
    func testTheSubjectsFoldersAreOfferedForACodeWithoutExampleContent() throws {
        let adopted: SkeletonCatalog.Family = try XCTUnwrap(SkeletonCatalog.structureToAdopt(
            forCode: "AMU3M", currentSharedFolders: WizardDefaults.sharedFolders))
        XCTAssertTrue(adopted.sharedFolders.contains("Repertoire"))
        XCTAssertTrue(adopted.perSectionFiles.contains("Key Links.md"))
    }

    /// A teacher who has edited the folder list keeps their edit, even if
    /// they then correct a typo in the course code.
    @MainActor
    func testAnEditedFolderListIsNeverOverwritten() {
        XCTAssertNil(SkeletonCatalog.structureToAdopt(
            forCode: "AMU3M", currentSharedFolders: ["Only", "Mine"]))
    }

    /// Switching between two codes in the same family changes nothing, so
    /// the wizard never churns the list while the teacher types.
    @MainActor
    func testTheSameFamilyTwiceChangesNothing() throws {
        let music: SkeletonCatalog.Family = try XCTUnwrap(SkeletonCatalog.family(forCode: "AMU3M"))
        XCTAssertNil(SkeletonCatalog.structureToAdopt(
            forCode: "AMU2O", currentSharedFolders: music.sharedFolders))
    }

    @MainActor
    func testACodeWithExampleContentKeepsItsOwnStructure() {
        XCTAssertNil(SkeletonCatalog.structureToAdopt(
            forCode: "ADA1O", currentSharedFolders: WizardDefaults.sharedFolders),
            "The example content chooses the folders for a code that has it")
        let wizard: NewCourseWizardView = NewCourseWizardView()
        XCTAssertEqual(
            wizard.buildConfigurationDictionary(code: "ADA1O", name: "Drama")["use_skeleton"] as? Bool,
            false)
        XCTAssertEqual(
            wizard.buildConfigurationDictionary(code: "AMU3M", name: "Music")["use_skeleton"] as? Bool,
            true)
    }
}
