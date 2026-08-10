import SwiftUI

/// The app's single window: a collapsible sidebar of courses and sections,
/// with either course settings or a section's preview/deploy view beside it.
struct MainWindowView: View {

    // MARK: - Stored properties

    @Environment(WorkspaceModel.self) var workspace

    /// Matches the sidebar's footer, so both dividers sit on one line.
    @ScaledMetric(relativeTo: .body) var scaledFooterHeight: CGFloat = WindowChrome.footerHeight

    // MARK: - Body

    var body: some View {
        @Bindable var workspace = workspace

        Group {
            if workspace.workspaceURL == nil || workspace.workspaceProblem != nil || workspace.workspaceCanBeInitialized || workspace.workspaceIsUnrecognized {
                WorkspacePickerView()
            } else {
                NavigationSplitView {
                    SidebarView()
                        .navigationSplitViewColumnWidth(min: 180, ideal: 220)
                } detail: {
                    // The path bar sits under the content, spanning the
                    // detail column, exactly where Finder puts its own.
                    VStack(spacing: 0) {
                        detailView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        workingFolderPathBar
                    }
                }
            }
        }
        // Adding a course lives on the sidebar's own +/- bar, where
        // macOS list interfaces conventionally put it.
        .sheet(isPresented: $workspace.isShowingNewCourseWizard) {
            NewCourseWizardView()
        }
        .fileImporter(
            isPresented: $workspace.isChoosingWorkspace,
            allowedContentTypes: [.folder]
        ) { result in
            switch result {
            case .success(let url):
                workspace.chooseWorkspace(at: url)
            case .failure:
                break
            }
        }
    }

    // MARK: - Computed properties

    /// A footer showing which folder this window is working in, in the
    /// same form Finder's Path Bar uses.
    @ViewBuilder
    var workingFolderPathBar: some View {
        if let workspaceURL = workspace.workspaceURL {
            Divider()
            FinderPathBarView(folderURL: workspaceURL)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: scaledFooterHeight, maxHeight: scaledFooterHeight, alignment: .leading)
                .background(.bar)
                .help(workspaceURL.path)
                .accessibilityIdentifier("windowPathBar")
        }
    }

    @ViewBuilder
    var detailView: some View {
        switch workspace.selection {
        case .course(let code):
            if let course = course(withCode: code) {
                CourseSettingsView(course: course)
                    .id(code)
            } else {
                missingSelectionView
            }
        case .section(let code, let sectionNumber):
            if let course = course(withCode: code) {
                SectionDetailView(course: course, sectionNumber: sectionNumber)
                    .id("\(code)-\(sectionNumber)")
            } else {
                missingSelectionView
            }
        case .archived(let identifier):
            if let item = archivedItem(withIdentifier: identifier) {
                ContentUnavailableView {
                    Label(item.title, systemImage: item.symbolName)
                } description: {
                    Text("\(item.subtitle). It is not part of your courses until you restore it.")
                } actions: {
                    Button("Restore…") {
                        workspace.restoreRequest = item
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("restoreArchivedButton")
                }
            } else {
                missingSelectionView
            }
        case nil:
            // Telling someone to choose from an empty list is a dead end.
            if workspace.courses.isEmpty {
                ContentUnavailableView {
                    Label("No Courses Yet", systemImage: "books.vertical")
                } description: {
                    Text("Add your first course, or start from the example course to see how everything fits together.")
                } actions: {
                    Button("Add a Course…") {
                        workspace.isShowingNewCourseWizard = true
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("emptyStateAddCourseButton")
                }
            } else {
                ContentUnavailableView(
                    "Select a Course or Section",
                    systemImage: "sidebar.left",
                    description: Text("Choose a course to edit its settings, or a section to preview and publish its website.")
                )
            }
        }
    }

    var missingSelectionView: some View {
        ContentUnavailableView(
            "Course Not Found",
            systemImage: "questionmark.folder",
            description: Text("Reload courses from the File menu, or choose a different working folder.")
        )
    }

    // MARK: - Functions

    func archivedItem(withIdentifier identifier: String) -> ArchivedItem? {
        for item in workspace.archivedItems {
            if item.id == identifier {
                return item
            }
        }
        return nil
    }

    func course(withCode code: String) -> Course? {
        for course in workspace.courses {
            if course.code == code {
                return course
            }
        }
        return nil
    }
}
