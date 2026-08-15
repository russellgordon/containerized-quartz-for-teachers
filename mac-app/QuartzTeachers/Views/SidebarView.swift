import AppKit
import SwiftUI

/// The "Courses & Clubs" sidebar: each course expands to show its
/// sections, with the add/remove/filter bar macOS lists conventionally
/// carry along their bottom edge.
struct SidebarView: View {

    // MARK: - Stored properties

    @Environment(WorkspaceModel.self) var workspace

    /// Opens the assistant, which is a window of its own rather than a sheet.
    @Environment(\.openWindow) var openWindow

    /// The item the remove button is asking about, if any.
    @State var removalRequest: RemovalRequest?

    /// A failure while archiving, shown as an alert.
    @State var removalProblem: String?

    /// The footer's height, growing with the system text size so the bar
    /// and the path bar opposite it stay the same height.
    @ScaledMetric(relativeTo: .body) var scaledFooterHeight: CGFloat = WindowChrome.footerHeight

    // The Archived group and the course disclosure triangles keep their
    // open/closed state on the WINDOW's model, not view-locally: the
    // window remembers them with its folder, so a restored window shows
    // the same courses unfolded that were being worked on.

    /// The course "Add Section…" was chosen on, while its sheet is up.
    @State var addSectionCourse: Course?

    /// The section "Schedule Deploy…" was chosen on, while its sheet is up.
    @State var scheduleRequest: ScheduledDeployRequest?

    /// The scheduled deploy the teacher is being asked about cancelling.
    @State var cancelScheduleRequest: ScheduledDeployRequest?

    /// Bumped whenever a deploy is scheduled or cancelled. The rows read
    /// launchd rather than a stored list, and nothing about a file in
    /// `~/Library/LaunchAgents` is observable, so this is what tells the
    /// sidebar its answer has gone stale.
    @State var scheduleGeneration: Int = 0

    /// Why a scheduled deploy could not be cancelled, shown as an alert.
    @State var scheduleProblem: String?

    // MARK: - Body

    var body: some View {
        @Bindable var workspace = workspace

        VStack(spacing: 0) {
            List(selection: $workspace.selection) {
                Section("Courses & Clubs") {
                    ForEach(workspace.filteredCourses) { course in
                        DisclosureGroup(isExpanded: expansionBinding(for: course.code)) {
                            ForEach(course.sectionNumbers, id: \.self) { sectionNumber in
                                // Asked of launchd during the row's render,
                                // not kept as a note of ours: the teacher can
                                // delete the agent themselves, and a clock
                                // promising a deploy that will never happen is
                                // worse than no clock. `scheduleGeneration`
                                // makes the row read it again after a change.
                                let scheduledFor: Date? = scheduledDeployTime(
                                    courseCode: course.code,
                                    sectionNumber: sectionNumber,
                                    generation: scheduleGeneration
                                )
                                sectionRowLabel(sectionNumber: sectionNumber, scheduledFor: scheduledFor)
                                    .tag(SidebarSelection.section(course.code, sectionNumber))
                                    .accessibilityIdentifier("sidebar-\(course.code)-section\(sectionNumber)")
                                    .contextMenu {
                                        // The assistant sits at the TOP, in a
                                        // group of its own. It is the item a
                                        // teacher comes to this menu for most
                                        // often, and burying it under the
                                        // editing and folder actions made it
                                        // read as an afterthought.
                                        reviseWithAIItem(course: course, sectionNumber: sectionNumber)
                                        Divider()
                                        openInObsidianItem(
                                            revealing: course.sectionDirectoryURL(forSection: sectionNumber),
                                            vaultURL: course.directoryURL
                                        )
                                        Divider()
                                        // One item or the other, never a
                                        // greyed-out line — a menu that
                                        // teaches teachers to stop reading it
                                        // is worse than a shorter menu.
                                        if let scheduledFor {
                                            Button("Cancel Deploy at \(ScheduledDeploy.timeText(scheduledFor))…", systemImage: "clock") {
                                                cancelScheduleRequest = ScheduledDeployRequest(
                                                    course: course,
                                                    sectionNumber: sectionNumber,
                                                    when: scheduledFor
                                                )
                                            }
                                            .accessibilityIdentifier("cancelScheduledDeploy-\(course.code)-section\(sectionNumber)")
                                        } else {
                                            Button("Schedule Deploy…", systemImage: "clock") {
                                                scheduleRequest = ScheduledDeployRequest(
                                                    course: course,
                                                    sectionNumber: sectionNumber,
                                                    when: nil
                                                )
                                            }
                                            .accessibilityIdentifier("scheduleDeploy-\(course.code)-section\(sectionNumber)")
                                        }
                                        Divider()
                                        folderMenuItems(for: course.sectionDirectoryURL(forSection: sectionNumber))
                                    }
                            }
                        } label: {
                            // Read the busy state HERE, during the row's
                            // render: the registries are observable, so
                            // the row redraws — menu included — the
                            // moment a preview or publish starts or
                            // stops. Reading it only inside the menu
                            // closure left the menu showing the state
                            // from whenever the row last drew.
                            let busyReason: String? = busyReason(for: course)
                            Label(course.code, systemImage: "books.vertical")
                                .tag(SidebarSelection.course(course.code))
                                .accessibilityIdentifier("sidebar-\(course.code)")
                                .contextMenu {
                                    openInObsidianItem(revealing: course.directoryURL, vaultURL: course.directoryURL)
                                    Divider()
                                    // Adding a section re-runs the course
                                    // setup, which rewrites the course's
                                    // folders — never while a preview or
                                    // publish could be reading them.
                                    Button("Add Section…", systemImage: "doc.badge.plus") {
                                        addSectionCourse = course
                                    }
                                    .disabled(busyReason != nil)
                                    if let busyReason {
                                        Text(busyReason)
                                    }
                                    Divider()
                                    // Backing up only READS the course, so
                                    // it stays available even mid-preview —
                                    // the moment before risky editing is
                                    // exactly when it's wanted.
                                    Button("Back Up Now", systemImage: "clock.arrow.circlepath") {
                                        workspace.backUp(course)
                                    }
                                    Divider()
                                    folderMenuItems(for: course.directoryURL)
                                }
                        }
                    }
                }

                if !workspace.backupItems.isEmpty {
                    // Saved copies of whole courses, above Archived: these
                    // are safety nets the teacher made on purpose, not
                    // things put away.
                    Section(isExpanded: $workspace.isShowingBackups) {
                        ForEach(workspace.backupItems) { item in
                            Label(item.title, systemImage: item.symbolName)
                                .help(item.subtitle)
                                .tag(SidebarSelection.backup(item.id))
                                .accessibilityIdentifier("backup-\(item.id)")
                                .contextMenu {
                                    Button("Restore…", systemImage: "arrow.uturn.backward") {
                                        workspace.backupRestoreRequest = item
                                    }
                                    Button("Show in Finder", systemImage: "finder") {
                                        NSWorkspace.shared.activateFileViewerSelecting([item.fileURL])
                                    }
                                    Divider()
                                    Button("Delete Backup…", systemImage: "trash", role: .destructive) {
                                        workspace.backupDeleteRequest = item
                                    }
                                }
                        }
                    } header: {
                        Text("Backups")
                            .accessibilityIdentifier("backupsGroup")
                    }
                }

                if !workspace.archivedItems.isEmpty {
                    // A collapsible section header, the way Finder's
                    // "Locations" behaves: the chevron appears on hover, and
                    // the rows beneath read like any other sidebar row.
                    Section(isExpanded: $workspace.isShowingArchived) {
                        ForEach(workspace.archivedItems) { item in
                            Label(item.title, systemImage: item.symbolName)
                                .help(item.subtitle)
                                .tag(SidebarSelection.archived(item.id))
                                .accessibilityIdentifier("archived-\(item.id)")
                                .contextMenu {
                                    Button("Restore…", systemImage: "arrow.uturn.backward") {
                                        workspace.restoreRequest = item
                                    }
                                    Button("Show in Finder", systemImage: "finder") {
                                        NSWorkspace.shared.activateFileViewerSelecting([item.fileURL])
                                    }
                                    Divider()
                                    Button("Delete Archive…", systemImage: "trash", role: .destructive) {
                                        workspace.archiveDeleteRequest = item
                                    }
                                }
                        }
                    } header: {
                        Text("Archived")
                            .accessibilityIdentifier("archivedGroup")
                    }
                }
            }
            .listStyle(.sidebar)
            .accessibilityIdentifier("coursesSidebar")
            .onChange(of: workspace.expandedCourseCodes) {
                WorkspaceModel.rememberOpenFolders()
            }
            .onChange(of: workspace.isShowingArchived) {
                WorkspaceModel.rememberOpenFolders()
            }
            .onChange(of: workspace.isShowingBackups) {
                WorkspaceModel.rememberOpenFolders()
            }
            .onChange(of: workspace.selection) {
                WorkspaceModel.rememberOpenFolders()
            }
            .overlay {
                if showsNoFilterMatches {
                    ContentUnavailableView {
                        Label("No Matches", systemImage: "magnifyingglass")
                    } description: {
                        Text("No course or club matches “\(workspace.filterText)”.")
                    }
                    .accessibilityIdentifier("noFilterMatchesMessage")
                }
            }

            Divider()

            bottomBar
        }
        .alert(
            removalRequest?.title ?? "",
            isPresented: removalRequestIsPresented,
            presenting: removalRequest
        ) { request in
            Button("Remove", role: .destructive) {
                performRemoval(request)
            }
            Button("Cancel", role: .cancel) {
            }
        } message: { request in
            Text(request.message)
        }
        .alert(
            "Restore \(workspace.restoreRequest?.title ?? "")?",
            isPresented: restoreRequestIsPresented,
            presenting: workspace.restoreRequest
        ) { item in
            Button("Restore") {
                workspace.restore(item)
            }
            Button("Cancel", role: .cancel) {
            }
        } message: { item in
            Text(restoreMessage(for: item))
        }
        .alert(
            "Restore \(workspace.backupRestoreRequest?.courseCode ?? "") from this backup?",
            isPresented: backupRestoreRequestIsPresented,
            presenting: workspace.backupRestoreRequest
        ) { item in
            Button("Restore") {
                workspace.restoreBackup(item)
            }
            Button("Cancel", role: .cancel) {
            }
        } message: { item in
            Text("""
                \(item.courseCode) goes back to how it was when this backup was made:

                \(item.whenDescription)

                Anything added since then isn’t in the backup.

                Nothing is lost, though: the version you have right now moves to Archived, at the bottom of the sidebar, where you can get it back.

                This backup is kept.
                """)
        }
        .alert(
            "Delete this backup of \(workspace.backupDeleteRequest?.courseCode ?? "")?",
            isPresented: backupDeleteRequestIsPresented,
            presenting: workspace.backupDeleteRequest
        ) { item in
            Button("Delete", role: .destructive) {
                workspace.deleteBackup(item)
            }
            Button("Cancel", role: .cancel) {
            }
        } message: { item in
            Text("""
                This deletes the backup for good — unlike removing a course, nothing is kept.

                \(item.courseCode) itself is not touched.
                """)
        }
        .alert(
            "Delete this archive of \(workspace.archiveDeleteRequest?.title ?? "")?",
            isPresented: archiveDeleteRequestIsPresented,
            presenting: workspace.archiveDeleteRequest
        ) { item in
            Button("Delete", role: .destructive) {
                workspace.deleteArchive(item)
            }
            Button("Cancel", role: .cancel) {
            }
        } message: { item in
            // The app knows what deleting would leave behind — the live
            // course, another archive or backup, or nothing at all — so
            // the warning states a fact, not an "if".
            switch workspace.archiveStanding(item) {
            case .liveInCourses:
                Text("""
                    This deletes the archive for good — nothing is kept.

                    \(item.title) itself is not touched — it’s still in Courses & Clubs.
                    """)
            case .otherCopiesRemain:
                Text("""
                    This deletes the archive for good — nothing is kept.

                    \(item.title) isn’t in Courses & Clubs any more, but this isn’t its only copy — another archive or backup of it remains.
                    """)
            case .onlyRemainingCopy:
                Text("""
                    This deletes the archive for good — nothing is kept.

                    \(item.title) isn’t in Courses & Clubs any more, and this archive is its only remaining copy.
                    """)
            }
        }
        .alert("Could not do that", isPresented: backupProblemBinding) {
            Button("OK") {
                workspace.backupProblem = nil
            }
        } message: {
            Text(workspace.backupProblem ?? "")
        }
        .alert("Could not restore", isPresented: restoreProblemBinding) {
            Button("OK") {
                workspace.restoreProblem = nil
            }
        } message: {
            Text(workspace.restoreProblem ?? "")
        }
        .alert("Could not remove", isPresented: removalProblemBinding) {
            Button("OK") {
                removalProblem = nil
            }
        } message: {
            Text(removalProblem ?? "")
        }
        .sheet(item: $addSectionCourse) { course in
            AddSectionSheet(course: course) { sectionNumber in
                workspace.reloadCourses()
                workspace.selection = SidebarSelection.section(course.code, sectionNumber)
            }
        }
        .sheet(item: $scheduleRequest) { request in
            if let workspaceURL = workspace.workspaceURL {
                ScheduleDeploySheet(
                    course: request.course,
                    sectionNumber: request.sectionNumber,
                    workspaceURL: workspaceURL
                ) {
                    scheduleGeneration += 1
                }
            }
        }
        .alert(
            "Cancel this scheduled deploy?",
            isPresented: cancelScheduleRequestIsPresented,
            presenting: cancelScheduleRequest
        ) { request in
            Button("Cancel It", role: .destructive) {
                cancelScheduledDeploy(request)
            }
            Button("Leave It Scheduled", role: .cancel) {
            }
        } message: { request in
            Text(cancelMessage(for: request))
        }
        .alert("Could not change the scheduled deploy", isPresented: scheduleProblemBinding) {
            Button("OK") {
                scheduleProblem = nil
            }
        } message: {
            Text(scheduleProblem ?? "")
        }
    }

    /// A section's row, wearing a clock when it is set to deploy on its own.
    @ViewBuilder
    func sectionRowLabel(sectionNumber: Int, scheduledFor: Date?) -> some View {
        if let scheduledFor {
            HStack {
                Label("Section \(sectionNumber)", systemImage: "doc.richtext")
                Spacer()
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("scheduledDeployBadge-section\(sectionNumber)")
            }
            .help(SidebarView.scheduledDeployTooltip(for: scheduledFor))
        } else {
            Label("Section \(sectionNumber)", systemImage: "doc.richtext")
        }
    }

    /// How big the footer's +/- targets are. Named so a test can check the
    /// buttons really are this size on screen.
    static let footerButtonSize: CGSize = CGSize(width: 26, height: 24)

    /// The glyph and its target at the SYSTEM text size, scaled from the
    /// base sizes above. A fixed point size ignores Accessibility ▸ Display
    /// ▸ Text size entirely, which would leave someone who enlarges text
    /// with the same small target they had before.
    @ScaledMetric(relativeTo: .body) var scaledGlyphSize: CGFloat = SidebarView.footerGlyphSize
    @ScaledMetric(relativeTo: .body) var scaledButtonWidth: CGFloat = SidebarView.footerButtonSize.width
    @ScaledMetric(relativeTo: .body) var scaledButtonHeight: CGFloat = SidebarView.footerButtonSize.height

    /// How large the +/- glyphs are drawn. SwiftUI's default renders these a
    /// little smaller than the same buttons elsewhere on the system — Xcode's
    /// list footers, for one — so the size is stated rather than inherited.
    static let footerGlyphSize: CGFloat = 15

    /// Add, remove, and filter — the standard macOS list footer.
    var bottomBar: some View {
        @Bindable var workspace = workspace

        return HStack(spacing: 0) {
            // A bare glyph is a tiny target — the minus is barely a few
            // pixels tall. The frame gives each button a real area and
            // contentShape makes the whole of it clickable.
            //
            // Both must be INSIDE the button's label: applied to the button
            // itself, contentShape only reshapes bounds that are already
            // just the glyph, which is why it appeared to do nothing.
            Button {
                workspace.isShowingNewCourseWizard = true
            } label: {
                Label("Add Course or Club", systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .font(.system(size: scaledGlyphSize))
                    .frame(width: scaledButtonWidth, height: scaledButtonHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .help("Add a course or club")
            .accessibilityIdentifier("addCourseButton")

            Button {
                prepareRemoval()
            } label: {
                Label("Remove Selected", systemImage: "minus")
                    .labelStyle(.iconOnly)
                    .font(.system(size: scaledGlyphSize))
                    .frame(width: scaledButtonWidth, height: scaledButtonHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            // An archived item is already put away, so there is nothing
            // for this button to do while one is selected.
            .disabled(workspace.selectedCourse == nil)
            .help("Remove the selected course or section")
            .accessibilityIdentifier("removeSelectedButton")
            .padding(.trailing, 5)

            TextField("Filter", text: $workspace.filterText)
                .textFieldStyle(.roundedBorder)
                .controlSize(.small)
                .accessibilityIdentifier("courseFilterField")
        }
        .padding(.horizontal, 8)
        .frame(height: scaledFooterHeight)
    }

    // MARK: - Computed properties

    /// True when the filter has hidden everything — as against there being
    /// nothing to show in the first place, which the window's own empty
    /// state already explains.
    var showsNoFilterMatches: Bool {
        return SidebarView.showsNoFilterMatches(
            courseCount: workspace.courses.count,
            matchCount: workspace.filteredCourses.count,
            filterText: workspace.filterText
        )
    }

    static func showsNoFilterMatches(courseCount: Int, matchCount: Int, filterText: String) -> Bool {
        if filterText.trimmingCharacters(in: .whitespaces).isEmpty {
            return false
        }
        if courseCount == 0 {
            return false
        }
        return matchCount == 0
    }

    /// What restoring this item will do, said plainly.
    func restoreMessage(for item: ArchivedItem) -> String {
        if let sectionNumber = item.sectionNumber {
            return "Section \(sectionNumber) will be put back into \(item.courseCode), and will no longer be listed as archived."
        }
        return "\(item.courseCode) will be put back into Courses & Clubs, and will no longer be listed as archived."
    }

    var removalRequestIsPresented: Binding<Bool> {
        return Binding(
            get: { removalRequest != nil },
            set: { isPresented in
                if !isPresented {
                    removalRequest = nil
                }
            }
        )
    }

    var restoreRequestIsPresented: Binding<Bool> {
        return Binding(
            get: { workspace.restoreRequest != nil },
            set: { isPresented in
                if !isPresented {
                    workspace.restoreRequest = nil
                }
            }
        )
    }

    var restoreProblemBinding: Binding<Bool> {
        return Binding(
            get: { workspace.restoreProblem != nil },
            set: { isPresented in
                if !isPresented {
                    workspace.restoreProblem = nil
                }
            }
        )
    }

    var backupRestoreRequestIsPresented: Binding<Bool> {
        return Binding(
            get: { workspace.backupRestoreRequest != nil },
            set: { isPresented in
                if !isPresented {
                    workspace.backupRestoreRequest = nil
                }
            }
        )
    }

    var backupDeleteRequestIsPresented: Binding<Bool> {
        return Binding(
            get: { workspace.backupDeleteRequest != nil },
            set: { isPresented in
                if !isPresented {
                    workspace.backupDeleteRequest = nil
                }
            }
        )
    }

    var archiveDeleteRequestIsPresented: Binding<Bool> {
        return Binding(
            get: { workspace.archiveDeleteRequest != nil },
            set: { isPresented in
                if !isPresented {
                    workspace.archiveDeleteRequest = nil
                }
            }
        )
    }

    var backupProblemBinding: Binding<Bool> {
        return Binding(
            get: { workspace.backupProblem != nil },
            set: { isPresented in
                if !isPresented {
                    workspace.backupProblem = nil
                }
            }
        )
    }

    var removalProblemBinding: Binding<Bool> {
        return Binding(
            get: { removalProblem != nil },
            set: { isPresented in
                if !isPresented {
                    removalProblem = nil
                }
            }
        )
    }

    var cancelScheduleRequestIsPresented: Binding<Bool> {
        return Binding(
            get: { cancelScheduleRequest != nil },
            set: { isPresented in
                if !isPresented {
                    cancelScheduleRequest = nil
                }
            }
        )
    }

    var scheduleProblemBinding: Binding<Bool> {
        return Binding(
            get: { scheduleProblem != nil },
            set: { isPresented in
                if !isPresented {
                    scheduleProblem = nil
                }
            }
        )
    }

    // MARK: - Functions

    /// When this section next deploys on its own, or nil when nothing is
    /// scheduled.
    ///
    /// `generation` is not used: it is here so that reading it during the
    /// row's render makes SwiftUI redraw the row when a deploy is
    /// scheduled or cancelled. Without it the clock would appear only
    /// after something else happened to redraw the sidebar.
    func scheduledDeployTime(courseCode: String, sectionNumber: Int, generation: Int) -> Date? {
        _ = generation
        return ScheduledDeploy.nextRun(courseCode: courseCode, sectionNumber: sectionNumber)
    }

    /// What the clock beside a section means, said in full on hover.
    static func scheduledDeployTooltip(for when: Date) -> String {
        return "Deploying on its own at \(ScheduledDeploy.timeText(when)) on \(ScheduledDeploy.dayText(when)). Right-click to cancel. This Mac must be on and awake."
    }

    /// What cancelling would mean, stated rather than implied.
    func cancelMessage(for request: ScheduledDeployRequest) -> String {
        guard let when = request.when else {
            return "This section will no longer deploy on its own."
        }
        return "\(request.course.code) Section \(request.sectionNumber) is set to deploy on its own at \(ScheduledDeploy.timeText(when)) on \(ScheduledDeploy.dayText(when)). Cancelling means it will not go out then, and the site stays as it is until you deploy it yourself."
    }

    func cancelScheduledDeploy(_ request: ScheduledDeployRequest) {
        if let problem = ScheduledDeploy.cancelScheduledDeploy(
            courseCode: request.course.code,
            sectionNumber: request.sectionNumber
        ) {
            scheduleProblem = problem
        }
        scheduleGeneration += 1
    }

    /// Why the course is busy — previewing or publishing, in any window
    /// showing this working folder — or nil when it isn't.
    func busyReason(for course: Course) -> String? {
        guard let workspaceURL = workspace.workspaceURL else {
            return nil
        }
        return CourseActivity.busyDescription(folderPath: workspaceURL.path, courseCode: course.code)
    }

    /// The open/closed state of one course's disclosure triangle, living
    /// on the window's model so restoration can bring it back.
    func expansionBinding(for courseCode: String) -> Binding<Bool> {
        return Binding(
            get: { workspace.expandedCourseCodes.contains(courseCode) },
            set: { isOpen in
                if isOpen {
                    workspace.expandedCourseCodes.insert(courseCode)
                } else {
                    workspace.expandedCourseCodes.remove(courseCode)
                }
            }
        )
    }

    /// The editing action, set apart in its own menu section. The Obsidian
    /// vault is the COURSE folder even for a section row — the section is a
    /// subfolder within it, and Obsidian lands there.
    @ViewBuilder
    func openInObsidianItem(revealing folderURL: URL, vaultURL: URL) -> some View {
        Button("Open in Obsidian", systemImage: "square.and.pencil") {
            FolderActions.openInObsidian(revealing: folderURL, vaultURL: vaultURL)
        }
        .disabled(!FolderActions.obsidianIsInstalled)
    }

    /// Opens the assistant for one section, in a window of its own.
    ///
    /// Offered per SECTION rather than per course because that is the scope
    /// the assistant actually works in: its tools take a course and a section,
    /// and its window names them. A course-level entry point would have to ask
    /// which section first, which is a question the menu has already answered.
    ///
    /// Hidden rather than disabled on a Mac that cannot run it — an Intel Mac
    /// is not going to grow a Metal GPU, so a permanently greyed item would be
    /// a standing invitation to wonder what is wrong.
    @ViewBuilder
    func reviseWithAIItem(course: Course, sectionNumber: Int) -> some View {
        if AssistHardwareBudget.current().canRunAssistant, let folder = workspace.workspaceURL {
            Button("Revise with AI…", systemImage: "sparkles") {
                openWindow(value: AssistWindowRequest(
                    courseCode: course.code,
                    sectionNumber: sectionNumber,
                    workingFolder: folder
                ))
            }
        }
    }

    /// The shared context-menu items for a course or section folder.
    @ViewBuilder
    func folderMenuItems(for folderURL: URL) -> some View {
        Button("Show in Finder", systemImage: "finder") {
            FolderActions.showInFinder(folderURL)
        }
        Button("New Terminal at Folder", systemImage: "terminal") {
            FolderActions.openTerminal(at: folderURL)
        }
    }

    /// Works out what the remove button would do and asks first.
    func prepareRemoval() {
        guard let selection = workspace.selection else {
            return
        }
        guard let course = workspace.selectedCourse else {
            return
        }

        switch selection {
        case .course:
            removalRequest = RemovalRequest(
                courseCode: course.code,
                sectionNumber: nil,
                title: "Remove \(course.code)?",
                message: "Nothing is deleted. \(course.code) and all of its sections move to Archived, at the bottom of the sidebar, where you can get them back."
            )
        case .archived:
            // The minus button removes live courses; an archived item is
            // already put away.
            return
        case .backup:
            // Deleting a backup is a real deletion, so it happens only
            // through its own explicit menu item, never the minus button.
            return
        case .section(_, let sectionNumber):
            if course.sectionNumbers.count <= 1 {
                // Removing the only section leaves nothing behind, so be
                // explicit that this removes the whole course.
                removalRequest = RemovalRequest(
                    courseCode: course.code,
                    sectionNumber: nil,
                    title: "Remove \(course.code)?",
                    message: "Section \(sectionNumber) is the only section of \(course.code), so the whole course moves to Archived. Nothing is deleted — you can get it back from the bottom of the sidebar."
                )
            } else {
                removalRequest = RemovalRequest(
                    courseCode: course.code,
                    sectionNumber: sectionNumber,
                    title: "Remove Section \(sectionNumber) of \(course.code)?",
                    message: "Nothing is deleted. This section moves to Archived, at the bottom of the sidebar, where you can get it back."
                )
            }
        }
    }

    func performRemoval(_ request: RemovalRequest) {
        guard let coursesDirectoryURL = workspace.coursesDirectoryURL else {
            return
        }
        var courseToRemove: Course?
        for course in workspace.courses {
            if course.code == request.courseCode {
                courseToRemove = course
            }
        }
        guard let courseToRemove else {
            return
        }

        do {
            if let sectionNumber = request.sectionNumber {
                try CourseArchiver.archiveAndRemoveSection(
                    sectionNumber,
                    from: courseToRemove,
                    coursesDirectoryURL: coursesDirectoryURL
                )
            } else {
                try CourseArchiver.archiveAndRemoveCourse(
                    courseToRemove,
                    coursesDirectoryURL: coursesDirectoryURL
                )
            }
        } catch {
            removalProblem = error.localizedDescription
            return
        }

        workspace.selection = nil
        workspace.reloadCourses()
    }
}

/// One section's scheduled deploy, as the sidebar's sheet and alert pass it
/// around. `when` is nil while asking for a time, and carries the agent's own
/// moment while asking whether to cancel it.
struct ScheduledDeployRequest: Identifiable {

    // MARK: - Stored properties

    let course: Course
    let sectionNumber: Int
    let when: Date?

    // MARK: - Computed properties

    var id: String {
        return "\(course.code)-section\(sectionNumber)"
    }
}

/// What the remove button is about to do, pending confirmation.
struct RemovalRequest: Identifiable {

    // MARK: - Stored properties

    let courseCode: String

    /// nil means the whole course.
    let sectionNumber: Int?

    let title: String
    let message: String

    // MARK: - Computed properties

    var id: String {
        if let sectionNumber {
            return "\(courseCode)-section\(sectionNumber)"
        }
        return courseCode
    }
}
