import Foundation

/// Brings an archived course or section back into the working folder.
///
/// The archive holds the folder itself at its root — `section1/…` or
/// `IZN2O/…` — so restoring is an extract into the right parent. Nothing is
/// ever written over: if something already occupies the destination, the
/// restore stops and says so, because the thing in the way may be newer work.
enum CourseRestorer {

    // MARK: - Types

    /// Why a restore could not go ahead, in words a teacher can act on.
    enum Problem: LocalizedError {
        case courseAlreadyPresent(String)
        case courseMissing(String)
        case sectionAlreadyPresent(String, Int)
        case archiveUnreadable(String)

        var errorDescription: String? {
            switch self {
            case .courseAlreadyPresent(let code):
                return "\(code) is already in Courses & Clubs. Remove it first if you want the archived copy back."
            case .courseMissing(let code):
                return "\(code) is not in Courses & Clubs. Restore the course first, then restore this section into it."
            case .sectionAlreadyPresent(let code, let number):
                return "Section \(number) of \(code) already exists. Remove it first if you want the archived copy back."
            case .archiveUnreadable(let reason):
                return "The archive could not be opened: \(reason)"
            }
        }
    }

    // MARK: - Functions

    /// Restores one archived item, then removes the archive — the content is
    /// live again, and a list of archived things should not include it.
    static func restore(_ item: ArchivedItem, coursesDirectoryURL: URL, courses: [Course]) throws {
        let fileManager: FileManager = FileManager.default
        let courseURL: URL = coursesDirectoryURL.appendingPathComponent(item.courseCode)

        if let sectionNumber = item.sectionNumber {
            var matchingCourse: Course?
            for course in courses {
                if course.code == item.courseCode {
                    matchingCourse = course
                }
            }
            guard let course = matchingCourse else {
                throw Problem.courseMissing(item.courseCode)
            }
            let sectionURL: URL = course.sectionDirectoryURL(forSection: sectionNumber)
            if fileManager.fileExists(atPath: sectionURL.path) {
                throw Problem.sectionAlreadyPresent(item.courseCode, sectionNumber)
            }

            try extract(item.fileURL, named: "section\(sectionNumber)", into: courseURL)
            try putSectionBack(sectionNumber, into: course)
        } else {
            if fileManager.fileExists(atPath: courseURL.path) {
                throw Problem.courseAlreadyPresent(item.courseCode)
            }
            try extract(item.fileURL, named: item.courseCode, into: coursesDirectoryURL)
        }

        try? fileManager.removeItem(at: item.fileURL)
    }

    /// Adds the section number back to the course's settings, in order.
    /// Archiving took it out; restoring has to put it back or the section
    /// exists on disk while the course carries on ignoring it.
    private static func putSectionBack(_ sectionNumber: Int, into course: Course) throws {
        var numbers: [Int] = course.sectionNumbers
        if !numbers.contains(sectionNumber) {
            numbers.append(sectionNumber)
        }
        numbers.sort()
        course.configuration.setSectionNumbers(numbers)
        try course.configuration.write(to: course.configFileURL)
    }

    /// Unpacks the archive somewhere safe, checks it holds what its name
    /// promised, and only then moves it into place.
    private static func extract(_ archiveURL: URL, named expectedName: String, into destinationParent: URL) throws {
        let fileManager: FileManager = FileManager.default
        let staging: URL = fileManager.temporaryDirectory.appendingPathComponent("restore-" + UUID().uuidString)
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: staging) }

        let unzip: Process = Process()
        unzip.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        unzip.arguments = ["-x", "-k", archiveURL.path, staging.path]
        let errors: Pipe = Pipe()
        unzip.standardError = errors
        try unzip.run()
        unzip.waitUntilExit()
        if unzip.terminationStatus != 0 {
            let data: Data = errors.fileHandleForReading.readDataToEndOfFile()
            let reason: String = String(data: data, encoding: .utf8) ?? "unknown error"
            throw Problem.archiveUnreadable(reason.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        var payload: URL = staging.appendingPathComponent(expectedName)
        if !fileManager.fileExists(atPath: payload.path) {
            // Fall back to whatever single folder the archive held, so an
            // archive made by another version still restores.
            let entries: [URL] = (try? fileManager.contentsOfDirectory(at: staging, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
            if entries.count == 1 {
                payload = entries[0]
            } else {
                throw Problem.archiveUnreadable("it does not contain \(expectedName)")
            }
        }

        try fileManager.createDirectory(at: destinationParent, withIntermediateDirectories: true)
        try fileManager.moveItem(at: payload, to: destinationParent.appendingPathComponent(expectedName))
    }
}
