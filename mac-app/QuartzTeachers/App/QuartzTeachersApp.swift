import SwiftUI

@main
struct QuartzTeachersApp: App {

    // MARK: - Stored properties

    @State var workspace = WorkspaceModel.shared

    // MARK: - Initializer

    init() {
        // Register bundled fonts so the settings form can preview the
        // site font choices.
        BundledFontList.registerFonts()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup("Containerized Quartz for Teachers") {
            MainWindowView()
                .environment(workspace)
                .frame(minWidth: 900, minHeight: 600)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Change Working Folder…") {
                    workspace.isChoosingWorkspace = true
                }
                Button("Reload Courses") {
                    workspace.reloadCourses()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
}
