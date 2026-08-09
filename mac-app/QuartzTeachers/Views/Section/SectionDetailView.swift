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
    @State var previewController = WebPreviewController()
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
                WebPreviewView(controller: previewController, url: previewURL)
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
            if previewURL != nil {
                ToolbarItemGroup(placement: .navigation) {
                    Button("Back", systemImage: "chevron.left") {
                        previewController.goBack()
                    }
                    .disabled(!previewController.canGoBack)
                    .accessibilityIdentifier("previewBackButton")

                    Button("Forward", systemImage: "chevron.right") {
                        previewController.goForward()
                    }
                    .disabled(!previewController.canGoForward)
                    .accessibilityIdentifier("previewForwardButton")

                    Button("Reload", systemImage: "arrow.clockwise") {
                        previewController.reload()
                    }
                    .accessibilityIdentifier("previewReloadButton")
                }
            }
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
        .focusedSceneValue(\.previewController, previewURL != nil ? previewController : nil)
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

    /// Opens the page currently shown in the preview (not just the site
    /// root) in the teacher's default browser.
    func openInBrowser() {
        var urlToOpen: URL? = previewController.webView.url
        if urlToOpen == nil {
            urlToOpen = previewURL
        }
        if let urlToOpen {
            NSWorkspace.shared.open(SectionDetailView.browserSafeURL(for: urlToOpen))
        }
    }

    /// Rewrites "localhost" to "127.0.0.1" for hand-off to a browser.
    /// Safari tries IPv6 (::1) first for "localhost", and the container
    /// only publishes the port on IPv4 — which reads as "server dropped
    /// the connection". The numeric address sidesteps that entirely.
    static func browserSafeURL(for url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        if components.host == "localhost" {
            components.host = "127.0.0.1"
        }
        if let rewritten = components.url {
            return rewritten
        }
        return url
    }

    /// Waits for THIS run's Quartz server, then switches the view from
    /// console output to the embedded website.
    ///
    /// A previous preview (possibly of a different course) can still be
    /// serving on port 8081 when this run starts — the toolchain only
    /// kills it partway through the build. Polling immediately would
    /// happily embed that stale site, so this waits for the script's own
    /// "Launching Quartz preview" line first and only then trusts a
    /// response from the port.
    func waitForPreviewServer() async {
        let serverURL: URL = URL(string: "http://127.0.0.1:8081/")!

        // Phase 1: wait for the script to announce ITS server is starting
        // (which happens right after it has freed the port).
        // Up to 10 minutes: a first-ever build may pull the Docker image
        // and install npm dependencies.
        var waitedSeconds: Int = 0
        while waitedSeconds < 600 {
            if !previewRunner.isRunning && previewRunner.lastExitCode != nil {
                // The script exited before the server came up: show output.
                isWaitingForServer = false
                return
            }
            if previewRunner.transcript.displayText.contains("Launching Quartz preview") {
                break
            }
            try? await Task.sleep(for: .seconds(1))
            waitedSeconds += 1
        }

        // Phase 2: poll until the newly launched server responds.
        while waitedSeconds < 600 {
            if !previewRunner.isRunning && previewRunner.lastExitCode != nil {
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
            waitedSeconds += 1
        }
        isWaitingForServer = false
    }
}
