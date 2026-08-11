import Foundation

/// Looks up Ontario course names by course code, using the same
/// `ontario_secondary_courses.json` the command-line wizard consults
/// (bundled as an app resource). The wizard offers a formal name and a
/// short name for known codes; the app does the same.
enum CourseNameCatalog {

    // MARK: - Stored properties

    static let entries: [String: CourseNames] = loadEntries()

    // MARK: - Functions

    /// The known names for a course code, or nil for unknown codes
    /// (including club codes). Lookup is case-insensitive, matching the
    /// wizard's behaviour of uppercasing the code first.
    static func names(forCode code: String) -> CourseNames? {
        let normalized: String = code.trimmingCharacters(in: .whitespaces).uppercased()
        return entries[normalized]
    }

    private static func loadEntries() -> [String: CourseNames] {
        guard let url = Bundle.main.url(forResource: "ontario_secondary_courses", withExtension: "json") else {
            return [:]
        }
        guard let data = try? Data(contentsOf: url) else {
            return [:]
        }
        guard let decoded = try? JSONSerialization.jsonObject(with: data) else {
            return [:]
        }
        guard let dictionary = decoded as? [String: Any] else {
            return [:]
        }

        var result: [String: CourseNames] = [:]
        for (code, rawEntry) in dictionary {
            guard let entry = rawEntry as? [String: Any] else {
                continue
            }
            guard let formalName = entry["formal_name"] as? String else {
                continue
            }
            guard let shortName = entry["short_name"] as? String else {
                continue
            }
            result[code] = CourseNames(formal: formalName, short: shortName)
        }
        return result
    }
}

/// The two name variants the lookup file offers for each course code.
struct CourseNames: Equatable {

    // MARK: - Stored properties

    let formal: String
    let short: String

    // MARK: - Computed properties

    /// The formal name without the catalog's citation suffix: the Ministry
    /// writes "Computer Science, Grade 12, U", but a course TITLE wants
    /// "Computer Science" — the grade is the grade toggle's business.
    var display: String {
        if let suffixRange = formal.range(of: #",\s*Grade\s*\d+.*$"#, options: .regularExpression) {
            let stripped: String = String(formal[..<suffixRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            if !stripped.isEmpty {
                return stripped
            }
        }
        return formal
    }
}
