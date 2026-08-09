import Foundation
import Observation

/// One course (or club) folder inside the working folder's `courses/`
/// directory, together with its loaded configuration.
@Observable
class Course: Identifiable {

    // MARK: - Stored properties

    /// The course code, e.g. "ICS3U" — also the folder name.
    let code: String

    /// The course folder, e.g. `<workspace>/courses/ICS3U`.
    let directoryURL: URL

    /// The loaded `course_config.json` for this course.
    let configuration: CourseConfiguration

    // MARK: - Computed properties

    var id: String {
        return code
    }

    /// The timetable section numbers for this course, from the configuration.
    var sectionNumbers: [Int] {
        return configuration.sectionNumbers
    }

    var configFileURL: URL {
        return directoryURL.appendingPathComponent("course_config.json")
    }

    // MARK: - Functions

    /// The folder holding one section's content, e.g.
    /// `<workspace>/courses/ICS3U/section3`.
    func sectionDirectoryURL(forSection sectionNumber: Int) -> URL {
        return directoryURL.appendingPathComponent("section\(sectionNumber)")
    }

    // MARK: - Initializer

    init(code: String, directoryURL: URL, configuration: CourseConfiguration) {
        self.code = code
        self.directoryURL = directoryURL
        self.configuration = configuration
    }
}
