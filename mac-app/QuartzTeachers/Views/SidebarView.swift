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
                        }
                    } label: {
                        Label(course.code, systemImage: "books.vertical")
                            .tag(SidebarSelection.course(course.code))
                            .accessibilityIdentifier("sidebar-\(course.code)")
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .accessibilityIdentifier("coursesSidebar")
    }
}
