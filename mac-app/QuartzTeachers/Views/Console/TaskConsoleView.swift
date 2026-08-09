import SwiftUI

/// Shows a running script's streamed output, with an input field so any
/// interactive prompt (for example, pasting a Netlify token on first
/// deploy) can be answered right in the app.
struct TaskConsoleView: View {

    // MARK: - Stored properties

    let runner: ScriptRunner
    let title: String

    @State var pendingInput: String = ""

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if runner.isRunning {
                    ProgressView()
                        .controlSize(.small)
                } else if let exitCode = runner.lastExitCode {
                    if exitCode == 0 {
                        Label("Finished", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("Failed (exit \(exitCode))", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    Text(transcriptText)
                        .font(.body.monospaced())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .textSelection(.enabled)
                        .accessibilityIdentifier("consoleText")
                    Color.clear
                        .frame(height: 1)
                        .id("consoleBottom")
                }
                .onChange(of: runner.transcript.lines.count) {
                    proxy.scrollTo("consoleBottom", anchor: .bottom)
                }
            }
            .background(.background.secondary)

            if let problem = runner.launchProblem {
                Text(problem)
                    .foregroundStyle(.red)
                    .padding(8)
            }

            if runner.isRunning {
                Divider()
                HStack {
                    TextField("If you’re asked a question, type your answer here…", text: $pendingInput)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            sendPendingInput()
                        }
                        .accessibilityIdentifier("consoleInputField")
                    Button("Send") {
                        sendPendingInput()
                    }
                    Button("Stop", role: .destructive) {
                        runner.terminate()
                    }
                }
                .padding(8)
            }
        }
    }

    // MARK: - Computed properties

    var transcriptText: String {
        let text: String = runner.transcript.displayText
        if text.isEmpty {
            return "Starting…"
        }
        return text
    }

    // MARK: - Functions

    func sendPendingInput() {
        runner.send(line: pendingInput)
        pendingInput = ""
    }
}
