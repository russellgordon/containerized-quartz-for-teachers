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

    /// Whether the Restore question is on screen.
    @State private var isConfirmingRestore: Bool = false

    /// What has been asked for before, walked with the arrow keys.
    ///
    /// Per section, and kept across launches, because that is what makes it
    /// worth having: a teacher who works on one section over several days
    /// asks for the same handful of things in the same handful of words, and
    /// a history that emptied every time the window closed would only ever
    /// hold what they had just finished typing anyway.
    @State private var history: AssistPromptHistory = AssistPromptHistory()

    /// Where that history lives between launches. Keyed by section, so one
    /// course's phrasings never surface while working on another.
    @AppStorage private var storedHistory: String

    /// The last line the arrow keys put in the box, so an edit can be told
    /// apart from the walk's own writing.
    @State private var lastRecalled: String?

    /// Whether the box has the keyboard. Tapping a suggestion puts text in it
    /// and gives it focus, so the teacher can edit straight away rather than
    /// having to click into it first.
    @FocusState private var isComposerFocused: Bool

    // MARK: - Initializer

    init(courseCode: String, sectionNumber: Int, workingFolder: URL) {
        _session = State(initialValue: AssistSession(
            courseCode: courseCode,
            sectionNumber: sectionNumber,
            workingFolder: workingFolder
        ))
        _storedHistory = AppStorage(
            wrappedValue: "",
            "AssistPromptHistory-\(courseCode)-\(sectionNumber)"
        )
    }

    // MARK: - Computed properties

    var body: some View {
        VStack(spacing: 0) {
            if session.canRestoreSection {
                restoreBanner
                Divider()
            }
            // Pinned at the top, with the conversation scrolling beneath
            // it. Shut by default, so it costs four scannable lines and
            // stays put however long the conversation grows.
            if session.readiness == .ready {
                // Tapping puts the phrasing in the box; it does NOT send it.
                // These are examples to start from, and most of them want
                // editing before they are true — "Publish Unit 2, Day 3" is a
                // shape, not usually the actual page. A card that fired
                // immediately would make the shelf a row of buttons a teacher
                // learns not to touch.
                AssistPromptShelfView { phrasing in
                    show(phrasing)
                    history.stopBrowsing()
                    isComposerFocused = true
                }
                Divider()
            }
            transcript
            Divider()
            composer
        }
        .frame(minWidth: 460, minHeight: 420)
        .navigationTitle("Assistant — \(session.courseCode) section \(session.sectionNumber)")
        // When something in here needs class dates for a section that has
        // none recorded, it asks through SectionSchedulePrompt and the sheet
        // opens on the window the teacher is already looking at.
        .sectionSchedulePrompt(
            courseCode: session.courseCode,
            sectionNumber: session.sectionNumber,
            workingFolder: session.workingFolder
        )
        // Comes back where it was left, per section. The window group stays
        // unrestored on purpose — reopening it at launch would load a model
        // nobody asked for — so this remembers only the PLACEMENT, which is
        // the part a teacher notices: an assistant that reappears in the
        // middle of the screen, on top of the section it is meant to sit
        // beside, gets dragged back every single time.
        .background(WindowAccessor { window in
            AssistWindowPlacement.remember(
                window,
                courseCode: session.courseCode,
                sectionNumber: session.sectionNumber
            )
        })
        .task {
            history = AssistPromptHistory.read(fromStored: storedHistory)
            await session.prepare()
        }
        .onDisappear {
            session.finish()
        }
    }

    /// The way back to how this section was when the conversation started.
    ///
    /// A banner across the top rather than a line in the transcript, because
    /// the moment it is wanted is the moment something has gone wrong, and a
    /// teacher scrolling a long chat for the way out is a teacher already
    /// having a bad time. It appears only once the conversation has actually
    /// changed something, so it is never furniture.
    ///
    /// Hard to press by accident, in three ways: it is a bordered button rather
    /// than a tap target in the flow of the text, its title ends in an ellipsis
    /// promising a question, and the question that follows makes Cancel the
    /// default — a Return pressed out of habit leaves the section alone.
    private var restoreBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(AssistSectionRestore.bannerTitle(sectionNumber: session.sectionNumber))
                    .font(.callout)
                Text(AssistSectionRestore.bannerDetail())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Button(AssistSectionRestore.buttonTitle(sectionNumber: session.sectionNumber)) {
                isConfirmingRestore = true
            }
            .disabled(session.agent?.isBusy ?? false)
            .accessibilityIdentifier("assistRestoreSectionButton")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
        .alert(
            AssistSectionRestore.confirmationTitle(
                courseCode: session.courseCode, sectionNumber: session.sectionNumber
            ),
            isPresented: $isConfirmingRestore
        ) {
            Button("Cancel", role: .cancel) {
                isConfirmingRestore = false
            }
            .keyboardShortcut(.defaultAction)
            .accessibilityIdentifier("assistCancelRestoreButton")

            Button(
                AssistSectionRestore.goAheadTitle(sectionNumber: session.sectionNumber),
                role: .destructive
            ) {
                session.restoreSection()
            }
            .accessibilityIdentifier("assistConfirmRestoreButton")
        } message: {
            Text(AssistSectionRestore.confirmationMessage(
                courseCode: session.courseCode, sectionNumber: session.sectionNumber
            ))
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
                    ForEach(Array(transcriptLines.enumerated()), id: \.element.id) { position, line in
                        switch line {
                        case .said(let entry):
                            AssistEntryView(
                                entry: entry,
                                hasTail: AssistChatLayout.showsTail(
                                    at: position, in: transcriptSpeakers
                                )
                            )
                        case .restored(let note):
                            AssistRestoreNoteView(note: note)
                        }
                    }

                    // Three dots while the model is working. It appears for
                    // thinking AND for running a tool: both are waits with
                    // nothing on screen, and a teacher does not care which of
                    // the two the assistant is busy with.
                    if session.agent?.isBusy == true, session.agent?.pendingApproval == nil {
                        AssistTypingIndicator()
                    }
                    if let approval = session.agent?.pendingApproval,
                       let agent = session.agent {
                        AssistApprovalView(isDeploy: agent.pendingIsDeploy) {
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
            .onChange(of: transcriptLines.count) {
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
                // Up and Down walk what has been asked before, the way a
                // Terminal does.
                //
                // Handed back as `.ignored` in two cases, so the keys keep
                // doing their ordinary job when history is not what is
                // wanted: when the box holds more than one line, where the
                // arrows have to move the caret between those lines, and
                // when there is nowhere further to walk — a key that silently
                // does nothing reads as a dropped keystroke, while one that
                // is passed on lets the field answer it.
                .onKeyPress(.upArrow) {
                    if typing.contains("\n") {
                        return .ignored
                    }
                    guard let recalled = history.earlier(startingFrom: typing) else {
                        return .ignored
                    }
                    show(recalled)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    if typing.contains("\n") {
                        return .ignored
                    }
                    guard let recalled = history.later() else {
                        return .ignored
                    }
                    show(recalled)
                    return .handled
                }
                // Editing a recalled line makes it a new line, so Down must
                // not come along afterwards and replace what was typed. The
                // walk writes through `show(_:)`, which records what it put
                // there — so anything ELSE that changes the box came from the
                // keyboard, and ends the walk.
                .onChange(of: typing) { _, current in
                    if history.isBrowsing && current != lastRecalled {
                        history.stopBrowsing()
                    }
                }
                .focused($isComposerFocused)
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

    /// Who said each line, in order, with a placeholder for the lines nobody
    /// said. The tail rule reads this rather than the views.
    private var transcriptSpeakers: [AssistAgent.Entry.Speaker] {
        var speakers: [AssistAgent.Entry.Speaker] = []
        for line in transcriptLines {
            switch line {
            case .said(let entry):
                speakers.append(entry.speaker)
            case .restored:
                // A restore is something that HAPPENED, not something said,
                // so it neither wears a tail nor ends anybody's turn.
                speakers.append(.problem)
            }
        }
        return speakers
    }

    /// The conversation and the restores, laid together in the order they
    /// happened.
    ///
    /// A restore is not something either side said, so it is not among the
    /// agent's own entries — but it IS something that happened during this
    /// conversation, and a teacher reading back afterwards needs to find it at
    /// the point where the section changed under them, not tacked on the end.
    private var transcriptLines: [AssistTranscriptLine] {
        let entries: [AssistAgent.Entry] = session.agent?.entries ?? []
        let notes: [AssistSession.RestoreNote] = session.restoreNotes

        var lines: [AssistTranscriptLine] = []
        var notesPlaced: Int = 0
        for (index, entry) in entries.enumerated() {
            while notesPlaced < notes.count && notes[notesPlaced].saidSoFar <= index {
                lines.append(AssistTranscriptLine.restored(notes[notesPlaced]))
                notesPlaced += 1
            }
            lines.append(AssistTranscriptLine.said(entry))
        }
        while notesPlaced < notes.count {
            lines.append(AssistTranscriptLine.restored(notes[notesPlaced]))
            notesPlaced += 1
        }
        return lines
    }

    // MARK: - Functions

    /// Put a recalled line in the box, remembering that the walk is what put
    /// it there rather than the teacher.
    private func show(_ recalled: String) {
        lastRecalled = recalled
        typing = recalled
    }

    private func send(_ text: String) async {
        let message: String = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if message.isEmpty {
            return
        }
        history.remember(message)
        storedHistory = history.stored
        lastRecalled = nil
        typing = ""
        // The cursor stays put. A teacher sending two things in a row should
        // not have to click back into the box between them, and losing focus
        // after every send also loses the arrow-key history that depends on
        // the field having it.
        isComposerFocused = true
        await session.agent?.say(message)
    }
}

/// One line of what a teacher reads back: something said, or a restore.
private enum AssistTranscriptLine: Identifiable {
    case said(AssistAgent.Entry)
    case restored(AssistSession.RestoreNote)

    var id: UUID {
        switch self {
        case .said(let entry):
            return entry.id
        case .restored(let note):
            return note.id
        }
    }
}

/// A restore, written into the conversation so it records what happened.
private struct AssistRestoreNoteView: View {

    // MARK: - Stored properties

    let note: AssistSession.RestoreNote

    // MARK: - Computed properties

    var body: some View {
        Label(note.text, systemImage: note.isProblem ? "exclamationmark.triangle" : "clock.arrow.circlepath")
            .font(.callout)
            .foregroundStyle(note.isProblem ? Color.orange : Color.secondary)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("assistRestoreNote")
    }
}

/// One line of the conversation.
private struct AssistEntryView: View {

    // MARK: - Stored properties

    let entry: AssistAgent.Entry

    /// Whether this bubble ends its participant's run, and so wears the tail.
    let hasTail: Bool

    // MARK: - Computed properties

    var body: some View {
        switch entry.speaker {
        // Blue, on the right, the way the person holding the keyboard is
        // shown in every messaging app a teacher already uses. White text
        // rather than the label colour: the accent is a strong fill, and
        // primary text on it fails in one of the two themes.
        case .teacher:
            HStack {
                Spacer(minLength: 48)
                Text(entry.text)
                    .foregroundStyle(.white)
                    .textSelection(.enabled)
                    .padding(.leading, 14)
                    .padding(.trailing, 14 + AssistChatBubbleShape.reach)
                    .padding(.top, 9)
                    .padding(.bottom, 9 + (hasTail ? AssistChatBubbleShape.drop : 0))
                    .background(
                        AssistChatBubbleShape(side: .teacher, hasTail: hasTail)
                            .fill(Color.accentColor)
                    )
            }
            .padding(.bottom, hasTail ? 4 : 0)

        // Grey, on the left. Softer than the teacher's bubble on purpose:
        // the assistant talks more than the teacher does, and a column of
        // strong fills down one side is exhausting to read.
        case .assistant:
            HStack {
                Text(AssistSaid.styled(entry.text))
                    .textSelection(.enabled)
                    // The tail's side gets the extra room, so the words sit
                    // the same distance from the bubble's edge on both sides.
                    .padding(.leading, 14 + AssistChatBubbleShape.reach)
                    .padding(.trailing, 14)
                    .padding(.top, 9)
                    .padding(.bottom, 9 + (hasTail ? AssistChatBubbleShape.drop : 0))
                    .background(
                        AssistChatBubbleShape(side: .assistant, hasTail: hasTail)
                            .fill(Color.secondary.opacity(0.16))
                    )
                Spacer(minLength: 48)
            }
            .padding(.bottom, hasTail ? 4 : 0)

        case .toolResult:
            // What ran is said in the teacher's terms, not the tool's name —
            // "Published Unit 2, Day 3", never "publish_pages returned ok".
            //
            // When the result has a list behind it, the line unfolds. A count
            // on its own is not actionable — "1 broken link" says something is
            // wrong and nothing about where — but the list is long enough to
            // bury the conversation if it were always open, so it folds.
            if let detail = entry.detail {
                DisclosureGroup {
                    Text(detail)
                        .font(.callout)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                        .padding(.leading, 4)
                } label: {
                    Label(entry.text, systemImage: "checkmark.circle")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("assistResultDetail")
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Label(entry.text, systemImage: "checkmark.circle")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

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
/// The two buttons, and nothing else.
///
/// It used to carry a heading and a copy of the plan. Both have moved into the
/// conversation, where they belong: the plan is something the assistant SAID,
/// the question is another thing it said, and what the teacher chose is their
/// own reply. What is left here is the only part that is not a message — the
/// choice itself.
private struct AssistApprovalView: View {

    // MARK: - Stored properties

    let isDeploy: Bool
    let approve: () -> Void
    let decline: () -> Void

    // MARK: - Computed properties

    private var goTitle: String {
        return isDeploy ? "Deploy" : "Go"
    }

    var body: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            Button("Cancel", action: decline)
                .accessibilityIdentifier("assistDeclineButton")
            Button(goTitle, action: approve)
                .keyboardShortcut(.defaultAction)
                // A deploy is the one act that cannot be taken back, so its
                // button says so in the way macOS says it.
                .buttonStyle(.borderedProminent)
                .tint(isDeploy ? .orange : .accentColor)
                .accessibilityIdentifier("assistApproveButton")
        }
        .padding(.top, 2)
        .frame(maxWidth: .infinity, alignment: .trailing)
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
