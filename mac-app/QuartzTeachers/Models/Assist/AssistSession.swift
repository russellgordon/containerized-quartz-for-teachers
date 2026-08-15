import Foundation
import Observation

/// One assistant window's worth of everything: the hardware decision, the
/// weights, the server, and the conversation.
@Observable
@MainActor
final class AssistSession {

    // MARK: - Types

    /// What stands between the teacher and a conversation, if anything.
    enum Readiness: Equatable {
        case checkingHardware
        case unsupported(reason: String)
        case needsDownload(tier: AssistModelTier)
        case downloading(fractionComplete: Double, receivedBytes: Int64, totalBytes: Int64)
        case starting
        case ready
        case failed(reason: String)
    }

    // MARK: - Stored properties

    let courseCode: String
    let sectionNumber: Int
    let workingFolder: URL

    /// What this Mac is allowed to give the assistant.
    let budget: AssistHardwareBudget

    /// The weights for this Mac.
    let store: AssistModelStore

    /// The conversation, once there is something to have it with.
    private(set) var agent: AssistAgent?

    /// Where the window is up to.
    private(set) var readiness: Readiness = .checkingHardware

    /// The engine.
    private var host: AssistServerHost?

    // MARK: - Computed properties

    /// The model chosen for this Mac.
    var tier: AssistModelTier {
        return budget.tier
    }

    /// Whether the teacher can type.
    var canAcceptTyping: Bool {
        guard readiness == .ready, let agent else {
            return false
        }
        return !agent.isBusy
    }

    // MARK: - Initializer

    init(courseCode: String, sectionNumber: Int, workingFolder: URL) {
        self.courseCode = courseCode
        self.sectionNumber = sectionNumber
        self.workingFolder = workingFolder
        let budget: AssistHardwareBudget = AssistHardwareBudget.current()
        self.budget = budget
        self.store = AssistModelStore(tier: budget.tier)
    }

    // MARK: - Functions

    /// Work out what this window can offer, and get as far towards a
    /// conversation as it can without asking the teacher anything.
    func prepare() async {
        guard budget.canRunAssistant else {
            readiness = .unsupported(reason:
                "The assistant needs an Apple silicon Mac. Everything else in Plantoir works as usual."
            )
            return
        }

        if !store.isReady {
            readiness = .needsDownload(tier: tier)
            await followDownload()
            if !store.isReady {
                return
            }
        }

        await startEngine()
    }

    /// Watch the download until it finishes or fails, mirroring its progress
    /// into this window's own state.
    ///
    /// The cancellation check is load-bearing. `try? await Task.sleep`
    /// swallows the cancellation error, so without it this loop keeps
    /// spinning every 200 ms after the window has closed — the enclosing
    /// `.task` is cancelled, nobody is watching, and the loop runs until the
    /// app quits.
    private func followDownload() async {
        while !Task.isCancelled {
            switch store.state {
            case .ready:
                return
            case .failed(let reason):
                readiness = .failed(reason: reason)
                return
            case .downloading(let fraction, let received, let total):
                readiness = .downloading(fractionComplete: fraction, receivedBytes: received, totalBytes: total)
            case .missing:
                // Waiting for the teacher to press the button.
                if case .downloading = readiness {
                    readiness = .needsDownload(tier: tier)
                }
            }
            do {
                try await Task.sleep(for: .milliseconds(200))
            } catch {
                return
            }
        }
    }

    /// Start the server and build the agent.
    private func startEngine() async {
        readiness = .starting

        let host: AssistServerHost = AssistServerHost(modelURL: store.fileURL, budget: budget)
        self.host = host
        await host.start()

        switch host.state {
        case .ready:
            guard let baseURL = host.baseURL else {
                readiness = .failed(reason: "The assistant's engine started but gave no address.")
                return
            }
            // The assistant window is its own window, so it gets its own
            // workspace pointed at the same folder rather than reaching into
            // the main window's. The tools take the course and section as
            // arguments — the same shape the MCP server uses — so the runner
            // needs the folder, not this window's particular section.
            let workspace: WorkspaceModel = WorkspaceModel()
            workspace.adoptRestoredPath(workingFolder.path)
            let runner: AssistToolRunner = AssistToolRunner(workspace: workspace)
            let agent: AssistAgent = AssistAgent(
                courseCode: courseCode,
                sectionNumber: sectionNumber,
                client: AssistModelClient(baseURL: baseURL),
                tools: runner,
                planMode: AssistPlanMode(tier: tier)
            )
            self.agent = agent
            readiness = .ready
            await warmUp(client: AssistModelClient(baseURL: baseURL), runner: runner)

        case .failed(let reason):
            readiness = .failed(reason: reason)

        case .stopped, .starting:
            readiness = .failed(reason: "The assistant's engine did not become ready.")
        }
    }

    /// Read the tool definitions once, before the teacher has typed anything.
    ///
    /// The prompt is mostly tool schemas — about 3,400 tokens — and reading it
    /// is a one-off cost per conversation. On the small model that is two
    /// seconds and on the large one about twelve; either way it is time the
    /// teacher would otherwise spend watching their first message sit there.
    /// Doing it while they are still reading the promise card and deciding
    /// what to type makes it free.
    ///
    /// It is deliberately fire-and-forget: if it fails, the first real message
    /// simply pays the cost itself, which is exactly what would have happened
    /// anyway. Nothing is shown to the teacher either way.
    private func warmUp(client: AssistModelClient, runner: AssistToolRunner) async {
        var definitions: [AssistToolDefinition] = []
        for definition in runner.definitions {
            definitions.append(definition.namingTheRealCourse(courseCode))
        }
        let priming: [AssistMessage] = [
            AssistMessage.system(AssistAgent.systemPrompt(course: courseCode, section: sectionNumber)),
            AssistMessage.user("Say only: ready"),
        ]
        _ = try? await client.respond(messages: priming, tools: definitions)
    }

    /// The window is closing. Stop the server — a model holding several
    /// gigabytes of a teacher's RAM after they have finished with it is the
    /// sort of thing that gets an app uninstalled.
    func finish() {
        store.cancel()
        host?.stop()
        host = nil
        agent = nil
    }
}
