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

    /// Why a deploy could not start, shown as an alert.
    @State var deployRefusal: String?

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
                        description: Text(course.configuration.deploysToLocalFolder
                            ? "Click Preview to build this section's website and see it here, or Deploy to copy it to your deploy folder."
                            : "Click Preview to build this section's website and see it here, or Deploy to put it online.")
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
                Button("Open in Obsidian", systemImage: "square.and.pencil") {
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
                // The icon alone doesn't say what these two buttons do, so
                // they wear their titles; the neighbouring icons are the
                // familiar Obsidian and Safari actions and stay icon-only.
                .labelStyle(.titleAndIcon)
                .disabled(!previewRunner.isRunning && isBusy)
                .help(previewRunner.isRunning ? "Stop previewing this section" : "Preview this section's website")
                .accessibilityIdentifier(previewRunner.isRunning ? "stopPreviewButton" : "previewButton")

                // "Deploy", NOT "Publish" — a page is published (the
                // `publish:` flag decides whether students see it); the
                // whole site is deployed. One word for both had the
                // teacher and the assistant talking past each other.
                Button("Deploy", systemImage: "paperplane.fill") {
                    startDeploy()
                }
                .labelStyle(.titleAndIcon)
                .disabled(isBusy)
                .help("Deploy this section's website")
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
        // The assistant cannot drive a preview itself — it holds neither the
        // port lease nor the web view — so this window hands it the two things
        // it alone can do. Registered rather than observed: the assistant has
        // to stop the preview, change files, and start it again IN THAT ORDER,
        // and an observer that acts whenever SwiftUI next evaluates a body
        // cannot promise the stop happened before the writes.
        //
        // These are the same functions the toolbar button calls, so the
        // assistant and the button can never drift apart.
        .onAppear {
            guard let folder = workspace.workspaceURL else {
                return
            }
            SectionPreviewControllers.shared.register(
                folderPath: folder.path,
                courseCode: course.code,
                sectionNumber: sectionNumber,
                controller: SectionPreviewControllers.Controller(
                    isRunning: { previewRunner.isRunning },
                    start: { startPreview() },
                    stop: { await stopPreviewAndWait() }
                )
            )
        }
        .onDisappear {
            if let folder = workspace.workspaceURL {
                SectionPreviewControllers.shared.unregister(
                    folderPath: folder.path,
                    courseCode: course.code,
                    sectionNumber: sectionNumber
                )
            }
            stopPreview()
        }
        .alert("Cannot Preview Yet", isPresented: previewRefusalBinding) {
            Button("OK") {
                previewRefusal = nil
            }
        } message: {
            Text(previewRefusal ?? "")
        }
        .alert("Cannot Deploy Yet", isPresented: deployRefusalBinding) {
            Button("OK") {
                deployRefusal = nil
            }
        } message: {
            Text(deployRefusal ?? "")
        }
    }

    /// Why this section's deploy would not get anywhere, or nil when it
    /// would. Both destinations that need something from the teacher are
    /// checked: the folder, and the Cloudflare Account ID.
    var deployRefusalReason: String? {
        return SectionDetailView.deployRefusalReason(
            configuration: course.configuration,
            cloudflareAccountID: AppSettings.shared.cloudflareAccountID
        )
    }

    /// The same check, free of the view, so it can be tested.
    static func deployRefusalReason(configuration: CourseConfiguration, cloudflareAccountID: String) -> String? {
        if configuration.deployTarget == "local_folder" {
            if let folderProblem = CourseConfiguration.deployFolderProblem(forPath: configuration.deployFolderPath) {
                return "\(folderProblem) Fix it in this course’s settings, under Deploying, then deploy again."
            }
        }
        if configuration.deploysToCloudflare {
            if let accountProblem = CourseConfiguration.cloudflareAccountProblem(forID: cloudflareAccountID) {
                return "\(accountProblem) Add it in this course’s settings, under Deploying, then deploy again."
            }
        }
        return nil
    }

    var deployRefusalBinding: Binding<Bool> {
        return Binding(
            get: { deployRefusal != nil },
            set: { isPresented in
                if !isPresented {
                    deployRefusal = nil
                }
            }
        )
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
                TaskProgressView(runner: deployRunner, title: "Deploying \(titleText)")
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

        Task { @MainActor in
            // Wait for any stop that is still finishing before building.
            //
            // Stop mode finds a section's processes BY WORKING DIRECTORY, so
            // it "catches builds as well as servers" — `preview.sh` says so
            // itself. A stop still running when this build starts kills the
            // build, and what gets served is the last `public/` that was
            // allowed to finish: the site as it was BEFORE the edit.
            //
            // That is why stopping and starting quickly showed stale content
            // while doing the same slowly worked. Nothing failed, nothing was
            // logged; the only symptom was a preview that looked like the
            // edit had not happened.
            //
            // The guard lives HERE, at the one place a preview begins, rather
            // than beside each caller — the button, the assistant, a window
            // being reopened. Somewhere there will always be a caller nobody
            // remembered.
            await PreviewStopper.waitForStopsToFinish(
                courseCode: course.code, sectionNumber: sectionNumber
            )
            // What the built page looked like BEFORE this build — so we can
            // wait for it to CHANGE rather than for it to look new.
            //
            // Comparing against a timestamp taken here does not work, and the
            // reason is easy to miss: this file is written inside the Linux
            // VM, whose clock is its own. If the VM is running ahead — which
            // it does after the Mac sleeps — the OLD file already looks newer
            // than any moment noted on the Mac, so the check passes at once
            // and the teacher is shown the previous build. Waiting for the
            // value to change asks nothing of either clock.
            let siteAsItWas: Date? = builtIndexWrittenAt()
            previewRunner.run(
                scriptNamed: "preview.sh",
                arguments: [course.code, String(sectionNumber), "--port", String(lease.port)],
                workingDirectory: workspaceURL
            )
            await waitForPreviewServer(port: lease.port, siteAsItWas: siteAsItWas)
        }
    }

    /// Stop, and do not come back until the container-side processes have
    /// actually gone.
    ///
    /// The button does not need this — the teacher has finished with the
    /// preview and nothing is racing it. The ASSISTANT does: it stops, writes
    /// the pages, and starts again, and if the stop is still running when the
    /// start begins it kills the new build. What a teacher then sees is not an
    /// error but something worse: no preview, and a site on disk still showing
    /// the last build that was allowed to finish.
    func stopPreviewAndWait() async {
        let courseCode: String = course.code
        let section: Int = sectionNumber
        let folder: URL? = workspace.workspaceURL
        stopPreview()
        if let folder {
            await PreviewStopper.stopSectionProcessesAndWait(
                courseCode: courseCode, sectionNumber: section, workspaceURL: folder
            )
        }
    }

    func stopPreview() {
        // Ending the host-side script leaves the build or server inside
        // the container running; the launcher's stop mode reclaims them.
        if previewRunner.isRunning, let workspaceURL = workspace.workspaceURL {
            PreviewStopper.stopSectionProcesses(
                courseCode: course.code,
                sectionNumber: sectionNumber,
                workspaceURL: workspaceURL
            )
        }
        previewRunner.stopByUser()
        previewURL = nil
        isWaitingForServer = false
        // The next preview reuses this section's port, so its address will be
        // identical to the one already loaded. Without this the web view sees
        // a URL it has seen before and shows the pages it already had —
        // which is how a rebuilt site kept appearing unchanged.
        previewController.forgetLoadedPage()
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

        // Whatever is wrong with the destination is said here, before a
        // build starts: discovering it after several minutes of work would
        // waste the teacher's time and read as a failure of the deploy.
        if let problem = deployRefusalReason {
            deployRefusal = problem
            return
        }

        let needsBuild: Bool = BuildFreshness.needsRebuild(course: course, sectionNumber: sectionNumber)
        // A folder or Cloudflare deploy never touches Netlify, so their
        // progress must not talk about it either.
        if course.configuration.deploysToLocalFolder {
            deployRunner.milestones = needsBuild ? TaskMilestones.buildAndDeployToFolder : TaskMilestones.deployToFolder
        } else if course.configuration.deploysToCloudflare {
            deployRunner.milestones = needsBuild ? TaskMilestones.buildAndDeployToCloudflare : TaskMilestones.deployToCloudflare
        } else {
            deployRunner.milestones = needsBuild ? TaskMilestones.buildAndDeploy : TaskMilestones.deploy
        }

        // When this section has a custom domain, the live-site link shown
        // after publishing wears it instead of the Netlify address.
        let customDomain: String = CourseConfiguration.normalizedCustomDomain(
            course.configuration.customDomain(forSection: sectionNumber)
        )
        deployRunner.customDomainForLinks = customDomain.isEmpty ? nil : customDomain

        // Let the rest of the app know this course is mid-publish (so,
        // for example, Add Section… declines until it finishes).
        CourseActivity.beginPublish(
            folderPath: workspaceURL.path,
            courseCode: course.code,
            sectionNumber: sectionNumber
        )

        Task {
            defer {
                CourseActivity.endPublish(
                    folderPath: workspaceURL.path,
                    courseCode: course.code,
                    sectionNumber: sectionNumber
                )
            }

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

            // What the launcher is asked to do is decided in one place —
            // shared with the scheduled deploy, so an alarm set for half
            // six sends the site to the same destination this button does.
            let deployArguments: [String] = DeployCommand.arguments(
                courseCode: course.code,
                sectionNumber: sectionNumber,
                configuration: course.configuration,
                cloudflareAccountID: AppSettings.shared.cloudflareAccountID
            )
            deployRunner.run(
                scriptNamed: DeployCommand.scriptName,
                arguments: deployArguments,
                workingDirectory: workspaceURL,
                keepingTranscript: needsBuild
            )
            await deployRunner.waitUntilFinished()
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
    /// When this section's built landing page was last written, or nil when
    /// it has never been built.
    func builtIndexWrittenAt() -> Date? {
        let builtIndex: URL = course.directoryURL
            .appendingPathComponent(".merged_output")
            .appendingPathComponent("section\(sectionNumber)")
            .appendingPathComponent("public")
            .appendingPathComponent("index.html")
        return (try? FileManager.default
            .attributesOfItem(atPath: builtIndex.path)[.modificationDate]) as? Date
    }

    func waitForPreviewServer(port: Int, siteAsItWas: Date?) async {
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

        // Phase 2: wait for THIS build to have written the site.
        //
        // Quartz's own handlers.js does this, in this order:
        //
        //     server.listen(argv.port)
        //     "Started a Quartz server listening at ..."
        //     await build(clientRefresh)
        //
        // It SERVES THE EXISTING public/ BEFORE IT REBUILDS IT. So the server
        // answers 200 straight away with the previous build and the fresh one
        // lands seconds later — which is why previewing after an edit showed
        // the old page, why stopping and starting showed it too, why doing the
        // same thing slowly worked, and why pressing Reload fixed it.
        //
        // The signal is the OUTPUT FILE, not a line of console text: Quartz's
        // wording can change between versions and its progress lines are
        // written through a spinner.
        //
        // And it is the file CHANGING, not the file looking recent. The build
        // happens inside the Linux VM, whose clock is its own — run ahead,
        // which it does after the Mac sleeps, and the previous build's
        // index.html already looks newer than any moment noted here, so a
        // "is it newer than now?" test passes immediately and shows exactly
        // the stale page it was written to prevent. Waiting for the value to
        // differ from what it was asks nothing of either clock.
        //
        // Bounded, so a build that never lands cannot leave a teacher watching
        // a spinner: after 120 seconds we show it anyway, and that is the one
        // case the reload below exists for.
        var buildFinished: Bool = false
        var waitedForBuild: Int = 0
        while waitedSeconds < 600 && waitedForBuild < 120 {
            if !previewRunner.isRunning && previewRunner.lastExitCode != nil {
                isWaitingForServer = false
                releasePreviewLease()
                return
            }
            if let announced = previewRunner.previewAddress {
                serverURL = announced
            }
            if let written = builtIndexWrittenAt(), written != siteAsItWas {
                buildFinished = true
                break
            }
            try? await Task.sleep(for: .seconds(1))
            waitedSeconds += 1
            waitedForBuild += 1
        }
        if !buildFinished {
            AppLog.interface.info("preview showed before its build landed; it will reload once")
        }

        // Phase 3: poll until it actually answers, so the web view is never
        // pointed at an address that is not ready.
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
                        // A reload ONLY when we never saw the build finish.
                        //
                        // While Phase 2 waits for Quartz's emit line, the page
                        // is loaded once, at the right moment, and looks it.
                        // An unconditional reload was tried and was worse than
                        // the problem: every preview in the app flickered, for
                        // a case that by then could not happen. The signal
                        // tells us which situation we are in, so it decides —
                        // no signal, no certainty, so reload; signal, so leave
                        // the teacher's page alone.
                        if !buildFinished {
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(900))
                                previewController.reload()
                            }
                        }
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
