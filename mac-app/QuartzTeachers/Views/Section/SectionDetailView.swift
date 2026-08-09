import SwiftUI

/// One section of a course: Preview builds and serves the site with
/// `preview.sh` and shows it in an embedded web view; Deploy publishes it
/// with `deploy.sh`. All output streams into a console below.
struct SectionDetailView: View {

    // MARK: - Stored properties

    let course: Course
    let sectionNumber: Int

    @State var previewRunner = ScriptRunner()
    @State var deployRunner = ScriptRunner()
    @State var previewURL: URL?
    @State var isWaitingForServer: Bool = false

    @Environment(WorkspaceModel.self) var workspace

    // MARK: - Computed properties

    var titleText: String {
        return "\(course.code)-S\(sectionNumber)"
    }

    var isBusy: Bool {
        return previewRunner.isRunning || deployRunner.isRunning
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if let previewURL {
                WebPreviewView(url: previewURL)
                    .accessibilityIdentifier("previewWebView")
            } else if isWaitingForServer || isBusy || !previewRunner.transcript.lines.isEmpty || !deployRunner.transcript.lines.isEmpty {
                consoleArea
            } else {
                ContentUnavailableView(
                    "No Preview Running",
                    systemImage: "globe",
                    description: Text("Click Preview to build this section's website and see it here, or Deploy to publish it to Netlify.")
                )
            }
        }
        .navigationTitle(titleText)
        .toolbar {
            ToolbarItemGroup {
                if previewRunner.isRunning {
                    Button("Stop Preview", systemImage: "stop.fill") {
                        stopPreview()
                    }
                    .accessibilityIdentifier("stopPreviewButton")
                } else {
                    Button("Preview", systemImage: "play.fill") {
                        startPreview()
                    }
                    .disabled(isBusy)
                    .accessibilityIdentifier("previewButton")
                }

                Button("Deploy", systemImage: "paperplane.fill") {
                    startDeploy()
                }
                .disabled(isBusy)
                .accessibilityIdentifier("deployButton")

                if previewURL != nil {
                    Button("Open in Browser", systemImage: "safari") {
                        openInBrowser()
                    }
                }
            }
        }
        .onDisappear {
            stopPreview()
        }
    }

    var consoleArea: some View {
        VStack(spacing: 0) {
            if isWaitingForServer {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Building the site — the preview appears here when it is ready…")
                        .foregroundStyle(.secondary)
                }
                .padding(8)
            }
            if deployRunner.isRunning || !deployRunner.transcript.lines.isEmpty {
                TaskConsoleView(runner: deployRunner, title: "Deploy output")
            } else {
                TaskConsoleView(runner: previewRunner, title: "Preview output")
            }
        }
    }

    // MARK: - Functions

    func startPreview() {
        guard let workspaceURL = workspace.workspaceURL else {
            return
        }
        previewURL = nil
        isWaitingForServer = true
        previewRunner.run(
            scriptNamed: "preview.sh",
            arguments: [course.code, String(sectionNumber)],
            workingDirectory: workspaceURL
        )
        Task {
            await waitForPreviewServer()
        }
    }

    func stopPreview() {
        previewRunner.terminate()
        previewURL = nil
        isWaitingForServer = false
    }

    func startDeploy() {
        guard let workspaceURL = workspace.workspaceURL else {
            return
        }
        deployRunner.run(
            scriptNamed: "deploy.sh",
            arguments: [course.code, String(sectionNumber)],
            workingDirectory: workspaceURL
        )
    }

    func openInBrowser() {
        if let previewURL {
            NSWorkspace.shared.open(previewURL)
        }
    }

    /// Polls localhost:8081 until the Quartz preview server responds, then
    /// switches the view from console output to the embedded website.
    func waitForPreviewServer() async {
        let serverURL: URL = URL(string: "http://localhost:8081/")!
        // Up to 10 minutes: a first-ever build may pull the Docker image
        // and install npm dependencies.
        for _ in 0..<600 {
            if !previewRunner.isRunning && previewRunner.lastExitCode != nil {
                // The script exited before the server came up: show output.
                isWaitingForServer = false
                return
            }
            var request: URLRequest = URLRequest(url: serverURL)
            request.timeoutInterval = 2
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        isWaitingForServer = false
                        previewURL = serverURL
                        return
                    }
                }
            } catch {
                // Server not up yet — keep waiting.
            }
            try? await Task.sleep(for: .seconds(1))
        }
        isWaitingForServer = false
    }
}
