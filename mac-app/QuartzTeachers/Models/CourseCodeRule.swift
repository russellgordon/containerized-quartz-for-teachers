import Foundation

/// What a course code may be — asked by the New Course wizard and by
/// renaming, so a code one accepts is a code the other accepts.
///
/// This lives in one place because it used to live in two. The wizard had
/// the rule as a private idea of its own, which meant a code the wizard let
/// a teacher create could not necessarily be typed again anywhere else. A
/// second copy of a rule is a rule that will disagree with itself.
///
/// The rule is narrow on purpose. A course code is not a label the app keeps
/// to itself: it **is** the folder name under `courses/`, it is written into
/// `course_config.json` for the shared Python to read, it rides in the name
/// of every backup and archive zip, and it becomes part of a launchd label
/// when a section is set to publish on its own. Each of those has its own
/// opinion about what characters it will carry. One narrow rule everywhere
/// beats four that disagree at the edges.
enum CourseCodeRule {

    // MARK: - Stored properties

    /// The most characters a course code may carry.
    ///
    /// Ontario codes are six (ICS3U). Clubs are named by the teacher, and
    /// eight leaves room for ROBOTICS without letting a code grow into a
    /// sentence — the code has to stay readable as a sidebar row, a folder
    /// name and a zip's prefix all at once.
    static let mostCharacters: Int = 8

    // MARK: - Functions

    /// A code as it will be STORED: trimmed of surrounding whitespace and
    /// upper-cased.
    ///
    /// Settling the case here is what stops `ICS3U` and `ics3u` reading as
    /// two different courses. A Mac's disk is case-insensitive but
    /// case-preserving, so two folders differing only in case cannot both
    /// exist — and a clash check that missed it would offer the teacher a
    /// rename that then failed on the file system with a puzzling error.
    static func normalized(_ raw: String) -> String {
        return raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    /// Why a code can't be used, or nil when it is fine.
    ///
    /// An EMPTY code is nil rather than a complaint: nothing has been said
    /// yet, so there is nothing to warn about, and a warning that appears
    /// before the teacher has typed anything is noise.
    ///
    /// `currentCode` is the code of the course being renamed, when there is
    /// one. A course does not clash with itself, so re-typing a course's own
    /// code — or only its capitalisation — is not an error.
    static func problem(
        _ text: String,
        existingCodes: [String],
        currentCode: String? = nil
    ) -> String? {
        let code: String = normalized(text)
        if code.isEmpty {
            return nil
        }

        // Checked before the general character rule so the commonest
        // mistake gets the sentence that names it.
        if code.contains(" ") {
            return "A course code cannot contain spaces."
        }
        for character in code {
            if !characterIsAllowed(character) {
                return "A course code can only use letters and numbers."
            }
        }
        if code.count > mostCharacters {
            return "A course code can be at most \(mostCharacters) characters."
        }

        if let currentCode {
            if normalized(currentCode) == code {
                return nil
            }
        }
        for existingCode in existingCodes {
            if normalized(existingCode) == code {
                return "A course named \(code) already exists — choose a different code."
            }
        }
        return nil
    }

    /// True when this character may appear in a course code: an ASCII letter
    /// or digit, and nothing else.
    ///
    /// Emoji fail here, and so does an accented letter. Both are refused for
    /// the same reason a space is — see the type's own note. The message a
    /// teacher reads says "letters and numbers", which is true of what is
    /// allowed even though it is not the whole story about É; the alternative
    /// is a sentence about character encodings in a sidebar row.
    private static func characterIsAllowed(_ character: Character) -> Bool {
        if !character.isASCII {
            return false
        }
        return character.isLetter || character.isNumber
    }
}
