import Foundation

/// A question from a running task, prepared for a dialog rather than a
/// terminal: plain wording, the default already filled in, and the way
/// the task itself understands "stop".
struct AskedQuestion {

    // MARK: - Stored properties

    /// The wording to show.
    var question: String

    /// The answer to start the text field with.
    var suggestedAnswer: String

    /// What to send if the teacher backs out ("" when nothing is safe).
    var cancelToken: String
}
