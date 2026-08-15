import Foundation

/// What running one tool produced.
///
/// Two audiences, deliberately kept apart. `summary` is the line the teacher
/// sees in the transcript — one sentence, no paths, no counts they did not ask
/// for. `detail` is what goes back to the model, and can be as long as the
/// answer needs to be.
///
/// `shouldContinue` is the whole turn-taking rule in one flag. A READ hands
/// back so the model can answer the question it was reading for. A WRITE is the
/// end of the turn: the teacher asked for something, it happened, and another
/// lap round the model can only invent a follow-up nobody asked for. That
/// applies to a write that REFUSED, too — a refusal the model can retry from is
/// a refusal it can retry forever.
struct AssistToolOutcome: Sendable, Equatable {

    // MARK: - Stored properties

    /// One line for the transcript, in the teacher's language.
    let summary: String

    /// What the model is told, at whatever length it needs.
    let detail: String

    /// Whether the model gets another turn after this.
    let shouldContinue: Bool

    // MARK: - Initializer

    init(summary: String, detail: String, shouldContinue: Bool) {
        self.summary = summary
        self.detail = detail
        self.shouldContinue = shouldContinue
    }

    // MARK: - Functions

    /// A read: the same words to both, and the model gets to answer.
    static func read(_ summary: String, detail: String) -> AssistToolOutcome {
        return AssistToolOutcome(summary: summary, detail: detail, shouldContinue: true)
    }

    /// A write: it happened, and the turn is over.
    static func wrote(_ summary: String, detail: String) -> AssistToolOutcome {
        return AssistToolOutcome(summary: summary, detail: detail, shouldContinue: false)
    }

    /// A write that did not go ahead. The reason is an answer, not a crash:
    /// the teacher reads it and says what to do instead.
    static func refused(_ reason: String) -> AssistToolOutcome {
        return AssistToolOutcome(summary: reason, detail: reason, shouldContinue: false)
    }

    /// A read that could not be answered. Reads hand back either way, so the
    /// model can say plainly what was missing rather than inventing it.
    static func couldNotRead(_ reason: String) -> AssistToolOutcome {
        return AssistToolOutcome(summary: reason, detail: reason, shouldContinue: true)
    }
}
