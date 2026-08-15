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
                    if let approval = session.agent?.pendingApproval {
                        AssistApprovalView(explanation: approval.explanation) {
                            Task { await session.agent?.approvePending() }
                        } decline: {
                            session.agent?.declinePending()
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

/// The one act that waits for a button.
private struct AssistApprovalView: View {

    // MARK: - Stored properties

    let explanation: String
    let approve: () -> Void
    let decline: () -> Void

    // MARK: - Computed properties

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("This one needs your say-so", systemImage: "hand.raised")
                .font(.headline)
            Text(explanation)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Deploy", action: approve)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("assistApproveButton")
                Button("Not now", action: decline)
                    .accessibilityIdentifier("assistDeclineButton")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
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
