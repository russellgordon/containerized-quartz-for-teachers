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
            .fixedSize(horizontal: false, vertical: true)

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
                // Fill whatever space remains below the pinned header —
                // the container (sheet or window) is fixed-size, so this
                // can never grow past it; clipped() guarantees it.
                TaskConsoleView(runner: runner, title: title)
                    .frame(minHeight: 200, maxHeight: .infinity)
                    .clipped()
            }
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
