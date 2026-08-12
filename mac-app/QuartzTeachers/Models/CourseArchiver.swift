import Foundation

/// Removes a course or one of its sections from the working folder —
/// but never destroys the content: the folder is zipped into
/// `courses/_backups/<CODE>/` first, matching the archive the setup
/// wizard writes before it changes a course.
enum CourseArchiver {

    // MARK: - Functions

    /// Saves a copy of an entire course — and touches nothing: the course
    /// stays exactly where it is. Made on purpose before risky editing so
    /// there is always a way back. Returns the backup that was written.
    ///
    /// The name (`<CODE>_backup_<timestamp>.zip`) is what separates a
    /// backup from an archive in the shared `_backups` folder.
    @discardableResult
    static func backUpCourse(_ course: Course, coursesDirectoryURL: URL) throws -> URL {
        return try archive(
            folderURL: course.directoryURL,
            named: timestampedName(prefix: "\(course.code)_backup"),
            forCourseCode: course.code,
            coursesDirectoryURL: coursesDirectoryURL
        )
    }

    /// Archives and removes an entire course folder.
    /// Returns the archive that was written.
    @discardableResult
    static func archiveAndRemoveCourse(_ course: Course, coursesDirectoryURL: URL) throws -> URL {
        let archiveURL: URL = try archive(
            folderURL: course.directoryURL,
            named: timestampedName(prefix: course.code),
            forCourseCode: course.code,
            coursesDirectoryURL: coursesDirectoryURL
        )
        try FileManager.default.removeItem(at: course.directoryURL)
        return archiveURL
    }

    /// Archives and removes one section folder, and takes that section
    /// out of the course's saved settings so it stops being listed.
    @discardableResult
    static func archiveAndRemoveSection(
        _ sectionNumber: Int,
        from course: Course,
        coursesDirectoryURL: URL
    ) throws -> URL {
        let sectionURL: URL = course.sectionDirectoryURL(forSection: sectionNumber)
        let archiveURL: URL = try archive(
            folderURL: sectionURL,
            named: timestampedName(prefix: "\(course.code)-section\(sectionNumber)"),
            forCourseCode: course.code,
            coursesDirectoryURL: coursesDirectoryURL
        )
        if FileManager.default.fileExists(atPath: sectionURL.path) {
            try FileManager.default.removeItem(at: sectionURL)
        }

        var remainingSections: [Int] = []
        for existingSection in course.sectionNumbers {
            if existingSection != sectionNumber {
                remainingSections.append(existingSection)
            }
        }
        course.configuration.setSectionNumbers(remainingSections)
        try course.configuration.write(to: course.configFileURL)

        return archiveURL
    }

    /// Things that are rebuilt rather than written, and so are left out of
    /// an archive. `.merged_output` is the important one: it holds a whole
    /// Quartz checkout with its dependencies, which dwarfs the course a
    /// teacher actually wrote and can always be produced again.
    ///
    /// The same list the setup wizard uses for its own backups.
    static let excludedFromArchives: [String] = [
        ".merged_output",
        "node_modules",
        ".git",
        ".quartz-cache",
        ".cache",
        "dist",
        "build",
        "out",
        "__pycache__",
        ".DS_Store",
    ]

    /// Zips a folder into `courses/_backups/<CODE>/<name>.zip`.
    private static func archive(
        folderURL: URL,
        named archiveName: String,
        forCourseCode courseCode: String,
        coursesDirectoryURL: URL
    ) throws -> URL {
        let backupsURL: URL = coursesDirectoryURL
            .appendingPathComponent("_backups")
            .appendingPathComponent(courseCode)
        try FileManager.default.createDirectory(at: backupsURL, withIntermediateDirectories: true)
        let archiveURL: URL = backupsURL.appendingPathComponent(archiveName)

        // Zipped with the system's own tool rather than NSFileCoordinator,
        // because this one can leave things out — and a course's built
        // output is many times the size of the course itself.
        var arguments: [String] = ["-r", "-q", "-X", archiveURL.path, folderURL.lastPathComponent]
        arguments.append("-x")
        for name in excludedFromArchives {
            arguments.append("*/\(name)/*")
            arguments.append("*/\(name)")
        }

        let zipper: Process = Process()
        zipper.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        zipper.arguments = arguments
        zipper.currentDirectoryURL = folderURL.deletingLastPathComponent()
        let errors: Pipe = Pipe()
        zipper.standardError = errors
        try zipper.run()
        zipper.waitUntilExit()
        if zipper.terminationStatus != 0 {
            let data: Data = errors.fileHandleForReading.readDataToEndOfFile()
            let reason: String = String(data: data, encoding: .utf8) ?? "unknown error"
            throw NSError(
                domain: "CourseArchiver",
                code: Int(zipper.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "Could not write the archive: \(reason.trimmingCharacters(in: .whitespacesAndNewlines))"]
            )
        }
        return archiveURL
    }

    /// "ICS3U_2026-08-09_141530.zip"
    private static func timestampedName(prefix: String) -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return "\(prefix)_\(formatter.string(from: Date())).zip"
    }
}
