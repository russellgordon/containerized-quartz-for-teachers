import SwiftUI

/// The "Courses & Clubs" sidebar: each course expands to show its sections.
struct SidebarView: View {

    // MARK: - Stored properties

    @Environment(WorkspaceModel.self) var workspace

    // MARK: - Body

    var body: some View {
        @Bindable var workspace = workspace

        List(selection: $workspace.selection) {
            Section("Courses & Clubs") {
                ForEach(workspace.courses) { course in
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
}
