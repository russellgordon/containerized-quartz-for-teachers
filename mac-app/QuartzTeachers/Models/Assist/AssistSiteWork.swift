import Foundation

/// How a run of the toolchain ended.
struct AssistSiteWorkResult {

    // MARK: - Stored properties

    let succeeded: Bool

    /// What happened, in words meant to be read to a teacher.
    let message: String
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
    func deploy(course: Course, sectionNumber: Int) async -> AssistSiteWorkResult {
        guard let workspaceURL = workspace.workspaceURL else {
            return AssistSiteWorkResult(
                succeeded: false, message: AssistToolRefusal.noWorkingFolder.message
            )
        }
        if let busy = CourseActivity.busyDescription(folderPath: workspaceURL.path, courseCode: course.code) {
            return AssistSiteWorkResult(succeeded: false, message: busy)
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
            runner.milestones = course.configuration.deploysToLocalFolder
                ? TaskMilestones.buildAndDeployToFolder
                : TaskMilestones.buildAndDeploy
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
            runner.milestones = course.configuration.deploysToLocalFolder
                ? TaskMilestones.deployToFolder
                : TaskMilestones.deploy
        }

        var arguments: [String] = [course.code, String(sectionNumber)]
        if course.configuration.deploysToLocalFolder {
            arguments.append(contentsOf: ["--to-folder", course.configuration.deployFolderPath])
        }
        runner.run(
            scriptNamed: "deploy.sh",
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
}
