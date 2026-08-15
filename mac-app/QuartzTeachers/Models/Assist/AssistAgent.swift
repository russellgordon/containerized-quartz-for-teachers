import Foundation
import Observation

/// The conversation loop: what the teacher said, what the model chose, what
/// ran, and what came back.
///
/// The safety rules do NOT live here. They live in the tools — which is what
/// lets the built-in assistant and Claude Code drive the same server without
/// the rules drifting between them. This type's job is to route, to hold the
/// gate open for the one act that needs a button, and to keep the transcript.
@Observable
@MainActor
final class AssistAgent {

    // MARK: - Types

    /// One line of the conversation as the teacher sees it.
    struct Entry: Identifiable, Equatable {
        let id: UUID = UUID()
        let speaker: Speaker
        let text: String

        enum Speaker: Equatable {
            case teacher
            case assistant
            case toolResult(name: String)
            case problem
        }
    }

    /// A write waiting for the teacher to say yes.
    struct PendingApproval: Equatable {
        let call: AssistToolCall
        let explanation: String
    }

    /// What the agent is doing.
    enum Activity: Equatable {
        case idle
        case thinking
        case running(toolName: String)
        case waitingForApproval
    }

    // MARK: - Stored properties

    /// The conversation, oldest first.
    private(set) var entries: [Entry] = []

    /// What it is doing now.
    private(set) var activity: Activity = .idle

    /// The deploy waiting on a button, if any.
    private(set) var pendingApproval: PendingApproval?

    /// The course and section this window is about.
    let courseCode: String
    let sectionNumber: Int

    /// Where requests go.
    private let client: AssistModelClient

    /// What can be run.
    private let tools: AssistToolRunner

    /// The messages actually sent, including tool results.
    private var messages: [AssistMessage] = []

    // MARK: - Computed properties

    /// The tool surface for this window, with the examples naming the real
    /// course rather than a placeholder.
    private var toolDefinitions: [AssistToolDefinition] {
        var named: [AssistToolDefinition] = []
        for definition in tools.definitions {
            named.append(definition.namingTheRealCourse(courseCode))
        }
        return named
    }

    /// Whether a teacher can type right now.
    var isBusy: Bool {
        return activity != .idle
    }

    // MARK: - Initializer

    init(courseCode: String,
         sectionNumber: Int,
         client: AssistModelClient,
         tools: AssistToolRunner) {
        self.courseCode = courseCode
        self.sectionNumber = sectionNumber
        self.client = client
        self.tools = tools
        messages = [AssistMessage.system(AssistAgent.systemPrompt(course: courseCode, section: sectionNumber))]
    }

    // MARK: - Functions

    /// Take what the teacher typed and see it through.
    func say(_ text: String) async {
        let trimmed: String = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return
        }
        entries.append(Entry(speaker: .teacher, text: trimmed))

        // The fixed shapes never reach the model — see AssistCardCommand for
        // the measurement that decided this.
        if let command = AssistCardCommand.matching(trimmed) {
            await run(call: AssistToolCall(
                id: UUID().uuidString,
                type: "function",
                function: AssistToolCall.Function(
                    name: command.toolName,
                    arguments: encode(command.arguments)
                )
            ))
            return
        }

        // The date goes on the END of the message. Prepended, the same line
        // cost 15 points of routing accuracy on the Windows measurements —
        // the position really is the finding, not the presence.
        messages.append(AssistMessage.user("\(trimmed) \(AssistAgent.dateline())"))
        await think()
    }

    /// Approve the waiting deploy.
    func approvePending() async {
        guard let pending = pendingApproval else {
            return
        }
        pendingApproval = nil
        await execute(call: pending.call)
    }

    /// Decline the waiting deploy.
    func declinePending() {
        guard let pending = pendingApproval else {
            return
        }
        pendingApproval = nil
        activity = .idle
        messages.append(AssistMessage.toolResult(
            callID: pending.call.id,
            name: pending.call.function.name,
            text: "The teacher decided not to. Nothing was done."
        ))
        entries.append(Entry(speaker: .assistant, text: "Left as it was."))
    }

    /// Ask the model what to do next, then do it.
    private func think() async {
        activity = .thinking
        do {
            let reply: AssistMessage = try await client.respond(
                messages: messages, tools: toolDefinitions
            )
            messages.append(reply)

            if let calls = reply.toolCalls, let first = calls.first {
                // One tool at a time, on purpose: a model that batches has
                // decided an order, and the order is exactly the reasoning
                // we are trying not to leave with it.
                await run(call: first)
                return
            }

            let text: String = (reply.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            entries.append(Entry(speaker: .assistant, text: text.isEmpty ? "I am not sure what to do with that." : text))
            activity = .idle
        } catch {
            entries.append(Entry(speaker: .problem, text: error.localizedDescription))
            activity = .idle
        }
    }

    /// Run a tool, stopping at the gate when it needs one.
    private func run(call: AssistToolCall) async {
        guard let definition = tools.definition(named: call.function.name) else {
            messages.append(AssistMessage.toolResult(
                callID: call.id, name: call.function.name,
                text: "There is no tool by that name."
            ))
            await think()
            return
        }

        // ONLY DEPLOYS WAIT FOR A BUTTON. Publishing and unpublishing are
        // backed up and undoable, and a gate in front of every write trains a
        // teacher to click through gates. Deploying is the one act that puts
        // something in front of students immediately and cannot be taken back
        // by us — so that is the one that asks.
        if definition.needsApproval {
            pendingApproval = PendingApproval(
                call: call,
                explanation: tools.explain(call: call)
            )
            activity = .waitingForApproval
            return
        }

        await execute(call: call)
    }

    /// Actually run it, and hand the result back to the model.
    private func execute(call: AssistToolCall) async {
        activity = .running(toolName: call.function.name)
        let outcome: AssistToolOutcome = await tools.run(call: call)

        entries.append(Entry(speaker: .toolResult(name: call.function.name), text: outcome.summary))
        messages.append(AssistMessage.toolResult(
            callID: call.id, name: call.function.name, text: outcome.detail
        ))

        // A read hands back to the model so it can answer the question it was
        // reading for. A write is the end of the turn: the teacher asked for
        // something, it happened, and another lap round the model can only
        // invent a follow-up nobody asked for.
        if outcome.shouldContinue {
            await think()
        } else {
            activity = .idle
        }
    }

    private func encode(_ arguments: [String: String]) -> String {
        var payload: [String: Any] = [
            "course": courseCode,
            "section": sectionNumber,
        ]
        for (key, value) in arguments {
            payload[key] = value
        }
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return text
    }

    /// Today, in the form the model reads best.
    nonisolated static func dateline() -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let day: DateFormatter = DateFormatter()
        day.dateFormat = "EEEE"
        let now: Date = Date()
        return "(Today is \(formatter.string(from: now)), a \(day.string(from: now)).)"
    }

    /// What the model is told it is.
    ///
    /// The publish/deploy paragraph is not padding. The two acts share a word
    /// in ordinary speech and the model will happily conflate them; saying
    /// plainly that they are different is what stops "publish tomorrow's
    /// class" turning into a live site.
    nonisolated static func systemPrompt(course: String, section: Int) -> String {
        return """
        You are Plantoir's assistant, helping a teacher with \(course) section \(section). \
        Choose exactly one tool at a time and fill in its arguments from what the teacher said. \
        Publishing and unpublishing are safe to do straight away — every change is backed up \
        and undo_last_change takes it back — so do what was asked without asking permission first. \
        Never guess a course, a section, a page title or a date — if you are not certain, look it \
        up or ask. If no tool fits, say so plainly instead of inventing one.
        PUBLISHING a page decides whether students can see it in the site. \
        DEPLOYING sends the whole site to the web. They are different acts. \
        After a change, Plantoir opens the preview by itself so the teacher can look it over. \
        Do not offer to deploy unless they ask; when they do ask, say plainly that deploying puts \
        the change in front of students immediately and that reviewing the preview first is the \
        safer order — then do as they decide.
        """
    }
}
