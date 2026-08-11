import XCTest
@testable import QuartzTeachers

/// The LCS-terminology switch: school-neutral factory defaults, with one
/// toggle bringing back LCS's own words and folders.
final class TerminologyTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testTheNeutralDefaultsCarryNoLCSTerms() {
        XCTAssertFalse(WizardDefaults.sharedFolders.contains("College Board Curriculum"))
        XCTAssertFalse(WizardDefaults.sharedFiles.contains("SIC Drop-In Sessions.md"))
        XCTAssertFalse(WizardDefaults.sharedFiles.contains("Grove Time.md"))
        XCTAssertTrue(WizardDefaults.sharedFiles.contains("Extra Help.md"))
    }

    @MainActor
    func testTheLCSSetRestoresTheSchoolsOwnSetUp() {
        XCTAssertTrue(WizardDefaults.lcsSharedFolders.contains("College Board Curriculum"))
        XCTAssertTrue(WizardDefaults.lcsSharedFiles.contains("SIC Drop-In Sessions.md"))
        XCTAssertTrue(WizardDefaults.lcsSharedFiles.contains("Grove Time.md"))
        XCTAssertFalse(WizardDefaults.lcsSharedFiles.contains("Extra Help.md"))
    }

    @MainActor
    func testSwitchingReplacesFactoryItemsAndKeepsCustomOnes() {
        var files: [String] = WizardDefaults.sharedFiles
        files.append("Course Calendar.md")

        let switched: [String] = WizardDefaults.switchingFactoryItems(
            in: files,
            toFactory: WizardDefaults.lcsSharedFiles,
            fromFactory: WizardDefaults.sharedFiles
        )
        XCTAssertTrue(switched.contains("Grove Time.md"))
        XCTAssertFalse(switched.contains("Extra Help.md"))
        XCTAssertTrue(switched.contains("Course Calendar.md"),
                      "A file the teacher added themselves survives the switch")

        let switchedBack: [String] = WizardDefaults.switchingFactoryItems(
            in: switched,
            toFactory: WizardDefaults.sharedFiles,
            fromFactory: WizardDefaults.lcsSharedFiles
        )
        XCTAssertEqual(switchedBack, WizardDefaults.sharedFiles + ["Course Calendar.md"])
    }

    @MainActor
    func testHiddenDefaultsCoverBothTerminologies() {
        for name in ["Extra Help.md", "Grove Time.md", "SIC Drop-In Sessions.md", "College Board Curriculum"] {
            XCTAssertTrue(WizardDefaults.hiddenItems.contains(name), "\(name) missing from hidden defaults")
        }
    }

    @MainActor
    func testTheWizardWritesTheTerminologyChoice() {
        let wizard: NewCourseWizardView = NewCourseWizardView()
        let configuration: [String: Any] = wizard.buildConfigurationDictionary(
            code: "ICS3U", name: "Computer Science"
        )
        XCTAssertEqual(configuration["use_lcs_terminology"] as? Bool, false,
                       "School-neutral is the factory default")
    }
}
