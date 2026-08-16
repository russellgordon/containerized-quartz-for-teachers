import Foundation

/// How a run of the toolchain ended.
struct AssistSiteWorkResult {

    // MARK: - Stored properties

    let succeeded: Bool

    /// What happened, in words meant to be read to a teacher.
    let message: String

    /// Whether what stopped it was the DESTINATION — no deploy folder, no
    /// Cloudflare account — rather than anything that happened while running.
    ///
    /// The section window shows these as an alert, because they are the one
    /// kind of refusal a teacher can go and fix in course settings, and the
    /// button that raised it has no other voice. Everything else the window
    /// says through its console, which is already on screen.
    let isAboutTheDestination: Bool

    // MARK: - Initializer

    init(succeeded: Bool, message: String, isAboutTheDestination: Bool = false) {
        self.succeeded = succeeded
        self.message = message
        self.isAboutTheDestination = isAboutTheDestination
    }
}

/// The two acts that leave Swift and run the toolchain: building a section's
/// preview, and putting it on the web.
///
/// A seam rather than a call, for two reasons. The app already owns this work
/// — a preview takes a port lease and a web view, a deploy narrates itself into
/// the section's console — so the window is entitled to hand the assistant its
/// own way of doing it. And a test must be able to exercise "publish tomorrow's
/// class" without starting Docker.
@MainActor
protocol AssistSiteWork {

    // MARK: - Functions

    func rebuildPreview(course: Course, sectionNumber: Int) async -> AssistSiteWorkResult

    func deploy(course: Course, sectionNumber: Int) async -> AssistSiteWorkResult
}

/// The real thing: the same `preview.sh` and `deploy.sh` a teacher would run in
/// Terminal, through the same `ScriptRunner` the section's own buttons use.
///
/// The app never re-implements toolchain behaviour, and the assistant is not an
/// exception to that.
@MainActor
final class AssistToolchainWork: AssistSiteWork {

    // MARK: - Stored properties

    /// Read at call time rather than kept, so an assistant window whose folder
    /// changed under it refuses rather than working in the old one.
    private let workspace: WorkspaceModel

    /// The runner in use, so a caller can watch the output if it wants to.
    private(set) var runner: ScriptRunner = ScriptRunner()

    // MARK: - Initializer

    init(workspace: WorkspaceModel) {
        self.workspace = workspace
    }

    // MARK: - Functions

    /// Builds the section's site.
    ///
    /// `--build-only`, deliberately. Serving the preview and putting it on
    /// screen is the section window's job: it holds the port lease and the web
    /// view, and a second server started behind its back would take a port it
    /// then could not have. So the assistant brings the built site up to date
    /// and tells the teacher where to look at it.
    func rebuildPreview(course: Course, sectionNumber: Int) async -> AssistSiteWorkResult {
        guard let workspaceURL = workspace.workspaceURL else {
            return AssistSiteWorkResult(
                succeeded: false, message: AssistToolRefusal.noWorkingFolder.message
            )
        }

        runner = ScriptRunner()
        runner.milestones = TaskMilestones.preview
        runner.run(
            scriptNamed: "preview.sh",
            arguments: [course.code, String(sectionNumber), "--build-only"],
            workingDirectory: workspaceURL
        )
        if let problem = runner.launchProblem {
            return AssistSiteWorkResult(succeeded: false, message: problem)
        }
        let built: Bool = await runner.waitUntilFinished()

        if !built {
            return AssistSiteWorkResult(
                succeeded: false,
                message: "The preview for \(course.code) Section \(sectionNumber) did not finish building. "
                       + "The output is in that section's console in Plantoir."
            )
        }
        return AssistSiteWorkResult(
            succeeded: true,
            message: "Rebuilt the preview for \(course.code) Section \(sectionNumber). "
                   + "Open that section in Plantoir to look it over."
        )
    }

    /// Publishes the section, building first when the built site is out of
    /// date — so what goes to students is always current.
    ///
    /// **This is the path for callers with no window.** Claude Code over MCP,
    /// and a deploy set for half six in the morning. When a section window IS
    /// open the assistant presses ITS Deploy instead, so the output lands in
    /// the console the teacher is looking at — `AssistToolRunner.deploySection`
    /// decides which, and this runs when nothing is on screen to press.
    func deploy(course: Course, sectionNumber: Int) async -> AssistSiteWorkResult {
        guard let workspaceURL = workspace.workspaceURL else {
            return AssistSiteWorkResult(
                succeeded: false, message: AssistToolRefusal.noWorkingFolder.message
            )
        }
        if CourseActivity.busyDescription(folderPath: workspaceURL.path, courseCode: course.code) != nil {
            // A whole sentence, not the menu fragment `busyDescription`
            // returns. That string is written to sit under a greyed-out menu
            // item — "Available once preview completed" — and read out on its
            // own in a conversation it says nothing about what was asked for
            // or what to do about it. This refusal is the last word of a turn.
            return AssistSiteWorkResult(
                succeeded: false,
                message: "\(course.code) is busy in Plantoir — a preview or a deploy is running. "
                       + "Wait for that to finish, then ask again."
            )
        }

        let needsBuild: Bool = BuildFreshness.needsRebuild(course: course, sectionNumber: sectionNumber)
        CourseActivity.beginPublish(
            folderPath: workspaceURL.path, courseCode: course.code, sectionNumber: sectionNumber
        )
        defer {
            CourseActivity.endPublish(
                folderPath: workspaceURL.path, courseCode: course.code, sectionNumber: sectionNumber
            )
        }

        runner = ScriptRunner()
        if needsBuild {
            runner.milestones = AssistToolchainWork.milestones(
                for: course.configuration, buildingFirst: true
            )
            runner.run(
                scriptNamed: "preview.sh",
                arguments: [course.code, String(sectionNumber), "--build-only"],
                workingDirectory: workspaceURL
            )
            if let problem = runner.launchProblem {
                return AssistSiteWorkResult(succeeded: false, message: problem)
            }
            let built: Bool = await runner.waitUntilFinished()
            if !built {
                return AssistSiteWorkResult(
                    succeeded: false,
                    message: "\(course.code) Section \(sectionNumber) could not be built, so nothing was "
                           + "sent to students. The output is in that section's console in Plantoir."
                )
            }
        } else {
            runner.milestones = AssistToolchainWork.milestones(
                for: course.configuration, buildingFirst: false
            )
        }

        // Asked of the SAME place the Deploy button asks. Built here instead,
        // this path sent a Cloudflare course to Netlify — `--target` and
        // `--account` were never passed, and `deploy.sh` defaults to Netlify
        // because every course written before Cloudflare existed relies on
        // that. Nothing failed; the site simply went to the wrong web host.
        let arguments: [String] = DeployCommand.arguments(
            courseCode: course.code,
            sectionNumber: sectionNumber,
            configuration: course.configuration,
            cloudflareAccountID: AppSettings.shared.cloudflareAccountID
        )
        runner.run(
            scriptNamed: DeployCommand.scriptName,
            arguments: arguments,
            workingDirectory: workspaceURL,
            keepingTranscript: needsBuild
        )
        if let problem = runner.launchProblem {
            return AssistSiteWorkResult(succeeded: false, message: problem)
        }
        let deployed: Bool = await runner.waitUntilFinished()

        if !deployed {
            return AssistSiteWorkResult(
                succeeded: false,
                message: "The deploy of \(course.code) Section \(sectionNumber) did not finish. "
                       + "The output is in that section's console in Plantoir."
            )
        }
        return AssistSiteWorkResult(
            succeeded: true,
            message: "\(course.code) Section \(sectionNumber) is deployed. Students can reach it now."
        )
    }

    /// The steps a teacher is shown for this course's destination.
    ///
    /// A folder or Cloudflare deploy never touches Netlify, so their progress
    /// must not talk about it either — the section window works this out the
    /// same way, and getting it wrong here narrated a Cloudflare deploy as a
    /// Netlify one.
    private static func milestones(
        for configuration: CourseConfiguration, buildingFirst: Bool
    ) -> [TaskMilestone] {
        if configuration.deploysToLocalFolder {
            return buildingFirst ? TaskMilestones.buildAndDeployToFolder : TaskMilestones.deployToFolder
        }
        if configuration.deploysToCloudflare {
            return buildingFirst ? TaskMilestones.buildAndDeployToCloudflare : TaskMilestones.deployToCloudflare
        }
        return buildingFirst ? TaskMilestones.buildAndDeploy : TaskMilestones.deploy
    }
}
