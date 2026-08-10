import SwiftUI

/// The "Courses & Clubs" sidebar: each course expands to show its
/// sections, with the add/remove/filter bar macOS lists conventionally
/// carry along their bottom edge.
struct SidebarView: View {

    // MARK: - Stored properties

    @Environment(WorkspaceModel.self) var workspace

    /// The item the remove button is asking about, if any.
    @State var removalRequest: RemovalRequest?

    /// A failure while archiving, shown as an alert.
    @State var removalProblem: String?

    // MARK: - Body

    var body: some View {
        @Bindable var workspace = workspace

        VStack(spacing: 0) {
            List(selection: $workspace.selection) {
                Section("Courses & Clubs") {
                    ForEach(workspace.filteredCourses) { course in
                        DisclosureGroup {
                            ForEach(course.sectionNumbers, id: \.self) { sectionNumber in
                                Label("Section \(sectionNumber)", systemImage: "doc.richtext")
                                    .tag(SidebarSelection.section(course.code, sectionNumber))
                                    .accessibilityIdentifier("sidebar-\(course.code)-section\(sectionNumber)")
                                    .contextMenu {
                                        folderMenuItems(for: course.sectionDirectoryURL(forSection: sectionNumber))
                                    }
                            }
                        } label: {
                            Label(course.code, systemImage: "books.vertical")
                                .tag(SidebarSelection.course(course.code))
                                .accessibilityIdentifier("sidebar-\(course.code)")
                                .contextMenu {
                                    folderMenuItems(for: course.directoryURL)
                                }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .accessibilityIdentifier("coursesSidebar")

            Divider()

            bottomBar
        }
        .alert(item: $removalRequest) { request in
            Alert(
                title: Text(request.title),
                message: Text(request.message),
                primaryButton: .destructive(Text("Remove")) {
                    performRemoval(request)
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Could not remove", isPresented: removalProblemBinding) {
            Button("OK") {
                removalProblem = nil
            }
        } message: {
            Text(removalProblem ?? "")
        }
    }

    /// How big the footer's +/- targets are. Named so a test can check the
    /// buttons really are this size on screen.
    static let footerButtonSize: CGSize = CGSize(width: 24, height: 22)

    /// Add, remove, and filter — the standard macOS list footer.
    var bottomBar: some View {
        @Bindable var workspace = workspace

        return HStack(spacing: 6) {
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
                    .frame(width: SidebarView.footerButtonSize.width, height: SidebarView.footerButtonSize.height)
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
                    .frame(width: SidebarView.footerButtonSize.width, height: SidebarView.footerButtonSize.height)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .disabled(workspace.selection == nil)
            .help("Remove the selected course or section")
            .accessibilityIdentifier("removeSelectedButton")

            TextField("Filter", text: $workspace.filterText)
                .textFieldStyle(.roundedBorder)
                .controlSize(.small)
                .accessibilityIdentifier("courseFilterField")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - Computed properties

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

    // MARK: - Functions

    /// The shared context-menu items for a course or section folder.
    @ViewBuilder
    func folderMenuItems(for folderURL: URL) -> some View {
        Button("Show in Finder", systemImage: "folder") {
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
                message: "\(course.code) and all of its sections will be moved out of your working folder. Nothing is deleted — a copy is archived in the _backups folder, so you can get it back."
            )
        case .section(_, let sectionNumber):
            if course.sectionNumbers.count <= 1 {
                // Removing the only section leaves nothing behind, so be
                // explicit that this removes the whole course.
                removalRequest = RemovalRequest(
                    courseCode: course.code,
                    sectionNumber: nil,
                    title: "Remove \(course.code)?",
                    message: "Section \(sectionNumber) is the only section of \(course.code), so the whole course will be moved out of your working folder. Nothing is deleted — a copy is archived in the _backups folder."
                )
            } else {
                removalRequest = RemovalRequest(
                    courseCode: course.code,
                    sectionNumber: sectionNumber,
                    title: "Remove Section \(sectionNumber) of \(course.code)?",
                    message: "This section will be moved out of your working folder. Nothing is deleted — a copy is archived in the _backups folder, so you can get it back."
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
