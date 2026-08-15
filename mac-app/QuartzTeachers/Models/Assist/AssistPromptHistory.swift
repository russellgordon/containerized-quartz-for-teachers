import Foundation

/// What the teacher has asked for before, and where they are in it while the
/// arrow keys walk back through it.
///
/// Modelled on a Terminal's history because that is what it is being compared
/// to, and the details a Terminal gets right are the ones people notice when
/// they are missing:
///
/// - **The half-typed line is not lost.** Press Up with something already in
///   the box and it is put aside, not thrown away; walking back Down past the
///   newest entry hands it over again exactly as it was.
/// - **The same thing twice in a row is remembered once.** Testing something
///   by running it five times should not mean five presses of Up to get past
///   it. (An earlier, non-adjacent repeat is left alone — the order a teacher
///   did things in is the thing they are scrolling through.)
/// - **Pressing Up at the oldest entry does nothing**, rather than wrapping
///   round to the newest, which would look like the keyboard had misfired.
/// - **Typing stops the walk.** Once a recalled line has been edited it is a
///   new line, and Down should not silently replace what has just been typed.
///
/// Kept apart from the view so those rules can be tested without a window, and
/// `nonisolated` so the tests are not forced onto the main actor for a type
/// that touches nothing shared.
nonisolated struct AssistPromptHistory: Equatable {

    // MARK: - Stored properties

    /// Everything asked for, oldest first — the order a teacher would scroll
    /// back through.
    private(set) var entries: [String] = []

    /// Where the walk has got to, or nil when the teacher is typing normally
    /// rather than looking back.
    private var position: Int?

    /// What was in the box when the walk began, so Down can give it back.
    private var draft: String = ""

    /// Enough to cover a working session without the stored value growing
    /// without limit. A teacher who has asked for more than fifty things is
    /// not going to find the fifty-first by pressing Up.
    static let mostRemembered: Int = 50

    // MARK: - Computed properties

    /// Whether the arrow keys are currently walking the history.
    var isBrowsing: Bool {
        return position != nil
    }

    /// The history as one string, for `@AppStorage`.
    ///
    /// JSON rather than a separator, because a prompt is free text: any
    /// character picked as a separator is a character a teacher may type, and
    /// the failure would be silent and strange rather than loud.
    var stored: String {
        guard let data = try? JSONEncoder().encode(entries),
              let text = String(data: data, encoding: .utf8) else {
            return ""
        }
        return text
    }

    // MARK: - Initializer

    init(entries: [String] = []) {
        self.entries = entries
    }

    // MARK: - Functions

    /// Read back what was stored. Anything unreadable becomes an empty
    /// history: losing the list is a small thing, and refusing to open the
    /// assistant over it would not be.
    static func read(fromStored text: String) -> AssistPromptHistory {
        guard let data = text.data(using: .utf8),
              let entries = try? JSONDecoder().decode([String].self, from: data) else {
            return AssistPromptHistory()
        }
        return AssistPromptHistory(entries: entries)
    }

    /// Record something the teacher has actually sent, and end any walk.
    mutating func remember(_ prompt: String) {
        let trimmed: String = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        stopBrowsing()
        if trimmed.isEmpty {
            return
        }
        if entries.last == trimmed {
            return
        }
        entries.append(trimmed)
        while entries.count > AssistPromptHistory.mostRemembered {
            entries.removeFirst()
        }
    }

    /// Up: the entry before this one, or nil when there is nowhere further
    /// back to go.
    ///
    /// `typed` is whatever is in the box right now. It is only kept the FIRST
    /// time, which is what makes Down able to return the teacher to their own
    /// half-written sentence rather than to a recalled one.
    mutating func earlier(startingFrom typed: String) -> String? {
        if entries.isEmpty {
            return nil
        }
        guard let current = position else {
            draft = typed
            position = entries.count - 1
            return entries[entries.count - 1]
        }
        if current == 0 {
            return nil
        }
        position = current - 1
        return entries[current - 1]
    }

    /// Down: the entry after this one, or the half-typed line back again once
    /// the walk reaches the end. Nil when no walk is under way.
    mutating func later() -> String? {
        guard let current = position else {
            return nil
        }
        if current + 1 < entries.count {
            position = current + 1
            return entries[current + 1]
        }
        let waiting: String = draft
        stopBrowsing()
        return waiting
    }

    /// Called when the teacher types: an edited line is a new line, so Down
    /// must not replace it with something out of the history.
    mutating func stopBrowsing() {
        position = nil
        draft = ""
    }
}
