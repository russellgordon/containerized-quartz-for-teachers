import Foundation

/// Removes a course or one of its sections from the working folder —
/// but never destroys the content: the folder is zipped into
/// `courses/_backups/<CODE>/` first, matching the archive the setup
/// wizard writes before it changes a course.
enum CourseArchiver {

    // MARK: - Functions

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

        // NSFileCoordinator's "for uploading" reading intent hands back a
        // zip of the folder — the system's own archiver, no dependencies.
        var coordinatorError: NSError?
        var copyError: Error?
        let coordinator: NSFileCoordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: folderURL, options: [.forUploading], error: &coordinatorError) { temporaryZipURL in
            do {
                try FileManager.default.copyItem(at: temporaryZipURL, to: archiveURL)
            } catch {
                copyError = error
            }
        }
        if let coordinatorError {
            throw coordinatorError
        }
        if let copyError {
            throw copyError
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
