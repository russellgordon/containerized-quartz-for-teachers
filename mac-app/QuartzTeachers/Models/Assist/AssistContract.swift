import Foundation

/// The two files in `contracts/`, written from the app's own types.
///
/// **What this is for.** The Windows app is built from what this side learns,
/// by somebody who cannot read the Swift or watch it being tested. Handing
/// them a document that describes the assistant's behaviour means they retype
/// it as tests, by hand, once per change — a day each time, and the sentences
/// drift the moment one side edits without telling the other. Handing them
/// DATA means an xUnit `[Theory]` reads the same file this app is built from.
///
/// **Why generated rather than hand-kept.** A hand-kept contract is a fifth
/// copy of the same sentences, and copies drift silently: the identical deploy
/// failure was already worded two ways depending only on which function ran
/// it. Generating from `AssistWording`, `AssistCardCommand` and the tool
/// surface means the contract cannot describe behaviour the app does not have.
/// `AssistContractTests` runs this in-process and fails when what is committed
/// no longer matches, so a changed sentence fails HERE, in the same test run
/// that changed it — not on a Windows machine three weeks later.
///
/// **What it deliberately does NOT generate.** `nearMisses` and `scenarios` in
/// the cases file are hand-written and are preserved on every run. Nothing in
/// the code says which near-miss phrasings are worth guarding, or which ORDER
/// events must happen in — those are decisions, and a decision cannot be read
/// off the thing it produced.
/// Main-actor, because the tool surface is: `AssistToolRunner` is a
/// `@MainActor` type and its three lists are its properties. Nothing here
/// waits on anything, so this costs a hop and buys not having a second,
/// nonisolated copy of the surface to keep in step.
@MainActor
enum AssistContract {

    // MARK: - Stored properties

    /// The placeholder a course code leaves in a generated template.
    static let coursePlaceholder: String = "{course}"

    /// The placeholder a section number leaves in a generated template.
    static let sectionPlaceholder: String = "{section}"

    static let wordingFileName: String = "assist-wording.json"
    static let casesFileName: String = "assist-cases.json"

    /// The top-level keys of the cases file that this writes. Everything else
    /// in that file is hand-written and survives a regeneration.
    static let generatedCaseKeys: [String] = ["cardPhrasings", "tools"]

    /// How the flag is spelled.
    static let flag: String = "--assist-contract"

    // MARK: - Functions

    /// The wording file's contents.
    ///
    /// Every value here comes from calling the real function with the
    /// placeholders as its arguments — which is the whole reason
    /// `AssistWording` takes Strings where the rest of the app has an Int.
    static func wording() -> [String: Any] {
        let course: String = coursePlaceholder
        let section: String = sectionPlaceholder
        let table: [String: String] = [
            "deployApproval": AssistWording.deployApproval,
            "deployQuestion": AssistWording.deployQuestion,
            "planQuestion": AssistWording.planQuestion,
            "deployAccepted": AssistWording.deployAccepted,
            "planAccepted": AssistWording.planAccepted,
            "cancelled": AssistWording.cancelled,
            "deployWasCancelled": AssistWording.deployWasCancelled,
            "planWasCancelled": AssistWording.planWasCancelled,
            "deployed": AssistWording.deployed(course: course, section: section),
            "couldNotBuildBeforeDeploying": AssistWording.couldNotBuildBeforeDeploying(
                course: course, section: section
            ),
            "deployDidNotFinish": AssistWording.deployDidNotFinish(course: course, section: section),
            "sectionIsBusy": AssistWording.sectionIsBusy(course: course, section: section),
            "courseIsBusy": AssistWording.courseIsBusy(course: course),
            "previewIsRebuilding": AssistWording.previewIsRebuilding(course: course, section: section),
            "builtWithNoWindowOpen": AssistWording.builtWithNoWindowOpen(course: course, section: section),
            "rebuiltForACallerWithNoWindow": AssistWording.rebuiltForACallerWithNoWindow(
                course: course, section: section
            ),
            "previewDidNotBuild": AssistWording.previewDidNotBuild(course: course, section: section),
            "whereTheOutputIs": AssistWording.whereTheOutputIs,
            "nothingToDo": AssistWording.nothingToDo,
        ]
        return [
            "note": "Generated from mac-app AssistWording by `Plantoir --assist-contract`. "
                  + "Do not hand-edit; see contracts/README.md.",
            "placeholders": [
                "course": "a course code, e.g. ICS3U",
                "section": "a section number, e.g. 1",
            ],
            "wording": table,
        ]
    }

    /// The generated half of the cases file, by top-level key.
    static func generatedCases() -> [String: Any] {
        return [
            "cardPhrasings": cardPhrasings(),
            "tools": tools(),
        ]
    }

    private static func cardPhrasings() -> [String: Any] {
        var matches: [[String: Any]] = []
        for shape in AssistCardCommand.everyFixedShape {
            matches.append([
                "phrasing": shape.phrasing,
                "tool": shape.command.toolName,
                "arguments": shape.command.arguments,
            ])
        }
        return [
            "note": "Matched in CODE and never sent to the model. Trimmed, case-folded, trailing . and ! "
                  + "removed, then compared for EQUALITY. Measured: the model misrouted five of the "
                  + "eleven suggested phrasings in every trial while filling arguments perfectly, so the "
                  + "shapes with no ambiguity in them do not reach it.",
            "matches": matches,
        ]
    }

    private static func tools() -> [String: Any] {
        var all: [String] = []
        for tool in AssistToolRunner.tools {
            all.append(tool.name)
        }
        var local: [String] = []
        for tool in AssistToolRunner.localTools {
            local.append(tool.name)
        }
        var mcpOnly: [String] = []
        for tool in AssistToolRunner.mcpOnlyTools {
            mcpOnly.append(tool.name)
        }

        // Asked of each definition rather than listed, so a tool that starts
        // or stops needing a button changes this file by being built.
        var needsApproval: [String] = []
        var twins: [String: String] = [:]
        var everyName: Set<String> = []
        for tool in AssistToolRunner.mcpTools {
            everyName.insert(tool.name)
        }
        for tool in AssistToolRunner.mcpTools {
            if tool.needsApproval {
                needsApproval.append(tool.name)
            }
            // A twin's NAME is not a twin's existence: `add_curriculum_mentions`
            // would name `plan_add_curriculum_mentions`, and the tool that
            // actually exists is `plan_curriculum_mentions`. Plan mode asks the
            // surface for exactly this reason, and so does this.
            if let twin = tool.planTwinName, everyName.contains(twin) {
                twins[tool.name] = twin
            }
        }

        return [
            "note": "Three lists, deliberately. `all` is what the runner can execute; `local` is what the "
                  + "small model is SHOWN (the plan twins and remember_timetable are taken off, because "
                  + "the model never has to name a plan and dates it supplies are dates it may have "
                  + "invented); `mcpOnly` is offered to Claude Code on top of everything, being the three "
                  + "that ask for judgement about meaning.",
            "all": all,
            "local": local,
            "mcpOnly": mcpOnly,
            "needsApproval": needsApproval.sorted(),
            "planTwins": twins,
            "planTwinsNote": "A write with a twin is shown as a plan first. Four writes have none, "
                           + "deliberately: rebuild_preview changes no page, undo_last_change IS the "
                           + "remedy, deploy_section waits on its own button whatever plan mode says, and "
                           + "a cancelled scheduled deploy is remedied by scheduling it again.",
        ]
    }

    /// Write both files into `directory`, keeping the hand-written keys of the
    /// cases file exactly as they were.
    ///
    /// Returns what to say to whoever ran it — the paths, or what stopped it.
    static func write(into directory: URL) -> String {
        let wordingURL: URL = directory.appendingPathComponent(wordingFileName)
        let casesURL: URL = directory.appendingPathComponent(casesFileName)

        // The cases file is READ first, because most of it is not ours to
        // write. A regeneration that dropped the scenarios would look like a
        // successful run and lose the reasoning in the same stroke.
        var cases: [String: Any] = [:]
        if let data = try? Data(contentsOf: casesURL),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            cases = existing
        }
        for (key, value) in generatedCases() {
            cases[key] = value
        }
        cases["generated"] = [
            "note": "These top-level keys are written by `Plantoir --assist-contract` from the app's own "
                  + "types and will be overwritten: " + generatedCaseKeys.joined(separator: ", ")
                  + ". The rest — nearMisses, scenarios — is hand-written intent and is preserved.",
            "keys": generatedCaseKeys,
        ]
        if cases["note"] == nil {
            cases["note"] = "Generated from the macOS app by `Plantoir --assist-contract`. "
                          + "Do not hand-edit; see contracts/README.md."
        }

        do {
            try encode(wording()).write(to: wordingURL)
            try encode(cases).write(to: casesURL)
        } catch {
            return "Could not write the contract: \(error.localizedDescription)"
        }
        return "Wrote \(wordingURL.path)\nWrote \(casesURL.path)"
    }

    /// Sorted keys and a trailing newline, so a regeneration that changed
    /// nothing produces no diff at all.
    static func encode(_ value: [String: Any]) throws -> Data {
        var data: Data = try JSONSerialization.data(
            withJSONObject: value, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        )
        data.append(contentsOf: [0x0A])
        return data
    }

    /// The folder asked for on the command line, if this run is a generation.
    static func requestedDirectory(from arguments: [String]) -> URL? {
        guard let index = arguments.firstIndex(of: flag) else {
            return nil
        }
        let next: Int = index + 1
        if next < arguments.count {
            return URL(fileURLWithPath: arguments[next])
        }
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("contracts")
    }
}
