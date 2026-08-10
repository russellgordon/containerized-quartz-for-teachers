import AppKit
import OSLog
import SwiftUI

/// The friendly face of a running task: an indeterminate progress bar
/// with a plain-language phase description, and the detailed output
/// tucked behind a "Show details" toggle.
///
/// Layout contract: the header is pinned and fixed; the output area is
/// a FIXED-HEIGHT scroll view that is clipped, so no amount of output
/// can ever push the header (or anything else) out of reach.
struct TaskProgressView: View {

    // MARK: - Stored properties

    let runner: ScriptRunner
    let title: String

    @State var isShowingDetails: Bool = false

    // MARK: - Initializer

    init(runner: ScriptRunner, title: String, showingDetailsForTesting: Bool = false) {
        self.runner = runner
        self.title = title
        _isShowingDetails = State(initialValue: showingDetailsForTesting)
    }

    /// The answer being typed into the question alert.
    @State var answer: String = ""

    /// When the header last refreshed, so a stalled main thread shows up
    /// in the log as a gap rather than only as a blank window.
    ///
    /// Held in a plain class, NOT in @State: writing observed state while
    /// a body is being evaluated invalidates the view and re-evaluates
    /// the body, which spins the main thread forever.
    @State var refreshTracker: RefreshTracker = RefreshTracker()

    // MARK: - Computed properties

    /// Drives the question alert without writing state during a body.
    var awaitingInputBinding: Binding<Bool> {
        return Binding(
            get: { runner.isAwaitingInput },
            set: { isPresented in
                if !isPresented {
                    runner.isAwaitingInput = false
                }
            }
        )
    }

    // MARK: - Functions

    /// Records each refresh; a long gap means the interface was stalled.
    /// Also reports window geometry, because a blank window with a
    /// RESPONSIVE app means the content is being laid out somewhere
    /// other than inside the window.
    func noteRefresh(at date: Date) {
        let gap: TimeInterval = date.timeIntervalSince(refreshTracker.lastRefreshAt)
        if gap > 3 {
            AppLog.interface.error("Interface stalled for \(gap, format: .fixed(precision: 1))s (task: \(title, privacy: .public))")
        }
        refreshTracker.lastRefreshAt = date

        // Once every 5 refreshes, describe where things actually are.
        refreshTracker.refreshCount += 1
        if refreshTracker.refreshCount % 5 != 0 {
            return
        }
        guard let window = NSApp.windows.first(where: { candidate in candidate.isVisible && !candidate.isSheet }) else {
            AppLog.interface.error("No visible window while a task is running")
            return
        }
        let windowFrame: NSRect = window.frame
        let contentFrame: NSRect = window.contentView?.frame ?? .zero
        let contentSubviewCount: Int = window.contentView?.subviews.count ?? 0
        var deepestFrame: NSRect = .zero
        if let firstSubview = window.contentView?.subviews.first {
            deepestFrame = firstSubview.frame
        }
        AppLog.interface.info("""
            window \(NSStringFromRect(windowFrame), privacy: .public) \
            content \(NSStringFromRect(contentFrame), privacy: .public) \
            subviews \(contentSubviewCount) \
            first \(NSStringFromRect(deepestFrame), privacy: .public)
            """)

        // When the hierarchy is taller than the window, name every view
        // responsible — this is what identifies the culprit.
        if deepestFrame.height > windowFrame.height + 1 {
            if let contentView = window.contentView {
                TaskProgressView.reportOversizedViews(in: contentView, limit: windowFrame.height, depth: 0)
            }
        }
    }

    /// Logs each view taller than the window, with its class and frame.
    static func reportOversizedViews(in view: NSView, limit: CGFloat, depth: Int) {
        if depth > 12 {
            return
        }
        for subview in view.subviews {
            if subview.frame.height > limit + 1 {
                let indent: String = String(repeating: "  ", count: depth)
                AppLog.interface.error("""
                    OVERSIZED \(indent, privacy: .public)\
                    \(String(describing: type(of: subview)), privacy: .public) \
                    \(NSStringFromRect(subview.frame), privacy: .public) \
                    subviews \(subview.subviews.count)
                    """)
            }
            reportOversizedViews(in: subview, limit: limit, depth: depth + 1)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let _ = noteRefresh(at: context.date)
                VStack(alignment: .leading, spacing: 10) {
                    if runner.isRunning {
                        HStack(spacing: 8) {
                            Text(title)
                                .font(.headline)
                            Spacer()
                            Text(runner.milestones.isEmpty ? runner.friendlyPhase : runner.stepDescription)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("taskPhaseLabel")
                        }
                        if runner.milestones.isEmpty {
                            ProgressView()
                                .progressViewStyle(.linear)
                        } else {
                            ProgressView(value: runner.progressFraction)
                                .progressViewStyle(.linear)
                                .animation(.easeInOut(duration: 0.4), value: runner.progressFraction)
                            Text(runner.currentMilestoneLabel)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("taskMilestoneLabel")
                        }
                    } else if let exitCode = runner.lastExitCode {
                        HStack(spacing: 8) {
                            Text(title)
                                .font(.headline)
                            Spacer()
                            if runner.wasCancelled {
                                Label("Cancelled", systemImage: "xmark.circle.fill")
                                    .foregroundStyle(.orange)
                                    .accessibilityIdentifier("cancelledNotice")
                            } else if exitCode == 0 {
                                Label("Done", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Label("Something went wrong", systemImage: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }

                        if runner.wasCancelled {
                            Text("\(title) was cancelled.")
                                .foregroundStyle(.secondary)
                        }

                        // Finish with something to click: the live site.
                        if !runner.wasCancelled, exitCode == 0, let siteURL = runner.publishedSiteURL {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your website is live.")
                                Link(siteURL.absoluteString, destination: siteURL)
                                    .accessibilityIdentifier("publishedSiteLink")
                            }
                        }
                    }

                    if runner.isAwaitingInput {
                        Label("Waiting for your answer…", systemImage: "questionmark.bubble")
                            .foregroundStyle(.orange)
                            .accessibilityIdentifier("awaitingInputNotice")
                    }

                    // The task is stopping itself; say so while it does.
                    if runner.wasCancelled && runner.isRunning {
                        Label("Cancelling…", systemImage: "xmark.circle")
                            .foregroundStyle(.orange)
                            .accessibilityIdentifier("cancellingNotice")
                    }

                    if let problem = runner.launchProblem {
                        Text(problem)
                            .foregroundStyle(.red)
                    }
                }
                .padding(12)
            }

            Divider()

            Button {
                isShowingDetails.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isShowingDetails ? "chevron.down" : "chevron.right")
                        .font(.caption)
                    Text(isShowingDetails ? "Hide details" : "Show details")
                        .font(.callout)
                }
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .accessibilityIdentifier("taskDetailsDisclosure")

            if isShowingDetails {
                // Fill the space below the pinned header — but declare a
                // small IDEAL height. Without it, an unbounded height
                // proposal resolves to the ideal size, and a scroll
                // view's ideal size is its entire content: a long
                // transcript then demanded tens of thousands of points,
                // growing the window's content past the window itself
                // and sliding the interface out of sight.
                TaskConsoleView(runner: runner, title: title)
                    .frame(minHeight: 200, idealHeight: 260, maxHeight: .infinity)
                    .clipped()
            }
        }
        // Ask the question outright rather than making a teacher open
        // the details and type into a console.
        // Neutral wording: a task may ask several questions in a row, so
        // the title must not promise how many are coming.
        .alert("Input required", isPresented: awaitingInputBinding) {
            TextField("Your answer", text: $answer)
            Button("Send") {
                runner.send(line: answer)
                answer = ""
            }
            Button("Cancel", role: .cancel) {
                // Let the task stop the way it stops itself, so its own
                // clean-up runs.
                runner.cancelPendingQuestion()
            }
        } message: {
            Text(runner.pendingQuestion)
        }
        .onChange(of: runner.isAwaitingInput) {
            // Start from the answer the task would have used anyway, so
            // agreeing is one keystroke and changing it is still easy.
            if runner.isAwaitingInput {
                answer = runner.suggestedAnswer
            }
        }
        .onChange(of: runner.lastExitCode) {
            // A failure is worth reading about: open the details.
            if let exitCode = runner.lastExitCode {
                if exitCode != 0 && !runner.wasCancelled {
                    isShowingDetails = true
                }
            }
        }
    }
}
