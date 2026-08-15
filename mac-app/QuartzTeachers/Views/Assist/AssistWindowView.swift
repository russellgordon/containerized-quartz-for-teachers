import SwiftUI

/// The assistant, in a window of its own for one section.
///
/// A window rather than a pane inside the main window, and that is a
/// deliberate choice: the teacher needs the section's preview on screen while
/// they talk about it. A pane would put the conversation and the thing it is
/// about in competition for the same space, and the conversation would win,
/// which is the wrong way round.
struct AssistWindowView: View {

    // MARK: - Stored properties

    /// Everything this window needs, assembled when it opens.
    @State private var session: AssistSession

    /// What the teacher is typing.
    @State private var typing: String = ""

    /// Keeps the newest line in view as the conversation grows.
    @Namespace private var bottom

    // MARK: - Initializer

    init(courseCode: String, sectionNumber: Int, workingFolder: URL) {
        _session = State(initialValue: AssistSession(
            courseCode: courseCode,
            sectionNumber: sectionNumber,
            workingFolder: workingFolder
        ))
    }

    // MARK: - Computed properties

    var body: some View {
        VStack(spacing: 0) {
            transcript
            Divider()
            composer
        }
        .frame(minWidth: 460, minHeight: 420)
        .navigationTitle("Assistant — \(session.courseCode) section \(session.sectionNumber)")
        .task {
            await session.prepare()
        }
        .onDisappear {
            session.finish()
        }
    }

    /// The conversation, or whatever is standing in the way of having one.
    @ViewBuilder
    private var transcript: some View {
        switch session.readiness {
        case .checkingHardware:
            AssistNoticeView(
                title: "Getting ready…",
                detail: "Looking at what this Mac can run."
            )

        case .unsupported(let reason):
            AssistNoticeView(title: "Not available on this Mac", detail: reason)

        case .needsDownload(let tier):
            AssistDownloadView(tier: tier, store: session.store) {
                session.store.download()
            }

        case .downloading(let fraction, let received, let total):
            AssistDownloadProgressView(fractionComplete: fraction, receivedBytes: received, totalBytes: total) {
                session.store.cancel()
            }

        case .starting:
            AssistNoticeView(
                title: "Starting the assistant…",
                detail: "Loading \(session.tier.displayName). This takes a moment the first time after opening."
            )

        case .failed(let reason):
            AssistNoticeView(title: "The assistant could not start", detail: reason)

        case .ready:
            conversation
        }
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if session.agent?.entries.isEmpty ?? true {
                        AssistPromiseCardView { phrasing in
                            Task { await send(phrasing) }
                        }
                    }
                    ForEach(session.agent?.entries ?? []) { entry in
                        AssistEntryView(entry: entry)
                    }
                    if let approval = session.agent?.pendingApproval,
                       let agent = session.agent {
                        AssistApprovalView(
                            explanation: approval.explanation,
                            isDeploy: agent.pendingIsDeploy
                        ) {
                            Task { await agent.approvePending() }
                        } decline: {
                            agent.declinePending()
                        }
                    }
                    if let agent = session.agent, agent.planMode.shouldOfferToStop {
                        AssistStopAskingOfferView {
                            agent.planMode.stopAsking()
                        } keepAsking: {
                            agent.planMode.keepAsking()
                        }
                    }
                    Color.clear.frame(height: 1).id(bottom)
                }
                .padding()
            }
            .onChange(of: session.agent?.entries.count ?? 0) {
                withAnimation {
                    proxy.scrollTo(bottom, anchor: .bottom)
                }
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 8) {
            TextField("Ask about this section…", text: $typing, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .onSubmit {
                    Task { await send(typing) }
                }
                .disabled(!session.canAcceptTyping)
                .accessibilityIdentifier("assistInputField")

            Button {
                Task { await send(typing) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(!session.canAcceptTyping || typing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityIdentifier("assistSendButton")
        }
        .padding(10)
        .background(.bar)
    }

    // MARK: - Functions

    private func send(_ text: String) async {
        let message: String = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if message.isEmpty {
            return
        }
        typing = ""
        await session.agent?.say(message)
    }
}

/// One line of the conversation.
private struct AssistEntryView: View {

    // MARK: - Stored properties

    let entry: AssistAgent.Entry

    // MARK: - Computed properties

    var body: some View {
        switch entry.speaker {
        case .teacher:
            HStack {
                Spacer(minLength: 40)
                Text(entry.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
            }

        case .assistant:
            Text(entry.text)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .toolResult:
            // What ran is said in the teacher's terms, not the tool's name —
            // "Published Unit 2, Day 3", never "publish_pages returned ok".
            Label(entry.text, systemImage: "checkmark.circle")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .problem:
            Label(entry.text, systemImage: "exclamationmark.triangle")
                .font(.callout)
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// What the assistant is about to do, waiting on a button.
///
/// Two shapes, one box. A DEPLOY always asks, because it puts something in
/// front of students immediately and cannot be taken back by us. Everything
/// else asks only while plan mode is on, and what it shows is the `plan_`
/// twin's own words rather than a tool name a teacher would have to decode.
private struct AssistApprovalView: View {

    // MARK: - Stored properties

    let explanation: String
    let isDeploy: Bool
    let approve: () -> Void
    let decline: () -> Void

    // MARK: - Computed properties

    private var title: String {
        return isDeploy ? "This one needs your say-so" : "Here is what I would do"
    }

    private var goTitle: String {
        return isDeploy ? "Deploy" : "Go"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: isDeploy ? "hand.raised" : "text.magnifyingglass")
                .font(.headline)
            Text(explanation)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button(goTitle, action: approve)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("assistApproveButton")
                Button("Cancel", action: decline)
                    .accessibilityIdentifier("assistDeclineButton")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (isDeploy ? Color.orange : Color.accentColor).opacity(0.10),
            in: RoundedRectangle(cornerRadius: 10)
        )
    }
}

/// The one-time offer to stop showing plans.
///
/// Offered after five plans accepted without a Cancel, while getting it
/// right five times running is still fresh — rather than months later in a
/// settings pane nobody opens. "Keep checking" is the default button: the
/// teacher who pressed Return without reading keeps the safer arrangement.
private struct AssistStopAskingOfferView: View {

    // MARK: - Stored properties

    let stopAsking: () -> Void
    let keepAsking: () -> Void

    // MARK: - Computed properties

    private var message: String {
        return "That is five in a row you have said yes to. I can just do what you "
             + "ask from now on — you can still undo anything, and Restore puts the "
             + "whole section back to how it was when we started."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Shall I stop checking first?", systemImage: "checkmark.seal")
                .font(.headline)
            Text(message)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Just do it", action: stopAsking)
                    .accessibilityIdentifier("assistStopAskingButton")
                Button("Keep checking", action: keepAsking)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("assistKeepAskingButton")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
    }
}

/// Something standing between the teacher and a conversation.
private struct AssistNoticeView: View {

    // MARK: - Stored properties

    let title: String
    let detail: String

    // MARK: - Computed properties

    var body: some View {
        VStack(spacing: 8) {
            Text(title).font(.headline)
            Text(detail)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
