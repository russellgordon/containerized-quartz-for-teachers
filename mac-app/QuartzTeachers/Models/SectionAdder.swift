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

        // A new section should behave like the sections beside it — the same
        // pages published, the same pages held back as drafts, the same
        // display flags. So each scaffolded file copies its frontmatter from
        // the matching file in an existing section when there is one, and
        // only falls back to the wizard's plain template when there is not.
        let indexFrontmatter: String = scaffoldFrontmatter(
            sibling: siblingFile(named: "index.md", in: course),
            replacingTitleWith: sectionTitle(for: course, sectionNumber: sectionNumber),
            created: created
        )
        let indexBody: String = """
        ---
        \(indexFrontmatter)
        ---
        """
        try indexBody.write(to: sectionURL.appendingPathComponent("index.md"), atomically: true, encoding: .utf8)

        for folderName in course.configuration.perSectionFolders {
            let folderURL: URL = sectionURL.appendingPathComponent(folderName)
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let folderFrontmatter: String = scaffoldFrontmatter(
                sibling: siblingFile(named: "\(folderName)/index.md", in: course),
                replacingTitleWith: nil,
                fallbackTitle: folderName,
                created: created
            )
            let folderIndex: String = """
            ---
            \(folderFrontmatter)
            ---
            This is the **\(folderName)** folder. Add Markdown files to this folder to build out your site.
            """
            try folderIndex.write(to: folderURL.appendingPathComponent("index.md"), atomically: true, encoding: .utf8)
        }

        for fileName in course.configuration.perSectionFiles {
            let fileFrontmatter: String = scaffoldFrontmatter(
                sibling: siblingFile(named: fileName, in: course),
                replacingTitleWith: nil,
                fallbackTitle: fileName.replacingOccurrences(of: ".md", with: ""),
                fallbackIsDraft: SectionAdder.unpublishedFileNames.contains(fileName),
                created: created
            )
            let fileBody: String = """
            ---
            \(fileFrontmatter)
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

    /// The same file in an existing section, if any section has it — the
    /// lowest-numbered one wins, so the choice is predictable.
    static func siblingFile(named relativePath: String, in course: Course) -> URL? {
        var numbers: [Int] = course.sectionNumbers
        numbers.sort()
        for number in numbers {
            let candidate: URL = course.sectionDirectoryURL(forSection: number).appendingPathComponent(relativePath)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }

    /// Pages that exist for the teacher's own eyes — the wizard creates
    /// them as drafts so they are never published, and a section added
    /// with no sibling to imitate must do the same.
    static let unpublishedFileNames: Set<String> = ["Private Notes.md", "Scratch Page.md"]

    /// The frontmatter for one scaffolded file. A sibling's frontmatter is
    /// carried over whole — draft status, table-of-contents and backlink
    /// flags, anything else the teacher set — with only `created:` freshened
    /// and, when a new title is given, the title swapped. Without a sibling,
    /// the wizard's plain template stands in.
    static func scaffoldFrontmatter(
        sibling: URL?,
        replacingTitleWith newTitle: String?,
        fallbackTitle: String? = nil,
        fallbackIsDraft: Bool = false,
        created: String
    ) -> String {
        if let sibling, let siblingLines = frontmatterLines(ofFileAt: sibling) {
            var result: [String] = []
            for line in siblingLines {
                if line.hasPrefix("created:") {
                    result.append("created: \(created)")
                } else if line.hasPrefix("title:"), let newTitle {
                    result.append("title: \(newTitle)")
                } else {
                    result.append(line)
                }
            }
            return result.joined(separator: "\n")
        }
        let title: String = newTitle ?? fallbackTitle ?? ""
        return "title: \(title)\ncreated: \(created)\ndraft: \(fallbackIsDraft ? "true" : "false")"
    }

    /// The lines between a file's opening and closing `---` markers, or nil
    /// when the file has no frontmatter to speak of.
    static func frontmatterLines(ofFileAt url: URL) -> [String]? {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        let lines: [String] = text.components(separatedBy: "\n")
        guard lines.first == "---" else {
            return nil
        }
        var collected: [String] = []
        var index: Int = 1
        while index < lines.count {
            if lines[index] == "---" {
                return collected
            }
            collected.append(lines[index])
            index += 1
        }
        return nil
    }

    /// The new section's landing-page title. A sibling section's title with
    /// the section number swapped is the most faithful source — it keeps
    /// whatever wording the teacher chose. Failing that, the wizard's form,
    /// without doubling the grade when the course name already leads with it
    /// ("Grade 9 Science" must not become "Grade 9 Grade 9 Science").
    static func sectionTitle(for course: Course, sectionNumber: Int) -> String {
        if let siblingIndex = siblingFile(named: "index.md", in: course),
           let siblingLines = frontmatterLines(ofFileAt: siblingIndex) {
            for line in siblingLines {
                if line.hasPrefix("title:") {
                    let siblingTitle: String = String(line.dropFirst("title:".count)).trimmingCharacters(in: .whitespaces)
                    if let range = siblingTitle.range(of: #"Section \d+$"#, options: .regularExpression) {
                        return siblingTitle.replacingCharacters(in: range, with: "Section \(sectionNumber)")
                    }
                }
            }
        }
        let gradeLabel: String = SectionAdder.gradeLabel(forCourseCode: course.code)
        let courseName: String = course.configuration.courseName
        // Deliberately literal, matching the build: the switch alone
        // decides. The settings warn when the name already carries the
        // grade; resolving that is the teacher's call, never guessed.
        var titlePrefix: String = ""
        if course.configuration.showsGradeInTitle(forSection: sectionNumber) && !gradeLabel.isEmpty {
            titlePrefix = "\(gradeLabel) "
        }
        return "\(titlePrefix)\(courseName), Section \(sectionNumber)"
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
