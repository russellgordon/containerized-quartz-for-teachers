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

    /// The port this window's preview holds, while it holds one.
    @State var previewLease: PreviewLeases.Lease?

    /// Why a preview could not start, shown as an alert.
    @State var previewRefusal: String?

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
        ZStack {
            // Base layer: always laid out in the normal, safe-area
            // respecting flow. Keeping it mounted means its geometry is
            // never inherited from the full-bleed web view above it —
            // which is what dragged the progress header under the
            // window's toolbar when a preview was restarted.
            VStack(spacing: 0) {
                if isWaitingForServer || isBusy || !previewRunner.transcript.lines.isEmpty || !deployRunner.transcript.lines.isEmpty {
                    consoleArea
                } else {
                    ContentUnavailableView(
                        "No Preview Running",
                        systemImage: "globe",
                        description: Text("Click Preview to build this section's website and see it here, or Deploy to publish it to Netlify.")
                    )
                }
            }

            // Cover layer: the site itself, deliberately full-bleed.
            if let previewURL {
                WebPreviewView(controller: previewController, url: previewURL)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityIdentifier("previewWebView")
            }
        }
        .navigationTitle(titleText)
        .toolbar {
            // Every item is ALWAYS present (disabled when inapplicable):
            // conditionally inserting toolbar items makes macOS rebuild
            // the toolbar, which briefly mis-lays-out the title area.
            ToolbarItemGroup(placement: .navigation) {
                Button("Back", systemImage: "chevron.left") {
                    previewController.goBack()
                }
                .disabled(previewURL == nil || !previewController.canGoBack)
                .help("Go back a page")
                .accessibilityIdentifier("previewBackButton")

                Button("Forward", systemImage: "chevron.right") {
                    previewController.goForward()
                }
                .disabled(previewURL == nil || !previewController.canGoForward)
                .help("Go forward a page")
                .accessibilityIdentifier("previewForwardButton")

                Button("Reload", systemImage: "arrow.clockwise") {
                    previewController.reload()
                }
                .disabled(previewURL == nil)
                .help("Reload this page")
                .accessibilityIdentifier("previewReloadButton")
            }
            ToolbarItemGroup {
                Button("Open in Obsidian", systemImage: "long.text.page.and.pencil") {
                    FolderActions.openInObsidian(
                        revealing: course.sectionDirectoryURL(forSection: sectionNumber),
                        vaultURL: course.directoryURL
                    )
                }
                .disabled(!FolderActions.obsidianIsInstalled)
                .help("Edit this section's pages in Obsidian")
                .accessibilityIdentifier("openInObsidianButton")

                // One stable item that changes face, not two swapped
                // items — swapping rebuilds the toolbar (same glitch).
                Button(
                    previewRunner.isRunning ? "Stop Preview" : "Preview",
                    systemImage: previewRunner.isRunning ? "stop.fill" : "play.fill"
                ) {
                    if previewRunner.isRunning {
                        stopPreview()
                    } else {
                        startPreview()
                    }
                }
                .disabled(!previewRunner.isRunning && isBusy)
                .help(previewRunner.isRunning ? "Stop previewing this section" : "Preview this section's website")
                .accessibilityIdentifier(previewRunner.isRunning ? "stopPreviewButton" : "previewButton")

                Button("Deploy", systemImage: "paperplane.fill") {
                    startDeploy()
                }
                .disabled(isBusy)
                .help("Publish this section's website")
                .accessibilityIdentifier("deployButton")

                Button("Open in Browser", systemImage: "safari") {
                    openInBrowser()
                }
                .disabled(previewURL == nil)
                .help("Open this preview in your web browser")
                .accessibilityIdentifier("openInBrowserButton")

            }
        }
        .focusedSceneValue(\.previewController, previewURL != nil ? previewController : nil)
        .onDisappear {
            stopPreview()
        }
        .alert("Cannot Preview Yet", isPresented: previewRefusalBinding) {
            Button("OK") {
                previewRefusal = nil
            }
        } message: {
            Text(previewRefusal ?? "")
        }
    }

    var previewRefusalBinding: Binding<Bool> {
        return Binding(
            get: { previewRefusal != nil },
            set: { isPresented in
                if !isPresented {
                    previewRefusal = nil
                }
            }
        )
    }

    var consoleArea: some View {
        VStack(spacing: 0) {
            if showsDeployProgress {
                TaskProgressView(runner: deployRunner, title: "Publishing \(titleText)")
            } else {
                TaskProgressView(runner: previewRunner, title: previewTaskTitle)
            }
            Spacer(minLength: 0)
        }
    }

    /// What the preview panel is called. While the preview is being made
    /// the title says so; once it has finished or been stopped, the panel
    /// is simply about the preview, so it must stop claiming to be
    /// preparing one.
    var previewTaskTitle: String {
        return SectionDetailView.previewTaskTitle(isPreparing: previewRunner.isRunning, sectionName: titleText)
    }

    /// True when the console should be about publishing rather than
    /// previewing.
    var showsDeployProgress: Bool {
        return SectionDetailView.showsDeployProgress(
            previewIsRunning: previewRunner.isRunning,
            deployIsRunning: deployRunner.isRunning,
            previewStartedAt: previewRunner.startedAt,
            deployStartedAt: deployRunner.startedAt
        )
    }

    // MARK: - Functions

    /// Names the preview panel for what it is at the moment.
    static func previewTaskTitle(isPreparing: Bool, sectionName: String) -> String {
        if isPreparing {
            return "Preparing the preview of \(sectionName)"
        }
        return "Preview of \(sectionName)"
    }

    /// Whichever task is running now, or — once both have finished — the
    /// one that started most recently.
    ///
    /// Judging by "has this task any output?" instead kept a finished
    /// publish on screen forever, so starting a preview afterwards left
    /// the publish's own summary sitting there as though nothing had
    /// happened.
    static func showsDeployProgress(previewIsRunning: Bool, deployIsRunning: Bool, previewStartedAt: Date?, deployStartedAt: Date?) -> Bool {
        if previewIsRunning {
            return false
        }
        if deployIsRunning {
            return true
        }
        let previewStart: Date = previewStartedAt ?? Date.distantPast
        let deployStart: Date = deployStartedAt ?? Date.distantPast
        return deployStart > previewStart
    }

    func startPreview() {
        guard let workspaceURL = workspace.workspaceURL else {
            return
        }
        // Each preview runs on its own port, so several windows can show
        // sections side by side without taking each other down.
        let lease: PreviewLeases.Lease
        do {
            lease = try PreviewLeases.lease(
                folderPath: workspaceURL.path,
                courseCode: course.code,
                sectionNumber: sectionNumber
            )
        } catch {
            previewRefusal = error.localizedDescription
            return
        }
        previewLease = lease
        previewURL = nil
        isWaitingForServer = true
        previewRunner.milestones = TaskMilestones.preview
        previewRunner.run(
            scriptNamed: "preview.sh",
            arguments: [course.code, String(sectionNumber), "--port", String(lease.port)],
            workingDirectory: workspaceURL
        )
        Task {
            await waitForPreviewServer(port: lease.port)
        }
    }

    func stopPreview() {
        previewRunner.stopByUser()
        previewURL = nil
        isWaitingForServer = false
        releasePreviewLease()
    }

    /// Hands the port back, whatever ended the preview.
    func releasePreviewLease() {
        if let lease = previewLease {
            PreviewLeases.release(lease)
            previewLease = nil
        }
    }

    /// Publishes the section. If the built site is missing or older than
    /// the teacher's content, it is rebuilt first — quietly, without
    /// showing a preview — so what gets published is always current.
    func startDeploy() {
        guard let workspaceURL = workspace.workspaceURL else {
            return
        }

        let needsBuild: Bool = BuildFreshness.needsRebuild(course: course, sectionNumber: sectionNumber)
        deployRunner.milestones = needsBuild ? TaskMilestones.buildAndDeploy : TaskMilestones.deploy

        Task {
            if needsBuild {
                deployRunner.run(
                    scriptNamed: "preview.sh",
                    arguments: [course.code, String(sectionNumber), "--build-only"],
                    workingDirectory: workspaceURL
                )
                let built: Bool = await deployRunner.waitUntilFinished()
                if !built {
                    // The failure and its output are already on screen.
                    return
                }
            }

            deployRunner.run(
                scriptNamed: "deploy.sh",
                arguments: [course.code, String(sectionNumber)],
                workingDirectory: workspaceURL,
                keepingTranscript: needsBuild
            )
        }
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
    func waitForPreviewServer(port: Int) async {
        // The launcher announces the real host address — the container's
        // ports map to a per-folder block, so the port cannot be assumed.
        var serverURL: URL = URL(string: "http://127.0.0.1:\(port)/")!

        // Phase 1: wait for the script to announce ITS server is starting
        // (which happens right after it has freed the port).
        // Up to 10 minutes: a first-ever build may pull the Docker image
        // and install npm dependencies.
        var waitedSeconds: Int = 0
        while waitedSeconds < 600 {
            if !previewRunner.isRunning && previewRunner.lastExitCode != nil {
                // The script exited before the server came up: show output.
                isWaitingForServer = false
                releasePreviewLease()
                return
            }
            if let announced = previewRunner.previewAddress {
                serverURL = announced
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
                releasePreviewLease()
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
