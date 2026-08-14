import Foundation
import Observation

/// An in-memory copy of one course's `course_config.json`.
///
/// This type deliberately stores the decoded JSON as a dictionary and exposes
/// typed accessors over it, rather than using `Codable`. The command-line
/// scripts own this file format; keeping unknown keys intact means a config
/// written by a newer script version survives a round trip through this app.
@Observable
class CourseConfiguration {

    // MARK: - Stored properties

    /// The decoded contents of `course_config.json`.
    var values: [String: Any]

    /// The bytes most recently read from or written to disk, used by
    /// `discardChanges()` to implement the Cancel button.
    private var lastSavedData: Data

    // MARK: - Computed properties

    var courseCode: String {
        return stringValue(forKey: "course_code")
    }

    var courseName: String {
        get { return stringValue(forKey: "course_name") }
        set { values["course_name"] = newValue }
    }

    /// Where deploys go: "netlify" (the default) or "local_folder" — a
    /// folder on this computer, for teachers who upload to their own web
    /// host themselves (e.g. over SFTP). Course-level: every section of
    /// the course publishes the same way.
    var deployTarget: String {
        get {
            let stored: String = stringValue(forKey: "deploy_target")
            return stored.isEmpty ? "netlify" : stored
        }
        set { values["deploy_target"] = newValue }
    }

    /// The folder local-folder deploys publish into; each section lands
    /// in its own sectionN subfolder inside it.
    var deployFolderPath: String {
        get { return stringValue(forKey: "deploy_folder_path") }
        set { values["deploy_folder_path"] = newValue }
    }

    /// True when this course publishes to a folder rather than Netlify.
    var deploysToLocalFolder: Bool {
        return deployTarget == "local_folder" && !deployFolderPath.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// What is wrong with a folder chosen for local-folder publishing, or
    /// nil when the folder is usable. Both the settings form and the
    /// wizard check this live — and block saving — so a deploy never
    /// discovers the problem after the fact.
    static func deployFolderProblem(forPath rawPath: String) -> String? {
        let path: String = rawPath.trimmingCharacters(in: .whitespaces)
        if path.isEmpty {
            return "Choose the folder this course publishes into."
        }
        let fileManager: FileManager = FileManager.default
        var isDirectory: ObjCBool = false
        let exists: Bool = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        if !exists {
            return "That folder doesn’t exist — use Choose… to pick or create one."
        }
        if !isDirectory.boolValue {
            return "That’s a file — publishing needs a folder."
        }
        if !fileManager.isWritableFile(atPath: path) {
            return "That folder can’t be written to — choose a different one."
        }
        return nil
    }

    var customShortName: String {
        get { return stringValue(forKey: "custom_short_name") }
        set { values["custom_short_name"] = newValue }
    }

    var locale: String {
        get {
            let stored: String = stringValue(forKey: "locale")
            if stored.isEmpty {
                return "en-US"
            }
            return stored
        }
        set { values["locale"] = newValue }
    }

    /// True when the course code has no numeric grade in position four
    /// (e.g. "CODING") — the scripts treat these as clubs.
    var isClub: Bool {
        let code: String = courseCode
        if code.count < 4 {
            return true
        }
        let characters: [Character] = Array(code)
        return !characters[3].isNumber
    }

    var sectionNumbers: [Int] {
        if let numbers = values["section_numbers"] as? [Int] {
            return numbers
        }
        // Older configs may store numbers as NSNumber via JSONSerialization.
        if let rawNumbers = values["section_numbers"] as? [Any] {
            var result: [Int] = []
            for rawNumber in rawNumbers {
                if let number = rawNumber as? NSNumber {
                    result.append(number.intValue)
                }
            }
            if !result.isEmpty {
                return result
            }
        }
        let count: Int = intValue(forKey: "num_sections", fallback: 1)
        var result: [Int] = []
        for sectionNumber in 1...max(count, 1) {
            result.append(sectionNumber)
        }
        return result
    }

    var sharedFolders: [String] {
        get { return stringListValue(forKey: "shared_folders") }
        set { values["shared_folders"] = newValue }
    }

    var sharedFiles: [String] {
        get { return stringListValue(forKey: "shared_files") }
        set { values["shared_files"] = newValue }
    }

    var perSectionFolders: [String] {
        get { return stringListValue(forKey: "per_section_folders") }
        set { values["per_section_folders"] = newValue }
    }

    var perSectionFiles: [String] {
        get { return stringListValue(forKey: "per_section_files") }
        set { values["per_section_files"] = newValue }
    }

    var hiddenItems: [String] {
        get { return stringListValue(forKey: "hidden") }
        set { values["hidden"] = newValue }
    }

    var expandableItems: [String] {
        get { return stringListValue(forKey: "expandable") }
        set { values["expandable"] = newValue }
    }

    var expandOnFolderClick: Bool {
        get { return boolValue(forKey: "expandOnFolderClick", fallback: false) }
        set { values["expandOnFolderClick"] = newValue }
    }

    var footerHTML: String {
        get { return stringValue(forKey: "footer_html") }
        set { values["footer_html"] = newValue }
    }

    /// Whether a section's site title leads with the grade ("Grade 12
    /// Computer Science…") — per section, like the section marker. On by
    /// default; the build recomputes the landing title on every build.
    /// An older config that stored one course-wide Bool is honoured.
    func showsGradeInTitle(forSection sectionNumber: Int) -> Bool {
        if let legacy = values["show_grade_in_title"] as? Bool {
            return legacy
        }
        let sectionsMap: [String: Any] = nestedDictionary(forKey: "show_grade_in_title", childKey: "sections")
        if let stored = sectionsMap["section\(sectionNumber)"] as? Bool {
            return stored
        }
        return true
    }

    func setShowsGradeInTitle(_ shows: Bool, forSection sectionNumber: Int) {
        // A legacy course-wide Bool would shadow the per-section map, so
        // it is replaced by the map the first time a section is set.
        if values["show_grade_in_title"] is Bool {
            values["show_grade_in_title"] = [String: Any]()
        }
        setNestedValue(shows, forKey: "show_grade_in_title", childKey: "sections", entryKey: "section\(sectionNumber)")
    }

    /// The landing page's title as the build will compute it — the same
    /// literal rule as `computed_landing_title` in `scripts/build_site.py`:
    /// the grade prefix when its switch is on and the code carries a grade
    /// digit, the course name, and ", Section N" when the marker switch is
    /// on. Used wherever the app previews the site's own headline.
    static func landingTitle(
        courseName: String,
        courseCode: String,
        showsGrade: Bool,
        showsSectionMarker: Bool,
        sectionNumber: Int
    ) -> String {
        let name: String = courseName.trimmingCharacters(in: .whitespaces)
        var prefix: String = ""
        let gradeLabel: String = SectionAdder.gradeLabel(forCourseCode: courseCode)
        if showsGrade && !gradeLabel.isEmpty {
            prefix = "\(gradeLabel) "
        }
        var title: String = "\(prefix)\(name)"
        if showsSectionMarker {
            title = "\(title), Section \(sectionNumber)"
        }
        return title
    }

    /// A quiet warning when turning the grade on would repeat a grade the
    /// course name already carries — "Computer Science, Grade 12, U" would
    /// become "Grade 12 Computer Science, Grade 12, U". The behaviour
    /// stays exactly what the switch says; this only points the problem
    /// out, and the teacher decides: edit the name, or turn the switch off.
    static func gradeInTitleWarning(courseName: String, courseCode: String, showsGrade: Bool) -> String? {
        guard showsGrade else {
            return nil
        }
        let label: String = SectionAdder.gradeLabel(forCourseCode: courseCode)
        guard !label.isEmpty, courseName.contains(label) else {
            return nil
        }
        return "The course name already includes “\(label)”, so the site title would repeat it. Edit the name, or turn this off."
    }

    var showReadingTime: Bool {
        get { return boolValue(forKey: "show_reading_time", fallback: false) }
        set { values["show_reading_time"] = newValue }
    }

    /// Whether this course publishes the Curriculum Coverage page.
    var includesCurriculumCoverage: Bool {
        get { return boolValue(forKey: "include_curriculum_coverage", fallback: true) }
        set {
            values["include_curriculum_coverage"] = newValue
            // The sections cannot outlive the page they sit on.
            if !newValue {
                values["include_coverage_notes"] = false
            }
        }
    }

    /// Whether the coverage page carries its two explanatory sections.
    var includesCoverageNotes: Bool {
        get {
            return CourseConfiguration.coverageNotesEnabled(
                curriculumCoverageEnabled: includesCurriculumCoverage,
                includesCoverageNotes: boolValue(forKey: "include_coverage_notes", fallback: true)
            )
        }
        set { values["include_coverage_notes"] = newValue }
    }

    /// Every item that can be hidden or made expandable in the sidebar.
    var allSidebarItems: [String] {
        var result: [String] = []
        for folder in sharedFolders {
            result.append(folder)
        }
        for file in sharedFiles {
            result.append(file)
        }
        for folder in perSectionFolders {
            result.append(folder)
        }
        for file in perSectionFiles {
            result.append(file)
        }
        return result
    }

    // MARK: - Initializer

    init(values: [String: Any], lastSavedData: Data) {
        self.values = values
        self.lastSavedData = lastSavedData
    }

    /// Loads a configuration from `course_config.json` on disk.
    convenience init(contentsOf url: URL) throws {
        let data: Data = try Data(contentsOf: url)
        let decoded: Any = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = decoded as? [String: Any] else {
            throw CourseConfigurationError.notADictionary
        }
        self.init(values: dictionary, lastSavedData: data)
    }

    // MARK: - Functions

    /// Replaces the course's timetable section numbers (used when a
    /// section is archived and removed).
    func setSectionNumbers(_ sectionNumbers: [Int]) {
        values["section_numbers"] = sectionNumbers
        values["num_sections"] = sectionNumbers.count
    }

    /// The emoji shown beside the site title for a given section.
    func emoji(forSection sectionNumber: Int) -> String {
        let sectionsMap: [String: Any] = nestedDictionary(forKey: "emojis", childKey: "sections")
        if let stored = sectionsMap["section\(sectionNumber)"] as? String {
            if !stored.isEmpty {
                return stored
            }
        }
        return "📚"
    }

    func setEmoji(_ emoji: String, forSection sectionNumber: Int) {
        setNestedValue(emoji, forKey: "emojis", childKey: "sections", entryKey: "section\(sectionNumber)")
    }

    /// The teacher's own domain for a section's published site — shown in
    /// links to the live site in place of the address Netlify assigns.
    /// Empty when the Netlify address is used as-is.
    func customDomain(forSection sectionNumber: Int) -> String {
        let sectionsMap: [String: Any] = nestedDictionary(forKey: "custom_domains", childKey: "sections")
        if let stored = sectionsMap["section\(sectionNumber)"] as? String {
            return stored
        }
        return ""
    }

    func setCustomDomain(_ domain: String, forSection sectionNumber: Int) {
        setNestedValue(domain, forKey: "custom_domains", childKey: "sections", entryKey: "section\(sectionNumber)")
    }

    /// A typed or pasted domain, reduced to just the domain: whitespace
    /// trimmed, any scheme stripped, and anything from the first slash on
    /// dropped — so a pasted "https://ics3u.school.ca/" stores as
    /// "ics3u.school.ca".
    /// Whether the curriculum coverage map should be switched on for a new
    /// course.
    ///
    /// The map is drawn from the site's own links to the curriculum pages,
    /// so it cannot exist without them: declining the curriculum forces the
    /// map off, whatever the toggle was last left at. The reverse is not
    /// true — keeping the curriculum pages and declining the map is a
    /// reasonable choice, and this returns exactly what the teacher asked
    /// for in that case.
    ///
    /// The rule lives here rather than inside the wizard view so that it
    /// can be tested: a SwiftUI `@State` property has no backing store
    /// until the view is on screen, so a test that sets one and reads a
    /// computed result gets the default back every time.
    static func curriculumCoverageEnabled(
        codeHasExampleContent: Bool,
        prepopulatesExampleContent: Bool,
        payloadIncludesCurriculum: Bool,
        includesCurriculumPages: Bool,
        includesCurriculumCoverage: Bool
    ) -> Bool {
        guard codeHasExampleContent,
              prepopulatesExampleContent,
              payloadIncludesCurriculum,
              includesCurriculumPages else {
            return false
        }
        return includesCurriculumCoverage
    }

    /// Whether the coverage page's two explanatory sections should be
    /// switched on for a new course.
    ///
    /// The sections live on the coverage page, so they cannot exist without
    /// it: declining the map forces them off whatever the toggle was last
    /// left at. Keeping the map and declining the sections is a reasonable
    /// choice — a page published to students is often better as the map
    /// alone — and this returns exactly that.
    static func coverageNotesEnabled(
        curriculumCoverageEnabled: Bool,
        includesCoverageNotes: Bool
    ) -> Bool {
        guard curriculumCoverageEnabled else {
            return false
        }
        return includesCoverageNotes
    }

    static func normalizedCustomDomain(_ raw: String) -> String {
        var domain: String = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        for scheme in ["https://", "http://"] {
            if domain.hasPrefix(scheme) {
                domain = String(domain.dropFirst(scheme.count))
            }
        }
        if let slashIndex = domain.firstIndex(of: "/") {
            domain = String(domain[..<slashIndex])
        }
        return domain
    }

    /// Whether the site title shows the "S1"-style marker for a given section.
    func showsSectionMarker(forSection sectionNumber: Int) -> Bool {
        let sectionsMap: [String: Any] = nestedDictionary(forKey: "show_section_marker", childKey: "sections")
        if let stored = sectionsMap["section\(sectionNumber)"] as? Bool {
            return stored
        }
        return true
    }

    func setShowsSectionMarker(_ shows: Bool, forSection sectionNumber: Int) {
        setNestedValue(shows, forKey: "show_section_marker", childKey: "sections", entryKey: "section\(sectionNumber)")
    }

    /// The colour scheme id chosen for a given section, or "" when unset.
    func colourSchemeID(forSection sectionNumber: Int) -> String {
        if let map = values["color_schemes"] as? [String: Any] {
            if let stored = map["section\(sectionNumber)"] as? String {
                return stored
            }
        }
        return ""
    }

    func setColourSchemeID(_ schemeID: String, forSection sectionNumber: Int) {
        var map: [String: Any] = [:]
        if let existing = values["color_schemes"] as? [String: Any] {
            map = existing
        }
        map["section\(sectionNumber)"] = schemeID
        values["color_schemes"] = map
    }

    /// The font choices for a section, falling back to the course default.
    func fontChoice(forSection sectionNumber: Int) -> FontChoice {
        let sectionsMap: [String: Any] = nestedDictionary(forKey: "fonts", childKey: "sections")
        if let stored = sectionsMap["section\(sectionNumber)"] as? [String: Any] {
            return FontChoice(dictionary: stored)
        }
        if let fonts = values["fonts"] as? [String: Any] {
            if let defaultChoice = fonts["default"] as? [String: Any] {
                return FontChoice(dictionary: defaultChoice)
            }
        }
        return FontChoice.systemDefault
    }

    func setFontChoice(_ choice: FontChoice, forSection sectionNumber: Int) {
        setNestedValue(choice.dictionaryRepresentation, forKey: "fonts", childKey: "sections", entryKey: "section\(sectionNumber)")
    }

    var defaultFontChoice: FontChoice {
        get {
            if let fonts = values["fonts"] as? [String: Any] {
                if let stored = fonts["default"] as? [String: Any] {
                    return FontChoice(dictionary: stored)
                }
            }
            return FontChoice.systemDefault
        }
        set {
            var fonts: [String: Any] = [:]
            if let existing = values["fonts"] as? [String: Any] {
                fonts = existing
            }
            fonts["default"] = newValue.dictionaryRepresentation
            values["fonts"] = fonts
        }
    }

    /// Writes the configuration to disk in the same shape the setup wizard
    /// uses: pretty-printed JSON with a trailing newline.
    func write(to url: URL) throws {
        let options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data: Data = try JSONSerialization.data(withJSONObject: values, options: options)
        data.append(contentsOf: [0x0A])
        try data.write(to: url, options: [.atomic])
        lastSavedData = data
    }

    /// Reverts all in-memory edits back to the last data read from or
    /// written to disk (the Cancel button).
    func discardChanges() throws {
        let decoded: Any = try JSONSerialization.jsonObject(with: lastSavedData)
        guard let dictionary = decoded as? [String: Any] else {
            throw CourseConfigurationError.notADictionary
        }
        values = dictionary
    }

    /// True when the in-memory values differ from what was last saved.
    var hasUnsavedChanges: Bool {
        guard let savedDecoded = try? JSONSerialization.jsonObject(with: lastSavedData) else {
            return true
        }
        guard let savedDictionary = savedDecoded as? [String: Any] else {
            return true
        }
        let current = values as NSDictionary
        let saved = savedDictionary as NSDictionary
        return !current.isEqual(to: saved as! [AnyHashable: Any])
    }

    // MARK: - Private helpers

    private func stringValue(forKey key: String) -> String {
        if let stored = values[key] as? String {
            return stored
        }
        return ""
    }

    private func intValue(forKey key: String, fallback: Int) -> Int {
        if let stored = values[key] as? NSNumber {
            return stored.intValue
        }
        return fallback
    }

    private func boolValue(forKey key: String, fallback: Bool) -> Bool {
        if let stored = values[key] as? Bool {
            return stored
        }
        return fallback
    }

    private func stringListValue(forKey key: String) -> [String] {
        if let stored = values[key] as? [String] {
            return stored
        }
        return []
    }

    private func nestedDictionary(forKey key: String, childKey: String) -> [String: Any] {
        if let outer = values[key] as? [String: Any] {
            if let inner = outer[childKey] as? [String: Any] {
                return inner
            }
        }
        return [:]
    }

    private func setNestedValue(_ value: Any, forKey key: String, childKey: String, entryKey: String) {
        var outer: [String: Any] = [:]
        if let existing = values[key] as? [String: Any] {
            outer = existing
        }
        var inner: [String: Any] = [:]
        if let existingInner = outer[childKey] as? [String: Any] {
            inner = existingInner
        }
        inner[entryKey] = value
        outer[childKey] = inner
        values[key] = outer
    }
}

enum CourseConfigurationError: Error {
    case notADictionary
}
