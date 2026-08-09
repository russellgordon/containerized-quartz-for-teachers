import SwiftUI

/// The friendly face of a running task: an indeterminate progress bar
/// with a plain-language phase description, and the detailed output
/// tucked behind a "Show details" disclosure.
///
/// If the task appears stuck at a question (which the app normally
/// answers itself), a notice invites the teacher to open the details
/// and reply. Details open automatically when a task fails.
struct TaskProgressView: View {

    // MARK: - Stored properties

    let runner: ScriptRunner
    let title: String

    @State var isShowingDetails: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(alignment: .leading, spacing: 10) {
                    if runner.isRunning {
                        HStack(spacing: 8) {
                            Text(title)
                                .font(.headline)
                            Spacer()
                            Text(runner.friendlyPhase)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("taskPhaseLabel")
                        }
                        ProgressView()
                            .progressViewStyle(.linear)
                    } else if let exitCode = runner.lastExitCode {
                        HStack(spacing: 8) {
                            Text(title)
                                .font(.headline)
                            Spacer()
                            if exitCode == 0 {
                                Label("Done", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Label("Something went wrong", systemImage: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    if runner.mayBeWaitingForInput(asOf: context.date) {
                        Label(
                            "A question needs your attention — click “Show details” below to see it and type an answer.",
                            systemImage: "questionmark.bubble"
                        )
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("awaitingInputNotice")
                    }

                    if let problem = runner.launchProblem {
                        Text(problem)
                            .foregroundStyle(.red)
                    }
                }
                .padding(12)
            }

            Divider()

            DisclosureGroup(isExpanded: $isShowingDetails) {
                TaskConsoleView(runner: runner, title: title)
                    .frame(minHeight: 220)
            } label: {
                Text("Show details")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .accessibilityIdentifier("taskDetailsDisclosure")
        }
        .onChange(of: runner.lastExitCode) {
            // A failure is worth reading about: open the details.
            if let exitCode = runner.lastExitCode {
                if exitCode != 0 {
                    isShowingDetails = true
                }
            }
        }
    }
}
