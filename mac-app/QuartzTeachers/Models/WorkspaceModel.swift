import AppKit
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

    /// Where the last-used folder is remembered. Injected so a test can
    /// never write into the real preferences — which is how a test run used
    /// to leave the app pointing at a deleted temporary folder.
    private let defaults: UserDefaults

    /// The key holding the most recently chosen folder.
    static let storedPathKey: String = "workspacePath"

    /// True when the hosted test suite is running. Tests drive the real
    /// window, and must not leave the teacher pointed at a fixture folder
    /// that is deleted when the run ends.
    static let isRunningTests: Bool = NSClassFromString("XCTestCase") != nil

    /// The models belonging to open windows, in the order they appeared.
    /// Windows register themselves so the in-app tests can drive the real
    /// interface rather than a model nothing is showing.
    static private(set) var windowModels: [WorkspaceModel] = []

    /// The working folder of the window most recently key, so a new window
    /// can open where the teacher just was.
    static var mostRecentKeyFolderPath: String?

    /// Takes the folder a brand-new window should open in, right now — the
    /// key window's. Only for MID-SESSION windows: the restoration claims
    /// have closed, so there is nothing to wait for, and deciding before
    /// the first frame renders is what keeps the picker from flashing. At
    /// launch this does nothing; the folder waits for the window claims,
    /// which need the window's settled frame.
    func adoptFolderForNewWindow() {
        guard workspaceURL == nil else {
            return
        }
        guard Date() > WindowFolderMemory.claimsOpenUntil else {
            return
        }
        var otherOpenFolderPaths: [String] = []
        for existing in WorkspaceModel.windowModels {
            if existing !== self, let path = existing.workspaceURL?.path {
                otherOpenFolderPaths.append(path)
            }
        }
        if let path = WorkspaceModel.folderForNewWindow(
            otherOpenFolderPaths: otherOpenFolderPaths,
            mostRecentKeyPath: WorkspaceModel.mostRecentKeyFolderPath
        ) {
            adoptRestoredPath(path)
        }
    }

    /// What a brand-new window should open to. With no other windows open,
    /// nothing — the folder picker. Otherwise the folder of the window
    /// that was key when the command ran, falling back to any open
    /// window's folder if the remembered key folder is no longer among
    /// them.
    static func folderForNewWindow(otherOpenFolderPaths: [String], mostRecentKeyPath: String?) -> String? {
        if otherOpenFolderPaths.isEmpty {
            return nil
        }
        if let mostRecentKeyPath, otherOpenFolderPaths.contains(mostRecentKeyPath) {
            return mostRecentKeyPath
        }
        return otherOpenFolderPaths[0]
    }

    static func registerWindowModel(_ model: WorkspaceModel) {
        for existing in windowModels {
            if existing === model {
                return
            }
        }
        windowModels.append(model)
    }

    /// True once the app has begun quitting. Windows closing as part of
    /// the quit must not rewrite the remembered list — that is the list
    /// the next launch restores from.
    static var isTerminating: Bool = false

    /// A window has closed, so it should no longer be remembered as open.
    static func unregisterWindowModel(_ model: WorkspaceModel) {
        if isTerminating {
            return
        }
        var remaining: [WorkspaceModel] = []
        for existing in windowModels {
            if existing !== model {
                remaining.append(existing)
            }
        }
        windowModels = remaining
        rememberOpenFolders()
        if let path = model.workspaceURL?.path {
            releaseFolderIfUnused(path)
        }
    }

    /// True while some open window is working in this folder.
    static func folderIsInUse(_ path: String) -> Bool {
        for model in windowModels {
            if model.workspaceURL?.path == path {
                return true
            }
        }
        return false
    }

    /// Lets a folder's container rest once no window is using the folder.
    static func releaseFolderIfUnused(_ path: String) {
        if folderIsInUse(path) {
            return
        }
        FolderContainers.stopContainer(forFolder: path)
    }

    /// Writes down which folder each open window is in, paired with the
    /// window's frame so a restored window can find its own.
    static func rememberOpenFolders(defaults: UserDefaults = UserDefaults.standard) {
        var entries: [WindowFolderMemory.Entry] = []
        for model in windowModels {
            if let path = model.workspaceURL?.path {
                let frame: String = model.window.map { NSStringFromRect($0.frame) } ?? ""
                entries.append(WindowFolderMemory.Entry(
                    path: path,
                    frame: frame,
                    expandedCourses: model.expandedCourseCodes.sorted(),
                    archivedExpanded: model.isShowingArchived,
                    backupsExpanded: model.isShowingBackups,
                    selection: model.selection?.storageValue ?? ""
                ))
            }
        }
        WindowFolderMemory.record(entries, defaults: defaults)
    }

    /// The active working folder, or nil before one has been chosen.
    var workspaceURL: URL?

    /// True while this window is still waiting to learn which restored
    /// folder is its own — the brief moment between launch and the claim
    /// resolving. While true, the window shows a quiet holding view
    /// instead of flashing the folder picker it is about to replace.
    var isResolvingRestoredFolder: Bool = false

    /// Which courses' sidebar disclosure triangles are open, and whether
    /// the Archived group is — per window, remembered with the folder so
    /// a restored window shows the same courses unfolded.
    var expandedCourseCodes: Set<String> = []
    var isShowingArchived: Bool = false

    /// The window this model belongs to, once it is on screen. Used only
    /// to read the frame; never retained.
    @ObservationIgnored weak var window: NSWindow?

    /// True while the New Course wizard sheet should be shown.
    var isShowingNewCourseWizard: Bool = false

    /// The courses discovered inside `<workspace>/courses/`.
    var courses: [Course] = []

    /// Courses and sections the teacher has removed, newest first.
    var archivedItems: [ArchivedItem] = []

    /// The archived item a confirmation is being shown for, if any.
    var restoreRequest: ArchivedItem?

    /// The archived item a DELETE confirmation is being shown for, if any.
    var archiveDeleteRequest: ArchivedItem?

    /// Why a restore could not go ahead, shown as an alert.
    var restoreProblem: String?

    /// Saved copies of whole courses, newest first.
    var backupItems: [BackupItem] = []

    /// Whether the sidebar's Backups group is open.
    var isShowingBackups: Bool = false

    /// The backup a restore confirmation is being shown for, if any.
    var backupRestoreRequest: BackupItem?

    /// The backup a delete confirmation is being shown for, if any.
    var backupDeleteRequest: BackupItem?

    /// Why a backup action could not go ahead, shown as an alert.
    var backupProblem: String?

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
        case .archived:
            // An archived item belongs to no live course.
            selectedCode = nil
        case .backup:
            // A backup is a copy, not the live course itself.
            selectedCode = nil
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

    init(defaults: UserDefaults = UserDefaults.standard) {
        self.defaults = defaults
        // A UI test can point the app at a fixture folder via the
        // environment, which also keeps test runs out of the preferences.
        let environment: [String: String] = ProcessInfo.processInfo.environment
        if let fixturePath = environment["UITEST_WORKSPACE"] {
            self.isUnderUITest = true
            self.workspaceURL = URL(fileURLWithPath: fixturePath)
        } else {
            self.isUnderUITest = false
            WorkspaceModel.migratePreferencesFromOldName(into: defaults)
            // No folder is adopted here. A RESTORED window's folder arrives
            // through the window claims; a brand-new window inherits from
            // the window that was key when it was opened, or — when it is
            // the only window — starts with the picker. The last-chosen
            // path stays recorded for migration, but a lone new window
            // silently opening on whatever folder was used last proved
            // surprising.
        }
        reloadCourses()
    }

    /// Whether this model may record the folder for next time.
    ///
    /// A test may exercise remembering with a store of its own, but nothing
    /// under test may write the REAL preference — that is how a test run
    /// used to leave the app pointing at a deleted fixture folder.
    private var canRememberChoice: Bool {
        if isUnderUITest {
            return false
        }
        if WorkspaceModel.isRunningTests && defaults === UserDefaults.standard {
            return false
        }
        return true
    }

    /// Brings settings across from the app's earlier bundle identifier
    /// (ca.russellgordon.QuartzTeachers), once, so renaming the app does
    /// not cost anyone their working folder or remembered windows.
    static func migratePreferencesFromOldName(into defaults: UserDefaults) {
        if isRunningTests || defaults != UserDefaults.standard {
            return
        }
        if defaults.string(forKey: storedPathKey) != nil {
            return
        }
        guard let old = UserDefaults(suiteName: "ca.russellgordon.QuartzTeachers") else {
            return
        }
        if let path = old.string(forKey: storedPathKey) {
            defaults.set(path, forKey: storedPathKey)
        }
        if let folders = old.array(forKey: WindowFolderMemory.storageKey) {
            defaults.set(folders, forKey: WindowFolderMemory.storageKey)
        }
    }

    /// True when a folder is actually there to be worked in.
    static func folderExists(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists: Bool = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    // MARK: - Functions

    /// Adopts a new working folder, validates it, and remembers it.
    func chooseWorkspace(at url: URL) {
        let previousPath: String? = workspaceURL?.path
        workspaceURL = url
        if canRememberChoice {
            // Remembered app-wide so a NEW window opens where the last one
            // left off; each window then keeps its own choice in its scene.
            defaults.set(url.path, forKey: WorkspaceModel.storedPathKey)
        }
        reloadCourses()
        if let previousPath, previousPath != url.path {
            WorkspaceModel.releaseFolderIfUnused(previousPath)
        }
    }

    /// Adopts the folder a window remembered from its last session.
    ///
    /// Windows are restored one by one, each with its own saved folder, so
    /// this runs per window rather than once for the app.
    func adoptRestoredPath(_ path: String) {
        if path.isEmpty || isUnderUITest {
            return
        }
        if !WorkspaceModel.folderExists(atPath: path) {
            return
        }
        if workspaceURL?.path == path {
            return
        }
        workspaceURL = URL(fileURLWithPath: path)
        reloadCourses()
    }

    /// Keeps this folder's launcher scripts current.
    ///
    /// A working folder carries its own copy of the launchers, taken when
    /// the folder was set up — and a copy taken once is a copy that goes
    /// stale, exactly as the image and the container used to. Whenever the
    /// app works in a folder, any launcher that differs from the app's
    /// bundled (current) copy is replaced. These are toolchain files, not
    /// the teacher's own work, so replacing them is correct.
    func refreshLaunchersIfNeeded() {
        guard let workspaceURL else {
            return
        }
        // Test fixtures use stub launchers on purpose; leave them alone.
        if isUnderUITest || WorkspaceModel.isRunningTests {
            return
        }
        var sources: [String: URL] = [:]
        for scriptName in ["setup.sh", "preview.sh", "deploy.sh"] {
            if let bundledURL = Bundle.main.url(forResource: scriptName, withExtension: nil) {
                sources[scriptName] = bundledURL
            }
        }
        let refreshed: [String] = WorkspaceModel.refreshLaunchers(in: workspaceURL, from: sources)
        if !refreshed.isEmpty {
            AppLog.interface.info("refreshed launchers in \(workspaceURL.path, privacy: .public): \(refreshed.joined(separator: ", "), privacy: .public)")
        }
        refreshToolchain(in: workspaceURL)
    }

    /// Keeps the folder's `.toolchain/` — the recipe the image is built
    /// from — mirroring the app's bundled copy. The launchers hash this
    /// folder to name the image, so a changed recipe rebuilds the image
    /// and, through the image-mismatch check, recreates the container.
    /// One updater (the app) now drives every layer.
    func refreshToolchain(in workspaceURL: URL) {
        let fileManager: FileManager = FileManager.default
        // Only a folder that is already a workspace gets a toolchain.
        if !fileManager.fileExists(atPath: workspaceURL.appendingPathComponent("preview.sh").path) {
            return
        }
        let toolchainURL: URL = workspaceURL.appendingPathComponent(".toolchain")

        var changed: Int = 0
        var rootFiles: [String] = ["Dockerfile"]
        rootFiles += ["setup.sh", "preview.sh", "deploy.sh"]
        rootFiles += ["setup.bat", "preview.bat", "deploy.bat"]
        rootFiles += ["setup.ps1", "preview.ps1", "deploy.ps1"]
        for name in rootFiles {
            if let sourceURL = Bundle.main.url(forResource: name, withExtension: nil) {
                changed += WorkspaceModel.syncFile(from: sourceURL, to: toolchainURL.appendingPathComponent(name))
            }
        }
        // Whole folders, mirrored (extraneous files removed — they would
        // change the hash and force rebuilds for nothing).
        for folderName in ["patches", "scripts", "support"] {
            if let sourceURL = Bundle.main.url(forResource: folderName, withExtension: nil) {
                changed += WorkspaceModel.syncDirectory(from: sourceURL, to: toolchainURL.appendingPathComponent(folderName))
            }
        }
        if changed > 0 {
            AppLog.interface.info("refreshed .toolchain in \(workspaceURL.path, privacy: .public): \(changed) file(s)")
        }
    }

    /// Copies one file when the destination differs or is missing.
    static func syncFile(from sourceURL: URL, to destinationURL: URL) -> Int {
        let fileManager: FileManager = FileManager.default
        guard let sourceData = try? Data(contentsOf: sourceURL) else {
            return 0
        }
        if let existing = try? Data(contentsOf: destinationURL), existing == sourceData {
            return 0
        }
        do {
            try fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try sourceData.write(to: destinationURL, options: [.atomic])
            if destinationURL.pathExtension == "sh" {
                try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destinationURL.path)
            }
            return 1
        } catch {
            return 0
        }
    }

    /// Mirrors a directory: copies what differs, removes what should not
    /// be there. Returns how many files changed either way.
    static func syncDirectory(from sourceURL: URL, to destinationURL: URL) -> Int {
        let fileManager: FileManager = FileManager.default
        var changed: Int = 0

        var sourceFiles: [String] = []
        if let enumerator = fileManager.enumerator(at: sourceURL, includingPropertiesForKeys: [.isRegularFileKey]) {
            for case let fileURL as URL in enumerator {
                let isFile: Bool = (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false
                if isFile {
                    let relative: String = String(fileURL.path.dropFirst(sourceURL.path.count + 1))
                    sourceFiles.append(relative)
                    changed += WorkspaceModel.syncFile(from: fileURL, to: destinationURL.appendingPathComponent(relative))
                }
            }
        }

        if let enumerator = fileManager.enumerator(at: destinationURL, includingPropertiesForKeys: [.isRegularFileKey]) {
            var toRemove: [URL] = []
            for case let fileURL as URL in enumerator {
                let isFile: Bool = (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false
                if isFile {
                    let relative: String = String(fileURL.path.dropFirst(destinationURL.path.count + 1))
                    if !sourceFiles.contains(relative) {
                        toRemove.append(fileURL)
                    }
                }
            }
            for fileURL in toRemove {
                try? fileManager.removeItem(at: fileURL)
                changed += 1
            }
        }
        return changed
    }

    /// Replaces any launcher whose content differs from the current copy.
    /// Only files that already exist are touched: a folder without
    /// launchers is a folder that has not been initialized, which is the
    /// picker's business, not this method's.
    static func refreshLaunchers(in workspaceURL: URL, from sources: [String: URL]) -> [String] {
        let fileManager: FileManager = FileManager.default
        var refreshed: [String] = []
        for (scriptName, sourceURL) in sources {
            let destinationURL: URL = workspaceURL.appendingPathComponent(scriptName)
            if !fileManager.fileExists(atPath: destinationURL.path) {
                continue
            }
            guard let current = try? Data(contentsOf: sourceURL),
                  let existing = try? Data(contentsOf: destinationURL) else {
                continue
            }
            if current == existing {
                continue
            }
            do {
                try current.write(to: destinationURL, options: [.atomic])
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destinationURL.path)
                refreshed.append(scriptName)
            } catch {
                // A read-only folder is unusual but not fatal: the stale
                // script will fail loudly on its own if it matters.
                continue
            }
        }
        return refreshed.sorted()
    }

    /// Scans `<workspace>/courses/` for course folders containing a
    /// `course_config.json` and loads each one.
    func reloadCourses() {
        courses = []
        archivedItems = []
        workspaceProblem = nil
        refreshLaunchersIfNeeded()
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
        archivedItems = WorkspaceModel.findArchivedItems(in: coursesDirectoryURL)
        backupItems = WorkspaceModel.findBackupItems(in: coursesDirectoryURL)
    }

    /// The archived item matching a sidebar selection, if that is what is
    /// selected.
    var selectedArchivedItem: ArchivedItem? {
        guard case .archived(let identifier) = selection else {
            return nil
        }
        for item in archivedItems {
            if item.id == identifier {
                return item
            }
        }
        return nil
    }

    /// Brings an archived course or section back, then reloads so the
    /// sidebar shows it in its proper place.
    func restore(_ item: ArchivedItem) {
        guard let coursesDirectoryURL else {
            return
        }
        do {
            try CourseRestorer.restore(item, coursesDirectoryURL: coursesDirectoryURL, courses: courses)
        } catch {
            restoreProblem = error.localizedDescription
            return
        }
        selection = nil
        reloadCourses()
        if let sectionNumber = item.sectionNumber {
            selection = SidebarSelection.section(item.courseCode, sectionNumber)
        } else {
            selection = SidebarSelection.course(item.courseCode)
        }
    }

    /// The backup matching a sidebar selection, if that is what is
    /// selected.
    var selectedBackupItem: BackupItem? {
        guard case .backup(let identifier) = selection else {
            return nil
        }
        for item in backupItems {
            if item.id == identifier {
                return item
            }
        }
        return nil
    }

    /// Saves a copy of a whole course, then reloads so the Backups group
    /// shows it — opened, so the new row is visible feedback.
    func backUp(_ course: Course) {
        guard let coursesDirectoryURL else {
            return
        }
        do {
            try CourseArchiver.backUpCourse(course, coursesDirectoryURL: coursesDirectoryURL)
        } catch {
            backupProblem = error.localizedDescription
            return
        }
        isShowingBackups = true
        reloadCourses()
    }

    /// Puts a backed-up course back in place of the current one. The
    /// current version is ARCHIVED first — even a restore has an undo —
    /// and the backup itself stays until the teacher deletes it.
    func restoreBackup(_ item: BackupItem) {
        guard let coursesDirectoryURL else {
            return
        }
        if let workspacePath = workspaceURL?.path {
            if CourseActivity.courseIsBusy(folderPath: workspacePath, courseCode: item.courseCode) {
                backupProblem = "\(item.courseCode) is previewing or publishing right now. Stop that first, then restore."
                return
            }
        }
        do {
            // Archive WITHOUT removing: the restore replaces the course's
            // contents in place, so Obsidian's file watcher — anchored to
            // the course folder, which is the vault — keeps up instead of
            // showing stale files until the vault is reopened.
            for course in courses {
                if course.code == item.courseCode {
                    try CourseArchiver.archiveCourse(course, coursesDirectoryURL: coursesDirectoryURL)
                }
            }
            try CourseRestorer.restoreBackup(item, coursesDirectoryURL: coursesDirectoryURL)
        } catch {
            backupProblem = error.localizedDescription
            reloadCourses()
            return
        }
        selection = nil
        reloadCourses()
        selection = SidebarSelection.course(item.courseCode)
    }

    /// Deletes a backup for good — no archive behind it, which is why
    /// its confirmation says so.
    func deleteBackup(_ item: BackupItem) {
        do {
            try FileManager.default.removeItem(at: item.fileURL)
        } catch {
            backupProblem = error.localizedDescription
            return
        }
        if selection == SidebarSelection.backup(item.id) {
            selection = nil
        }
        reloadCourses()
    }

    /// What deleting an archive would leave behind, so the confirmation
    /// can state a fact instead of an "if".
    enum ArchiveStanding {
        /// The archived course or section is still in Courses & Clubs.
        case liveInCourses
        /// It is gone from Courses & Clubs, but another archive or a
        /// backup still covers it.
        case otherCopiesRemain
        /// It is gone, and this archive is the only copy left anywhere.
        case onlyRemainingCopy
    }

    func archiveStanding(_ item: ArchivedItem) -> ArchiveStanding {
        return WorkspaceModel.archiveStanding(
            item, among: courses, archives: archivedItems, backups: backupItems
        )
    }

    static func archiveStanding(
        _ item: ArchivedItem,
        among courses: [Course],
        archives: [ArchivedItem],
        backups: [BackupItem]
    ) -> ArchiveStanding {
        for course in courses {
            if course.code == item.courseCode {
                guard let sectionNumber = item.sectionNumber else {
                    return .liveInCourses
                }
                if course.sectionNumbers.contains(sectionNumber) {
                    return .liveInCourses
                }
            }
        }
        for other in archives {
            if other.id == item.id || other.courseCode != item.courseCode {
                continue
            }
            // A whole-course archive covers every section; a section
            // archive covers only its own section. A section archive
            // never covers a whole-course one.
            if other.sectionNumber == nil || other.sectionNumber == item.sectionNumber {
                return .otherCopiesRemain
            }
        }
        for backup in backups {
            if backup.courseCode == item.courseCode {
                return .otherCopiesRemain
            }
        }
        return .onlyRemainingCopy
    }

    /// Deletes an archive for good. The promise made at removal time —
    /// "nothing is deleted" — was about REMOVING; this is a second,
    /// deliberate act with its own plain-spoken confirmation.
    func deleteArchive(_ item: ArchivedItem) {
        do {
            try FileManager.default.removeItem(at: item.fileURL)
        } catch {
            backupProblem = error.localizedDescription
            return
        }
        if selection == SidebarSelection.archived(item.id) {
            selection = nil
        }
        reloadCourses()
    }

    /// Finds the teacher's saved backups, newest first.
    static func findBackupItems(in coursesDirectoryURL: URL) -> [BackupItem] {
        let fileManager: FileManager = FileManager.default
        let backupsRoot: URL = coursesDirectoryURL.appendingPathComponent("_backups")
        var found: [BackupItem] = []

        guard let courseFolders = try? fileManager.contentsOfDirectory(
            at: backupsRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return found
        }

        for courseFolder in courseFolders {
            let courseCode: String = courseFolder.lastPathComponent
            guard let zips = try? fileManager.contentsOfDirectory(
                at: courseFolder,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }
            for zipURL in zips {
                if let item = BackupItem.from(fileURL: zipURL, courseCode: courseCode) {
                    found.append(item)
                }
            }
        }

        found.sort { first, second in
            return first.backedUpAt > second.backedUpAt
        }
        return found
    }

    /// Finds what the teacher has archived, newest first.
    ///
    /// Archives live beside each course's automatic backups; only the ones
    /// named after what was removed belong here — see `ArchivedItem`.
    static func findArchivedItems(in coursesDirectoryURL: URL) -> [ArchivedItem] {
        let fileManager: FileManager = FileManager.default
        let archivesRoot: URL = coursesDirectoryURL.appendingPathComponent("_backups")
        var found: [ArchivedItem] = []

        guard let courseFolders = try? fileManager.contentsOfDirectory(
            at: archivesRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return found
        }

        for courseFolder in courseFolders {
            let courseCode: String = courseFolder.lastPathComponent
            guard let archives = try? fileManager.contentsOfDirectory(
                at: courseFolder,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }
            for archiveURL in archives {
                if let item = ArchivedItem.from(fileURL: archiveURL, courseCode: courseCode) {
                    found.append(item)
                }
            }
        }

        found.sort { first, second in
            return first.archivedAt > second.archivedAt
        }
        return found
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
