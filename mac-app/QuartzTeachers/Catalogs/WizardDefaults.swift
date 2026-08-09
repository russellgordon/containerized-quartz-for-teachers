import Foundation

/// The defaults the setup wizard offers for a brand-new course, mirroring
/// the constants at the top of `scripts/setup_course.py`.
enum WizardDefaults {

    // MARK: - Stored properties

    static let sharedFolders: [String] = [
        "Concepts", "Discussions", "Examples", "Exercises",
        "Ontario Curriculum", "College Board Curriculum", "Portfolios",
        "Recaps", "Setup", "Style", "Tasks", "Tutorials",
    ]

    static let sharedFiles: [String] = [
        "SIC Drop-In Sessions.md", "Grove Time.md", "Learning Goals.md",
    ]

    static let perSectionFolders: [String] = [
        "All Classes",
    ]

    static let perSectionFiles: [String] = [
        "Private Notes.md", "Scratch Page.md", "Key Links.md",
    ]

    static let hiddenItems: [String] = [
        "Media", "Ontario Curriculum", "College Board Curriculum",
        "SIC Drop-In Sessions.md", "Grove Time.md", "Learning Goals.md",
        "Private Notes.md", "Scratch Page.md", "Key Links.md",
    ]

    static let expandableItems: [String] = [
        "Concepts", "Discussions", "Examples", "Exercises", "Portfolios",
        "Recaps", "Setup", "Style", "Tasks", "Tutorials",
    ]
}
