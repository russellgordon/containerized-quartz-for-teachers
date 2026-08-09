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

    var showReadingTime: Bool {
        get { return boolValue(forKey: "show_reading_time", fallback: false) }
        set { values["show_reading_time"] = newValue }
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
