import Foundation

/// One file as it was before a change, and as the change left it.
struct AssistSavedFile: Equatable {

    // MARK: - Stored properties

    let fileURL: URL

    /// The whole file, before.
    let before: String

    /// The whole file, after — kept so an undo can tell "nobody has touched
    /// this since" from "the teacher has been editing it in Obsidian".
    let after: String
}

/// One thing the assistant did, in a form that can be taken straight back.
struct AssistChange: Equatable {

    // MARK: - Stored properties

    /// What it was, in words meant to be read to a teacher: "published 4 pages
    /// in ICS3U Section 1".
    let description: String

    let files: [AssistSavedFile]
}

/// How an undo went.
struct AssistUndoResult {

    // MARK: - Stored properties

    /// What was undone, or why nothing was.
    let description: String

    let restored: [URL]

    /// Files left alone because they have changed since — putting the old copy
    /// back would throw away newer work.
    let skipped: [URL]

    let succeeded: Bool
}

/// What this conversation has changed, so it can be taken back.
///
/// Whole-file copies, in memory, for the length of one conversation. That is a
/// deliberately small promise, and it is the right size: it makes `undo that`
/// instant and exact, and everything older is covered by the course backup
/// taken before each change, which lives on disk and outlives the window.
///
/// The rule that matters is the SKIP. A file that has changed since the
/// assistant wrote it is left exactly as it is. A teacher who published a class
/// and then spent ten minutes writing it in Obsidian must not lose those ten
/// minutes to "undo that" — so the undo puts back only what it can prove it
/// still owns, and says plainly what it left behind.
@MainActor
final class AssistChangeHistory {

    // MARK: - Stored properties

    /// Oldest first; the last one is what `undo_last_change` takes back.
    private(set) var changes: [AssistChange] = []

    // MARK: - Computed properties

    var isEmpty: Bool {
        return changes.isEmpty
    }

    // MARK: - Functions

    func record(_ change: AssistChange) {
        if change.files.isEmpty {
            return
        }
        changes.append(change)
    }

    /// Put the most recent change back.
    func undo() -> AssistUndoResult {
        guard let change = changes.last else {
            return AssistUndoResult(
                description: "This conversation hasn't changed anything yet, so there is nothing to undo.",
                restored: [],
                skipped: [],
                succeeded: false
            )
        }

        var restored: [URL] = []
        var skipped: [URL] = []
        for file in change.files {
            let current: String? = try? String(contentsOf: file.fileURL, encoding: .utf8)
            if current != file.after {
                skipped.append(file.fileURL)
                continue
            }
            do {
                try file.before.write(to: file.fileURL, atomically: true, encoding: .utf8)
                restored.append(file.fileURL)
            } catch {
                skipped.append(file.fileURL)
            }
        }

        // A change with something left behind stays on the list, so it can be
        // tried again once the teacher has dealt with the file in the way.
        if skipped.isEmpty {
            changes.removeLast()
        }

        return AssistUndoResult(
            description: change.description,
            restored: restored,
            skipped: skipped,
            succeeded: !restored.isEmpty
        )
    }
}
