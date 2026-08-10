import Foundation

/// Works out whether a section's built website is still up to date with
/// the teacher's content, so publishing can rebuild first when needed.
enum BuildFreshness {

    // MARK: - Functions

    /// True when there is no built site yet, or the content has changed
    /// since it was built.
    static func needsRebuild(course: Course, sectionNumber: Int) -> Bool {
        guard let builtDate = builtSiteDate(course: course, sectionNumber: sectionNumber) else {
            return true
        }
        guard let contentDate = newestContentDate(course: course) else {
            // No readable content: nothing to rebuild for.
            return false
        }
        return contentDate > builtDate
    }

    /// When the section's site was last built, or nil if it never was.
    static func builtSiteDate(course: Course, sectionNumber: Int) -> Date? {
        let indexURL: URL = course.directoryURL
            .appendingPathComponent(".merged_output")
            .appendingPathComponent("section\(sectionNumber)")
            .appendingPathComponent("public")
            .appendingPathComponent("index.html")
        return modificationDate(of: indexURL)
    }

    /// The newest change anywhere in the course's own content.
    ///
    /// Hidden entries are skipped, which conveniently excludes the
    /// generated `.merged_output`, the Netlify markers in
    /// `.netlify_sites`, Obsidian's `.obsidian` settings, and `.DS_Store`
    /// — none of which are content a rebuild should chase.
    static func newestContentDate(course: Course) -> Date? {
        let fileManager: FileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: course.directoryURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        var newestDate: Date?
        for case let fileURL as URL in enumerator {
            guard let date = modificationDate(of: fileURL) else {
                continue
            }
            if newestDate == nil || date > newestDate! {
                newestDate = date
            }
        }
        return newestDate
    }

    private static func modificationDate(of url: URL) -> Date? {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        return values?.contentModificationDate
    }
}
