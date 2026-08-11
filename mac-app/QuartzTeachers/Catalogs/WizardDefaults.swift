import Foundation

/// The defaults the setup wizard offers for a brand-new course, mirroring
/// the constants at the top of `scripts/setup_course.py`.
///
/// The factory defaults are deliberately school-neutral; the "Use
/// LCS-specific terminology" switch brings back LCS's own set-up — its
/// terms (Grove Time, SIC) and the College Board folder its AP courses
/// use. The paired lists are the whole difference.
enum WizardDefaults {

    // MARK: - Stored properties

    static let sharedFolders: [String] = [
        "Concepts", "Discussions", "Examples", "Exercises",
        "Ontario Curriculum", "Portfolios",
        "Recaps", "Setup", "Style", "Tasks", "Tutorials",
    ]

    static let lcsSharedFolders: [String] = [
        "Concepts", "Discussions", "Examples", "Exercises",
        "Ontario Curriculum", "College Board Curriculum", "Portfolios",
        "Recaps", "Setup", "Style", "Tasks", "Tutorials",
    ]

    static let sharedFiles: [String] = [
        "Extra Help.md", "Learning Goals.md",
    ]

    static let lcsSharedFiles: [String] = [
        "SIC Drop-In Sessions.md", "Grove Time.md", "Learning Goals.md",
    ]

    static let perSectionFolders: [String] = [
        "All Classes",
    ]

    static let perSectionFiles: [String] = [
        "Private Notes.md", "Scratch Page.md", "Key Links.md",
    ]

    /// Both terminologies appear here, so whichever names a course ends up
    /// with are hidden by default.
    static let hiddenItems: [String] = [
        "Media", "Ontario Curriculum", "College Board Curriculum",
        "Extra Help.md", "SIC Drop-In Sessions.md", "Grove Time.md",
        "Learning Goals.md",
        "Private Notes.md", "Scratch Page.md", "Key Links.md",
    ]

    static let expandableItems: [String] = [
        "Concepts", "Discussions", "Examples", "Exercises", "Portfolios",
        "Recaps", "Setup", "Style", "Tasks", "Tutorials",
    ]

    // MARK: - Functions

    /// The current list, moved to the other terminology's factory set:
    /// factory items are replaced wholesale, while names the teacher added
    /// themselves survive at the end of the list. A factory item the
    /// teacher deleted stays deleted only if they also deleted its
    /// counterpart's spot — the switch is a reset of the factory portion,
    /// which keeps its behaviour predictable.
    static func switchingFactoryItems(
        in currentNames: [String],
        toFactory factory: [String],
        fromFactory previousFactory: [String]
    ) -> [String] {
        var result: [String] = []
        for name in factory {
            result.append(name)
        }
        for name in currentNames {
            let belongsToAFactorySet: Bool = factory.contains(name) || previousFactory.contains(name)
            if !belongsToAFactorySet && !result.contains(name) {
                result.append(name)
            }
        }
        return result
    }
}
