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
        XCTAssertTrue(music.sharedFolders.contains("Curriculum"),
                      "Named as the example-content payloads name it")
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

    /// The folders a skeleton hides and expands are its own, not the app's
    /// generic list — which knows nothing about Repertoire.
    @MainActor
    func testASkeletonCourseHidesAndExpandsItsOwnFolders() {
        let wizard: NewCourseWizardView = NewCourseWizardView()
        let configuration: [String: Any] = wizard.buildConfigurationDictionary(
            code: "AMU3M", name: "Music")
        let hidden: [String] = try! XCTUnwrap(configuration["hidden"] as? [String])
        let expandable: [String] = try! XCTUnwrap(configuration["expandable"] as? [String])
        XCTAssertTrue(hidden.contains("Curriculum"))
        XCTAssertTrue(hidden.contains("Media"))
        XCTAssertTrue(expandable.contains("Repertoire"))
        XCTAssertFalse(expandable.contains("Curriculum"),
                       "A hidden folder cannot also be expandable")
    }

    /// Editing the folder list must not cost the teacher the skeleton's
    /// sidebar choices — that was the bug: one added folder and the
    /// curriculum folder reappeared while the subject folders lost their
    /// chevrons.
    @MainActor
    func testAnAddedFolderKeepsTheSidebarRulesAndGetsItsOwnChevron() throws {
        let music: SkeletonCatalog.Family = try XCTUnwrap(SkeletonCatalog.family(forCode: "AMU3M"))
        let plan = SkeletonCatalog.sidebar(
            for: music,
            sharedFolders: music.sharedFolders + ["Field Trips"],
            sharedFiles: music.sharedFiles,
            perSectionFolders: music.perSectionFolders,
            perSectionFiles: music.perSectionFiles
        )
        XCTAssertTrue(plan.hidden.contains("Curriculum"))
        XCTAssertTrue(plan.hidden.contains("Media"))
        XCTAssertTrue(plan.expandable.contains("Repertoire"))
        XCTAssertTrue(plan.expandable.contains("Field Trips"),
                      "A folder the teacher added is a section like any other")
        XCTAssertFalse(plan.expandable.contains("Curriculum"),
                       "A hidden folder cannot also be expandable")
        XCTAssertFalse(plan.expandable.contains("All Classes"),
                       "All Classes stays a plain link to its listing")
    }

    /// Every family, not just the one this test happened to name.
    @MainActor
    func testEveryFamilyHidesItsCurriculumAndExpandsEverythingElse() throws {
        for name in SkeletonCatalog.everyFamilyName() {
            let family: SkeletonCatalog.Family = try XCTUnwrap(SkeletonCatalog.family(named: name))
            let plan = SkeletonCatalog.sidebar(
                for: family,
                sharedFolders: family.sharedFolders,
                sharedFiles: family.sharedFiles,
                perSectionFolders: family.perSectionFolders,
                perSectionFiles: family.perSectionFiles
            )
            XCTAssertTrue(plan.hidden.contains("Curriculum"), "\(name) shows its curriculum folder")
            for folder in family.sharedFolders where folder != "Curriculum" {
                XCTAssertTrue(plan.expandable.contains(folder), "\(name): \(folder) has no chevron")
            }
            for folder in family.perSectionFolders {
                XCTAssertFalse(plan.expandable.contains(folder), "\(name): \(folder) should stay a plain link")
            }
        }
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
