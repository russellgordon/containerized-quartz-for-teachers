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

    /// Add, remove, and filter — the standard macOS list footer.
    var bottomBar: some View {
        @Bindable var workspace = workspace

        return HStack(spacing: 6) {
            Button("Add Course or Club", systemImage: "plus") {
                workspace.isShowingNewCourseWizard = true
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .accessibilityIdentifier("addCourseButton")

            Button("Remove Selected", systemImage: "minus") {
                prepareRemoval()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .disabled(workspace.selection == nil)
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
