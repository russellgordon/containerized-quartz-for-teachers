import Foundation
import Observation

/// The app's top-level state: which working folder is active, the courses
/// found inside it, and what is selected in the sidebar.
///
/// The working folder is the one teachers use with the command-line
/// toolchain — it contains `setup.sh`, `preview.sh`, `deploy.sh`, and a
/// `courses/` directory.
@Observable
class WorkspaceModel {

    // MARK: - Stored properties

    /// The single instance the app runs on. Kept reachable so the hosted
    /// test suite can drive the real user interface.
    static let shared: WorkspaceModel = WorkspaceModel()

    /// The active working folder, or nil before one has been chosen.
    var workspaceURL: URL?

    /// True while the New Course wizard sheet should be shown.
    var isShowingNewCourseWizard: Bool = false

    /// The courses discovered inside `<workspace>/courses/`.
    var courses: [Course] = []

    /// The current sidebar selection.
    var selection: SidebarSelection?

    /// True while the folder-picker sheet should be shown.
    var isChoosingWorkspace: Bool = false

    /// Text typed into the sidebar's filter field.
    var filterText: String = ""

    /// A human-readable problem with the current folder, if any.
    var workspaceProblem: String?

    /// True when the chosen folder is empty and can be set up as a fresh
    /// working folder by copying the launcher scripts in.
    var workspaceCanBeInitialized: Bool = false

    /// True when the chosen folder is neither a working folder nor empty.
    /// The picker stays up (its guidance already covers what to choose)
    /// without displaying an error — this state is not the teacher's
    /// fault, just an unfinished choice.
    var workspaceIsUnrecognized: Bool = false

    /// Set by the test harness (UITEST_WORKSPACE) to bypass persistence.
    private let isUnderUITest: Bool

    // MARK: - Computed properties

    var coursesDirectoryURL: URL? {
        if let workspaceURL {
            return workspaceURL.appendingPathComponent("courses")
        }
        return nil
    }

    /// The courses the sidebar should show, honouring the filter field.
    /// Matching is case-insensitive across the code and the course name.
    var filteredCourses: [Course] {
        let query: String = filterText.trimmingCharacters(in: .whitespaces)
        if query.isEmpty {
            return courses
        }
        var result: [Course] = []
        for course in courses {
            let codeMatches: Bool = course.code.localizedCaseInsensitiveContains(query)
            let nameMatches: Bool = course.configuration.courseName.localizedCaseInsensitiveContains(query)
            if codeMatches || nameMatches {
                result.append(course)
            }
        }
        return result
    }

    /// The course object matching the sidebar selection, if any.
    var selectedCourse: Course? {
        var selectedCode: String?
        switch selection {
        case .course(let code):
            selectedCode = code
        case .section(let code, _):
            selectedCode = code
        case nil:
            selectedCode = nil
        }
        guard let selectedCode else {
            return nil
        }
        for course in courses {
            if course.code == selectedCode {
                return course
            }
        }
        return nil
    }

    // MARK: - Initializer

    init() {
        // A UI test can point the app at a fixture folder via the
        // environment, which also keeps test runs out of UserDefaults.
        let environment: [String: String] = ProcessInfo.processInfo.environment
        if let fixturePath = environment["UITEST_WORKSPACE"] {
            self.isUnderUITest = true
            self.workspaceURL = URL(fileURLWithPath: fixturePath)
        } else {
            self.isUnderUITest = false
            if let storedPath = UserDefaults.standard.string(forKey: "workspacePath") {
                self.workspaceURL = URL(fileURLWithPath: storedPath)
            }
        }
        reloadCourses()
    }

    // MARK: - Functions

    /// Adopts a new working folder, validates it, and remembers it.
    func chooseWorkspace(at url: URL) {
        workspaceURL = url
        if !isUnderUITest {
            UserDefaults.standard.set(url.path, forKey: "workspacePath")
        }
        reloadCourses()
    }

    /// Scans `<workspace>/courses/` for course folders containing a
    /// `course_config.json` and loads each one.
    func reloadCourses() {
        courses = []
        workspaceProblem = nil
        workspaceCanBeInitialized = false
        workspaceIsUnrecognized = false

        guard let workspaceURL else {
            return
        }

        let fileManager: FileManager = FileManager.default
        let previewScriptURL: URL = workspaceURL.appendingPathComponent("preview.sh")
        if !fileManager.fileExists(atPath: previewScriptURL.path) {
            if folderIsEffectivelyEmpty(workspaceURL) {
                // A brand-new folder: offer to set it up rather than
                // presenting an error.
                workspaceCanBeInitialized = true
            } else {
                // Not a working folder: keep the picker up, no error —
                // its own guidance already says what to choose.
                workspaceIsUnrecognized = true
            }
            return
        }

        guard let coursesDirectoryURL else {
            return
        }
        if !fileManager.fileExists(atPath: coursesDirectoryURL.path) {
            workspaceProblem = "There are no courses in this folder yet. Click New Course to create your first one."
            return
        }

        var loadedCourses: [Course] = []
        var entryURLs: [URL] = []
        do {
            entryURLs = try fileManager.contentsOfDirectory(
                at: coursesDirectoryURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            workspaceProblem = "Could not read the courses folder: \(error.localizedDescription)"
            return
        }

        for entryURL in entryURLs {
            let configURL: URL = entryURL.appendingPathComponent("course_config.json")
            if !fileManager.fileExists(atPath: configURL.path) {
                continue
            }
            do {
                let configuration: CourseConfiguration = try CourseConfiguration(contentsOf: configURL)
                let course: Course = Course(
                    code: entryURL.lastPathComponent,
                    directoryURL: entryURL,
                    configuration: configuration
                )
                loadedCourses.append(course)
            } catch {
                // A malformed config should not hide every other course.
                continue
            }
        }

        // Sort courses alphabetically by code for a stable sidebar.
        loadedCourses.sort { firstCourse, secondCourse in
            return firstCourse.code < secondCourse.code
        }
        courses = loadedCourses
    }

    /// Sets up an empty folder as a fresh working folder: copies the
    /// bundled launcher scripts in (the same files the Docker image's
    /// export-scripts command delivers), marks them executable, creates
    /// `courses/`, and opens the New Course wizard.
    func initializeWorkspace() {
        guard let workspaceURL else {
            return
        }
        let fileManager: FileManager = FileManager.default

        let scriptNames: [String] = ["setup.sh", "preview.sh", "deploy.sh"]
        for scriptName in scriptNames {
            guard let bundledURL = Bundle.main.url(forResource: scriptName, withExtension: nil) else {
                workspaceProblem = "Part of the app’s built-in setup files is missing (\(scriptName)) — please reinstall the app."
                return
            }
            let destinationURL: URL = workspaceURL.appendingPathComponent(scriptName)
            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.copyItem(at: bundledURL, to: destinationURL)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destinationURL.path)
            } catch {
                workspaceProblem = "Could not set up this folder: \(error.localizedDescription)"
                return
            }
        }

        do {
            try fileManager.createDirectory(
                at: workspaceURL.appendingPathComponent("courses"),
                withIntermediateDirectories: true
            )
        } catch {
            workspaceProblem = "Could not create the courses folder: \(error.localizedDescription)"
            return
        }

        reloadCourses()

        // The natural next step in a fresh folder is creating a course.
        if workspaceProblem == nil {
            isShowingNewCourseWizard = true
        }
    }

    /// True when the folder contains nothing but ignorable clutter
    /// (e.g. the .DS_Store file Finder sprinkles around).
    private func folderIsEffectivelyEmpty(_ folderURL: URL) -> Bool {
        let fileManager: FileManager = FileManager.default
        var entryNames: [String] = []
        do {
            entryNames = try fileManager.contentsOfDirectory(atPath: folderURL.path)
        } catch {
            return false
        }
        for entryName in entryNames {
            if entryName == ".DS_Store" {
                continue
            }
            return false
        }
        return true
    }
}
