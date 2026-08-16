import Foundation

/// The fixed phrasings the assistant window offers, matched in CODE rather
/// than routed through the model.
///
/// This is the least obvious thing in the whole feature, and it was measured
/// rather than guessed. The promise card's phrasings are what the window
/// TELLS a teacher it is good at, so a teacher clicks one — or types it
/// verbatim — and the assistant had better be good at it. Word for word, the
/// model misrouted **five of the eleven, in every trial**, while filling in
/// the arguments perfectly (87 trials, zero wrong courses, dates or types).
///
/// So the shapes with no ambiguity in them are matched here and never reach
/// the model. The model keeps everything with a story in it — the requests a
/// teacher phrases their own way, which is what a language model is actually
/// for. This is the same principle as the coarse tools: reasoning moved out
/// of the model is reliability bought back.
nonisolated struct AssistCardCommand: Sendable, Equatable {

    // MARK: - Stored properties

    /// The tool this phrasing always means.
    let toolName: String

    /// Arguments the phrasing itself determines.
    let arguments: [String: String]

    // MARK: - Functions

    /// The command a teacher's message is, if it is one of the fixed shapes.
    ///
    /// Matching is deliberately strict — trimmed and case-insensitive, but
    /// otherwise the exact phrasing. A loose match here would swallow
    /// requests that only LOOK like a card phrasing ("publish tomorrow's
    /// class, but not the linked pages") and answer the wrong question with
    /// total confidence, which is worse than routing it.
    static func matching(_ message: String) -> AssistCardCommand? {
        let tidied: String = message.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".!"))
            .lowercased()

        for (phrasing, command) in fixedShapes {
            if tidied == phrasing {
                return command
            }
        }
        return nil
    }

    /// One fixed shape, for anything that has to enumerate them — the
    /// contract generator does, and a tuple array cannot be handed out.
    struct FixedShape: Sendable, Equatable {

        // MARK: - Stored properties

        let phrasing: String
        let command: AssistCardCommand
    }

    /// Every shape, in the order they are matched.
    static var everyFixedShape: [FixedShape] {
        var shapes: [FixedShape] = []
        for (phrasing, command) in fixedShapes {
            shapes.append(FixedShape(phrasing: phrasing, command: command))
        }
        return shapes
    }

    /// The fixed shapes, worded exactly as the shelf offers them.
    ///
    /// Anything whose arguments depend on what the teacher said — a page
    /// title, a time — is NOT here: those need the model to read them out,
    /// and reading arguments out is the thing it does reliably.
    ///
    /// These have to be kept in step with `AssistPromptShelfView` BY HAND: a
    /// phrasing the shelf offers and this does not match is not broken, it
    /// simply goes to the model — but it goes to the model on a shape that was
    /// put here precisely because the model gets it wrong.
    private static let fixedShapes: [(String, AssistCardCommand)] = [
        ("what would students see in this section right now?",
         AssistCardCommand(toolName: "check_section", arguments: [:])),

        ("what do students see right now?",
         AssistCardCommand(toolName: "check_section", arguments: [:])),

        // The shelf says "Preview" — one word, and the same word the button
        // in the section window wears, because they now do the same thing.
        // The older, longer wording is kept for a teacher who learned it.
        ("preview",
         AssistCardCommand(toolName: "rebuild_preview", arguments: [:])),

        ("rebuild the preview",
         AssistCardCommand(toolName: "rebuild_preview", arguments: [:])),

        ("undo that",
         AssistCardCommand(toolName: "undo_last_change", arguments: [:])),

        // The shelf says "Deploy now". The old, longer wording is kept as
        // well: a teacher who learned it from an earlier version and types it
        // should still be answered by the same tool.
        ("deploy now",
         AssistCardCommand(toolName: "deploy_section", arguments: [:])),

        ("deploy this section now",
         AssistCardCommand(toolName: "deploy_section", arguments: [:])),

        // The bare word, which the shelf does not offer and a teacher types
        // anyway — the button in the section window wears it, so it is the
        // word they have in front of them. On its own it means one thing and
        // there is nothing in it for the model to read out, which is the test
        // for belonging on this list. Sent to the model it came back as a
        // sentence about deploying rather than a deploy.
        ("deploy",
         AssistCardCommand(toolName: "deploy_section", arguments: [:])),

        ("publish tomorrow's class",
         AssistCardCommand(toolName: "publish_class_on", arguments: ["when": "tomorrow"])),
    ]
}
