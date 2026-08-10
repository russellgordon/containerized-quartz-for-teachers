import Foundation

/// Creates a brand-new section for an existing course — the reverse of
/// removing one. The scaffolding mirrors what the setup wizard builds for
/// each section: a `sectionN/` folder with its `index.md`, plus whichever
/// per-section folders and files the course's settings call for. Shared
/// folders and files already exist at the course level and are left alone.
enum SectionAdder {

    // MARK: - Types

    /// Why a section could not be added, in words a teacher can act on.
    enum Problem: LocalizedError {
        case sectionAlreadyListed(String, Int)
        case folderInTheWay(String, Int)

        var errorDescription: String? {
            switch self {
            case .sectionAlreadyListed(let code, let number):
                return "Section \(number) of \(code) already exists."
            case .folderInTheWay(let code, let number):
                return "A folder for section \(number) of \(code) is already on disk. Move it aside first — it may hold work you want to keep."
            }
        }
    }

    // MARK: - Functions

    /// Adds one section: scaffolds its folder and adds its number to the
    /// course's settings, keeping the numbers in order. Nothing is ever
    /// written over — a folder already at the destination stops the add,
    /// because whatever is in the way may be newer work.
    static func addSection(_ sectionNumber: Int, to course: Course) throws {
        if course.sectionNumbers.contains(sectionNumber) {
            throw Problem.sectionAlreadyListed(course.code, sectionNumber)
        }

        let fileManager: FileManager = FileManager.default
        let sectionURL: URL = course.sectionDirectoryURL(forSection: sectionNumber)
        if fileManager.fileExists(atPath: sectionURL.path) {
            throw Problem.folderInTheWay(course.code, sectionNumber)
        }

        let created: String = timestamp()
        try fileManager.createDirectory(at: sectionURL, withIntermediateDirectories: true)

        // The section's own landing page, titled the way the wizard titles
        // one: "Grade 11 Computer Science, Section 3" — or without the grade
        // for a club, whose code has no grade digit.
        let gradeLabel: String = SectionAdder.gradeLabel(forCourseCode: course.code)
        let titlePrefix: String = gradeLabel.isEmpty ? "" : "\(gradeLabel) "
        let indexBody: String = """
        ---
        title: \(titlePrefix)\(course.configuration.courseName), Section \(sectionNumber)
        created: \(created)
        draft: false
        ---
        """
        try indexBody.write(to: sectionURL.appendingPathComponent("index.md"), atomically: true, encoding: .utf8)

        for folderName in course.configuration.perSectionFolders {
            let folderURL: URL = sectionURL.appendingPathComponent(folderName)
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let folderIndex: String = """
            ---
            title: \(folderName)
            created: \(created)
            draft: false
            ---
            This is the **\(folderName)** folder. Add Markdown files to this folder to build out your site.
            """
            try folderIndex.write(to: folderURL.appendingPathComponent("index.md"), atomically: true, encoding: .utf8)
        }

        for fileName in course.configuration.perSectionFiles {
            let fileBody: String = """
            ---
            title: \(fileName.replacingOccurrences(of: ".md", with: ""))
            created: \(created)
            draft: false
            ---
            This is the per-section file **\(fileName)**.
            """
            try fileBody.write(to: sectionURL.appendingPathComponent(fileName), atomically: true, encoding: .utf8)
        }

        // Only once the folder is safely in place does the section join the
        // course's settings — the same order restore uses, so a failure
        // partway never leaves the settings pointing at nothing.
        var numbers: [Int] = course.sectionNumbers
        numbers.append(sectionNumber)
        numbers.sort()
        course.configuration.setSectionNumbers(numbers)
        try course.configuration.write(to: course.configFileURL)
    }

    /// The grade named by the course code's fourth character, matching the
    /// wizard: "ICS3U" → "Grade 11". A club code like "CODING" has no grade
    /// digit there, so no grade label at all.
    static func gradeLabel(forCourseCode code: String) -> String {
        let characters: [Character] = Array(code)
        guard characters.count >= 4 else {
            return ""
        }
        let gradeCharacter: Character = characters[3]
        guard gradeCharacter.isNumber else {
            return ""
        }
        switch gradeCharacter {
        case "1": return "Grade 9"
        case "2": return "Grade 10"
        case "3": return "Grade 11"
        case "4": return "Grade 12"
        default: return "Grade ?"
        }
    }

    /// The `created:` timestamp, in the same form the wizard writes:
    /// `2026-08-10T14:30:00.000-0400`.
    static func timestamp(for date: Date = Date()) -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.000Z"
        return formatter.string(from: date)
    }

    /// The number the sheet should offer first: the smallest section number
    /// not already in use, so "add section 1" and "add the next one" are
    /// each a single click.
    static func suggestedNumber(existing: [Int]) -> Int {
        var candidate: Int = 1
        while existing.contains(candidate) {
            candidate += 1
        }
        return candidate
    }

    /// What is wrong with the typed section number, or nil when nothing is —
    /// worded like the wizard's own warnings. An empty field is quietly
    /// invalid: nothing has been said yet, so there is nothing to warn about.
    static func entryProblem(_ entry: String, existing: [Int], courseCode: String) -> String? {
        let trimmed: String = entry.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return nil
        }
        guard let number = Int(trimmed) else {
            return "“\(trimmed)” isn’t a section number — sections are 1 or higher."
        }
        if number < 1 {
            return "“\(trimmed)” isn’t a section number — sections are 1 or higher."
        }
        if existing.contains(number) {
            return "Section \(number) of \(courseCode) already exists."
        }
        return nil
    }

    /// True when the typed entry names a section that can be added right now.
    static func entryIsAddable(_ entry: String, existing: [Int]) -> Bool {
        let trimmed: String = entry.trimmingCharacters(in: .whitespaces)
        guard let number = Int(trimmed) else {
            return false
        }
        return number >= 1 && !existing.contains(number)
    }
}
